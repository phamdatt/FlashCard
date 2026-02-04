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

    init() {
        loadLearningData()
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
        
        // Tự động tạo topicKey từ tên chủ đề (ví dụ: "Thể thao" -> "user_the_thao_17123456")
        // Việc tạo key tự động giúp người dùng không phải nhập tay một mã kỹ thuật
        let timestamp = Int(Date().timeIntervalSince1970)
        let safeName = trimmedName.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "topic"
        let generatedKey = "user_\(safeName)_\(timestamp)"

        let newTopic = Topic(
            name: trimmedName,
            subjectName: subject.name,
            topicKey: generatedKey, // Truyền key vừa tạo vào đây
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
            DatabaseManager.shared.insertFlashcard(newFlashcard, topicKey: topic.topicKey)
            
            // 2. Load lại toàn bộ (Hàm loadFlashcards trong DatabaseManager sẽ tự động gen Options mới)
            loadLearningData()

            // 3. Khôi phục trạng thái lựa chọn
            if let updatedSubject = subjects.first(where: { $0.name == topic.subjectName }),
            let updatedTopic = updatedSubject.topics.first(where: { $0.topicKey == topic.topicKey }) {
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
        DatabaseManager.shared.deleteTopic(topicKey: topic.topicKey)
        
        // 2. Sync UI
        let currentSubjectName = selectedSubject?.name
        loadLearningData()
        
        if selectedTopic?.topicKey == topic.topicKey {
            selectedTopic = nil
            selectedFlashcard = nil
        }
        
        if let currentSubjectName = currentSubjectName {
            selectedSubject = subjects.first(where: { $0.name == currentSubjectName })
        }
    }

    func deleteFlashcard(_ flashcard: Flashcard) {
        // 1. Xóa trong SQLite
        DatabaseManager.shared.deleteFlashcard(id: flashcard.id)
        
        // 2. Sync UI
        let currentTopicKey = selectedTopic?.topicKey
        let currentSubjectName = selectedSubject?.name
        
        loadLearningData()
        
        if let subName = currentSubjectName, let tKey = currentTopicKey {
            selectedSubject = subjects.first(where: { $0.name == subName })
            selectedTopic = selectedSubject?.topics.first(where: { $0.topicKey == tKey })
        }
        
        if selectedFlashcard?.id == flashcard.id {
            selectedFlashcard = selectedTopic?.flashcards.first
        }
    }

    // MARK: - Learning Data Management

    private func loadLearningData() {
        let dbManager = DatabaseManager.shared
        dbManager.seedAllData()
        subjects = dbManager.loadAllSubjects()
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
}
