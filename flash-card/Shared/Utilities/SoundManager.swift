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

    private static let practiceSoundEnabledKey = "practiceSoundEnabled"

    /// Bật/tắt âm thanh khi chọn đáp án (đúng/sai) và khi kết thúc practice. Mặc định bật.
    static var practiceSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: practiceSoundEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: practiceSoundEnabledKey) }
    }

    private var correctSound: NSSound?
    private var incorrectSound: NSSound?
    private var successSound: NSSound?
    private var countdownTickSound: NSSound?
    private var recordingReadySound: NSSound?

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

        // Completion / success (celebratory, Duolingo-style)
        successSound = NSSound(named: "Hero") ?? NSSound(named: "Glass") ?? NSSound(named: "Tink")
        // Countdown tick (ngắn, rõ)
        countdownTickSound = NSSound(named: "Tink") ?? NSSound(named: "Pop")
        // Bắt đầu ghi âm / sẵn sàng
        recordingReadySound = NSSound(named: "Glass") ?? NSSound(named: "Ping") ?? NSSound(named: "Tink")
    }

    func playCountdownTick() {
        DispatchQueue.main.async { [weak self] in
            self?.stopAndPlay(self?.countdownTickSound)
        }
    }

    func playRecordingReady() {
        DispatchQueue.main.async { [weak self] in
            self?.stopAndPlay(self?.recordingReadySound)
        }
    }

    private func stopAndPlay(_ sound: NSSound?) {
        sound?.stop()
        sound?.play()
    }

    func playCorrect() {
        guard Self.practiceSoundEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            self?.stopAndPlay(self?.correctSound)
        }
    }

    func playIncorrect() {
        guard Self.practiceSoundEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            self?.stopAndPlay(self?.incorrectSound)
        }
    }

    func playSuccess() {
        guard Self.practiceSoundEnabled else { return }
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
