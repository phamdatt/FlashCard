//
//  Models.swift
//  learn-macos
//
//  Created by Dat Pham on 29/1/26.
//

import Foundation

// MARK: - Models

// Models for Learning section
struct Subject: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let icon: String
    var topics: [Topic]

    init(id: UUID = UUID(), name: String, icon: String, topics: [Topic]) {
        self.id = id
        self.name = name
        self.icon = icon
        self.topics = topics
    }
}

struct Topic: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let subjectName: String // To know which subject this belongs to
    let flashcards: [Flashcard]
    let readings: [ReadingPassage] // Add reading passages

    init(id: UUID = UUID(), name: String, subjectName: String, flashcards: [Flashcard], readings: [ReadingPassage] = []) {
        self.id = id
        self.name = name
        self.subjectName = subjectName
        self.flashcards = flashcards
        self.readings = readings
    }
}

struct Flashcard: Identifiable, Hashable, Codable {
    let id: UUID
    let question: String
    let answer: String
    let hint: String?

    // For multiple choice questions
    let options: [String]?
    let correctAnswer: String?

    // Exercise type
    let exerciseType: ExerciseType

    var isMultipleChoice: Bool {
        options != nil && correctAnswer != nil
    }

    init(id: UUID = UUID(), question: String, answer: String, hint: String? = nil, options: [String]? = nil, correctAnswer: String? = nil, exerciseType: ExerciseType) {
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
    case vietnameseToEnglish = "Dịch Việt → Anh"
    case fillInTheBlank = "Điền từ vào chỗ trống"
    case chooseCorrectWord = "Chọn từ đúng"
    case matchMeaning = "Ghép nghĩa"
}

// MARK: - Reading Passage Models
struct ReadingPassage: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let level: ReadingLevel
    let content: String
    let questions: [ReadingQuestion]
    let vocabularyHelp: [VocabularyItem]? // Optional vocabulary support

    init(id: UUID = UUID(), title: String, level: ReadingLevel, content: String, questions: [ReadingQuestion], vocabularyHelp: [VocabularyItem]? = nil) {
        self.id = id
        self.title = title
        self.level = level
        self.content = content
        self.questions = questions
        self.vocabularyHelp = vocabularyHelp
    }
}

struct ReadingQuestion: Identifiable, Hashable, Codable {
    let id: UUID
    let question: String
    let options: [String]
    let correctAnswer: String // The letter (A, B, C, D)
    let explanation: String? // Optional explanation

    init(id: UUID = UUID(), question: String, options: [String], correctAnswer: String, explanation: String? = nil) {
        self.id = id
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }
}

struct VocabularyItem: Identifiable, Hashable, Codable {
    let id: UUID
    let word: String
    let meaning: String
    let example: String?

    init(id: UUID = UUID(), word: String, meaning: String, example: String? = nil) {
        self.id = id
        self.word = word
        self.meaning = meaning
        self.example = example
    }
}

enum ReadingLevel: String, Hashable, Codable {
    case beginner = "Cơ bản"
    case elementary = "Sơ cấp"
    case intermediate = "Trung cấp"
    case upperIntermediate = "Trung cấp cao"
    case advanced = "Nâng cao"
}
