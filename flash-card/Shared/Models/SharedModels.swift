//
//  SharedModels.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import Foundation

// MARK: - Shared Models

struct StreakInfo: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let didPracticeToday: Bool
}
