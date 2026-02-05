//
//  LocalizationManager.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI
import Combine

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language = .vietnamese
    
    enum Language: String, CaseIterable {
        case vietnamese = "vi"
        case english = "en"
        case chinese = "zh"
        
        var displayName: String {
            switch self {
            case .vietnamese: return "Tiếng Việt"
            case .english: return "English"
            case .chinese: return "中文"
            }
        }
    }
    
    private init() {
        // Load saved language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language"),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        }
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "app_language")
    }
}

// MARK: - Localized String Extension
extension String {
    var localized: String {
        let language = LocalizationManager.shared.currentLanguage.rawValue
        let path = Bundle.main.path(forResource: language, ofType: "lproj") ?? Bundle.main.bundlePath
        let bundle = Bundle(path: path) ?? Bundle.main
        
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: localized, arguments: arguments)
    }
}

// MARK: - Localization Keys
struct LocalizedKeys {
    // Common
    static let cancel = "common.cancel"
    static let confirm = "common.confirm"
    static let next = "common.next"
    static let back = "common.back"
    static let done = "common.done"
    static let continue_ = "common.continue"
    
    // Review
    static let review = "review.title"
    static let reviewMistakes = "review.mistakes.title"
    static let noCardsToReview = "review.no_cards"
    static let allCardsReviewed = "review.all_reviewed"
    static let tapToShowAnswer = "review.tap_to_show"
    static let wrong = "review.wrong"
    static let hard = "review.hard"
    static let correct = "review.correct"
    static let reviewCompleted = "review.completed"
    static let reviewedCount = "review.reviewed_count"
    static let accuracy = "review.accuracy"
    static let reviewMore = "review.review_more"
    static let reviewAgain = "review.review_again"
    
    // Statistics
    static let statistics = "statistics.title"
    static let totalCards = "statistics.total_cards"
    static let learnedCards = "statistics.learned_cards"
    static let masteredCards = "statistics.mastered_cards"
    static let dueCards = "statistics.due_cards"
    
    // Practice
    static let practice = "practice.title"
    static let speaking = "practice.speaking"
    static let fillInBlank = "practice.fill_in_blank"
}
