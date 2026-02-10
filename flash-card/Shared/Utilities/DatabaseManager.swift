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
        createSimilarLookingTable()
        seedSimilarLookingGroupsIfNeeded()
    }

    deinit {
        closeDatabase()
    }

    /// Đóng kết nối database (dùng trước khi thay file .sqlite để phục hồi).
    private func closeDatabase() {
        guard let pointer = db else { return }
        sqlite3_close(pointer)
        db = nil
    }

    /// Thay database hiện tại bằng file .sqlite từ sourceURL (đóng DB → copy file → mở lại). Gọi loadLearningData() sau khi xong.
    func replaceDatabase(withFileAt sourceURL: URL) throws {
        closeDatabase()
        let destURL = DatabaseManager.databaseURL()
        let fm = FileManager.default
        if fm.fileExists(atPath: destURL.path) {
            try fm.removeItem(at: destURL)
        }
        try fm.copyItem(at: sourceURL, to: destURL)
        openDatabase()
        guard db != nil else {
            throw DBError.databaseNotOpen
        }
    }

    /// Export (copy) database ra file .sqlite tại destURL bằng SQLite Backup API. DB vẫn mở, không cần đóng.
    func exportDatabase(to destURL: URL) throws {
        guard let sourceDb = db else { throw DBError.databaseNotOpen }
        let fm = FileManager.default
        if fm.fileExists(atPath: destURL.path) {
            try fm.removeItem(at: destURL)
        }
        var destDb: OpaquePointer?
        if sqlite3_open(destURL.path, &destDb) != SQLITE_OK {
            let msg = destDb.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(destDb)
            throw DBError.openFailed(msg)
        }
        defer { sqlite3_close(destDb) }
        guard let backup = sqlite3_backup_init(destDb, "main", sourceDb, "main") else {
            let msg = String(cString: sqlite3_errmsg(destDb))
            throw DBError.message("Backup init failed: \(msg)")
        }
        defer { sqlite3_backup_finish(backup) }
        var rc = sqlite3_backup_step(backup, -1)
        while rc == SQLITE_OK {
            rc = sqlite3_backup_step(backup, -1)
        }
        if rc != SQLITE_DONE {
            let msg = destDb.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            throw DBError.message("Backup failed: \(msg)")
        }
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
                notes TEXT,
                radical TEXT,
                phonetic TEXT,
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
        _ = savedVersion < currentSeedVersion
        _ = fileManager.fileExists(atPath: destURL.path)

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
            _ = pointer.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(pointer)
            db = nil
            return
        }
        db = pointer
        sqlite3_exec(db, "PRAGMA foreign_keys = ON", nil, nil, nil)
        dropVocabulariesExerciseTypeAndPassageIdIfNeeded()
        addNotesAndRadicalToVocabulariesIfNeeded()
        addPhoneticToVocabulariesIfNeeded()
        moveNotesToPhoneticForEnglishIfNeeded()
        moveRadicalToPhoneticForEnglishIfNeeded()
        createPracticeSessionsTable()
        createSRSTables()
        dropOldReadingTablesIfNeeded()
        createReadingPassagesTable()
        ensureReadingSubjectExists()
        createSimilarLookingTable()
        seedSimilarLookingGroupsIfNeeded()
    }

    /// One-time migration: remove exercise_type and passage_id from vocabularies by recreating the table.
    private func dropVocabulariesExerciseTypeAndPassageIdIfNeeded() {
        let key = "vocabularies_dropped_exercise_type_passage_id"
        guard let db = db, !UserDefaults.standard.bool(forKey: key) else { return }
        let hasColumn: (String, String) -> Bool = { table, column in
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, "PRAGMA table_info(\(table))", -1, &stmt, nil) == SQLITE_OK else { return false }
            while sqlite3_step(stmt) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(stmt, 1))
                if name == column { return true }
            }
            return false
        }
        let hasExerciseType = hasColumn("vocabularies", "exercise_type")
        let hasPassageId = hasColumn("vocabularies", "passage_id")
        guard hasExerciseType || hasPassageId else {
            UserDefaults.standard.set(true, forKey: key)
            return
        }
        let createSQL = """
            CREATE TABLE IF NOT EXISTS vocabularies_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                topic_id INTEGER NOT NULL,
                question TEXT NOT NULL,
                answer TEXT NOT NULL,
                hint TEXT,
                FOREIGN KEY (topic_id) REFERENCES topics(id)
            )
            """
        guard sqlite3_exec(db, createSQL, nil, nil, nil) == SQLITE_OK else { return }
        guard sqlite3_exec(db, "INSERT INTO vocabularies_new (id, topic_id, question, answer, hint) SELECT id, topic_id, question, answer, hint FROM vocabularies", nil, nil, nil) == SQLITE_OK else { return }
        guard sqlite3_exec(db, "DROP TABLE vocabularies", nil, nil, nil) == SQLITE_OK else { return }
        guard sqlite3_exec(db, "ALTER TABLE vocabularies_new RENAME TO vocabularies", nil, nil, nil) == SQLITE_OK else { return }
        UserDefaults.standard.set(true, forKey: key)
    }

    /// One-time migration: add notes and radical columns to vocabularies, then backfill 部首 for Tiếng Trung.
    private func addNotesAndRadicalToVocabulariesIfNeeded() {
        guard let db = db else { return }
        if !hasColumn(table: "vocabularies", column: "notes") {
            sqlite3_exec(db, "ALTER TABLE vocabularies ADD COLUMN notes TEXT", nil, nil, nil)
        }
        if !hasColumn(table: "vocabularies", column: "radical") {
            sqlite3_exec(db, "ALTER TABLE vocabularies ADD COLUMN radical TEXT", nil, nil, nil)
        }
        backfillRadicalsInVocabularies(radicalLookup: Self.builtInRadicalMap)
    }

    /// One-time migration: add phonetic column (pinyin for 中文, IPA/phonetic for English).
    private func addPhoneticToVocabulariesIfNeeded() {
        guard let db = db else { return }
        if !hasColumn(table: "vocabularies", column: "phonetic") {
            sqlite3_exec(db, "ALTER TABLE vocabularies ADD COLUMN phonetic TEXT", nil, nil, nil)
        }
    }

    /// One-time migration: move notes → phonetic for Tiếng Anh (user đã nhập phiên âm vào Ghi chú).
    private func moveNotesToPhoneticForEnglishIfNeeded() {
        let key = "vocabularies_moved_notes_to_phonetic_english"
        guard let db = db, hasColumn(table: "vocabularies", column: "phonetic"), !UserDefaults.standard.bool(forKey: key) else { return }
        let sql = """
            UPDATE vocabularies SET phonetic = notes, notes = NULL
            WHERE (phonetic IS NULL OR phonetic = '')
            AND notes IS NOT NULL AND trim(notes) != ''
            AND topic_id IN (SELECT id FROM topics WHERE subject_id = (SELECT id FROM subjects WHERE name = 'Tiếng Anh'))
            """
        if sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK {
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    /// One-time migration: move radical → phonetic for Tiếng Anh (radical đã dùng nhầm cho phiên âm).
    private func moveRadicalToPhoneticForEnglishIfNeeded() {
        let key = "vocabularies_moved_radical_to_phonetic_english"
        guard let db = db, hasColumn(table: "vocabularies", column: "phonetic"), hasColumn(table: "vocabularies", column: "radical"), !UserDefaults.standard.bool(forKey: key) else { return }
        let sql = """
            UPDATE vocabularies SET phonetic = radical, radical = NULL
            WHERE radical IS NOT NULL AND trim(radical) != ''
            AND topic_id IN (SELECT id FROM topics WHERE subject_id = (SELECT id FROM subjects WHERE name = 'Tiếng Anh'))
            """
        if sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK {
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    private func hasColumn(table: String, column: String) -> Bool {
        guard let db = db else { return false }
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, "PRAGMA table_info(\(table))", -1, &stmt, nil) == SQLITE_OK else { return false }
        while sqlite3_step(stmt) == SQLITE_ROW {
            let name = String(cString: sqlite3_column_text(stmt, 1))
            if name == column { return true }
        }
        return false
    }

    /// Built-in 部首 (radical) for Chinese characters. Used to backfill vocabularies.radical for Tiếng Trung.
    private static let builtInRadicalMap: [String: String] = [
        "想": "心", "怎": "心", "意": "心", "思": "心", "息": "心", "您": "心", "心": "心", "总": "心", "感": "心", "愿": "心", "急": "心", "忘": "心", "忽": "心", "忍": "心", "恩": "心", "怒": "心", "情": "忄", "性": "忄",
        "你": "亻", "他": "亻", "们": "亻", "住": "亻", "作": "亻", "但": "亻", "位": "亻", "什": "亻", "件": "亻", "休": "亻", "体": "亻", "何": "亻", "信": "亻", "候": "亻", "借": "亻", "做": "亻", "像": "亻", "代": "亻", "价": "亻", "使": "亻", "例": "亻", "便": "亻", "保": "亻", "化": "亻",
        "好": "女", "要": "女", "她": "女", "妈": "女", "姐": "女", "妹": "女", "姓": "女", "始": "女", "奶": "女", "婚": "女", "如": "女",
        "安": "宀", "定": "宀", "字": "宀", "家": "宀", "实": "宀", "室": "宀", "客": "宀", "宿": "宀",
        "对": "寸", "得": "彳", "很": "彳", "行": "彳", "往": "彳", "后": "彳", "将": "寸", "复": "夂", "习": "习", "能": "月", "有": "月", "服": "月", "期": "月", "朋": "月", "明": "月", "朝": "月",
        "不": "一", "下": "一", "上": "一", "三": "一", "七": "一", "事": "一", "两": "一", "考": "耂", "老": "耂", "试": "讠", "说": "讠", "话": "讠", "请": "讠", "认": "讠", "识": "讠", "读": "讠", "谢": "讠", "谁": "讠", "课": "讠", "该": "讠", "让": "讠", "讲": "讠",
        "没": "氵", "法": "氵", "洗": "氵", "流": "氵", "海": "氵", "漂": "氵", "清": "氵", "温": "氵", "渴": "氵", "河": "氵", "油": "氵", "注": "氵", "泳": "氵", "酒": "氵", "消": "氵", "深": "氵", "满": "氵", "汉": "氵",
        "关": "丷", "系": "系", "舒": "人", "医": "匚", "院": "阝", "起": "走", "超": "走", "赶": "走", "越": "走", "趣": "走",
        "大": "大", "天": "大", "太": "大", "头": "大", "买": "乛", "卖": "十", "书": "乛", "会": "人", "人": "人", "个": "人", "今": "人", "从": "人", "以": "人", "先": "儿", "儿": "儿", "元": "儿", "兄": "儿", "克": "儿", "光": "儿", "免": "儿", "党": "儿",
        "学": "子", "子": "子", "孩": "子", "季": "子", "存": "子", "孝": "子", "孙": "子", "李": "木", "林": "木", "果": "木", "校": "木", "桌": "木", "概": "木", "机": "木", "杯": "木", "板": "木", "楼": "木", "样": "木", "根": "木", "桥": "木", "椅": "木", "本": "木", "来": "木", "业": "业",
        "步": "止", "正": "止", "此": "止", "武": "止", "岁": "止", "吃": "口", "叫": "口", "听": "口", "和": "口", "哪": "口", "唱": "口", "喝": "口", "啊": "口", "喂": "口", "右": "口", "号": "口", "名": "口", "告": "口", "味": "口", "呢": "口", "吧": "口", "员": "口", "响": "口", "喜": "口", "嘴": "口", "只": "口", "可": "口", "吗": "口",
        "回": "囗", "国": "囗", "因": "囗", "图": "囗", "园": "囗", "困": "囗", "爱": "爫", "看": "目", "着": "目", "眼": "目", "相": "目", "知": "矢", "短": "矢", "矮": "矢",
        "错": "钅", "钱": "钅", "钟": "钅", "锻": "钅", "铁": "钅", "门": "门", "问": "门", "间": "门", "闻": "门", "开": "廾", "发": "又", "友": "又", "反": "又", "叔": "又", "取": "又", "受": "又", "难": "隹", "离": "隹",
        "别": "刂", "到": "刂", "前": "刂", "力": "力", "办": "力", "加": "力", "动": "力", "助": "力", "努": "力", "功": "力", "劳": "力", "男": "力",
        "边": "辶", "这": "辶", "进": "辶", "还": "辶", "远": "辶", "近": "辶", "道": "辶", "那": "辶", "送": "辶", "通": "辶", "过": "辶", "选": "辶", "遇": "辶",
        "里": "里", "重": "里", "量": "里", "颗": "页", "题": "页", "页": "页", "顾": "页", "预": "页", "领": "页",
        "长": "长", "张": "弓", "强": "弓", "引": "弓", "弟": "弓", "第": "竹", "笑": "竹", "答": "竹", "笔": "竹", "等": "竹", "简": "竹", "算": "竹", "筷": "竹", "篮": "竹",
        "米": "米", "料": "米", "粉": "米", "糖": "米", "粗": "米", "精": "米", "类": "米", "菜": "艹", "茶": "艹", "英": "艹", "草": "艹", "花": "艹", "苦": "艹", "药": "艹", "蓝": "艹", "落": "艹", "薄": "艹", "藏": "艹",
        "在": "土", "地": "土", "是": "日", "时": "日", "的": "白", "了": "亅", "也": "亅", "我": "戈", "成": "戈", "就": "尢", "都": "者", "去": "厶", "生": "生", "而": "而", "出": "凵", "多": "夕", "外": "夕", "自": "自", "年": "干", "平": "干", "把": "扌", "见": "见", "手": "手", "真": "十", "十": "十", "用": "用", "打": "扌", "才": "扌", "接": "扌", "比": "比", "方": "方", "些": "二", "所": "户", "经": "纟", "又": "又", "高": "高", "点": "灬", "无": "无", "已": "己", "理": "王", "之": "丶", "主": "丶", "民": "氏", "表": "衣", "被": "衤", "内": "冂", "同": "冂", "西": "西", "马": "马", "数": "攵", "白": "白",
    ]

    /// Backfill vocabularies.radical for Tiếng Trung (subject name) using built-in map. Only updates rows with empty radical.
    private func backfillRadicalsInVocabularies(radicalLookup: [String: String]) {
        guard let db = db, hasColumn(table: "vocabularies", column: "radical"), !radicalLookup.isEmpty else { return }
        let sql = "SELECT v.id, v.question FROM vocabularies v JOIN topics t ON v.topic_id = t.id JOIN subjects s ON t.subject_id = s.id WHERE s.name = 'Tiếng Trung' AND (v.radical IS NULL OR v.radical = '')"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        var updateStmt: OpaquePointer?
        let updateSQL = "UPDATE vocabularies SET radical = ? WHERE id = ?"
        guard sqlite3_prepare_v2(db, updateSQL, -1, &updateStmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(updateStmt) }
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let question = String(cString: sqlite3_column_text(stmt, 1))
            let raw = Self.characterFromQuestion(question)
            let radical: String? = radicalLookup[raw] ?? raw.first.flatMap { radicalLookup[String($0)] }
            if let r = radical, !r.isEmpty {
                sqlite3_bind_text(updateStmt, 1, (r as NSString).utf8String, -1, nil)
                sqlite3_bind_int(updateStmt, 2, Int32(id))
                sqlite3_step(updateStmt)
                sqlite3_reset(updateStmt)
            }
        }
    }

    private static func characterFromQuestion(_ question: String) -> String {
        let s = question.trimmingCharacters(in: .whitespaces)
        guard let lastClose = s.lastIndex(of: ")") else { return s }
        let beforeClose = s[..<lastClose]
        guard let lastOpen = beforeClose.lastIndex(of: "(") else { return s }
        return String(s[..<lastOpen]).trimmingCharacters(in: .whitespaces)
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
        let hasNotes = hasColumn(table: "vocabularies", column: "notes")
        let hasRadical = hasColumn(table: "vocabularies", column: "radical")
        let hasPhonetic = hasColumn(table: "vocabularies", column: "phonetic")
        var cols = "id, question, answer, hint"
        if hasNotes { cols += ", notes" }
        if hasRadical { cols += ", radical" }
        if hasPhonetic { cols += ", phonetic" }
        let querySQL = "SELECT \(cols) FROM vocabularies WHERE topic_id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, querySQL, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(topicId))

        var flashcards: [Flashcard] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let question = String(cString: sqlite3_column_text(stmt, 1))
            let answer = String(cString: sqlite3_column_text(stmt, 2))
            let hint: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
            var notes: String? = nil
            var radical: String? = nil
            var phonetic: String? = nil
            var idx: Int32 = 4
            if hasNotes { notes = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
            if hasRadical { radical = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
            if hasPhonetic { phonetic = sqlite3_column_text(stmt, idx).map { String(cString: $0) } }

            flashcards.append(Flashcard(
                id: id,
                question: question,
                answer: answer,
                hint: hint,
                options: nil,
                correctAnswer: nil,
                exerciseType: Flashcard.exerciseTypeLabel,
                notes: notes,
                radical: radical,
                phonetic: phonetic
            ))
        }
        return generateOptions(for: flashcards)
    }

    /// Loads a single flashcard by id from vocabularies. Returns nil if not found.
    func loadFlashcard(byId id: Int) -> Flashcard? {
        guard db != nil else { return nil }
        let hasNotes = hasColumn(table: "vocabularies", column: "notes")
        let hasRadical = hasColumn(table: "vocabularies", column: "radical")
        let hasPhonetic = hasColumn(table: "vocabularies", column: "phonetic")
        var cols = "id, question, answer, hint"
        if hasNotes { cols += ", notes" }
        if hasRadical { cols += ", radical" }
        if hasPhonetic { cols += ", phonetic" }
        let sql = "SELECT \(cols) FROM vocabularies WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(id))
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        let question = String(cString: sqlite3_column_text(stmt, 1))
        let answer = String(cString: sqlite3_column_text(stmt, 2))
        let hint: String? = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
        var notes: String? = nil
        var radical: String? = nil
        var phonetic: String? = nil
        var idx: Int32 = 4
        if hasNotes { notes = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
        if hasRadical { radical = sqlite3_column_text(stmt, idx).map { String(cString: $0) }; idx += 1 }
        if hasPhonetic { phonetic = sqlite3_column_text(stmt, idx).map { String(cString: $0) } }
        return Flashcard(
            id: id,
            question: question,
            answer: answer,
            hint: hint,
            options: nil,
            correctAnswer: nil,
            exerciseType: Flashcard.exerciseTypeLabel,
            notes: notes,
            radical: radical,
            phonetic: phonetic
        )
    }

    /// Top flashcards by mistake count (last 30 days). Returns (flashcard, mistakeCount) ordered by count descending.
    func getTopMistakeFlashcards(limit: Int = 20) -> [(Flashcard, Int)] {
        guard db != nil else { return [] }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let cutoffStr = formatter.string(from: cutoff)
        let sql = """
            SELECT flashcard_id, COUNT(*) as cnt FROM mistake_records
            WHERE practice_date >= ?
            GROUP BY flashcard_id ORDER BY cnt DESC LIMIT ?
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_text(stmt, 1, (cutoffStr as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(limit))
        var result: [(Flashcard, Int)] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let fid = Int(sqlite3_column_int(stmt, 0))
            let cnt = Int(sqlite3_column_int(stmt, 1))
            if let card = loadFlashcard(byId: fid) {
                result.append((card, cnt))
            }
        }
        sqlite3_finalize(stmt)
        return result
    }

    /// Flashcards with oldest last_review_date (longest since review). Returns (flashcard, lastReviewDateString) ordered by oldest first.
    func getFlashcardsLongestSinceReview(limit: Int = 20) -> [(Flashcard, String)] {
        guard db != nil else { return [] }
        let sql = """
            SELECT flashcard_id, last_review_date FROM flashcard_progress
            WHERE total_reviews > 0 AND last_review_date IS NOT NULL AND last_review_date != ''
            ORDER BY last_review_date ASC LIMIT ?
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_int(stmt, 1, Int32(limit))
        var result: [(Flashcard, String)] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let fid = Int(sqlite3_column_int(stmt, 0))
            let dateStr = String(cString: sqlite3_column_text(stmt, 1))
            if let card = loadFlashcard(byId: fid) {
                result.append((card, dateStr))
            }
        }
        sqlite3_finalize(stmt)
        return result
    }

    // MARK: - Helpers

    /// Generates multiple-choice options for a list of flashcards (for use outside loadFlashcards, e.g. review mistakes).
    static func makeFlashcardsWithOptions(_ flashcards: [Flashcard]) -> [Flashcard] {
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
                if ans == card.answer { correctLabel = labels[i] }
            }
            return Flashcard(
                id: card.id,
                question: card.question,
                answer: card.answer,
                hint: card.hint,
                options: options,
                correctAnswer: correctLabel,
                exerciseType: card.exerciseType,
                notes: card.notes,
                radical: card.radical,
                phonetic: card.phonetic
            )
        }
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
                exerciseType: card.exerciseType,
                notes: card.notes,
                radical: card.radical,
                phonetic: card.phonetic
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

    /// Updates topic name. Throws on error.
    func updateTopicName(id: Int, name: String) throws {
        let db = try requireDB()
        let sql = "UPDATE topics SET name = ? WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(id))
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    /// Updates sort_order of topics within a subject. topicIdsInOrder = ordered topic ids. Throws on error.
    func updateTopicSortOrder(subjectId: Int, topicIdsInOrder: [Int]) throws {
        let db = try requireDB()
        let sql = "UPDATE topics SET sort_order = ? WHERE id = ? AND subject_id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        for (index, topicId) in topicIdsInOrder.enumerated() {
            sqlite3_reset(stmt)
            sqlite3_bind_int(stmt, 1, Int32(index))
            sqlite3_bind_int(stmt, 2, Int32(topicId))
            sqlite3_bind_int(stmt, 3, Int32(subjectId))
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
            }
        }
    }

    /// Inserts flashcard into topic. Throws on error.
    func insertFlashcard(_ card: Flashcard, topicId: Int) throws {
        let db = try requireDB()
        let hasNotes = hasColumn(table: "vocabularies", column: "notes")
        let hasRadical = hasColumn(table: "vocabularies", column: "radical")
        let hasPhonetic = hasColumn(table: "vocabularies", column: "phonetic")
        var cols = "topic_id, question, answer, hint"
        var placeholders = "?, ?, ?, ?"
        if hasNotes { cols += ", notes"; placeholders += ", ?" }
        if hasRadical { cols += ", radical"; placeholders += ", ?" }
        if hasPhonetic { cols += ", phonetic"; placeholders += ", ?" }
        let insertSQL = "INSERT INTO vocabularies (\(cols)) VALUES (\(placeholders))"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        var idx: Int32 = 1
        sqlite3_bind_int(stmt, idx, Int32(topicId)); idx += 1
        sqlite3_bind_text(stmt, idx, (card.question as NSString).utf8String, -1, nil); idx += 1
        sqlite3_bind_text(stmt, idx, (card.answer as NSString).utf8String, -1, nil); idx += 1
        sqlite3_bind_text(stmt, idx, ((card.hint ?? "") as NSString).utf8String, -1, nil); idx += 1
        if hasNotes { sqlite3_bind_text(stmt, idx, ((card.notes ?? "") as NSString).utf8String, -1, nil); idx += 1 }
        if hasRadical { sqlite3_bind_text(stmt, idx, ((card.radical ?? "") as NSString).utf8String, -1, nil); idx += 1 }
        if hasPhonetic { sqlite3_bind_text(stmt, idx, ((card.phonetic ?? "") as NSString).utf8String, -1, nil) }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
        }
    }

    /// Updates flashcard content. Throws on error.
    func updateFlashcard(id: Int, question: String, answer: String, hint: String?, notes: String? = nil, radical: String? = nil, phonetic: String? = nil) throws {
        let db = try requireDB()
        let hasNotes = hasColumn(table: "vocabularies", column: "notes")
        let hasRadical = hasColumn(table: "vocabularies", column: "radical")
        let hasPhonetic = hasColumn(table: "vocabularies", column: "phonetic")
        var setClause = "question = ?, answer = ?, hint = ?"
        if hasNotes { setClause += ", notes = ?" }
        if hasRadical { setClause += ", radical = ?" }
        if hasPhonetic { setClause += ", phonetic = ?" }
        let sql = "UPDATE vocabularies SET \(setClause) WHERE id = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(stmt) }
        var idx: Int32 = 1
        sqlite3_bind_text(stmt, idx, (question as NSString).utf8String, -1, nil); idx += 1
        sqlite3_bind_text(stmt, idx, (answer as NSString).utf8String, -1, nil); idx += 1
        sqlite3_bind_text(stmt, idx, ((hint ?? "") as NSString).utf8String, -1, nil); idx += 1
        if hasNotes { sqlite3_bind_text(stmt, idx, ((notes ?? "") as NSString).utf8String, -1, nil); idx += 1 }
        if hasRadical { sqlite3_bind_text(stmt, idx, ((radical ?? "") as NSString).utf8String, -1, nil); idx += 1 }
        if hasPhonetic { sqlite3_bind_text(stmt, idx, ((phonetic ?? "") as NSString).utf8String, -1, nil); idx += 1 }
        sqlite3_bind_int(stmt, idx, Int32(id))
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
            let flashcards = loadFlashcards(for: topicId).map { ExportFlashcard(question: $0.question, answer: $0.answer, hint: $0.hint, exerciseType: $0.exerciseType, notes: $0.notes, radical: $0.radical, phonetic: $0.phonetic) }
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
                    let f = Flashcard(question: card.question, answer: card.answer, hint: hintVal, exerciseType: Flashcard.exerciseTypeLabel, notes: card.notes, radical: card.radical, phonetic: card.phonetic)
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

    // MARK: - Similar-looking characters (Từ dễ nhầm)

    private func createSimilarLookingTable() {
        let sql = """
            CREATE TABLE IF NOT EXISTS similar_looking_groups (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                group_id INTEGER NOT NULL,
                character TEXT NOT NULL,
                UNIQUE(group_id, character)
            )
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    private static let defaultSimilarLookingGroups: [[Character]] = [
        ["未", "末"],
        ["己", "已", "巳"],
        ["人", "入"],
        ["日", "目"],
        ["大", "太", "天"],
        ["千", "干"],
        ["土", "士"],
        ["王", "玉"],
        ["木", "本"],
        ["白", "百"],
        ["厂", "广"],
        ["刀", "力"],
        ["午", "牛"],
        ["夫", "天"],
        ["田", "由", "甲"],
        ["贝", "见"],
        ["鸟", "乌"],
        ["今", "令"],
        ["候", "侯"],
        ["低", "底"],
        ["拆", "折"],
        ["免", "兔"],
        ["问", "间"],
        ["休", "体"],
        ["喝", "渴"],
        ["买", "卖"],
        ["左", "右"],
        ["心", "必"],
        ["子", "了"],
    ]

    private func seedSimilarLookingGroupsIfNeeded() {
        let key = "similar_looking_groups_seeded"
        guard let db = db, !UserDefaults.standard.bool(forKey: key) else { return }
        let sql = "INSERT OR IGNORE INTO similar_looking_groups (group_id, character) VALUES (?, ?)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        for (groupIndex, group) in Self.defaultSimilarLookingGroups.enumerated() {
            let groupId = Int32(groupIndex + 1)
            for ch in group {
                let charStr = String(ch)
                sqlite3_bind_int(stmt, 1, groupId)
                sqlite3_bind_text(stmt, 2, (charStr as NSString).utf8String, -1, nil)
                sqlite3_step(stmt)
                sqlite3_reset(stmt)
            }
        }
        sqlite3_finalize(stmt)
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Tất cả ký tự nằm trong các nhóm dễ nhầm (để filter nhanh).
    func getSimilarLookingCharacters() -> Set<Character> {
        guard let db = db else { return [] }
        let sql = "SELECT DISTINCT character FROM similar_looking_groups"
        var stmt: OpaquePointer?
        var result = Set<Character>()
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let cStr = sqlite3_column_text(stmt, 0) {
                let s = String(cString: cStr)
                if let ch = s.first { result.insert(ch) }
            }
        }
        sqlite3_finalize(stmt)
        return result
    }

    /// Các nhóm ký tự dễ nhầm (mỗi nhóm là mảng ký tự).
    func getSimilarLookingGroups() -> [[Character]] {
        guard let db = db else { return [] }
        let sql = "SELECT group_id, character FROM similar_looking_groups ORDER BY group_id, character"
        var stmt: OpaquePointer?
        var byGroup: [Int: [Character]] = [:]
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        while sqlite3_step(stmt) == SQLITE_ROW {
            let groupId = Int(sqlite3_column_int(stmt, 0))
            if let cStr = sqlite3_column_text(stmt, 1) {
                let s = String(cString: cStr)
                if let ch = s.first {
                    byGroup[groupId, default: []].append(ch)
                }
            }
        }
        sqlite3_finalize(stmt)
        let maxKey = byGroup.keys.max() ?? 0
        return (1...maxKey).compactMap { byGroup[$0] }.filter { !$0.isEmpty }
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

    /// Số từ đã ôn hôm nay (tổng total_questions trong practice_sessions của ngày hiện tại).
    func getWordsPracticedToday() -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        let sql = "SELECT COALESCE(SUM(total_questions), 0) FROM practice_sessions WHERE practice_date = ?"
        var stmt: OpaquePointer?
        var count = 0
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        sqlite3_bind_text(stmt, 1, (todayStr as NSString).utf8String, -1, nil)
        if sqlite3_step(stmt) == SQLITE_ROW {
            count = Int(sqlite3_column_int(stmt, 0))
        }
        sqlite3_finalize(stmt)
        return count
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
    
    /// Flashcard ids due for review today (next_review_date nằm trong hôm nay hoặc đã quá hạn).
    /// So sánh với đầu ngày mai (local) để thẻ đúng hẹn "hôm nay" luôn được tính, không phụ thuộc giờ.
    /// subjectId == nil: tất cả; khác nil: chỉ thẻ thuộc môn đó.
    func getDueFlashcards(subjectId: Int? = nil) -> [Int] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let calendar = Calendar.current
        let startOfTomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let boundStr = formatter.string(from: startOfTomorrow)

        let sql: String
        if subjectId != nil {
            sql = """
                SELECT fp.flashcard_id FROM flashcard_progress fp
                JOIN vocabularies v ON fp.flashcard_id = v.id
                JOIN topics t ON v.topic_id = t.id
                WHERE fp.next_review_date < ? AND t.subject_id = ?
                ORDER BY fp.next_review_date ASC
                """
        } else {
            sql = """
                SELECT flashcard_id FROM flashcard_progress
                WHERE next_review_date < ?
                ORDER BY next_review_date ASC
                """
        }
        var stmt: OpaquePointer?
        var flashcardIds: [Int] = []

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_text(stmt, 1, (boundStr as NSString).utf8String, -1, nil)
        if let id = subjectId {
            sqlite3_bind_int(stmt, 2, Int32(id))
        }

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
        getTotalFlashcardsCount(subjectId: nil)
    }

    /// Tổng số từ (có thể lọc theo môn). subjectId == nil thì đếm tất cả.
    func getTotalFlashcardsCount(subjectId: Int?) -> Int {
        let sql: String
        if subjectId != nil {
            sql = "SELECT COUNT(*) FROM vocabularies v JOIN topics t ON v.topic_id = t.id WHERE t.subject_id = ?"
        } else {
            sql = "SELECT COUNT(*) FROM vocabularies"
        }
        var stmt: OpaquePointer?
        var count = 0
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        if let id = subjectId {
            sqlite3_bind_int(stmt, 1, Int32(id))
        }
        if sqlite3_step(stmt) == SQLITE_ROW {
            count = Int(sqlite3_column_int(stmt, 0))
        }
        sqlite3_finalize(stmt)
        return count
    }

    private func getLearnedFlashcardsCount() -> Int {
        getLearnedFlashcardsCount(subjectId: nil)
    }

    /// Số từ đã học (có ít nhất 1 lần ôn). subjectId == nil thì đếm tất cả.
    func getLearnedFlashcardsCount(subjectId: Int?) -> Int {
        let sql: String
        if subjectId != nil {
            sql = """
                SELECT COUNT(DISTINCT fp.flashcard_id) FROM flashcard_progress fp
                JOIN vocabularies v ON fp.flashcard_id = v.id
                JOIN topics t ON v.topic_id = t.id
                WHERE fp.total_reviews > 0 AND t.subject_id = ?
                """
        } else {
            sql = "SELECT COUNT(DISTINCT flashcard_id) FROM flashcard_progress WHERE total_reviews > 0"
        }
        var stmt: OpaquePointer?
        var count = 0
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        if let id = subjectId {
            sqlite3_bind_int(stmt, 1, Int32(id))
        }
        if sqlite3_step(stmt) == SQLITE_ROW {
            count = Int(sqlite3_column_int(stmt, 0))
        }
        sqlite3_finalize(stmt)
        return count
    }

    /// Flashcard ids that have at least one review (for filter "đã học").
    func getLearnedFlashcardIds() -> [Int] {
        guard db != nil else { return [] }
        let sql = "SELECT flashcard_id FROM flashcard_progress WHERE total_reviews > 0"
        var stmt: OpaquePointer?
        var ids: [Int] = []
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        while sqlite3_step(stmt) == SQLITE_ROW {
            ids.append(Int(sqlite3_column_int(stmt, 0)))
        }
        sqlite3_finalize(stmt)
        return ids
    }
    
    private func getMasteredFlashcardsCount() -> Int {
        getMasteredFlashcardsCount(subjectId: nil)
    }

    /// Số từ đã thuộc (≥5 lần ôn và độ chính xác ≥ 80%). subjectId == nil thì đếm tất cả.
    func getMasteredFlashcardsCount(subjectId: Int?) -> Int {
        let sql: String
        if subjectId != nil {
            sql = """
                SELECT COUNT(*) FROM flashcard_progress fp
                JOIN vocabularies v ON fp.flashcard_id = v.id
                JOIN topics t ON v.topic_id = t.id
                WHERE fp.total_reviews >= 5 AND
                      (CAST(fp.correct_reviews AS REAL) / CAST(fp.total_reviews AS REAL)) >= 0.8
                      AND t.subject_id = ?
                """
        } else {
            sql = """
                SELECT COUNT(*) FROM flashcard_progress
                WHERE total_reviews >= 5 AND
                      (CAST(correct_reviews AS REAL) / CAST(total_reviews AS REAL)) >= 0.8
                """
        }
        var stmt: OpaquePointer?
        var count = 0
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        if let id = subjectId {
            sqlite3_bind_int(stmt, 1, Int32(id))
        }
        if sqlite3_step(stmt) == SQLITE_ROW {
            count = Int(sqlite3_column_int(stmt, 0))
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
