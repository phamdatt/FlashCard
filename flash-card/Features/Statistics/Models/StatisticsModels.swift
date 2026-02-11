//
//  StatisticsModels.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import Foundation

// MARK: - Statistics Models

struct LearningStatistics: Codable {
    let totalFlashcards: Int
    let learnedFlashcards: Int // Has been reviewed at least once
    let masteredFlashcards: Int // High accuracy and many reviews
    let dueFlashcards: Int // Cards due for review
    let accuracyByTopic: [Int: Double] // topicId -> accuracy
    let accuracyBySubject: [Int: Double] // subjectId -> accuracy
    let practiceHistory: [DailyPractice] // Daily practice stats
    let streakInfo: StreakInfo
}

/// Thống kê theo từng môn (Tiếng Anh, Tiếng Trung, …) để phân biệt trong tổng quan.
struct SubjectStats: Identifiable {
    let id: Int
    let name: String
    let total: Int
    let learned: Int
    let mastered: Int
    let due: Int
}

struct DailyPractice: Identifiable, Codable {
    let id: Int
    let date: Date
    let totalPracticed: Int
    let correctAnswers: Int
    let topicsPracticed: [Int] // topic IDs
    
    var accuracy: Double {
        guard totalPracticed > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalPracticed)
    }
}

/// Một phiên luyện tập (một lần bấm "Bắt đầu" → "Tiếp tục" kết thúc).
struct PracticeSessionRecord: Identifiable {
    let id: Int
    let practiceDate: String // yyyy-MM-dd
    let practiceType: String
    let topicId: Int?
    let topicName: String
    let subjectName: String
    let correctAnswers: Int
    let totalQuestions: Int
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
}

/// Số từ đến hạn theo ngày (cho biểu đồ).
struct DueCountByDay: Identifiable {
    let id: String // date string
    let date: Date
    let count: Int
}
