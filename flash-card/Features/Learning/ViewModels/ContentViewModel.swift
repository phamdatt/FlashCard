//
//  ContentViewModel.swift
//  learn-macos
//
//  Created by Dat Pham on 29/1/26.
//

import SwiftUI
import Combine

// MARK: - Detail Route (D1 – Router)
/// Detail screen state; ContentView renders detailColumn from this route.
enum DetailRoute: Equatable {
    case review
    case reviewMistakes
    case statistics
    case learning(topic: Topic?)
    case reading(topic: Topic)
}

/// Hành động bấm ở sidebar khi đang practice; confirm xong mới thực hiện.
enum PendingSidebarAction: Equatable {
    case switchToSubject(id: Int)
    case switchToWordOfDay(subjectId: Int, topicId: Int, flashcardIds: [Int])
    case switchToReviewMistakes
    case switchToStatistics
    case showKeyboardShortcuts
    case showSpeechAccent
    case showStrokeDraw
    case showBackupRestore
    case cycleTheme
    case none
}

// MARK: - ViewModel
@MainActor
class ContentViewModel: ObservableObject {
    /// Injected for tests (in-memory DB); nil uses real database.
    private var testDatabase: DatabaseManager?

    private var database: DatabaseManager { testDatabase ?? DatabaseManager.shared }

    // Learning section
    @Published var subjects: [Subject] = []
    @Published var selectedSubject: Subject?
    @Published var selectedTopic: Topic?
    @Published var selectedFlashcard: Flashcard?
    /// Multiple selection in flashcard list (IDs). Syncs to selectedFlashcard = first when set.
    @Published var selectedFlashcardIds: Set<Int> = []
    /// Đang trong phiên luyện tập (bấm Bắt đầu); đổi topic sẽ cần confirm.
    @Published var isPracticeSessionActive: Bool = false
    /// Topic muốn chuyển sang khi user chọn topic khác trong lúc practice; nil = không pending.
    @Published var pendingTopicSwitch: Topic?
    /// Đang ở tab Luyện tập (ẩn cột topic list).
    @Published var isInPracticeMode: Bool = false
    /// Bấm item sidebar khi đang practice → show popup, confirm mới thực hiện.
    @Published var pendingSidebarAction: PendingSidebarAction = .none

    // Search
    @Published var searchText = ""

    // Add Topic sheet
    @Published var showAddTopicSheet = false
    @Published var newTopicName = ""

    // Add Flashcard sheet
    @Published var showAddFlashcardSheet = false
    @Published var newFlashcardQuestion = ""
    @Published var newFlashcardAnswer = ""
    @Published var newFlashcardHint = ""

    // Add Reading passage sheet
    @Published var showAddReadingSheet = false
    @Published var newReadingTitle = ""
    @Published var newReadingContent = ""

    // Streak & daily goal
    @Published var streakInfo = StreakInfo(currentStreak: 0, longestStreak: 0, didPracticeToday: false)
    @Published var wordsPracticedToday: Int = 0
    @Published var dueFlashcardsCount: Int = 0
    private let dailyGoalKey = "dailyReviewGoal"
    var dailyReviewGoal: Int {
        get { UserDefaults.standard.object(forKey: dailyGoalKey) as? Int ?? 10 }
        set { UserDefaults.standard.set(newValue, forKey: dailyGoalKey) }
    }

    
    // SRS Views
    @Published var showReviewMode = false
    @Published var showReviewMistakes = false
    @Published var showStatistics = false

    // Pending delete (show confirmation before actually deleting)
    @Published var topicToDelete: Topic?
    @Published var flashcardToDelete: Flashcard?
    @Published var passageToDelete: ReadingPassage?

    // Rename topic sheet
    @Published var topicToRename: Topic?
    @Published var renameTopicName: String = ""

    // Error message for DB failures (shown as alert)
    @Published var errorMessage: String?
    /// Message after backup finishes (sheet closed, show alert on main screen).
    @Published var backupSaveResultMessage: String?
    /// Message after import finishes (sheet closed).
    @Published var importResultMessage: String?

    // Loading state (initial load / reload)
    @Published var isLoading = false

