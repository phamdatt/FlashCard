//
//  DatabaseManager.swift
//  flash-card
//
//  Created by Dat Pham on 4/2/26.
//

import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    private let currentSeedVersion = 1

    private init() {
        openDatabase()
        createTables()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Database Setup

    private func openDatabase() {
        let fileURL = DatabaseManager.databaseURL()

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("❌ Error opening database: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("✅ Database opened at \(fileURL.path)")
        }
    }

    static func databaseURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("flash-card", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("flashcards.sqlite")
    }

    private func createTables() {
        let createSQL = """
        CREATE TABLE IF NOT EXISTS subjects (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            icon TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS topics (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            subject_name TEXT NOT NULL,
            topic_key TEXT NOT NULL UNIQUE,
            sort_order INTEGER NOT NULL DEFAULT 0
        );
        CREATE INDEX IF NOT EXISTS idx_topics_subject ON topics(subject_name);

        CREATE TABLE IF NOT EXISTS flashcards (
            id TEXT PRIMARY KEY,
            topic_key TEXT NOT NULL,
            question TEXT NOT NULL,
            answer TEXT NOT NULL,
            hint TEXT,
            exercise_type TEXT NOT NULL DEFAULT 'Dịch Anh → Việt'
        );
        CREATE INDEX IF NOT EXISTS idx_flashcards_topic ON flashcards(topic_key);

        CREATE TABLE IF NOT EXISTS reading_passages (
            id TEXT PRIMARY KEY,
            topic_key TEXT NOT NULL,
            title TEXT NOT NULL,
            level TEXT NOT NULL,
            content TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0
        );
        CREATE INDEX IF NOT EXISTS idx_reading_passages_topic ON reading_passages(topic_key);

        CREATE TABLE IF NOT EXISTS reading_questions (
            id TEXT PRIMARY KEY,
            passage_id TEXT NOT NULL,
            question TEXT NOT NULL,
            option_a TEXT NOT NULL,
            option_b TEXT NOT NULL,
            option_c TEXT NOT NULL,
            option_d TEXT NOT NULL,
            correct_answer TEXT NOT NULL,
            explanation TEXT,
            sort_order INTEGER NOT NULL DEFAULT 0
        );
        CREATE INDEX IF NOT EXISTS idx_reading_questions_passage ON reading_questions(passage_id);

        CREATE TABLE IF NOT EXISTS vocabulary_items (
            id TEXT PRIMARY KEY,
            passage_id TEXT NOT NULL,
            word TEXT NOT NULL,
            meaning TEXT NOT NULL,
            example TEXT,
            sort_order INTEGER NOT NULL DEFAULT 0
        );
        CREATE INDEX IF NOT EXISTS idx_vocabulary_items_passage ON vocabulary_items(passage_id);
        """

        if sqlite3_exec(db, createSQL, nil, nil, nil) != SQLITE_OK {
            print("❌ Error creating tables: \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    // MARK: - Seed Versioning

    private var needsSeeding: Bool {
        UserDefaults.standard.integer(forKey: "db_seed_version") < currentSeedVersion
    }

    private func markSeeded() {
        UserDefaults.standard.set(currentSeedVersion, forKey: "db_seed_version")
    }

    // MARK: - Seed All Data

    func seedAllData() {
        guard needsSeeding else { return }

        print("🌱 Seeding database...")
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)

        importSubjectsCSV()
        importTopicsCSV()

        // Import all flashcard CSVs
        let topicFiles: [(filename: String, topicKey: String)] = [
            ("flashcards_family", "family"),
            ("flashcards_seasons", "seasons"),
            ("flashcards_colors", "colors"),
            ("flashcards_days", "days"),
            ("flashcards_food", "food"),
            ("flashcards_fruits", "fruits"),
            ("flashcards_animals", "animals"),
            ("flashcards_body", "body"),
            ("flashcards_clothes", "clothes"),
            ("flashcards_weather", "weather"),
            ("flashcards_christmas", "christmas"),
            ("flashcards_kitchen", "kitchen"),
            ("flashcards_tet", "tet"),
            ("flashcards_verbs", "verbs"),
            ("flashcards_adjectives", "adjectives"),
            ("flashcards_places", "places"),
            ("flashcards_internet", "internet"),
            ("flashcards_accommodation", "accommodation"),
            ("flashcards_study", "study"),
            ("flashcards_work", "work"),
            ("flashcards_daily_routine", "daily_routine"),
            ("flashcards_office_life", "office_life"),
            ("flashcards_transportation", "transportation"),
            ("flashcards_shopping", "shopping"),
            ("flashcards_hometown", "hometown"),
            ("flashcards_hospital", "hospital"),
            ("flashcards_ielts_environment", "ielts_environment"),
            ("flashcards_ielts_technology", "ielts_technology"),
            ("flashcards_ielts_health", "ielts_health"),
            ("flashcards_ielts_education", "ielts_education"),
            ("flashcards_ielts_society", "ielts_society"),
            ("flashcards_ielts_personality", "ielts_personality"),
            ("flashcards_it_vocabulary", "it_vocabulary"),
            ("flashcards_chinese_family", "chinese_family"),
            ("flashcards_chinese_colors", "chinese_colors"),
            ("flashcards_chinese_radicals", "chinese_radicals"),
        ]

        for (filename, key) in topicFiles {
            importFlashcardsCSV(filename: filename, topicKey: key)
        }

        // HSK3 (existing CSV format with 3 fields)
        importCSV(filename: "hsk3", topicKey: "hsk3")

        // Import reading passages
        importReadingsJSON()

        sqlite3_exec(db, "COMMIT", nil, nil, nil)
        markSeeded()
        print("✅ Database seeding complete")
    }

    // MARK: - Import Subjects

    private func importSubjectsCSV() {
        guard let fileURL = Bundle.main.url(forResource: "subjects", withExtension: "csv") else {
            print("❌ subjects.csv not found in bundle")
            return
        }
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return }

        let insertSQL = "INSERT OR IGNORE INTO subjects (id, name, icon, sort_order) VALUES (?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else { return }

        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        for line in lines {
            let fields = parseCSVLine(line)
            guard fields.count >= 3 else { continue }

            let name = fields[0].trimmingCharacters(in: .whitespaces)
            let icon = fields[1].trimmingCharacters(in: .whitespaces)
            let sortOrder = Int(fields[2].trimmingCharacters(in: .whitespaces)) ?? 0

            sqlite3_reset(stmt)
            let id = UUID().uuidString
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (icon as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 4, Int32(sortOrder))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        print("✅ Imported subjects")
    }

    // MARK: - Import Topics

    private func importTopicsCSV() {
        guard let fileURL = Bundle.main.url(forResource: "topics", withExtension: "csv") else {
            print("❌ topics.csv not found in bundle")
            return
        }
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return }

        let insertSQL = "INSERT OR IGNORE INTO topics (id, topic_key, name, subject_name, sort_order) VALUES (?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else { return }

        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        for line in lines {
            let fields = parseCSVLine(line)
            guard fields.count >= 4 else { continue }

            let topicKey = fields[0].trimmingCharacters(in: .whitespaces)
            let name = fields[1].trimmingCharacters(in: .whitespaces)
            let subjectName = fields[2].trimmingCharacters(in: .whitespaces)
            let sortOrder = Int(fields[3].trimmingCharacters(in: .whitespaces)) ?? 0

            sqlite3_reset(stmt)
            let id = UUID().uuidString
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (topicKey as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (subjectName as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 5, Int32(sortOrder))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        print("✅ Imported topics")
    }

    // MARK: - Import Flashcards (4-field CSV)

    @discardableResult
    private func importFlashcardsCSV(filename: String, topicKey: String) -> Int {
        if flashcardCount(for: topicKey) > 0 {
            return flashcardCount(for: topicKey)
        }

        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "csv") else {
            print("❌ CSV file '\(filename).csv' not found in bundle")
            return 0
        }
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return 0 }

        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var count = 0
        let insertSQL = "INSERT OR IGNORE INTO flashcards (id, topic_key, question, answer, hint, exercise_type) VALUES (?, ?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else { return 0 }

        for line in lines {
            let fields = parseCSVLine(line)
            guard fields.count >= 3 else { continue }

            let question = fields[0].trimmingCharacters(in: .whitespaces)
            let answer = fields[1].trimmingCharacters(in: .whitespaces)
            let hint = fields[2].trimmingCharacters(in: .whitespaces)
            let exerciseType: String
            if fields.count >= 4 {
                exerciseType = fields[3].trimmingCharacters(in: .whitespaces)
            } else {
                exerciseType = ExerciseType.englishToVietnamese.rawValue
            }

            guard !question.isEmpty, !answer.isEmpty else { continue }

            sqlite3_reset(stmt)
            let id = UUID().uuidString
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (topicKey as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (question as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (answer as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (hint as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (exerciseType as NSString).utf8String, -1, nil)

            if sqlite3_step(stmt) == SQLITE_DONE {
                count += 1
            }
        }

        sqlite3_finalize(stmt)
        print("✅ Imported \(count) flashcards for '\(topicKey)'")
        return count
    }

    // MARK: - Import HSK3 CSV (legacy 3-field format)

    @discardableResult
    func importCSV(filename: String, topicKey: String) -> Int {
        if flashcardCount(for: topicKey) > 0 {
            return flashcardCount(for: topicKey)
        }

        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "csv") else {
            print("❌ CSV file '\(filename).csv' not found in bundle")
            return 0
        }
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return 0 }

        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var count = 0
        let insertSQL = "INSERT OR IGNORE INTO flashcards (id, topic_key, question, answer, hint, exercise_type) VALUES (?, ?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else { return 0 }

        for line in lines {
            let fields = parseCSVLine(line)
            guard fields.count >= 3 else { continue }

            let word = fields[0].trimmingCharacters(in: .whitespaces)
            let meaning = fields[1].trimmingCharacters(in: .whitespaces)
            let hint = fields[2].trimmingCharacters(in: .whitespaces)

            guard !word.isEmpty, !meaning.isEmpty else { continue }

            sqlite3_reset(stmt)
            let id = UUID().uuidString
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (topicKey as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (word as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (meaning as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (hint as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (ExerciseType.englishToVietnamese.rawValue as NSString).utf8String, -1, nil)

            if sqlite3_step(stmt) == SQLITE_DONE {
                count += 1
            }
        }

        sqlite3_finalize(stmt)
        print("✅ Imported \(count) flashcards for '\(topicKey)'")
        return count
    }

    // MARK: - Import Reading Passages (JSON)

    private func importReadingsJSON() {
        guard let fileURL = Bundle.main.url(forResource: "readings_seed", withExtension: "json") else {
            print("❌ readings_seed.json not found in bundle")
            return
        }
        guard let data = try? Data(contentsOf: fileURL) else { return }

        struct SeedReadingTopic: Codable {
            let topic_key: String
            let passages: [SeedPassage]
        }
        struct SeedPassage: Codable {
            let title: String
            let level: String
            let content: String
            let questions: [SeedQuestion]
            let vocabulary: [SeedVocab]?
        }
        struct SeedQuestion: Codable {
            let question: String
            let options: [String]
            let correct_answer: String
            let explanation: String?
        }
        struct SeedVocab: Codable {
            let word: String
            let meaning: String
            let example: String?
        }

        guard let topics = try? JSONDecoder().decode([SeedReadingTopic].self, from: data) else {
            print("❌ Failed to decode readings_seed.json")
            return
        }

        let passageSQL = "INSERT OR IGNORE INTO reading_passages (id, topic_key, title, level, content, sort_order) VALUES (?, ?, ?, ?, ?, ?)"
        let questionSQL = "INSERT OR IGNORE INTO reading_questions (id, passage_id, question, option_a, option_b, option_c, option_d, correct_answer, explanation, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        let vocabSQL = "INSERT OR IGNORE INTO vocabulary_items (id, passage_id, word, meaning, example, sort_order) VALUES (?, ?, ?, ?, ?, ?)"

        var pStmt: OpaquePointer?
        var qStmt: OpaquePointer?
        var vStmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, passageSQL, -1, &pStmt, nil) == SQLITE_OK,
              sqlite3_prepare_v2(db, questionSQL, -1, &qStmt, nil) == SQLITE_OK,
              sqlite3_prepare_v2(db, vocabSQL, -1, &vStmt, nil) == SQLITE_OK else {
            print("❌ Failed to prepare reading statements")
            return
        }

        var passageCount = 0
        for topic in topics {
            for (pIdx, passage) in topic.passages.enumerated() {
                let passageId = UUID().uuidString

                sqlite3_reset(pStmt)
                sqlite3_bind_text(pStmt, 1, (passageId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(pStmt, 2, (topic.topic_key as NSString).utf8String, -1, nil)
                sqlite3_bind_text(pStmt, 3, (passage.title as NSString).utf8String, -1, nil)
                sqlite3_bind_text(pStmt, 4, (passage.level as NSString).utf8String, -1, nil)
                sqlite3_bind_text(pStmt, 5, (passage.content as NSString).utf8String, -1, nil)
                sqlite3_bind_int(pStmt, 6, Int32(pIdx))

                if sqlite3_step(pStmt) == SQLITE_DONE {
                    passageCount += 1
                }

                // Insert questions
                for (qIdx, q) in passage.questions.enumerated() {
                    sqlite3_reset(qStmt)
                    let qId = UUID().uuidString
                    sqlite3_bind_text(qStmt, 1, (qId as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(qStmt, 2, (passageId as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(qStmt, 3, (q.question as NSString).utf8String, -1, nil)

                    let optA = q.options.count > 0 ? q.options[0] : ""
                    let optB = q.options.count > 1 ? q.options[1] : ""
                    let optC = q.options.count > 2 ? q.options[2] : ""
                    let optD = q.options.count > 3 ? q.options[3] : ""

                    sqlite3_bind_text(qStmt, 4, (optA as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(qStmt, 5, (optB as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(qStmt, 6, (optC as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(qStmt, 7, (optD as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(qStmt, 8, (q.correct_answer as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(qStmt, 9, ((q.explanation ?? "") as NSString).utf8String, -1, nil)
                    sqlite3_bind_int(qStmt, 10, Int32(qIdx))
                    sqlite3_step(qStmt)
                }

                // Insert vocabulary
                if let vocab = passage.vocabulary {
                    for (vIdx, v) in vocab.enumerated() {
                        sqlite3_reset(vStmt)
                        let vId = UUID().uuidString
                        sqlite3_bind_text(vStmt, 1, (vId as NSString).utf8String, -1, nil)
                        sqlite3_bind_text(vStmt, 2, (passageId as NSString).utf8String, -1, nil)
                        sqlite3_bind_text(vStmt, 3, (v.word as NSString).utf8String, -1, nil)
                        sqlite3_bind_text(vStmt, 4, (v.meaning as NSString).utf8String, -1, nil)
                        sqlite3_bind_text(vStmt, 5, ((v.example ?? "") as NSString).utf8String, -1, nil)
                        sqlite3_bind_int(vStmt, 6, Int32(vIdx))
                        sqlite3_step(vStmt)
                    }
                }
            }
        }

        sqlite3_finalize(pStmt)
        sqlite3_finalize(qStmt)
        sqlite3_finalize(vStmt)
        print("✅ Imported \(passageCount) reading passages")
    }

    // MARK: - Load All Subjects

    func loadAllSubjects() -> [Subject] {
        var subjects: [Subject] = []

        let sql = "SELECT name, icon FROM subjects ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let name = String(cString: sqlite3_column_text(stmt, 0))
            let icon = String(cString: sqlite3_column_text(stmt, 1))

            let topics = loadTopics(for: name)
            subjects.append(Subject(name: name, icon: icon, topics: topics))
        }
        sqlite3_finalize(stmt)
        return subjects
    }

    // MARK: - Load Topics

    private func loadTopics(for subjectName: String) -> [Topic] {
        var topics: [Topic] = []
        
        // Thêm topic_key vào câu lệnh SELECT
        let sql = "SELECT id, name, topic_key FROM topics WHERE subject_name = ? ORDER BY sort_order"
        var stmt: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        
        sqlite3_bind_text(stmt, 1, (subjectName as NSString).utf8String, -1, nil)
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let idStr = String(cString: sqlite3_column_text(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let topicKey = String(cString: sqlite3_column_text(stmt, 2)) // Lấy topicKey từ DB
            
            let flashcards = loadFlashcards(for: topicKey)
            let readings = loadReadings(for: topicKey)
            
            // Thêm topicKey: topicKey vào hàm khởi tạo
            topics.append(Topic(
                id: UUID(uuidString: idStr) ?? UUID(),
                name: name,
                subjectName: subjectName,
                topicKey: topicKey, // <--- Sửa ở đây
                flashcards: flashcards,
                readings: readings
            ))
        }
        sqlite3_finalize(stmt)
        return topics
    }

    // MARK: - Load Flashcards

    func loadFlashcards(for topicKey: String) -> [Flashcard] {
        var flashcards: [Flashcard] = []

        let querySQL = "SELECT id, question, answer, hint, exercise_type FROM flashcards WHERE topic_key = ?"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, querySQL, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_text(stmt, 1, (topicKey as NSString).utf8String, -1, nil)

        while sqlite3_step(stmt) == SQLITE_ROW {
            let idStr = String(cString: sqlite3_column_text(stmt, 0))
            let question = String(cString: sqlite3_column_text(stmt, 1))
            let answer = String(cString: sqlite3_column_text(stmt, 2))
            let hint: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
            let exerciseTypeStr = String(cString: sqlite3_column_text(stmt, 4))

            let exerciseType = ExerciseType(rawValue: exerciseTypeStr) ?? .englishToVietnamese
            let id = UUID(uuidString: idStr) ?? UUID()

            flashcards.append(Flashcard(
                id: id,
                question: question,
                answer: answer,
                hint: hint,
                options: nil,
                correctAnswer: nil,
                exerciseType: exerciseType
            ))
        }
        sqlite3_finalize(stmt)

        // Generate multiple choice options
        return generateOptions(for: flashcards)
    }

    // MARK: - Load Reading Passages

    private func loadReadings(for topicKey: String) -> [ReadingPassage] {
        var passages: [ReadingPassage] = []

        let sql = "SELECT id, title, level, content FROM reading_passages WHERE topic_key = ? ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_text(stmt, 1, (topicKey as NSString).utf8String, -1, nil)

        while sqlite3_step(stmt) == SQLITE_ROW {
            let passageId = String(cString: sqlite3_column_text(stmt, 0))
            let title = String(cString: sqlite3_column_text(stmt, 1))
            let levelStr = String(cString: sqlite3_column_text(stmt, 2))
            let content = String(cString: sqlite3_column_text(stmt, 3))

            let level = ReadingLevel(rawValue: levelStr) ?? .beginner
            let questions = loadReadingQuestions(for: passageId)
            let vocabulary = loadVocabulary(for: passageId)

            passages.append(ReadingPassage(
                title: title,
                level: level,
                content: content,
                questions: questions,
                vocabularyHelp: vocabulary.isEmpty ? nil : vocabulary
            ))
        }
        sqlite3_finalize(stmt)
        return passages
    }

    private func loadReadingQuestions(for passageId: String) -> [ReadingQuestion] {
        var questions: [ReadingQuestion] = []

        let sql = "SELECT question, option_a, option_b, option_c, option_d, correct_answer, explanation FROM reading_questions WHERE passage_id = ? ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_text(stmt, 1, (passageId as NSString).utf8String, -1, nil)

        while sqlite3_step(stmt) == SQLITE_ROW {
            let question = String(cString: sqlite3_column_text(stmt, 0))
            let optA = String(cString: sqlite3_column_text(stmt, 1))
            let optB = String(cString: sqlite3_column_text(stmt, 2))
            let optC = String(cString: sqlite3_column_text(stmt, 3))
            let optD = String(cString: sqlite3_column_text(stmt, 4))
            let correctAnswer = String(cString: sqlite3_column_text(stmt, 5))
            let explanation: String? = sqlite3_column_text(stmt, 6).map { String(cString: $0) }

            questions.append(ReadingQuestion(
                question: question,
                options: [optA, optB, optC, optD],
                correctAnswer: correctAnswer,
                explanation: explanation?.isEmpty == true ? nil : explanation
            ))
        }
        sqlite3_finalize(stmt)
        return questions
    }

    private func loadVocabulary(for passageId: String) -> [VocabularyItem] {
        var items: [VocabularyItem] = []

        let sql = "SELECT word, meaning, example FROM vocabulary_items WHERE passage_id = ? ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_text(stmt, 1, (passageId as NSString).utf8String, -1, nil)

        while sqlite3_step(stmt) == SQLITE_ROW {
            let word = String(cString: sqlite3_column_text(stmt, 0))
            let meaning = String(cString: sqlite3_column_text(stmt, 1))
            let example: String? = sqlite3_column_text(stmt, 2).map { String(cString: $0) }

            items.append(VocabularyItem(
                word: word,
                meaning: meaning,
                example: example?.isEmpty == true ? nil : example
            ))
        }
        sqlite3_finalize(stmt)
        return items
    }

    // MARK: - Helpers

    func flashcardCount(for topicKey: String) -> Int {
        let sql = "SELECT COUNT(*) FROM flashcards WHERE topic_key = ?"
        var stmt: OpaquePointer?
        var count = 0

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (topicKey as NSString).utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)

        return fields
    }

    private func generateOptions(for flashcards: [Flashcard]) -> [Flashcard] {
        guard flashcards.count >= 4 else { return flashcards }

        let allAnswers = flashcards.map { $0.answer }

        return flashcards.map { card in
            let wrongPool = allAnswers.filter { $0 != card.answer }.shuffled()
            let wrongAnswers = Array(wrongPool.prefix(3))

            var allChoices = wrongAnswers + [card.answer]
            allChoices.shuffle()

            let labels = ["A", "B", "C", "D"]
            var options: [String] = []
            var correctLabel = "A"

            for (i, ans) in allChoices.prefix(4).enumerated() {
                options.append("\(labels[i]). \(ans)")
                if ans == card.answer {
                    correctLabel = labels[i]
                }
            }

            return Flashcard(
                id: card.id,
                question: card.question,
                answer: card.answer,
                hint: card.hint,
                options: options,
                correctAnswer: correctLabel,
                exerciseType: card.exerciseType
            )
        }
    }

    // MARK: - CRUD Operations

    func insertTopic(_ topic: Topic) {
        // Thứ tự: 1:id, 2:name, 3:subject_name, 4:topic_key, 5:sort_order
        let insertSQL = "INSERT INTO topics (id, name, subject_name, topic_key, sort_order) VALUES (?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK {
            let currentCount = Int32(getTotalTopicsCount(for: topic.subjectName))
            
            // Bind ID (Vị trí 1)
            sqlite3_bind_text(stmt, 1, (topic.id.uuidString as NSString).utf8String, -1, nil)
            // Bind Name (Vị trí 2)
            sqlite3_bind_text(stmt, 2, (topic.name as NSString).utf8String, -1, nil)
            // Bind Subject Name (Vị trí 3)
            sqlite3_bind_text(stmt, 3, (topic.subjectName as NSString).utf8String, -1, nil)
            // Bind Topic Key (Vị trí 4)
            sqlite3_bind_text(stmt, 4, (topic.topicKey as NSString).utf8String, -1, nil)
            // Bind Sort Order (Vị trí 5)
            sqlite3_bind_int(stmt, 5, currentCount)
            
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("❌ Error: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(stmt)
    }

    /// Thêm một Flashcard mới vào database
    func insertFlashcard(_ card: Flashcard, topicKey: String) {
        let insertSQL = "INSERT INTO flashcards (id, topic_key, question, answer, hint, exercise_type) VALUES (?, ?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (card.id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (topicKey as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (card.question as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, (card.answer as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, ((card.hint ?? "") as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, (card.exerciseType.rawValue as NSString).utf8String, -1, nil)
            
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("❌ Error inserting flashcard: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(stmt)
    }

    /// Xóa Topic và tất cả Flashcards/Readings liên quan
    func deleteTopic(topicKey: String) {
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)
        
        let queries = [
            "DELETE FROM flashcards WHERE topic_key = '\(topicKey)'",
            "DELETE FROM reading_passages WHERE topic_key = '\(topicKey)'",
            "DELETE FROM topics WHERE topic_key = '\(topicKey)'"
        ]
        
        for query in queries {
            if sqlite3_exec(db, query, nil, nil, nil) != SQLITE_OK {
                print("❌ Error deleting during topic removal: \(String(cString: sqlite3_errmsg(db)))")
                sqlite3_exec(db, "ROLLBACK", nil, nil, nil)
                return
            }
        }
        
        sqlite3_exec(db, "COMMIT", nil, nil, nil)
    }

    /// Xóa một Flashcard cụ thể theo ID
    func deleteFlashcard(id: UUID) {
        let deleteSQL = "DELETE FROM flashcards WHERE id = ?"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    // MARK: - Private Helpers for CRUD

    private func getTotalTopicsCount(for subjectName: String) -> Int {
        let sql = "SELECT COUNT(*) FROM topics WHERE subject_name = ?"
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (subjectName as NSString).utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }
}
