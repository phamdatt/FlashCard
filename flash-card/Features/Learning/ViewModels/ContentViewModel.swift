//
//  ContentViewModel.swift
//  learn-macos
//
//  Created by Dat Pham on 29/1/26.
//

import SwiftUI
import Combine

// MARK: - ViewModel
@MainActor
class ContentViewModel: ObservableObject {
    // Learning section
    @Published var subjects: [Subject] = []
    @Published var selectedSubject: Subject?
    @Published var selectedTopic: Topic?
    @Published var selectedFlashcard: Flashcard?

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

    // Add Reading passage sheet (subject Bài đọc)
    @Published var showAddReadingSheet = false
    @Published var newReadingTitle = ""
    @Published var newReadingContent = ""

    // Streak
    @Published var streakInfo = StreakInfo(currentStreak: 0, longestStreak: 0, didPracticeToday: false)
    
    // SRS Views
    @Published var showReviewMode = false
    @Published var showReviewMistakes = false
    @Published var showStatistics = false

    // Pending delete (show confirmation before actually deleting)
    @Published var topicToDelete: Topic?
    @Published var flashcardToDelete: Flashcard?
    @Published var passageToDelete: ReadingPassage?

    // Error message for DB failures (shown as alert)
    @Published var errorMessage: String?
    /// Thông báo sau khi sao lưu xong (sheet đã đóng, hiện alert trên màn chính).
    @Published var backupSaveResultMessage: String?

    // Loading state (initial load / reload)
    @Published var isLoading = false

    // Undo delete: show banner and allow restore within a few seconds
    enum UndoableItem {
        case topic(name: String, subjectId: Int, flashcards: [Flashcard], readings: [(title: String, content: String)])
        case flashcard(Flashcard, topicId: Int)
        case passage(title: String, content: String, topicId: Int)
    }
    @Published var undoableItem: UndoableItem?
    private var undoClearWorkItem: DispatchWorkItem?

    // Keyboard shortcuts help sheet (menu Help → Phím tắt / sidebar)
    @Published var showKeyboardShortcutsSheet = false

    // Backup / Restore sheet (sidebar)
    @Published var showBackupRestoreSheet = false

    // Giọng đọc tiếng Anh (TTS accent) sheet (sidebar)
    @Published var showSpeechAccentSheet = false

    // Import flashcards sheet (from CSV/JSON)
    @Published var showImportFlashcardSheet = false

    // MARK: - Navigation Helpers
    
    var isInSpecialMode: Bool {
        showReviewMode || showReviewMistakes || showStatistics
    }
    
