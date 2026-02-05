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

    // Streak
    @Published var streakInfo = StreakInfo(currentStreak: 0, longestStreak: 0, didPracticeToday: false)
    
    // SRS Views
    @Published var showReviewMode = false
    @Published var showReviewMistakes = false
    @Published var showStatistics = false
    
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
        loadLearningData()
        loadStreakInfo()
    }

    // Filter topics based on search text
    func filteredTopics(for subject: Subject) -> [Topic] {
        if searchText.isEmpty {
            return subject.topics
        }
        return subject.topics.filter { topic in
            topic.name.localizedCaseInsensitiveContains(searchText)
        }
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

    func deleteTopic(_ topic: Topic) {
        DatabaseManager.shared.deleteTopic(id: topic.id)

        let currentSubjectId = selectedSubject?.id
        loadLearningData()

        if selectedTopic?.id == topic.id {
            selectedTopic = nil
            selectedFlashcard = nil
        }

        if let currentSubjectId = currentSubjectId {
            selectedSubject = subjects.first(where: { $0.id == currentSubjectId })
        }
    }

    func deleteFlashcard(_ flashcard: Flashcard) {
        DatabaseManager.shared.deleteFlashcard(id: flashcard.id)
        
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

    // MARK: - Learning Data Management

    private func loadLearningData() {
        subjects = DatabaseManager.shared.loadAllSubjects()
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
