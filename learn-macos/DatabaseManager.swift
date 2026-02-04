//
//  DatabaseManager.swift
//  learn-macos
//
//  Created by Dat Pham on 4/2/26.
//

import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?

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
        let appDir = appSupport.appendingPathComponent("learn-macos", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        return appDir.appendingPathComponent("flashcards.sqlite")
    }

    private func createTables() {
        let createSQL = """
        CREATE TABLE IF NOT EXISTS flashcards (
            id TEXT PRIMARY KEY,
            topic_key TEXT NOT NULL,
            question TEXT NOT NULL,
            answer TEXT NOT NULL,
            hint TEXT,
            exercise_type TEXT NOT NULL DEFAULT 'Dịch Anh → Việt'
        );
        CREATE INDEX IF NOT EXISTS idx_flashcards_topic ON flashcards(topic_key);
        """

        if sqlite3_exec(db, createSQL, nil, nil, nil) != SQLITE_OK {
            print("❌ Error creating tables: \(String(cString: sqlite3_errmsg(db)))")
        }
    }

    // MARK: - Import CSV

    func importCSV(filename: String, topicKey: String) -> Int {
        // Check if already imported
        if flashcardCount(for: topicKey) > 0 {
            print("📦 Topic '\(topicKey)' already imported, skipping")
            return flashcardCount(for: topicKey)
        }

        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "csv") else {
            print("❌ CSV file '\(filename).csv' not found in bundle")
            return 0
        }

        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            print("❌ Failed to read CSV file")
            return 0
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // Begin transaction for performance
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)

        var count = 0
        let insertSQL = "INSERT OR IGNORE INTO flashcards (id, topic_key, question, answer, hint, exercise_type) VALUES (?, ?, ?, ?, ?, ?)"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) != SQLITE_OK {
            print("❌ Error preparing insert: \(String(cString: sqlite3_errmsg(db)))")
            return 0
        }

        for line in lines {
            let fields = parseCSVLine(line)
            guard fields.count >= 3 else { continue }

            let word = fields[0].trimmingCharacters(in: CharacterSet(charactersIn: "\"").union(.whitespaces))
            let meaning = fields[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"").union(.whitespaces))
            let hint = fields[2].trimmingCharacters(in: CharacterSet(charactersIn: "\"").union(.whitespaces))

            guard !word.isEmpty, !meaning.isEmpty else { continue }

            let id = UUID().uuidString
            let question = word // The Chinese word with pinyin is the question
            let answer = meaning
            let exerciseType = ExerciseType.englishToVietnamese.rawValue

            sqlite3_reset(stmt)
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
        sqlite3_exec(db, "COMMIT", nil, nil, nil)

        print("✅ Imported \(count) flashcards for topic '\(topicKey)'")
        return count
    }

    // MARK: - Load Flashcards

    func loadFlashcards(for topicKey: String) -> [Flashcard] {
        var flashcards: [Flashcard] = []

        let querySQL = "SELECT id, question, answer, hint, exercise_type FROM flashcards WHERE topic_key = ?"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, querySQL, -1, &stmt, nil) != SQLITE_OK {
            print("❌ Error preparing query: \(String(cString: sqlite3_errmsg(db)))")
            return []
        }

        sqlite3_bind_text(stmt, 1, (topicKey as NSString).utf8String, -1, nil)

        while sqlite3_step(stmt) == SQLITE_ROW {
            let idStr = String(cString: sqlite3_column_text(stmt, 0))
            let question = String(cString: sqlite3_column_text(stmt, 1))
            let answer = String(cString: sqlite3_column_text(stmt, 2))
            let hint: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
            let exerciseTypeStr = String(cString: sqlite3_column_text(stmt, 4))

            let exerciseType = ExerciseType(rawValue: exerciseTypeStr) ?? .englishToVietnamese
            let id = UUID(uuidString: idStr) ?? UUID()

            let flashcard = Flashcard(
                id: id,
                question: question,
                answer: answer,
                hint: hint,
                options: nil, // Will be generated later
                correctAnswer: nil,
                exerciseType: exerciseType
            )
            flashcards.append(flashcard)
        }

        sqlite3_finalize(stmt)

        // Generate multiple choice options
        flashcards = generateOptions(for: flashcards)

        return flashcards
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
}
