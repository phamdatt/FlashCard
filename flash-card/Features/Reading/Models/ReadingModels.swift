//
//  ReadingModels.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import Foundation

// MARK: - Reading Models

struct ReadingPassage: Identifiable, Hashable, Codable {
    let id: Int
    let title: String
    let level: ReadingLevel
    let content: String
    let questions: [ReadingQuestion]
    let vocabularyHelp: [VocabularyItem]?

    init(id: Int, title: String, level: ReadingLevel, content: String, questions: [ReadingQuestion], vocabularyHelp: [VocabularyItem]? = nil) {
        self.id = id
        self.title = title
        self.level = level
        self.content = content
        self.questions = questions
        self.vocabularyHelp = vocabularyHelp
    }
}

struct ReadingQuestion: Identifiable, Hashable, Codable {
    let id: Int
    let question: String
    let options: [String]
    let correctAnswer: String
    let explanation: String?

    init(id: Int, question: String, options: [String], correctAnswer: String, explanation: String? = nil) {
        self.id = id
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }
}

struct VocabularyItem: Identifiable, Hashable, Codable {
    let id: Int
    let word: String
    let meaning: String
    let example: String?

    init(id: Int, word: String, meaning: String, example: String? = nil) {
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
