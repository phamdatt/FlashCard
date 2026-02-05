//
//  SRSModels.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import Foundation

// MARK: - Flashcard Progress (SRS)
struct FlashcardProgress: Identifiable, Codable {
    let id: Int
    let flashcardId: Int
    var easeFactor: Double // Ease factor (default 2.5, min 1.3)
    var interval: Int // Days until next review
    var repetitions: Int // Number of successful reviews
    var nextReviewDate: Date // Next review date
    var lastReviewDate: Date? // Last review date
    var difficulty: Double // Difficulty rating (0.0 - 1.0)
    var totalReviews: Int // Total number of reviews
    var correctReviews: Int // Number of correct reviews
    var incorrectReviews: Int // Number of incorrect reviews
    
    init(id: Int = 0, flashcardId: Int, easeFactor: Double = 2.5, interval: Int = 0, repetitions: Int = 0, nextReviewDate: Date = Date(), lastReviewDate: Date? = nil, difficulty: Double = 0.0, totalReviews: Int = 0, correctReviews: Int = 0, incorrectReviews: Int = 0) {
        self.id = id
        self.flashcardId = flashcardId
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
        self.difficulty = difficulty
        self.totalReviews = totalReviews
        self.correctReviews = correctReviews
        self.incorrectReviews = incorrectReviews
    }
    
    var accuracy: Double {
        guard totalReviews > 0 else { return 0.0 }
        return Double(correctReviews) / Double(totalReviews)
    }
    
    var isDue: Bool {
        return nextReviewDate <= Date()
    }
    
    var daysUntilReview: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: nextReviewDate).day ?? 0
        return max(0, days)
    }
}

// MARK: - Mistake Record
struct MistakeRecord: Identifiable, Codable {
    let id: Int
    let flashcardId: Int
    let practiceDate: Date
    let practiceType: String
    let topicId: Int
    
    init(id: Int = 0, flashcardId: Int, practiceDate: Date = Date(), practiceType: String, topicId: Int) {
        self.id = id
        self.flashcardId = flashcardId
        self.practiceDate = practiceDate
        self.practiceType = practiceType
        self.topicId = topicId
    }
}

// MARK: - SRS Algorithm (SM-2 based)
class SRSAlgorithm {
    // SM-2 Algorithm parameters
    private let initialEaseFactor = 2.5
    private let minEaseFactor = 1.3
    private let easeFactorChange = 0.15
    
    // Calculate next review based on quality (0-5 scale, simplified to 0-1)
    func calculateNextReview(progress: FlashcardProgress, quality: Double) -> FlashcardProgress {
        var newProgress = progress
        let now = Date()
        
        // Quality: 0.0 = wrong, 0.5 = hard, 1.0 = correct
        let isCorrect = quality >= 0.8
        let isHard = quality >= 0.5 && quality < 0.8
        
        // Update statistics
        newProgress.totalReviews += 1
        if isCorrect {
            newProgress.correctReviews += 1
        } else {
            newProgress.incorrectReviews += 1
        }
        
        // Update difficulty
        newProgress.difficulty = (newProgress.difficulty * 0.7) + (quality * 0.3)
        
        if isCorrect {
            // Correct answer
            if newProgress.repetitions == 0 {
                newProgress.interval = 1
            } else if newProgress.repetitions == 1 {
                newProgress.interval = 6
            } else {
                newProgress.interval = Int(Double(newProgress.interval) * newProgress.easeFactor)
            }
            
            newProgress.repetitions += 1
            
            // Increase ease factor slightly for correct answers
            if !isHard {
                newProgress.easeFactor = min(2.5, newProgress.easeFactor + 0.05)
            }
        } else {
            // Incorrect answer
            newProgress.repetitions = 0
            newProgress.interval = 1
            
            // Decrease ease factor
            newProgress.easeFactor = max(minEaseFactor, newProgress.easeFactor - easeFactorChange)
        }
        
        // Calculate next review date
        let calendar = Calendar.current
        newProgress.nextReviewDate = calendar.date(byAdding: .day, value: newProgress.interval, to: now) ?? now
        newProgress.lastReviewDate = now
        
        return newProgress
    }
    
    // Get flashcards due for review
    func getDueFlashcards(progressList: [FlashcardProgress]) -> [Int] {
        let now = Date()
        return progressList.filter { $0.nextReviewDate <= now }.map { $0.flashcardId }
    }
}
