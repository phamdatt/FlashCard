//
//  SoundManager.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//
//  Correct/wrong feedback: system sounds with fallback; stop before playing for clarity.
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
        // Correct: bright, recognizable (Glass > Ping > Tink > Purr)
        correctSound = NSSound(named: "Glass")
            ?? NSSound(named: "Ping")
            ?? NSSound(named: "Tink")
            ?? NSSound(named: "Purr")

        // Wrong: low, clear (Basso > Funk > Blow)
        incorrectSound = NSSound(named: "Basso")
            ?? NSSound(named: "Funk")
            ?? NSSound(named: "Blow")

        // Completion / success
        successSound = NSSound(named: "Glass") ?? NSSound(named: "Hero")
    }

    private func stopAndPlay(_ sound: NSSound?) {
        sound?.stop()
        sound?.play()
    }

    func playCorrect() {
        DispatchQueue.main.async { [weak self] in
            self?.stopAndPlay(self?.correctSound)
        }
    }

    func playIncorrect() {
        DispatchQueue.main.async { [weak self] in
            self?.stopAndPlay(self?.incorrectSound)
        }
    }

    func playSuccess() {
        DispatchQueue.main.async { [weak self] in
            self?.stopAndPlay(self?.successSound)
        }
    }

    func playCorrectWithHaptic() {
        playCorrect()
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
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
