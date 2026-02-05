//
//  LearningModels.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import Foundation

// MARK: - Learning Models

struct Subject: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let icon: String
    var topics: [Topic]

    init(id: Int, name: String, icon: String, topics: [Topic]) {
        self.id = id
        self.name = name
        self.icon = icon
        self.topics = topics
    }
}

struct Topic: Identifiable, Hashable, Codable {
    var id: Int
    var name: String
    var subjectId: Int
    var flashcards: [Flashcard]
    var readings: [ReadingPassage]

    init(id: Int = 0, name: String, subjectId: Int, flashcards: [Flashcard], readings: [ReadingPassage] = []) {
        self.id = id
        self.name = name
        self.subjectId = subjectId
        self.flashcards = flashcards
        self.readings = readings
    }
}

struct ReadingPassage: Identifiable, Hashable, Codable {
    let id: Int
    let topicId: Int
    let title: String
    let content: String
    let createdAt: String

    init(id: Int, topicId: Int, title: String, content: String, createdAt: String) {
        self.id = id
        self.topicId = topicId
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}

struct Flashcard: Identifiable, Hashable, Codable {
    let id: Int
    let question: String
    let answer: String
    let hint: String?
    let options: [String]?
    let correctAnswer: String?
    let exerciseType: ExerciseType

    var isMultipleChoice: Bool {
        options != nil && correctAnswer != nil
    }

    init(id: Int = 0, question: String, answer: String, hint: String? = nil, options: [String]? = nil, correctAnswer: String? = nil, exerciseType: ExerciseType) {
        self.id = id
        self.question = question
        self.answer = answer
        self.hint = hint
        self.options = options
        self.correctAnswer = correctAnswer
        self.exerciseType = exerciseType
    }
}

enum ExerciseType: String, Hashable, Codable {
    case englishToVietnamese = "Dịch Anh → Việt"
    case chineseToVietnamese = "Dịch Trung → Việt"
    case vietnameseToEnglish = "Dịch Việt → Anh"
    case fillInTheBlank = "Điền từ vào chỗ trống"
    case chooseCorrectWord = "Chọn từ đúng"
    case matchMeaning = "Ghép nghĩa"
}