    /// Khi non-nil: FlashcardMainView của topic đó sẽ mở mode Luyện tập với danh sách thẻ.
    @Published var wordOfDayToPractice: (topic: Topic, flashcards: [Flashcard], subject: Subject)?
    /// Seed random mỗi lần mở app → topic và từ được chọn khác nhau mỗi phiên.
    private let wordOfDaySessionSeed: Int
    /// Practice session count per topic id (for "Đã làm" / "Chưa làm" badge).
    @Published var topicPracticeCounts: [Int: Int] = [:]
    /// Radical (部首) lookup for Tiếng Trung: character (汉字) -> bộ thủ. Built from topic "部首" under subject "Tiếng Trung".
    @Published var radicalLookup: [String: String] = [:]

    // Undo delete: show banner and allow restore within a few seconds
    enum UndoableItem {
        case topic(name: String, subjectId: Int, flashcards: [Flashcard], readings: [(title: String, content: String)])
        case flashcard(Flashcard, topicId: Int)
        case passage(title: String, content: String, topicId: Int)
    }
    @Published var undoableItem: UndoableItem?
    private var undoClearWorkItem: DispatchWorkItem?

    // Keyboard shortcuts help sheet (menu Help / sidebar)
    @Published var showKeyboardShortcutsSheet = false

    // Backup / Restore sheet (sidebar)
    @Published var showBackupRestoreSheet = false

    /// Vẽ nét → gợi ý từ (canvas + suggest by stroke count)
    @Published var showStrokeDrawSuggestSheet = false

    // TTS English accent sheet (sidebar)
    @Published var showSpeechAccentSheet = false

    // Import flashcards sheet (from CSV/JSON)
    @Published var showImportFlashcardSheet = false

    // MARK: - Navigation Helpers

    /// Current route for detail column; ContentView switches on this.
    var detailRoute: DetailRoute {
        if showReviewMode { return .review }
        if showReviewMistakes { return .reviewMistakes }
        if showStatistics { return .statistics }
        if let topic = selectedTopic {
            if selectedSubject?.name == "Bài đọc" {
                return .reading(topic: topic)
            }
            return .learning(topic: topic)
        }
        return .learning(topic: nil)
    }
    
    var isInSpecialMode: Bool {
        showReviewMode || showReviewMistakes || showStatistics
    }
    
    func switchToLearningMode() {
        // Keep selectedSubject when switching back to learning mode
        showReviewMode = false
        showReviewMistakes = false
        showStatistics = false
        loadStreakInfo()
        // Don't clear selectedSubject - keep it active
    }

    func switchToReviewMode() {
        // Batch updates to avoid multiple view updates
        // Keep selectedSubject active, only clear selectedTopic
        withAnimation(.easeInOut(duration: 0.25)) {
            showReviewMode = true
            showReviewMistakes = false
            showStatistics = false
            selectedTopic = nil
            // Don't clear selectedSubject - keep it active
        }
    }
    
    func switchToReviewMistakes() {
        // Batch updates to avoid multiple view updates
        // Keep selectedSubject active, only clear selectedTopic
        withAnimation(.easeInOut(duration: 0.25)) {
            showReviewMode = false
            showReviewMistakes = true
            showStatistics = false
            selectedTopic = nil
            // Don't clear selectedSubject - keep it active
        }
    }
    
    func switchToStatistics() {
        // Batch updates to avoid multiple view updates
        // Keep selectedSubject active, only clear selectedTopic
        withAnimation(.easeInOut(duration: 0.25)) {
            showReviewMode = false
            showReviewMistakes = false
            showStatistics = true
            selectedTopic = nil
            // Don't clear selectedSubject - keep it active
        }
    }

    init(databaseForTesting: DatabaseManager? = nil) {
        self.testDatabase = databaseForTesting
        self.wordOfDaySessionSeed = Int.random(in: 0..<Int.max)
        isLoading = true
        DispatchQueue.main.async { [weak self] in
            self?.loadLearningData()
            self?.loadStreakInfo()
            self?.isLoading = false
        }
    }

