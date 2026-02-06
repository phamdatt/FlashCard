//
//  DatabaseManager.swift
//  flash-card
//
//  Created by Dat Pham on 4/2/26.
//
//  SQLite singleton: subjects, topics, vocabularies (flashcards), reading_passages,
//  practice_sessions, flashcard_progress, mistake_records. Errors thrown as DBError.
//

import Foundation
import SQLite3

/// SQLite manager for flashcard app (subjects, topics, vocab, readings, SRS, stats).
class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    private let currentSeedVersion = 13

    private init() {
        copyDatabaseIfNeeded()
        openDatabase()
    }

    /// In-memory SQLite instance for testing. Schema: subjects, topics, vocabularies + SRS/reading tables.
    internal init(inMemoryForTesting: Bool) {
        guard inMemoryForTesting else {
            copyDatabaseIfNeeded()
            openDatabase()
            return
        }
        var pointer: OpaquePointer?
        guard sqlite3_open(":memory:", &pointer) == SQLITE_OK else {
            db = nil
            return
        }
        db = pointer
        sqlite3_exec(db, "PRAGMA foreign_keys = ON", nil, nil, nil)
        createCoreTablesForInMemoryTesting()
        createPracticeSessionsTable()
        createSRSTables()
        createReadingPassagesTable()
        ensureReadingSubjectExists()
    }

    deinit {
        sqlite3_close(db)
    }

    /// subjects, topics, vocabularies tables for in-memory test.
    private func createCoreTablesForInMemoryTesting() {
        sqlite3_exec(db, """
            CREATE TABLE IF NOT EXISTS subjects (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                icon TEXT NOT NULL,
                sort_order INTEGER NOT NULL
            )
            """, nil, nil, nil)
        sqlite3_exec(db, """
            CREATE TABLE IF NOT EXISTS topics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                subject_id INTEGER NOT NULL,
                sort_order INTEGER NOT NULL,
                is_user_created INTEGER NOT NULL DEFAULT 1,
                FOREIGN KEY (subject_id) REFERENCES subjects(id)
            )
            """, nil, nil, nil)
        sqlite3_exec(db, """
            CREATE TABLE IF NOT EXISTS vocabularies (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                topic_id INTEGER NOT NULL,
                question TEXT NOT NULL,
                answer TEXT NOT NULL,
                hint TEXT,
                exercise_type TEXT NOT NULL,
                FOREIGN KEY (topic_id) REFERENCES topics(id)
            )
            """, nil, nil, nil)
        sqlite3_exec(db, "INSERT OR IGNORE INTO subjects (id, name, icon, sort_order) VALUES (1, 'Test', 'book.fill', 0)", nil, nil, nil)
    }

    /// Ensures DB is open; throws if not (caller catches and sets errorMessage).
    private func requireDB() throws -> OpaquePointer {
        guard let db = db else { throw DBError.databaseNotOpen }
        return db
    }

    // MARK: - Database Setup
    private func copyDatabaseIfNeeded() {
        let destURL = DatabaseManager.databaseURL()
        let fileManager = FileManager.default

        let savedVersion = UserDefaults.standard.integer(forKey: "db_seed_version")
        let needsMigration = savedVersion < currentSeedVersion
        let dbExists = fileManager.fileExists(atPath: destURL.path)

        // if !dbExists || needsMigration {
        //     guard let bundleURL = Bundle.main.url(forResource: "flashcards", withExtension: "sqlite") else {
        //         print("❌ flashcards.sqlite not found in bundle")
        //         return
        //     }

        //     var userTopics: [(name: String, subjectId: Int, sortOrder: Int)] = []
        //     var userFlashcards: [(topicName: String, subjectId: Int, question: String, answer: String, hint: String, exerciseType: String)] = []

        //     if dbExists {
        //         var oldDb: OpaquePointer?
        //         if sqlite3_open(destURL.path, &oldDb) == SQLITE_OK {
        //             var stmt: OpaquePointer?
        //             let topicSQL = "SELECT name, subject_id, sort_order FROM topics WHERE is_user_created = 1"
        //             if sqlite3_prepare_v2(oldDb, topicSQL, -1, &stmt, nil) == SQLITE_OK {
        //                 while sqlite3_step(stmt) == SQLITE_ROW {
        //                     let name = String(cString: sqlite3_column_text(stmt, 0))
        //                     let subjectId = Int(sqlite3_column_int(stmt, 1))
        //                     let sortOrder = Int(sqlite3_column_int(stmt, 2))
        //                     userTopics.append((name, subjectId, sortOrder))
        //                 }
        //             }
        //             sqlite3_finalize(stmt)

        //             let cardSQL = """
        //                 SELECT t.name, t.subject_id, f.question, f.answer, COALESCE(f.hint, ''), f.exercise_type
        //                 FROM vocabularies f
        //                 JOIN topics t ON f.topic_id = t.id
        //                 WHERE t.is_user_created = 1
        //             """
        //             if sqlite3_prepare_v2(oldDb, cardSQL, -1, &stmt, nil) == SQLITE_OK {
        //                 while sqlite3_step(stmt) == SQLITE_ROW {
        //                     let topicName = String(cString: sqlite3_column_text(stmt, 0))
        //                     let subjectId = Int(sqlite3_column_int(stmt, 1))
        //                     let question = String(cString: sqlite3_column_text(stmt, 2))
        //                     let answer = String(cString: sqlite3_column_text(stmt, 3))
        //                     let hint = String(cString: sqlite3_column_text(stmt, 4))
        //                     let exerciseType = String(cString: sqlite3_column_text(stmt, 5))
        //                     userFlashcards.append((topicName, subjectId, question, answer, hint, exerciseType))
        //                 }
        //             }
        //             sqlite3_finalize(stmt)
        //         }
        //         sqlite3_close(oldDb)
        //         print("💾 Backed up \(userTopics.count) user topics, \(userFlashcards.count) user flashcards")
        //     }

        //     do {
        //         if dbExists {
        //             try fileManager.removeItem(at: destURL)
        //         }
        //         try fileManager.copyItem(at: bundleURL, to: destURL)
        //         UserDefaults.standard.set(currentSeedVersion, forKey: "db_seed_version")
        //         print("✅ Database copied from bundle to \(destURL.path)")
        //     } catch {
        //         print("❌ Error copying database: \(error)")
        //         return
        //     }

        //     if !userTopics.isEmpty {
        //         var newDb: OpaquePointer?
        //         if sqlite3_open(destURL.path, &newDb) == SQLITE_OK {
        //             sqlite3_exec(newDb, "BEGIN TRANSACTION", nil, nil, nil)

        //             // Insert topics
        //             let insertTopicSQL = "INSERT OR IGNORE INTO topics (name, subject_id, sort_order, is_user_created) VALUES (?, ?, ?, 1)"
        //             var stmt: OpaquePointer?
        //             if sqlite3_prepare_v2(newDb, insertTopicSQL, -1, &stmt, nil) == SQLITE_OK {
        //                 for t in userTopics {
        //                     sqlite3_reset(stmt)
        //                     sqlite3_bind_text(stmt, 1, (t.name as NSString).utf8String, -1, nil)
        //                     sqlite3_bind_int(stmt, 2, Int32(t.subjectId))
        //                     sqlite3_bind_int(stmt, 3, Int32(t.sortOrder))
        //                     sqlite3_step(stmt)
        //                 }
        //             }
        //             sqlite3_finalize(stmt)

        //             let insertCardSQL = """
        //                 INSERT OR IGNORE INTO vocabularies (topic_id, question, answer, hint, exercise_type)
        //                 VALUES ((SELECT id FROM topics WHERE name = ? AND subject_id = ?), ?, ?, ?, ?)
        //             """
        //             if sqlite3_prepare_v2(newDb, insertCardSQL, -1, &stmt, nil) == SQLITE_OK {
        //                 for c in userFlashcards {
        //                     sqlite3_reset(stmt)
        //                     sqlite3_bind_text(stmt, 1, (c.topicName as NSString).utf8String, -1, nil)
        //                     sqlite3_bind_int(stmt, 2, Int32(c.subjectId))
        //                     sqlite3_bind_text(stmt, 3, (c.question as NSString).utf8String, -1, nil)
        //                     sqlite3_bind_text(stmt, 4, (c.answer as NSString).utf8String, -1, nil)
        //                     sqlite3_bind_text(stmt, 5, (c.hint as NSString).utf8String, -1, nil)
        //                     sqlite3_bind_text(stmt, 6, (c.exerciseType as NSString).utf8String, -1, nil)
        //                     sqlite3_step(stmt)
        //                 }
        //             }
        //             sqlite3_finalize(stmt)

        //             sqlite3_exec(newDb, "COMMIT", nil, nil, nil)
        //             print("✅ Restored \(userTopics.count) user topics, \(userFlashcards.count) user flashcards")
        //         }
        //         sqlite3_close(newDb)
        //     }
        // }
    }

    private func openDatabase() {
        let fileURL = DatabaseManager.databaseURL()
        var pointer: OpaquePointer?
        if sqlite3_open(fileURL.path, &pointer) != SQLITE_OK {
            let msg = pointer.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(pointer)
            db = nil
            return
        }
        db = pointer
        sqlite3_exec(db, "PRAGMA foreign_keys = ON", nil, nil, nil)
        createPracticeSessionsTable()
        createSRSTables()
        dropOldReadingTablesIfNeeded()
        createReadingPassagesTable()
        ensureReadingSubjectExists()
    }

    /// One-time migration: drop old reading_questions/reading_passages, create new reading_passages (FK topic_id).
    private func dropOldReadingTablesIfNeeded() {
        let key = "reading_tables_migrated_v2"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        sqlite3_exec(db, "DROP TABLE IF EXISTS reading_questions", nil, nil, nil)
        sqlite3_exec(db, "DROP TABLE IF EXISTS reading_passages", nil, nil, nil)
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Reading passages table – foreign key to topic_id.
    private func createReadingPassagesTable() {
        let sql = """
            CREATE TABLE IF NOT EXISTS reading_passages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                topic_id INTEGER NOT NULL,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                created_at TEXT DEFAULT (datetime('now','localtime')),
                sort_order INTEGER DEFAULT 0,
                FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
            )
        """
        sqlite3_exec(db, sql, nil, nil, nil)
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_reading_passages_topic ON reading_passages(topic_id)", nil, nil, nil)
    }

    private func ensureReadingSubjectExists() {
        let sql = "INSERT OR IGNORE INTO subjects (name, icon, sort_order) VALUES ('Bài đọc', 'book.fill', 2)"
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    private func createSRSTables() {
        // Flashcard Progress table for SRS
        let progressSQL = """
            CREATE TABLE IF NOT EXISTS flashcard_progress (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                flashcard_id INTEGER NOT NULL UNIQUE,
                ease_factor REAL DEFAULT 2.5,
                interval_days INTEGER DEFAULT 0,
                repetitions INTEGER DEFAULT 0,
                next_review_date TEXT NOT NULL,
                last_review_date TEXT,
                difficulty REAL DEFAULT 0.0,
                total_reviews INTEGER DEFAULT 0,
                correct_reviews INTEGER DEFAULT 0,
                incorrect_reviews INTEGER DEFAULT 0,
                created_at TEXT DEFAULT (datetime('now','localtime')),
                updated_at TEXT DEFAULT (datetime('now','localtime')),
                FOREIGN KEY (flashcard_id) REFERENCES vocabularies(id) ON DELETE CASCADE
            )
        """
        sqlite3_exec(db, progressSQL, nil, nil, nil)
        
        // Mistake Records table
        let mistakeSQL = """
            CREATE TABLE IF NOT EXISTS mistake_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                flashcard_id INTEGER NOT NULL,
                practice_date TEXT NOT NULL,
                practice_type TEXT NOT NULL,
                topic_id INTEGER NOT NULL,
                created_at TEXT DEFAULT (datetime('now','localtime')),
                FOREIGN KEY (flashcard_id) REFERENCES vocabularies(id) ON DELETE CASCADE,
                FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
            )
        """
        sqlite3_exec(db, mistakeSQL, nil, nil, nil)
        
        // Create indexes for better performance
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_progress_flashcard ON flashcard_progress(flashcard_id)", nil, nil, nil)
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_progress_next_review ON flashcard_progress(next_review_date)", nil, nil, nil)
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_mistake_flashcard ON mistake_records(flashcard_id)", nil, nil, nil)
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_mistake_date ON mistake_records(practice_date)", nil, nil, nil)
    }

    /// SQLite file URL in Application Support (used when opening default DB).
    static func databaseURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("flash-card", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("flashcards.sqlite")
    }

    // MARK: - Load All Subjects

    /// Load all subjects with topics and flashcards/readings. Returns empty array if DB not open.
    func loadAllSubjects() -> [Subject] {
        guard db != nil else { return [] }
        var subjects: [Subject] = []

        let sql = "SELECT id, name, icon FROM subjects ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let icon = String(cString: sqlite3_column_text(stmt, 2))

            let topics = loadTopics(for: id, subjectName: name)
            subjects.append(Subject(id: id, name: name, icon: icon, topics: topics))
        }
        sqlite3_finalize(stmt)
        return subjects
    }

    // MARK: - Load Topics
    private func loadTopics(for subjectId: Int, subjectName: String = "") -> [Topic] {
        var topics: [Topic] = []

        let sql = "SELECT id, name FROM topics WHERE subject_id = ? ORDER BY sort_order"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        sqlite3_bind_int(stmt, 1, Int32(subjectId))

        let isReadingSubject = (subjectName == "Bài đọc")

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))

            let flashcards = loadFlashcards(for: id)
            let readings: [ReadingPassage] = isReadingSubject ? loadReadings(for: id) : []

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

    // MARK: - Reading Passages

    private func loadReadings(for topicId: Int) -> [ReadingPassage] {
        var list: [ReadingPassage] = []
        let sql = "SELECT id, topic_id, title, content, created_at FROM reading_passages WHERE topic_id = ? ORDER BY sort_order, id"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_int(stmt, 1, Int32(topicId))
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let topicId = Int(sqlite3_column_int(stmt, 1))
            let title = String(cString: sqlite3_column_text(stmt, 2))
            let content = String(cString: sqlite3_column_text(stmt, 3))
            let createdAt = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
            list.append(ReadingPassage(id: id, topicId: topicId, title: title, content: content, createdAt: createdAt))
        }
        sqlite3_finalize(stmt)
        return list
    }

    func insertReadingPassage(topicId: Int, title: String, content: String) throws {
        let db = try requireDB()
        let sql = "INSERT INTO reading_passages (topic_id, title, content, sort_order) VALUES (?, ?, ?, 0)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(topicId))
        sqlite3_bind_text(stmt, 2, (title as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (content as NSString).utf8String, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    /// Deletes reading passage by id. Throws on error.
    func deleteReadingPassage(id: Int) throws {
        let db = try requireDB()
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM reading_passages WHERE id = ?", -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(id))
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    // MARK: - Load Vocabularies

    /// Loads flashcards for a topic; generates multiple-choice options if at least 4 cards. Returns [] on error.
    func loadFlashcards(for topicId: Int) -> [Flashcard] {
        guard db != nil else { return [] }
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
            let exerciseType = exerciseTypeStr.isEmpty ? Flashcard.exerciseTypeLabel : exerciseTypeStr

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

    /// Inserts topic; returns topic id (auto-increment). Throws on error.
    func insertTopic(_ topic: Topic) throws -> Int {
        let db = try requireDB()
        let insertSQL = "INSERT INTO topics (name, subject_id, sort_order, is_user_created) VALUES (?, ?, ?, 1)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        let currentCount = Int32(getTotalTopicsCount(for: topic.subjectId))
        sqlite3_bind_text(stmt, 1, (topic.name as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(topic.subjectId))
        sqlite3_bind_int(stmt, 3, currentCount)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
        return Int(sqlite3_last_insert_rowid(db))
    }

    /// Inserts flashcard into topic. Throws on error.
    func insertFlashcard(_ card: Flashcard, topicId: Int) throws {
        let db = try requireDB()
        let insertSQL = "INSERT INTO vocabularies (topic_id, question, answer, hint, exercise_type) VALUES (?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(topicId))
        sqlite3_bind_text(stmt, 2, (card.question as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (card.answer as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, ((card.hint ?? "") as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, (card.exerciseType as NSString).utf8String, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    /// Updates flashcard content. Throws on error.
    func updateFlashcard(id: Int, question: String, answer: String, hint: String?) throws {
        let db = try requireDB()
        var stmt: OpaquePointer?
        let sql = "UPDATE vocabularies SET question = ?, answer = ?, hint = ? WHERE id = ?"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        let hintVal = hint ?? ""
        sqlite3_bind_text(stmt, 1, (question as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (answer as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (hintVal as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 4, Int32(id))
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    /// Deletes topic and related data. Throws on error.
    func deleteTopic(id: Int) throws {
        let db = try requireDB()
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)
        defer { sqlite3_exec(db, "ROLLBACK", nil, nil, nil) }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM vocabularies WHERE topic_id = ?", -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_int(stmt, 1, Int32(id))
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            sqlite3_finalize(stmt)
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_finalize(stmt)

        stmt = nil
        if sqlite3_prepare_v2(db, "DELETE FROM reading_passages WHERE topic_id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }

        stmt = nil
        guard sqlite3_prepare_v2(db, "DELETE FROM topics WHERE id = ?", -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_bind_int(stmt, 1, Int32(id))
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            sqlite3_finalize(stmt)
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_finalize(stmt)
        sqlite3_exec(db, "COMMIT", nil, nil, nil)
    }

    /// Deletes flashcard by id. Throws on error.
    func deleteFlashcard(id: Int) throws {
        let db = try requireDB()
        let deleteSQL = "DELETE FROM vocabularies WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, deleteSQL, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(id))
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    // MARK: - Backup / Restore

    /// Exports all user-created data (topics with is_user_created=1 and their flashcards/readings) as JSON.
    func exportUserData() -> Data? {
        guard db != nil else { return nil }
        let payload = loadUserDataForExport()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(payload)
    }

    /// Loads only user-created topics per subject and builds BackupPayload.
    private func loadUserDataForExport() -> BackupPayload {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let exportedAt = formatter.string(from: Date())
        var exportSubjects: [ExportSubject] = []
        let subjectSQL = "SELECT id, name, icon FROM subjects ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, subjectSQL, -1, &stmt, nil) == SQLITE_OK else { return BackupPayload(version: 1, exportedAt: exportedAt, subjects: []) }
        while sqlite3_step(stmt) == SQLITE_ROW {
            let subjectId = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let icon = String(cString: sqlite3_column_text(stmt, 2))
            let topics = loadUserCreatedTopics(for: subjectId, subjectName: name)
            if !topics.isEmpty {
                exportSubjects.append(ExportSubject(id: subjectId, name: name, icon: icon, topics: topics))
            }
        }
        sqlite3_finalize(stmt)
        return BackupPayload(version: 1, exportedAt: exportedAt, subjects: exportSubjects)
    }

    private func loadUserCreatedTopics(for subjectId: Int, subjectName: String) -> [ExportTopic] {
        var result: [ExportTopic] = []
        let sql = "SELECT id, name FROM topics WHERE subject_id = ? AND is_user_created = 1 ORDER BY sort_order"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_int(stmt, 1, Int32(subjectId))
        let isReading = (subjectName == "Bài đọc")
        while sqlite3_step(stmt) == SQLITE_ROW {
            let topicId = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let flashcards = loadFlashcards(for: topicId).map { ExportFlashcard(question: $0.question, answer: $0.answer, hint: $0.hint, exerciseType: $0.exerciseType) }
            let readings: [ExportReading] = isReading ? loadReadings(for: topicId).map { ExportReading(title: $0.title, content: $0.content) } : []
            result.append(ExportTopic(name: name, flashcards: flashcards, readings: readings))
        }
        sqlite3_finalize(stmt)
        return result
    }

    /// Imports user data from backup payload. Replaces all user-created topics and content. Throws on error.
    func importUserData(_ payload: BackupPayload) throws {
        let db = try requireDB()
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)
        defer { sqlite3_exec(db, "ROLLBACK", nil, nil, nil) }
        try deleteAllUserCreatedData()
        for exportSubj in payload.subjects {
            for exportTopic in exportSubj.topics {
                let newTopic = Topic(name: exportTopic.name, subjectId: exportSubj.id, flashcards: [], readings: [])
                let newTopicId = try insertTopic(newTopic)
                for card in exportTopic.flashcards {
                    let hintVal = (card.hint ?? "").isEmpty ? nil : card.hint
                    let f = Flashcard(question: card.question, answer: card.answer, hint: hintVal, exerciseType: Flashcard.exerciseTypeLabel)
                    try insertFlashcard(f, topicId: newTopicId)
                }
                for reading in exportTopic.readings {
                    try insertReadingPassage(topicId: newTopicId, title: reading.title, content: reading.content)
                }
            }
        }
        sqlite3_exec(db, "COMMIT", nil, nil, nil)
    }

    private func deleteAllUserCreatedData() throws {
        let db = try requireDB()
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM vocabularies WHERE topic_id IN (SELECT id FROM topics WHERE is_user_created = 1)", -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            sqlite3_finalize(stmt)
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_finalize(stmt)
        stmt = nil
        guard sqlite3_prepare_v2(db, "DELETE FROM reading_passages WHERE topic_id IN (SELECT id FROM topics WHERE is_user_created = 1)", -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            sqlite3_finalize(stmt)
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
        sqlite3_finalize(stmt)
        stmt = nil
        guard sqlite3_prepare_v2(db, "DELETE FROM topics WHERE is_user_created = 1", -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            sqlite3_finalize(stmt)
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
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

    /// Records a practice session (date, type, topic, correct/total) into practice_sessions.
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

    /// Number of practice sessions recorded for a topic. Used for "Đã làm" / "Chưa làm" status.
    func getPracticeSessionCount(topicId: Int) -> Int {
        guard db != nil else { return 0 }
        let sql = "SELECT COUNT(*) FROM practice_sessions WHERE topic_id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(topicId))
        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return 0
    }

    /// Streak info (consecutive days, record, studied today) from practice_sessions.
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
    
    // MARK: - SRS (Spaced Repetition System)

    /// SRS progress for a flashcard (interval, next_review_date, …); nil if none.
    func getFlashcardProgress(flashcardId: Int) -> FlashcardProgress? {
        let sql = """
            SELECT id, flashcard_id, ease_factor, interval_days, repetitions, 
                   next_review_date, last_review_date, difficulty, total_reviews, 
                   correct_reviews, incorrect_reviews
            FROM flashcard_progress
            WHERE flashcard_id = ?
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        
        sqlite3_bind_int(stmt, 1, Int32(flashcardId))
        
        var progress: FlashcardProgress? = nil
        if sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let flashcardId = Int(sqlite3_column_int(stmt, 1))
            let easeFactor = sqlite3_column_double(stmt, 2)
            let interval = Int(sqlite3_column_int(stmt, 3))
            let repetitions = Int(sqlite3_column_int(stmt, 4))
            let nextReviewStr = String(cString: sqlite3_column_text(stmt, 5))
            let lastReviewStr: String? = sqlite3_column_text(stmt, 6).map { String(cString: $0) }
            let difficulty = sqlite3_column_double(stmt, 7)
            let totalReviews = Int(sqlite3_column_int(stmt, 8))
            let correctReviews = Int(sqlite3_column_int(stmt, 9))
            let incorrectReviews = Int(sqlite3_column_int(stmt, 10))
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let nextReviewDate = formatter.date(from: nextReviewStr) ?? Date()
            let lastReviewDate = lastReviewStr.flatMap { formatter.date(from: $0) }
            
            progress = FlashcardProgress(
                id: id,
                flashcardId: flashcardId,
                easeFactor: easeFactor,
                interval: interval,
                repetitions: repetitions,
                nextReviewDate: nextReviewDate,
                lastReviewDate: lastReviewDate,
                difficulty: difficulty,
                totalReviews: totalReviews,
                correctReviews: correctReviews,
                incorrectReviews: incorrectReviews
            )
        }
        sqlite3_finalize(stmt)
        return progress
    }
    
    func saveFlashcardProgress(_ progress: FlashcardProgress) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let nextReviewStr = formatter.string(from: progress.nextReviewDate)
        let lastReviewStr = progress.lastReviewDate.map { formatter.string(from: $0) }
        
        let sql = """
            INSERT INTO flashcard_progress 
            (flashcard_id, ease_factor, interval_days, repetitions, next_review_date, 
             last_review_date, difficulty, total_reviews, correct_reviews, incorrect_reviews, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now','localtime'))
            ON CONFLICT(flashcard_id) DO UPDATE SET
                ease_factor = excluded.ease_factor,
                interval_days = excluded.interval_days,
                repetitions = excluded.repetitions,
                next_review_date = excluded.next_review_date,
                last_review_date = excluded.last_review_date,
                difficulty = excluded.difficulty,
                total_reviews = excluded.total_reviews,
                correct_reviews = excluded.correct_reviews,
                incorrect_reviews = excluded.incorrect_reviews,
                updated_at = datetime('now','localtime')
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        
        sqlite3_bind_int(stmt, 1, Int32(progress.flashcardId))
        sqlite3_bind_double(stmt, 2, progress.easeFactor)
        sqlite3_bind_int(stmt, 3, Int32(progress.interval))
        sqlite3_bind_int(stmt, 4, Int32(progress.repetitions))
        sqlite3_bind_text(stmt, 5, (nextReviewStr as NSString).utf8String, -1, nil)
        if let lastReviewStr = lastReviewStr {
            sqlite3_bind_text(stmt, 6, (lastReviewStr as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(stmt, 6)
        }
        sqlite3_bind_double(stmt, 7, progress.difficulty)
        sqlite3_bind_int(stmt, 8, Int32(progress.totalReviews))
        sqlite3_bind_int(stmt, 9, Int32(progress.correctReviews))
        sqlite3_bind_int(stmt, 10, Int32(progress.incorrectReviews))
        
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }
    
    /// Flashcard ids due for review today (next_review_date <= today).
    func getDueFlashcards() -> [Int] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nowStr = formatter.string(from: Date())
        
        let sql = """
            SELECT flashcard_id FROM flashcard_progress
            WHERE next_review_date <= ?
            ORDER BY next_review_date ASC
        """
        var stmt: OpaquePointer?
        var flashcardIds: [Int] = []
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_text(stmt, 1, (nowStr as NSString).utf8String, -1, nil)
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            flashcardIds.append(Int(sqlite3_column_int(stmt, 0)))
        }
        sqlite3_finalize(stmt)
        return flashcardIds
    }
    
    // MARK: - Mistake Records
    
    /// Records one wrong answer (for mistake review).
    func recordMistake(flashcardId: Int, practiceType: String, topicId: Int) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateStr = formatter.string(from: Date())
        
        let sql = """
            INSERT INTO mistake_records (flashcard_id, practice_date, practice_type, topic_id)
            VALUES (?, ?, ?, ?)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        
        sqlite3_bind_int(stmt, 1, Int32(flashcardId))
        sqlite3_bind_text(stmt, 2, (dateStr as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (practiceType as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 4, Int32(topicId))
        
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }
    
    /// Flashcard ids with mistakes in the last N days (default 30).
    func getMistakeFlashcards(days: Int = 30) -> [Int] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let cutoffStr = formatter.string(from: cutoffDate)
        
        let sql = """
            SELECT DISTINCT flashcard_id FROM mistake_records
            WHERE practice_date >= ?
            ORDER BY practice_date DESC
        """
        var stmt: OpaquePointer?
        var flashcardIds: [Int] = []
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_text(stmt, 1, (cutoffStr as NSString).utf8String, -1, nil)
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            flashcardIds.append(Int(sqlite3_column_int(stmt, 0)))
        }
        sqlite3_finalize(stmt)
        return flashcardIds
    }
    
    // MARK: - Statistics

    /// Aggregated learning stats (card counts, learned, due, accuracy, practice history, streak).
    func getLearningStatistics() -> LearningStatistics {
        // Get all flashcards
        let totalFlashcards = getTotalFlashcardsCount()
        
        // Get learned flashcards (has progress)
        let learnedFlashcards = getLearnedFlashcardsCount()
        
        // Get mastered flashcards (high accuracy, many reviews)
        let masteredFlashcards = getMasteredFlashcardsCount()
        
        // Get due flashcards
        let dueFlashcards = getDueFlashcards().count
        
        // Get accuracy by topic
        let accuracyByTopic = getAccuracyByTopic()
        
        // Get accuracy by subject
        let accuracyBySubject = getAccuracyBySubject()
        
        // Get practice history
        let practiceHistory = getPracticeHistory()
        
        // Get streak info
        let streakInfo = getStreakInfo()
        
        return LearningStatistics(
            totalFlashcards: totalFlashcards,
            learnedFlashcards: learnedFlashcards,
            masteredFlashcards: masteredFlashcards,
            dueFlashcards: dueFlashcards,
            accuracyByTopic: accuracyByTopic,
            accuracyBySubject: accuracyBySubject,
            practiceHistory: practiceHistory,
            streakInfo: streakInfo
        )
    }
    
    private func getTotalFlashcardsCount() -> Int {
        let sql = "SELECT COUNT(*) FROM vocabularies"
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }
    
    private func getLearnedFlashcardsCount() -> Int {
        let sql = "SELECT COUNT(DISTINCT flashcard_id) FROM flashcard_progress WHERE total_reviews > 0"
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }
    
    private func getMasteredFlashcardsCount() -> Int {
        let sql = """
            SELECT COUNT(*) FROM flashcard_progress
            WHERE total_reviews >= 5 AND 
                  (CAST(correct_reviews AS REAL) / CAST(total_reviews AS REAL)) >= 0.8
        """
        var stmt: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return count
    }
    
    private func getAccuracyByTopic() -> [Int: Double] {
        let sql = """
            SELECT v.topic_id, 
                   CAST(SUM(fp.correct_reviews) AS REAL) / CAST(SUM(fp.total_reviews) AS REAL) as accuracy
            FROM flashcard_progress fp
            JOIN vocabularies v ON fp.flashcard_id = v.id
            WHERE fp.total_reviews > 0
            GROUP BY v.topic_id
        """
        var stmt: OpaquePointer?
        var accuracy: [Int: Double] = [:]
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [:] }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let topicId = Int(sqlite3_column_int(stmt, 0))
            let acc = sqlite3_column_double(stmt, 1)
            accuracy[topicId] = acc
        }
        sqlite3_finalize(stmt)
        return accuracy
    }
    
    private func getAccuracyBySubject() -> [Int: Double] {
        let sql = """
            SELECT t.subject_id,
                   CAST(SUM(fp.correct_reviews) AS REAL) / CAST(SUM(fp.total_reviews) AS REAL) as accuracy
            FROM flashcard_progress fp
            JOIN vocabularies v ON fp.flashcard_id = v.id
            JOIN topics t ON v.topic_id = t.id
            WHERE fp.total_reviews > 0
            GROUP BY t.subject_id
        """
        var stmt: OpaquePointer?
        var accuracy: [Int: Double] = [:]
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [:] }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let subjectId = Int(sqlite3_column_int(stmt, 0))
            let acc = sqlite3_column_double(stmt, 1)
            accuracy[subjectId] = acc
        }
        sqlite3_finalize(stmt)
        return accuracy
    }
    
    private func getPracticeHistory() -> [DailyPractice] {
        let sql = """
            SELECT practice_date, 
                   SUM(total_questions) as total,
                   SUM(correct_answers) as correct,
                   GROUP_CONCAT(DISTINCT topic_id) as topics
            FROM practice_sessions
            GROUP BY practice_date
            ORDER BY practice_date DESC
            LIMIT 30
        """
        var stmt: OpaquePointer?
        var history: [DailyPractice] = []
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var index = 0
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let dateStr = String(cString: sqlite3_column_text(stmt, 0))
            let total = Int(sqlite3_column_int(stmt, 1))
            let correct = Int(sqlite3_column_int(stmt, 2))
            let topicsStr: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
            
            let date = formatter.date(from: dateStr) ?? Date()
            let topics = topicsStr?.components(separatedBy: ",").compactMap { Int($0) } ?? []
            
            history.append(DailyPractice(
                id: index,
                date: date,
                totalPracticed: total,
                correctAnswers: correct,
                topicsPracticed: topics
            ))
            index += 1
        }
        sqlite3_finalize(stmt)
        return history.reversed() // Oldest first
    }
}
