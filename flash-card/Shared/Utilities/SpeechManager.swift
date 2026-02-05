//
//  SpeechManager.swift
//  flash-card
//
//  Giữ AVSpeechSynthesizer để TTS không bị dừng do synthesizer bị giải phóng.
//

import Foundation
import AVFoundation
import Combine
import AppKit

/// Shared TTS: phải giữ synthesizer trong instance, không tạo local.
@MainActor
final class SpeechManager: ObservableObject {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    private let delegateHolder: SpeechDelegateHolder

    @Published private(set) var isSpeaking = false
    /// Khi TTS không dùng được (không có giọng), set message để UI hiện hướng dẫn.
    @Published var ttsUnavailableMessage: String?

    private init() {
        let holder = SpeechDelegateHolder()
        synthesizer.delegate = holder
        self.delegateHolder = holder
        holder.onFinish = { [weak self] in
            DispatchQueue.main.async { self?.isSpeaking = false }
        }
    }

    func speak(text: String, language: String? = nil) {
        ttsUnavailableMessage = nil
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let lang = language ?? detectLanguage(t)
        let voice = AVSpeechSynthesisVoice(language: lang)
            ?? AVSpeechSynthesisVoice(language: "en-US")
            ?? AVSpeechSynthesisVoice()
            ?? AVSpeechSynthesisVoice.speechVoices().first
        guard let voice = voice else {
            ttsUnavailableMessage = "Chưa có giọng đọc. Vào Cài đặt hệ thống → Trợ năng → Nội dung đọc (Spoken Content) để tải giọng."
            return
        }
        let utterance = AVSpeechUtterance(string: t)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.volume = 1.0
        utterance.voice = voice
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Mở Cài đặt hệ thống → Trợ năng (để user tự vào mục Nội dung đọc / Spoken Content).
    func openSpeechSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess") {
            NSWorkspace.shared.open(url)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func detectLanguage(_ text: String) -> String {
        let cjk = text.unicodeScalars.contains { s in (s.value >= 0x4E00 && s.value <= 0x9FFF) }
        if cjk { return "zh-CN" }
        return "vi-VN"
    }
}

private final class SpeechDelegateHolder: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish?()
    }
}