    /// Topics for display: when not searching, keep DB order (for drag reorder); when searching, filter and sort by name.
    func filteredTopics(for subject: Subject) -> [Topic] {
        if searchText.isEmpty {
            return subject.topics
        }
        let list = subject.topics.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        return list.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Reorder topics within a subject (persists to DB and reloads data).
    func reorderTopics(subject: Subject, from source: IndexSet, to destination: Int) {
        var list = subject.topics
        list.move(fromOffsets: source, toOffset: destination)
        let topicIds = list.map(\.id)
        do {
            try database.updateTopicSortOrder(subjectId: subject.id, topicIdsInOrder: topicIds)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        loadLearningData()
        if let updated = subjects.first(where: { $0.id == subject.id }) {
            selectedSubject = updated
            if let tid = selectedTopic?.id, let t = updated.topics.first(where: { $0.id == tid }) {
                selectedTopic = t
            }
        }
    }

    /// Từ theo ngày: mỗi môn (Tiếng Anh, Tiếng Trung) 5–10 từ. Random topic mỗi lần mở app.
    var wordOfTheDayBySubject: [(subject: Subject, topic: Topic, flashcards: [Flashcard])] {
        let vocabSubjects = ["Tiếng Anh", "Tiếng Trung"]
        var result: [(Subject, Topic, [Flashcard])] = []
        for subject in subjects where vocabSubjects.contains(subject.name) {
            let topicsWithCards = subject.topics.filter { !$0.flashcards.isEmpty }
            guard !topicsWithCards.isEmpty else { continue }
            let seed = wordOfDaySessionSeed + subject.id * 1000
            let topicIdx = abs(seed) % topicsWithCards.count
            let topic = topicsWithCards[topicIdx]
            let all = topic.flashcards
            let count = min(5 + (abs(seed + 1) % 6), all.count) // 5–10 từ
            guard count > 0 else { continue }
            let maxStart = max(0, all.count - count)
            let startIdx = maxStart > 0 ? abs(seed + 2) % (maxStart + 1) : 0
            let selected = Array(all.dropFirst(startIdx).prefix(count))
            result.append((subject, topic, selected))
        }
        return result
    }

    /// Search in flashcard question/answer within the given subject. Returns (topic, flashcard) pairs.
    func flashcardSearchResults(for subject: Subject) -> [(topic: Topic, flashcard: Flashcard)] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        var results: [(topic: Topic, flashcard: Flashcard)] = []
        for topic in subject.topics {
            for card in topic.flashcards {
                if card.question.localizedCaseInsensitiveContains(q) || (card.answer.localizedCaseInsensitiveContains(q)) {
                    results.append((topic, card))
                }
            }
        }
        return results
    }

    // MARK: - CRUD Operations

    func addTopic(name: String) {
        guard let subject = selectedSubject,
            !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Preserve selection before reload
        let currentSubjectId = subject.id

        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        let newTopic = Topic(
            name: trimmedName,
            subjectId: subject.id,
            flashcards: [],
            readings: []
        )

        do {
            _ = try database.insertTopic(newTopic)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        loadLearningData()

        // Restore selection after load
        if let updatedSubject = subjects.first(where: { $0.id == currentSubjectId }) {
            self.selectedSubject = updatedSubject
            // Keep current topic if still present
            if let currentTopicId = selectedTopic?.id,
               let updatedTopic = updatedSubject.topics.first(where: { $0.id == currentTopicId }) {
                self.selectedTopic = updatedTopic
            }
        }

        // Reset form
        newTopicName = ""
        showAddTopicSheet = false
    }

    func addFlashcard(question: String, answer: String, hint: String) {
            guard let topic = selectedTopic,
                !question.trimmingCharacters(in: .whitespaces).isEmpty,
                !answer.trimmingCharacters(in: .whitespaces).isEmpty else { return }

            // Preserve selection before reload
            let currentTopicId = topic.id
            let currentSubjectId = topic.subjectId

            let trimmedQuestion = question.trimmingCharacters(in: .whitespaces)
            let trimmedAnswer = answer.trimmingCharacters(in: .whitespaces)
            let trimmedHint = hint.trimmingCharacters(in: .whitespaces)

            let newFlashcard = Flashcard(
                question: trimmedQuestion,
                answer: trimmedAnswer,
                hint: trimmedHint.isEmpty ? nil : trimmedHint,
                options: nil,
                correctAnswer: nil,
                exerciseType: Flashcard.exerciseTypeLabel
            )
            
            do {
                try database.insertFlashcard(newFlashcard, topicId: currentTopicId)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
            loadLearningData()

            // Restore selection after load
            if let updatedSubject = subjects.first(where: { $0.id == currentSubjectId }),
               let updatedTopic = updatedSubject.topics.first(where: { $0.id == currentTopicId }) {
                self.selectedSubject = updatedSubject
                self.selectedTopic = updatedTopic
                self.selectedFlashcard = updatedTopic.flashcards.last
            }

            newFlashcardQuestion = ""
            newFlashcardAnswer = ""
            newFlashcardHint = ""
            showAddFlashcardSheet = false
    }

    /// Import rows into topic; closes sheet first, then runs import. Skips rows whose "từ gốc" (question) already exists in the topic.
    func importFlashcardsFromRows(topicId: Int, subjectId: Int, rows: [(question: String, answer: String, hint: String?, notes: String?, radical: String?, phonetic: String?)]) {
        var existing = Set(DatabaseManager.shared.loadFlashcards(for: topicId).map { $0.question.trimmingCharacters(in: .whitespaces) })
        var added = 0
        var skipped = 0
        for row in rows {
            let q = row.question.trimmingCharacters(in: .whitespaces)
            let a = row.answer.trimmingCharacters(in: .whitespaces)
            guard !q.isEmpty, !a.isEmpty else { continue }
            if existing.contains(q) {
                skipped += 1
                continue
            }
            let card = Flashcard(
                question: q,
                answer: a,
                hint: row.hint.flatMap { $0.isEmpty ? nil : $0 },
                options: nil,
                correctAnswer: nil,
                exerciseType: Flashcard.exerciseTypeLabel,
                notes: row.notes.flatMap { $0.isEmpty ? nil : $0 },
                radical: row.radical.flatMap { $0.isEmpty ? nil : $0 },
                phonetic: row.phonetic.flatMap { $0.isEmpty ? nil : $0 }
            )
            do {
                try database.insertFlashcard(card, topicId: topicId)
                added += 1
                existing.insert(q)
            } catch {
                errorMessage = error.localizedDescription
                loadLearningData()
                return
            }
        }
        loadLearningData()
        if let sub = subjects.first(where: { $0.id == subjectId }),
           let topic = sub.topics.first(where: { $0.id == topicId }) {
            selectedSubject = sub
            selectedTopic = topic
        }
        if skipped > 0 {
            importResultMessage = "Đã thêm \(added) thẻ. Bỏ qua \(skipped) thẻ trùng từ gốc."
        } else {
            importResultMessage = "Đã thêm \(added) thẻ."
        }
    }

    private func scheduleUndoClear() {
        undoClearWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.undoableItem = nil
            }
        }
        undoClearWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
    }

    func restoreUndo() {
        guard let item = undoableItem else { return }
        undoClearWorkItem?.cancel()
        undoClearWorkItem = nil
        switch item {
        case .topic(let name, let subjectId, let flashcards, let readings):
            let newTopic = Topic(name: name, subjectId: subjectId, flashcards: [], readings: [])
            do {
                let newTopicId = try database.insertTopic(newTopic)
                for card in flashcards {
                    try database.insertFlashcard(card, topicId: newTopicId)
                }
                for (title, content) in readings {
                    try database.insertReadingPassage(topicId: newTopicId, title: title, content: content)
                }
            } catch {
                errorMessage = error.localizedDescription
                return
            }
            loadLearningData()
            if let sub = subjects.first(where: { $0.id == subjectId }),
               let restored = sub.topics.first(where: { $0.name == name }) {
                selectedSubject = sub
                selectedTopic = restored
                selectedFlashcard = restored.flashcards.first
            }
        case .flashcard(let card, let topicId):
            do {
                try database.insertFlashcard(card, topicId: topicId)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
            loadLearningData()
            if let subId = selectedSubject?.id, let sub = subjects.first(where: { $0.id == subId }),
               let topic = sub.topics.first(where: { $0.id == topicId }) {
                selectedSubject = sub
                selectedTopic = topic
                selectedFlashcard = topic.flashcards.last
            }
        case .passage(let title, let content, let topicId):
            do {
                try database.insertReadingPassage(topicId: topicId, title: title, content: content)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
            loadLearningData()
            if let subId = selectedSubject?.id, let sub = subjects.first(where: { $0.id == subId }),
               let topic = sub.topics.first(where: { $0.id == topicId }) {
                selectedSubject = sub
                selectedTopic = topic
            }
        }
        undoableItem = nil
    }

    func dismissUndoBanner() {
        undoClearWorkItem?.cancel()
        undoClearWorkItem = nil
        undoableItem = nil
    }

    func deleteTopic(_ topic: Topic) {
        do {
            try database.deleteTopic(id: topic.id)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        let readingsSnapshot = topic.readings.map { ($0.title, $0.content) }
        undoableItem = .topic(name: topic.name, subjectId: topic.subjectId, flashcards: topic.flashcards, readings: readingsSnapshot)
        scheduleUndoClear()
        let currentSubjectId = selectedSubject?.id
        let wasSelected = (selectedTopic?.id == topic.id)
        if wasSelected {
            selectedTopic = nil
            selectedFlashcard = nil
        }
        loadLearningData()
        if let currentSubjectId = currentSubjectId {
            selectedSubject = subjects.first(where: { $0.id == currentSubjectId })
            if !wasSelected, let prevTopicId = selectedTopic?.id {
                selectedTopic = selectedSubject?.topics.first(where: { $0.id == prevTopicId })
            }
        }
    }

    func startRenameTopic(_ topic: Topic) {
        topicToRename = topic
        renameTopicName = topic.name
    }

    func renameTopic() {
        guard let topic = topicToRename else { return }
        let trimmed = renameTopicName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            try database.updateTopicName(id: topic.id, name: trimmed)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        let wasSelected = (selectedTopic?.id == topic.id)
        loadLearningData()
        if let subjectId = selectedSubject?.id {
            selectedSubject = subjects.first(where: { $0.id == subjectId })
            if wasSelected {
                selectedTopic = selectedSubject?.topics.first(where: { $0.id == topic.id })
            }
        }
        topicToRename = nil
        renameTopicName = ""
    }

    func addReadingPassage(topicId: Int, title: String, content: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedContent = content.trimmingCharacters(in: .whitespaces)

        do {
            try database.insertReadingPassage(topicId: topicId, title: trimmedTitle, content: trimmedContent)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        loadLearningData()

        let currentSubjectId = selectedSubject?.id
        if let subject = subjects.first(where: { $0.id == currentSubjectId }),
           let topic = subject.topics.first(where: { $0.id == topicId }) {
            selectedSubject = subject
            selectedTopic = topic
        }

        newReadingTitle = ""
        newReadingContent = ""
        showAddReadingSheet = false
    }

    func deleteReadingPassage(_ passage: ReadingPassage) {
        do {
            try database.deleteReadingPassage(id: passage.id)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        undoableItem = .passage(title: passage.title, content: passage.content, topicId: passage.topicId)
        scheduleUndoClear()
        let currentTopicId = selectedTopic?.id
        let currentSubjectId = selectedSubject?.id
        loadLearningData()
        if let subId = currentSubjectId, let tId = currentTopicId {
            selectedSubject = subjects.first(where: { $0.id == subId })
            selectedTopic = selectedSubject?.topics.first(where: { $0.id == tId })
        }
    }

    func deleteFlashcard(_ flashcard: Flashcard) {
        let topicId = selectedTopic?.id
        do {
            try database.deleteFlashcard(id: flashcard.id)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        if let topicId = topicId {
            undoableItem = .flashcard(flashcard, topicId: topicId)
            scheduleUndoClear()
        }
        let currentTopicId = selectedTopic?.id
        let currentSubjectId = selectedSubject?.id

        loadLearningData()

        if let subId = currentSubjectId, let tId = currentTopicId {
            selectedSubject = subjects.first(where: { $0.id == subId })
            selectedTopic = selectedSubject?.topics.first(where: { $0.id == tId })
        }

        selectedFlashcardIds.remove(flashcard.id)
        if selectedFlashcard?.id == flashcard.id {
            selectedFlashcard = selectedTopic?.flashcards.first
        }
    }

    func updateFlashcard(id: Int, question: String, answer: String, hint: String?, notes: String? = nil, radical: String? = nil, phonetic: String? = nil) {
        guard let topic = selectedTopic,
              !question.trimmingCharacters(in: .whitespaces).isEmpty,
              !answer.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let currentTopicId = topic.id
        let currentSubjectId = selectedSubject?.id
        let currentFlashcardId = selectedFlashcard?.id

        let trimmedQuestion = question.trimmingCharacters(in: .whitespaces)
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespaces)
        let trimmedHint = hint?.trimmingCharacters(in: .whitespaces)
        let hintOrNil = (trimmedHint?.isEmpty ?? true) ? nil : trimmedHint
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespaces)
        let notesOrNil = (trimmedNotes?.isEmpty ?? true) ? nil : trimmedNotes
        let trimmedRadical = radical?.trimmingCharacters(in: .whitespaces)
        let radicalOrNil = (trimmedRadical?.isEmpty ?? true) ? nil : trimmedRadical
        let trimmedPhonetic = phonetic?.trimmingCharacters(in: .whitespaces)
        let phoneticOrNil = (trimmedPhonetic?.isEmpty ?? true) ? nil : trimmedPhonetic

        do {
            try database.updateFlashcard(id: id, question: trimmedQuestion, answer: trimmedAnswer, hint: hintOrNil, notes: notesOrNil, radical: radicalOrNil, phonetic: phoneticOrNil)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        loadLearningData()

        if let subId = currentSubjectId, let sub = subjects.first(where: { $0.id == subId }),
           let top = sub.topics.first(where: { $0.id == currentTopicId }) {
            selectedSubject = sub
            selectedTopic = top
            if let fcId = currentFlashcardId {
                selectedFlashcard = top.flashcards.first(where: { $0.id == fcId })
            }
        }
    }

    // MARK: - Learning Data Management

    func loadLearningData() {
        subjects = database.loadAllSubjects()
        var counts: [Int: Int] = [:]
        var radicals: [String: String] = [:]
        for subject in subjects {
            for topic in subject.topics {
                counts[topic.id] = database.getPracticeSessionCount(topicId: topic.id)
                if subject.name == "Tiếng Trung" && (topic.name == "部首" || topic.name == "Bộ thủ") {
                    for fc in topic.flashcards {
                        radicals[fc.questionDisplayText] = fc.answer
                    }
                }
            }
        }
        topicPracticeCounts = counts
        radicalLookup = radicals
        if selectedSubject == nil, let first = subjects.first {
            selectSubject(first)
        }
    }

    /// Bộ thủ (部首) for character when subject is Tiếng Trung and topic 部首 exists. Returns nil otherwise.
    func radicalForCharacter(_ character: String) -> String? {
        let key = character.trimmingCharacters(in: .whitespaces)
        if key.isEmpty { return nil }
        return radicalLookup[key]
    }

    func selectSubject(_ subject: Subject) {
        // Check if current topic belongs to new subject
        let currentTopicId = selectedTopic?.id
        let currentTopicBelongsToNewSubject = currentTopicId != nil && 
            subject.topics.contains(where: { $0.id == currentTopicId })
        
        selectedSubject = subject
        
        if currentTopicBelongsToNewSubject, let currentTopic = subject.topics.first(where: { $0.id == currentTopicId }) {
            // Keep topic if it belongs to new subject
            selectedTopic = currentTopic
            // Keep flashcard if possible
            if let currentFlashcardId = selectedFlashcard?.id,
               currentTopic.flashcards.contains(where: { $0.id == currentFlashcardId }) {
                selectedFlashcard = currentTopic.flashcards.first(where: { $0.id == currentFlashcardId })
            } else {
                selectedFlashcard = currentTopic.flashcards.first
            }
        } else if let firstTopic = subject.topics.first {
            // Select first topic only if current topic not in new subject
            selectedTopic = firstTopic
            selectedFlashcard = firstTopic.flashcards.first
            selectedFlashcardIds = []
        } else {
            selectedTopic = nil
            selectedFlashcard = nil
            selectedFlashcardIds = []
        }
    }

    func selectTopic(_ topic: Topic) {
        // Update only when topic actually changed
        if selectedTopic?.id != topic.id {
            selectedTopic = topic
            selectedFlashcard = topic.flashcards.first
            selectedFlashcardIds = []
        }
    }

    /// Gọi khi user chọn topic từ list. Nếu đang practice thì gửi vào pending và cần confirm ở UI.
    func setSelectedTopic(_ topic: Topic?) {
        if isPracticeSessionActive, topic?.id != selectedTopic?.id {
            pendingTopicSwitch = topic
            return
        }
        applyTopicSwitch(to: topic)
    }

    /// Áp dụng chuyển topic (sau khi user confirm hoặc khi không trong practice).
    func applyTopicSwitch(to topic: Topic?) {
        pendingTopicSwitch = nil
        isPracticeSessionActive = false
        selectedTopic = topic
        selectedFlashcard = topic?.flashcards.first
        selectedFlashcardIds = []
    }

    /// Thực hiện hành động sidebar đã pending (sau khi user confirm "Kết thúc").
    func applyPendingSidebarAction() {
        defer { pendingSidebarAction = .none; isPracticeSessionActive = false }
        switch pendingSidebarAction {
        case .switchToSubject(let id):
            if let s = subjects.first(where: { $0.id == id }) {
                selectSubject(s)
                switchToLearningMode()
            }
        case .switchToWordOfDay(let subjectId, let topicId, let flashcardIds):
            if let s = subjects.first(where: { $0.id == subjectId }),
               let t = s.topics.first(where: { $0.id == topicId }) {
                let cards = flashcardIds.compactMap { id in t.flashcards.first(where: { $0.id == id }) }
                guard !cards.isEmpty, let firstCard = cards.first else { break }
                selectSubject(s)
                selectTopic(t)
                selectFlashcard(firstCard)
                switchToLearningMode()
                wordOfDayToPractice = (t, cards, s)
            }
        case .switchToReviewMistakes:
            switchToReviewMistakes()
        case .switchToStatistics:
            switchToStatistics()
        case .showKeyboardShortcuts:
            showKeyboardShortcutsSheet = true
        case .showSpeechAccent:
            showSpeechAccentSheet = true
        case .showStrokeDraw:
            showStrokeDrawSuggestSheet = true
        case .showBackupRestore:
            showBackupRestoreSheet = true
        case .cycleTheme:
            break
        case .none:
            break
        }
    }

    func selectFlashcard(_ flashcard: Flashcard) {
        selectedFlashcard = flashcard
    }

    /// Updates multi-selection from list; also sets selectedFlashcard to first.
    func setSelectedFlashcards(_ flashcards: Set<Flashcard>) {
        selectedFlashcardIds = Set(flashcards.map(\.id))
        selectedFlashcard = flashcards.first
    }

    /// Deletes all flashcards whose ids are in selectedFlashcardIds (call from current topic). Clears selection after.
    func deleteSelectedFlashcards(topicId: Int) {
        let ids = selectedFlashcardIds
        guard !ids.isEmpty else { return }
        let subjectId = selectedSubject?.id
        do {
            for id in ids {
                try database.deleteFlashcard(id: id)
            }
            selectedFlashcardIds = []
            selectedFlashcard = nil
            loadLearningData()
            if let subId = subjectId {
                selectedSubject = subjects.first(where: { $0.id == subId })
                selectedTopic = selectedSubject?.topics.first(where: { $0.id == topicId })
                selectedFlashcard = selectedTopic?.flashcards.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Streak

    func loadStreakInfo() {
        streakInfo = database.getStreakInfo()
        wordsPracticedToday = database.getWordsPracticedToday()
        dueFlashcardsCount = database.getDueFlashcards().count
    }

    func recordPractice(practiceType: String, topicId: Int, correct: Int, total: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        database.recordPracticeSession(
            practiceDate: today,
            practiceType: practiceType,
            topicId: topicId,
            correct: correct,
            total: total
        )
        topicPracticeCounts[topicId] = (topicPracticeCounts[topicId] ?? 0) + 1
        loadStreakInfo()
    }
}
