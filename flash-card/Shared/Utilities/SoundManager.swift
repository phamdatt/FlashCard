//
//  SoundManager.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import AppKit

class SoundManager {
    static let shared = SoundManager()
    
    private var correctSound: NSSound?
    private var incorrectSound: NSSound?
    private var successSound: NSSound?
    
    private init() {
        setupSounds()
    }
    
    private func setupSounds() {
        // Sử dụng system sounds tốt hơn
        // Correct: Purr (nhẹ nhàng, tích cực)
        correctSound = NSSound(named: "Purr")
        
        // Incorrect: Funk (ngắn gọn, không quá tiêu cực)
        incorrectSound = NSSound(named: "Funk")
        
        // Success: Glass (sáng, thành công)
        successSound = NSSound(named: "Glass")
    }
    
    func playCorrect() {
        correctSound?.play()
    }
    
    func playIncorrect() {
        incorrectSound?.play()
    }
    
    func playSuccess() {
        successSound?.play()
    }
    
    // Haptic feedback kết hợp
    func playCorrectWithHaptic() {
        playCorrect()
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    }
    
    func playIncorrectWithHaptic() {
        playIncorrect()
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    }
    
    func playSuccessWithHaptic() {
        playSuccess()
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
    }
}
