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
    private let currentSeedVersion = 4

    private init() {
        copyDatabaseIfNeeded()
        openDatabase()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Database Setup
    private func copyDatabaseIfNeeded() {
        let destURL = DatabaseManager.databaseURL()
        let fileManager = FileManager.default

        let savedVersion = UserDefaults.standard.integer(forKey: "db_seed_version")
        let needsMigration = savedVersion < currentSeedVersion
        let dbExists = fileManager.fileExists(atPath: destURL.path)

        if !dbExists || needsMigration {
            guard let bundleURL = Bundle.main.url(forResource: "flashcards", withExtension: "sqlite") else {
                print("❌ flashcards.sqlite not found in bundle")
                return
            }

            var userTopics: [(name: String, subjectId: Int, sortOrder: Int)] = []
            var userFlashcards: [(topicName: String, subjectId: Int, question: String, answer: String, hint: String, exerciseType: String)] = []

            if dbExists {
                var oldDb: OpaquePointer?
                if sqlite3_open(destURL.path, &oldDb) == SQLITE_OK {
                    var stmt: OpaquePointer?
                    let topicSQL = "SELECT name, subject_id, sort_order FROM topics WHERE is_user_created = 1"
                    if sqlite3_prepare_v2(oldDb, topicSQL, -1, &stmt, nil) == SQLITE_OK {
                        while sqlite3_step(stmt) == SQLITE_ROW {
                            let name = String(cString: sqlite3_column_text(stmt, 0))
                            let subjectId = Int(sqlite3_column_int(stmt, 1))
                            let sortOrder = Int(sqlite3_column_int(stmt, 2))
                            userTopics.append((name, subjectId, sortOrder))
                        }
                    }
                    sqlite3_finalize(stmt)

                    let cardSQL = """
                        SELECT t.name, t.subject_id, f.question, f.answer, COALESCE(f.hint, ''), f.exercise_type
                        FROM vocabularies f
                        JOIN topics t ON f.topic_id = t.id
                        WHERE t.is_user_created = 1
                    """
                    if sqlite3_prepare_v2(oldDb, cardSQL, -1, &stmt, nil) == SQLITE_OK {
                        while sqlite3_step(stmt) == SQLITE_ROW {
                            let topicName = String(cString: sqlite3_column_text(stmt, 0))
                            let subjectId = Int(sqlite3_column_int(stmt, 1))
                            let question = String(cString: sqlite3_column_text(stmt, 2))
                            let answer = String(cString: sqlite3_column_text(stmt, 3))
                            let hint = String(cString: sqlite3_column_text(stmt, 4))
                            let exerciseType = String(cString: sqlite3_column_text(stmt, 5))
                            userFlashcards.append((topicName, subjectId, question, answer, hint, exerciseType))
                        }
                    }
                    sqlite3_finalize(stmt)
                }
                sqlite3_close(oldDb)
                print("💾 Backed up \(userTopics.count) user topics, \(userFlashcards.count) user flashcards")
            }

            do {
                if dbExists {
                    try fileManager.removeItem(at: destURL)
                }
                try fileManager.copyItem(at: bundleURL, to: destURL)
                UserDefaults.standard.set(currentSeedVersion, forKey: "db_seed_version")
                print("✅ Database copied from bundle to \(destURL.path)")
            } catch {
                print("❌ Error copying database: \(error)")
                return
            }

            if !userTopics.isEmpty {
                var newDb: OpaquePointer?
                if sqlite3_open(destURL.path, &newDb) == SQLITE_OK {
                    sqlite3_exec(newDb, "BEGIN TRANSACTION", nil, nil, nil)

                    // Insert topics
                    let insertTopicSQL = "INSERT OR IGNORE INTO topics (name, subject_id, sort_order, is_user_created) VALUES (?, ?, ?, 1)"
                    var stmt: OpaquePointer?
                    if sqlite3_prepare_v2(newDb, insertTopicSQL, -1, &stmt, nil) == SQLITE_OK {
                        for t in userTopics {
                            sqlite3_reset(stmt)
                            sqlite3_bind_text(stmt, 1, (t.name as NSString).utf8String, -1, nil)
                            sqlite3_bind_int(stmt, 2, Int32(t.subjectId))
                            sqlite3_bind_int(stmt, 3, Int32(t.sortOrder))
                            sqlite3_step(stmt)
                        }
                    }
                    sqlite3_finalize(stmt)

                    let insertCardSQL = """
                        INSERT OR IGNORE INTO vocabularies (topic_id, question, answer, hint, exercise_type)
                        VALUES ((SELECT id FROM topics WHERE name = ? AND subject_id = ?), ?, ?, ?, ?)
                    """
                    if sqlite3_prepare_v2(newDb, insertCardSQL, -1, &stmt, nil) == SQLITE_OK {
                        for c in userFlashcards {
                            sqlite3_reset(stmt)
                            sqlite3_bind_text(stmt, 1, (c.topicName as NSString).utf8String, -1, nil)
                            sqlite3_bind_int(stmt, 2, Int32(c.subjectId))
                            sqlite3_bind_text(stmt, 3, (c.question as NSString).utf8String, -1, nil)
                            sqlite3_bind_text(stmt, 4, (c.answer as NSString).utf8String, -1, nil)
                            sqlite3_bind_text(stmt, 5, (c.hint as NSString).utf8String, -1, nil)
                            sqlite3_bind_text(stmt, 6, (c.exerciseType as NSString).utf8String, -1, nil)
                            sqlite3_step(stmt)
                        }
                    }
                    sqlite3_finalize(stmt)

                    sqlite3_exec(newDb, "COMMIT", nil, nil, nil)
                    print("✅ Restored \(userTopics.count) user topics, \(userFlashcards.count) user flashcards")
                }
                sqlite3_close(newDb)
            }
        }
    }

    private func openDatabase() {
        let fileURL = DatabaseManager.databaseURL()

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("❌ Error opening database: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("✅ Database opened at \(fileURL.path)")
            sqlite3_exec(db, "PRAGMA foreign_keys = ON", nil, nil, nil)
            createPracticeSessionsTable()
        }
    }

    static func databaseURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("flash-card", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("flashcards.sqlite")
    }

    // MARK: - Load All Subjects
    func loadAllSubjects() -> [Subject] {
        var subjects: [Subject] = []

        let sql = "SELECT id, name, icon FROM subjects ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let icon = String(cString: sqlite3_column_text(stmt, 2))

            let topics = loadTopics(for: id)
            subjects.append(Subject(id: id, name: name, icon: icon, topics: topics))
        }
        sqlite3_finalize(stmt)
        return subjects
    }

    // MARK: - Load Topics
    private func loadTopics(for subjectId: Int) -> [Topic] {
        var topics: [Topic] = []

        let sql = "SELECT id, name FROM topics WHERE subject_id = ? ORDER BY sort_order"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_int(stmt, 1, Int32(subjectId))

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))

            let flashcards = loadFlashcards(for: id)
            let readings = loadReadings(for: id)

            topics.append(Topic(
                id: id,
                name: name,
                subjectId: subjectId,
                flashcards: flashcards,
                readings: readings
            ))
        }
        sqlite3_finalize(stmt)
        return topics
    }

    // MARK: - Load Vocabularies
    func loadFlashcards(for topicId: Int) -> [Flashcard] {
        var flashcards: [Flashcard] = []

        let querySQL = "SELECT id, question, answer, hint, exercise_type FROM vocabularies WHERE topic_id = ?"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, querySQL, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_int(stmt, 1, Int32(topicId))

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let question = String(cString: sqlite3_column_text(stmt, 1))
            let answer = String(cString: sqlite3_column_text(stmt, 2))
            let hint: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
            let exerciseTypeStr = String(cString: sqlite3_column_text(stmt, 4))

            let exerciseType = ExerciseType(rawValue: exerciseTypeStr) ?? .englishToVietnamese

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

        return generateOptions(for: flashcards)
    }

    // MARK: - Load Reading Passages

    private func loadReadings(for topicId: Int) -> [ReadingPassage] {
        var passages: [ReadingPassage] = []

        let sql = "SELECT id, title, level, content FROM reading_passages WHERE topic_id = ? ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_int(stmt, 1, Int32(topicId))

        while sqlite3_step(stmt) == SQLITE_ROW {
            let passageId = Int(sqlite3_column_int(stmt, 0))
            let title = String(cString: sqlite3_column_text(stmt, 1))
            let levelStr = String(cString: sqlite3_column_text(stmt, 2))
            let content = String(cString: sqlite3_column_text(stmt, 3))

            let level = ReadingLevel(rawValue: levelStr) ?? .beginner
            let questions = loadReadingQuestions(for: passageId)
            let vocabulary = loadVocabulary(for: passageId)

            passages.append(ReadingPassage(
                id: passageId,
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

    private func loadReadingQuestions(for passageId: Int) -> [ReadingQuestion] {
        var questions: [ReadingQuestion] = []

        let sql = "SELECT id, question, option_a, option_b, option_c, option_d, correct_answer, explanation FROM reading_questions WHERE passage_id = ? ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_int(stmt, 1, Int32(passageId))

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let question = String(cString: sqlite3_column_text(stmt, 1))
            let optA = String(cString: sqlite3_column_text(stmt, 2))
            let optB = String(cString: sqlite3_column_text(stmt, 3))
            let optC = String(cString: sqlite3_column_text(stmt, 4))
            let optD = String(cString: sqlite3_column_text(stmt, 5))
            let correctAnswer = String(cString: sqlite3_column_text(stmt, 6))
            let explanation: String? = sqlite3_column_text(stmt, 7).map { String(cString: $0) }

            questions.append(ReadingQuestion(
                id: id,
                question: question,
                options: [optA, optB, optC, optD],
                correctAnswer: correctAnswer,
                explanation: explanation?.isEmpty == true ? nil : explanation
            ))
        }
        sqlite3_finalize(stmt)
        return questions
    }

    private func loadVocabulary(for passageId: Int) -> [VocabularyItem] {
        var items: [VocabularyItem] = []

        let sql = "SELECT id, question, answer, hint FROM vocabularies WHERE passage_id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_int(stmt, 1, Int32(passageId))

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let word = String(cString: sqlite3_column_text(stmt, 1))
            let meaning = String(cString: sqlite3_column_text(stmt, 2))
            let example: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }

            items.append(VocabularyItem(
                id: id,
                word: word,
                meaning: meaning,
                example: example?.isEmpty == true ? nil : example
            ))
        }
        sqlite3_finalize(stmt)
        return items
    }

    // MARK: - Helpers

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

    /// Insert topic, trả về topic id (auto-increment)
    @discardableResult
    func insertTopic(_ topic: Topic) -> Int {
        let insertSQL = "INSERT INTO topics (name, subject_id, sort_order, is_user_created) VALUES (?, ?, ?, 1)"
        var stmt: OpaquePointer?
        var newTopicId = 0

        if sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK {
            let currentCount = Int32(getTotalTopicsCount(for: topic.subjectId))

            sqlite3_bind_text(stmt, 1, (topic.name as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(topic.subjectId))
            sqlite3_bind_int(stmt, 3, currentCount)

            if sqlite3_step(stmt) == SQLITE_DONE {
                newTopicId = Int(sqlite3_last_insert_rowid(db))
            } else {
                print("❌ Error: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(stmt)
        return newTopicId
    }

    func insertFlashcard(_ card: Flashcard, topicId: Int) {
        let insertSQL = "INSERT INTO vocabularies (topic_id, question, answer, hint, exercise_type) VALUES (?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(topicId))
            sqlite3_bind_text(stmt, 2, (card.question as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, (card.answer as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, ((card.hint ?? "") as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, (card.exerciseType.rawValue as NSString).utf8String, -1, nil)

            if sqlite3_step(stmt) != SQLITE_DONE {
                print("❌ Error inserting flashcard: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(stmt)
    }

    func deleteTopic(id: Int) {
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)

        let deleteFlashcardsSQL = "DELETE FROM vocabularies WHERE topic_id = ?"
        let deleteReadingsSQL = "DELETE FROM reading_passages WHERE topic_id = ?"
        let deleteTopicSQL = "DELETE FROM topics WHERE id = ?"

        let queries = [deleteFlashcardsSQL, deleteReadingsSQL, deleteTopicSQL]

        for query in queries {
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, Int32(id))
                if sqlite3_step(stmt) != SQLITE_DONE {
                    print("❌ Error deleting: \(String(cString: sqlite3_errmsg(db)))")
                    sqlite3_finalize(stmt)
                    sqlite3_exec(db, "ROLLBACK", nil, nil, nil)
                    return
                }
            }
            sqlite3_finalize(stmt)
        }

        sqlite3_exec(db, "COMMIT", nil, nil, nil)
    }

    func deleteFlashcard(id: Int) {
        let deleteSQL = "DELETE FROM vocabularies WHERE id = ?"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, deleteSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    // MARK: - Private Helpers for CRUD

    // MARK: - Practice Sessions & Streak

    private func createPracticeSessionsTable() {
        let sql = """
            CREATE TABLE IF NOT EXISTS practice_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                practice_date TEXT NOT NULL,
                practice_type TEXT NOT NULL,
                topic_id INTEGER,
                correct_answers INTEGER NOT NULL,
                total_questions INTEGER NOT NULL,
                created_at TEXT DEFAULT (datetime('now','localtime'))
            )
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    func recordPracticeSession(practiceDate: String, practiceType: String, topicId: Int, correct: Int, total: Int) {
        let sql = "INSERT INTO practice_sessions (practice_date, practice_type, topic_id, correct_answers, total_questions) VALUES (?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (practiceDate as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (practiceType as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 3, Int32(topicId))
            sqlite3_bind_int(stmt, 4, Int32(correct))
            sqlite3_bind_int(stmt, 5, Int32(total))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func getStreakInfo() -> StreakInfo {
        // Get all distinct practice dates, ordered descending
        let sql = "SELECT DISTINCT practice_date FROM practice_sessions ORDER BY practice_date DESC"
        var stmt: OpaquePointer?
        var dates: [String] = []

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let date = String(cString: sqlite3_column_text(stmt, 0))
                dates.append(date)
            }
        }
        sqlite3_finalize(stmt)

        guard !dates.isEmpty else {
            return StreakInfo(currentStreak: 0, longestStreak: 0, didPracticeToday: false)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        let didPracticeToday = dates.first == todayStr

        // Calculate current streak
        let calendar = Calendar.current
        var currentStreak = 0
        var checkDate = Date()

        // If haven't practiced today, start checking from yesterday
        if !didPracticeToday {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        for dateStr in dates {
            let checkStr = formatter.string(from: checkDate)
            if dateStr == checkStr {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if dateStr < checkStr {
                break
            }
        }

        // Calculate longest streak
        var longestStreak = 0
        var tempStreak = 1

        for i in 0..<dates.count {
            if i == 0 {
                tempStreak = 1
                continue
            }
            guard let current = formatter.date(from: dates[i]),
                  let previous = formatter.date(from: dates[i - 1]) else { continue }

            let diff = calendar.dateComponents([.day], from: current, to: previous).day ?? 0
            if diff == 1 {
                tempStreak += 1
            } else {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 1
            }
        }
        longestStreak = max(longestStreak, tempStreak)

        return StreakInfo(currentStreak: currentStreak, longestStreak: longestStreak, didPracticeToday: didPracticeToday)
    }

    private func getTotalTopicsCount(for subjectId: Int) -> Int {
        let sql = "SELECT COUNT(*) FROM topics WHERE subject_id = ?"
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(subjectId))
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }
}
