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
    static let exerciseTypeLabel = "Từ vựng"

    let id: Int
    let question: String
    let answer: String
    let hint: String?
    let options: [String]?
    let correctAnswer: String?
    let exerciseType: String
    let notes: String?
    let radical: String?

    var isMultipleChoice: Bool {
        options != nil && correctAnswer != nil
    }

    /// Question text for display: only 汉字 (hán tự), with trailing "(pinyin)" removed.
    var questionDisplayText: String {
        let s = question.trimmingCharacters(in: .whitespaces)
        guard let lastClose = s.lastIndex(of: ")") else { return s }
        let beforeClose = s[..<lastClose]
        guard let lastOpen = beforeClose.lastIndex(of: "(") else { return s }
        let beforeParen = s[..<lastOpen].trimmingCharacters(in: .whitespaces)
        if beforeParen.hasSuffix(" ") {
            return beforeParen.trimmingCharacters(in: .whitespaces)
        }
        return beforeParen
    }

    /// Pinyin extracted from question if present, e.g. "你好 (nǐ hǎo)" → "nǐ hǎo". Nil if no parenthesized suffix.
    var pinyinFromQuestion: String? {
        let s = question.trimmingCharacters(in: .whitespaces)
        guard let lastClose = s.lastIndex(of: ")") else { return nil }
        let beforeClose = s[..<lastClose]
        guard let lastOpen = beforeClose.lastIndex(of: "(") else { return nil }
        let pinyin = String(s[s.index(after: lastOpen)..<lastClose]).trimmingCharacters(in: .whitespaces)
        return pinyin.isEmpty ? nil : pinyin
    }

    /// True if this flashcard has pinyin in question (for Điền pinyin mode).
    var hasPinyin: Bool { pinyinFromQuestion != nil }

    init(id: Int = 0, question: String, answer: String, hint: String? = nil, options: [String]? = nil, correctAnswer: String? = nil, exerciseType: String = Flashcard.exerciseTypeLabel, notes: String? = nil, radical: String? = nil) {
        self.id = id
        self.question = question
        self.answer = answer
        self.hint = hint
        self.options = options
        self.correctAnswer = correctAnswer
        self.exerciseType = exerciseType
        self.notes = notes
        self.radical = radical
    }
}