    func switchToLearningMode() {
        // Keep selectedSubject when switching back to learning mode
        showReviewMode = false
        showReviewMistakes = false
        showStatistics = false
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

    init() {
        isLoading = true
        DispatchQueue.main.async { [weak self] in
            self?.loadLearningData()
            self?.loadStreakInfo()
            self?.isLoading = false
        }
    }

    // Filter topics based on search text (topic name)
    func filteredTopics(for subject: Subject) -> [Topic] {
        if searchText.isEmpty {
            return subject.topics
        }
        return subject.topics.filter { topic in
            topic.name.localizedCaseInsensitiveContains(searchText)
        }
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

        // Lưu lại ID trước khi load lại data
        let currentSubjectId = subject.id

        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        let newTopic = Topic(
            name: trimmedName,
            subjectId: subject.id,
            flashcards: [],
            readings: []
        )

        DatabaseManager.shared.insertTopic(newTopic)

        loadLearningData()

        // Restore lại selection sau khi load
        if let updatedSubject = subjects.first(where: { $0.id == currentSubjectId }) {
            self.selectedSubject = updatedSubject
            // Giữ nguyên topic đang chọn nếu có
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

            // Lưu lại ID trước khi load lại data
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
                exerciseType: .chineseToVietnamese
            )
            
            DatabaseManager.shared.insertFlashcard(newFlashcard, topicId: currentTopicId)

            loadLearningData()

            // Restore lại selection sau khi load
            if let updatedSubject = subjects.first(where: { $0.id == currentSubjectId }),
               let updatedTopic = updatedSubject.topics.first(where: { $0.id == currentTopicId }) {
                self.selectedSubject = updatedSubject
                self.selectedTopic = updatedTopic
                self.selectedFlashcard = updatedTopic.flashcards.last // Chọn thẻ vừa tạo
            }

            newFlashcardQuestion = ""
            newFlashcardAnswer = ""
            newFlashcardHint = ""
            showAddFlashcardSheet = false
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
            let newTopicId = DatabaseManager.shared.insertTopic(newTopic)
            for card in flashcards {
                DatabaseManager.shared.insertFlashcard(card, topicId: newTopicId)
            }
            for (title, content) in readings {
                DatabaseManager.shared.insertReadingPassage(topicId: newTopicId, title: title, content: content)
            }
            loadLearningData()
            if let sub = subjects.first(where: { $0.id == subjectId }),
               let restored = sub.topics.first(where: { $0.name == name }) {
                selectedSubject = sub
                selectedTopic = restored
                selectedFlashcard = restored.flashcards.first
            }
        case .flashcard(let card, let topicId):
            DatabaseManager.shared.insertFlashcard(card, topicId: topicId)
            loadLearningData()
            if let subId = selectedSubject?.id, let sub = subjects.first(where: { $0.id == subId }),
               let topic = sub.topics.first(where: { $0.id == topicId }) {
                selectedSubject = sub
                selectedTopic = topic
                selectedFlashcard = topic.flashcards.last
            }
        case .passage(let title, let content, let topicId):
            DatabaseManager.shared.insertReadingPassage(topicId: topicId, title: title, content: content)
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
        guard DatabaseManager.shared.deleteTopic(id: topic.id) else {
            errorMessage = "Không thể xóa chủ đề. Vui lòng thử lại."
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

    func addReadingPassage(topicId: Int, title: String, content: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedContent = content.trimmingCharacters(in: .whitespaces)

        DatabaseManager.shared.insertReadingPassage(topicId: topicId, title: trimmedTitle, content: trimmedContent)
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
        guard DatabaseManager.shared.deleteReadingPassage(id: passage.id) else {
            errorMessage = "Không thể xóa bài đọc. Vui lòng thử lại."
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
        guard DatabaseManager.shared.deleteFlashcard(id: flashcard.id) else {
            errorMessage = "Không thể xóa từ vựng. Vui lòng thử lại."
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

        if selectedFlashcard?.id == flashcard.id {
            selectedFlashcard = selectedTopic?.flashcards.first
        }
    }

    func updateFlashcard(id: Int, question: String, answer: String, hint: String?) {
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

        DatabaseManager.shared.updateFlashcard(id: id, question: trimmedQuestion, answer: trimmedAnswer, hint: hintOrNil)
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
        subjects = DatabaseManager.shared.loadAllSubjects()
        if selectedSubject == nil, let first = subjects.first {
            selectSubject(first)
        }
    }

    func selectSubject(_ subject: Subject) {
        // Kiểm tra xem topic hiện tại có thuộc subject mới không
        let currentTopicId = selectedTopic?.id
        let currentTopicBelongsToNewSubject = currentTopicId != nil && 
            subject.topics.contains(where: { $0.id == currentTopicId })
        
        selectedSubject = subject
        
        if currentTopicBelongsToNewSubject, let currentTopic = subject.topics.first(where: { $0.id == currentTopicId }) {
            // Giữ nguyên topic đang chọn nếu nó thuộc subject mới
            selectedTopic = currentTopic
            // Giữ nguyên flashcard nếu có thể
            if let currentFlashcardId = selectedFlashcard?.id,
               currentTopic.flashcards.contains(where: { $0.id == currentFlashcardId }) {
                selectedFlashcard = currentTopic.flashcards.first(where: { $0.id == currentFlashcardId })
            } else {
                selectedFlashcard = currentTopic.flashcards.first
            }
        } else if let firstTopic = subject.topics.first {
            // Chỉ chọn topic đầu tiên nếu topic hiện tại không thuộc subject mới
            selectedTopic = firstTopic
            selectedFlashcard = firstTopic.flashcards.first
        } else {
            selectedTopic = nil
            selectedFlashcard = nil
        }
    }

    func selectTopic(_ topic: Topic) {
        // Chỉ update nếu topic thực sự thay đổi
        if selectedTopic?.id != topic.id {
            selectedTopic = topic
            selectedFlashcard = topic.flashcards.first
        }
    }

    func selectFlashcard(_ flashcard: Flashcard) {
        selectedFlashcard = flashcard
    }

    // MARK: - Streak

    func loadStreakInfo() {
        streakInfo = DatabaseManager.shared.getStreakInfo()
    }

    func recordPractice(practiceType: String, topicId: Int, correct: Int, total: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        DatabaseManager.shared.recordPracticeSession(
            practiceDate: today,
            practiceType: practiceType,
            topicId: topicId,
            correct: correct,
            total: total
        )
        loadStreakInfo()
    }
}
