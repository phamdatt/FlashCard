//
//  FontSizeManager.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI
import Combine

// MARK: - Font Size Manager
@MainActor
class FontSizeManager: ObservableObject {
    @Published var fontSizeMultiplier: CGFloat = 1.0
    
    private let minMultiplier: CGFloat = 0.5
    private let maxMultiplier: CGFloat = 2.0
    private let step: CGFloat = 0.1
    private let userDefaultsKey = "fontSizeMultiplier"
    
    init() {
        // Load saved font size from UserDefaults
        if let saved = UserDefaults.standard.object(forKey: userDefaultsKey) as? CGFloat {
            fontSizeMultiplier = max(minMultiplier, min(maxMultiplier, saved))
        }
    }
    
    func increaseFontSize() {
        fontSizeMultiplier = min(maxMultiplier, fontSizeMultiplier + step)
        saveFontSize()
    }
    
    func decreaseFontSize() {
        fontSizeMultiplier = max(minMultiplier, fontSizeMultiplier - step)
        saveFontSize()
    }
    
    func resetFontSize() {
        fontSizeMultiplier = 1.0
        saveFontSize()
    }
    
    private func saveFontSize() {
        UserDefaults.standard.set(fontSizeMultiplier, forKey: userDefaultsKey)
    }
    
    // Helper function to apply font size multiplier
    func scaledFont(_ baseSize: CGFloat) -> CGFloat {
        return baseSize * fontSizeMultiplier
    }
}
