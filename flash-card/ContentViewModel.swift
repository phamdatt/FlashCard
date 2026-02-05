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

        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        let newTopic = Topic(
            name: trimmedName,
            subjectId: subject.id,
            flashcards: [],
            readings: []
        )

        // Lưu vào SQLite
        DatabaseManager.shared.insertTopic(newTopic)

        // Load lại dữ liệu để UI cập nhật
        loadLearningData()

        // Reset form
        newTopicName = ""
        showAddTopicSheet = false
    }

    func addFlashcard(question: String, answer: String, hint: String) {
            guard let topic = selectedTopic,
                !question.trimmingCharacters(in: .whitespaces).isEmpty,
                !answer.trimmingCharacters(in: .whitespaces).isEmpty else { return }

            let trimmedQuestion = question.trimmingCharacters(in: .whitespaces)
            let trimmedAnswer = answer.trimmingCharacters(in: .whitespaces)
            let trimmedHint = hint.trimmingCharacters(in: .whitespaces)

            let newFlashcard = Flashcard(
                question: trimmedQuestion,
                answer: trimmedAnswer,
                hint: trimmedHint.isEmpty ? nil : trimmedHint,
                options: nil,
                correctAnswer: nil,
                exerciseType: .englishToVietnamese
            )
            
            // 1. Lưu xuống SQLite
            DatabaseManager.shared.insertFlashcard(newFlashcard, topicId: topic.id)

            // 2. Load lại toàn bộ (Hàm loadFlashcards trong DatabaseManager sẽ tự động gen Options mới)
            loadLearningData()

            // 3. Khôi phục trạng thái lựa chọn
            if let updatedSubject = subjects.first(where: { $0.id == topic.subjectId }),
            let updatedTopic = updatedSubject.topics.first(where: { $0.id == topic.id }) {
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
        // 1. Xóa trong SQLite
        DatabaseManager.shared.deleteTopic(id: topic.id)

        // 2. Sync UI
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
        // 1. Xóa trong SQLite
        DatabaseManager.shared.deleteFlashcard(id: flashcard.id)
        
        // 2. Sync UI
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
        selectedSubject = subject
        // Auto-select first topic if available
        if let firstTopic = subject.topics.first {
            selectedTopic = firstTopic
            // Auto-select first flashcard if available
            selectedFlashcard = firstTopic.flashcards.first
        } else {
            selectedTopic = nil
            selectedFlashcard = nil
        }
    }

    func selectTopic(_ topic: Topic) {
        selectedTopic = topic
        // Auto-select first flashcard if available
        selectedFlashcard = topic.flashcards.first
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
