//
//  SpeechManager.swift
//  flash-card
//
//  Hold AVSpeechSynthesizer so TTS is not stopped when synthesizer is released.
//

import Foundation
import AVFoundation
import Combine
import AppKit

/// Selectable English voice (accent) identifier.
enum EnglishAccent: String, CaseIterable, Identifiable {
    case us = "en-US"
    case gb = "en-GB"
    case au = "en-AU"
    case ie = "en-IE"
    case za = "en-ZA"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .us: return "English (US)"
        case .gb: return "English (UK)"
        case .au: return "English (Australia)"
        case .ie: return "English (Ireland)"
        case .za: return "English (South Africa)"
        }
    }
}

private let ttsEnglishAccentKey = "tts_english_accent"

/// Shared TTS: keep synthesizer in instance, do not create locally.
@MainActor
final class SpeechManager: ObservableObject {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    private let delegateHolder: SpeechDelegateHolder

    @Published private(set) var isSpeaking = false
    /// When TTS is unavailable (no voice), set message for UI to show guidance.
    @Published var ttsUnavailableMessage: String?

    /// English accent used for TTS (stored in UserDefaults).
    var preferredEnglishAccent: EnglishAccent {
        get {
            let raw = UserDefaults.standard.string(forKey: ttsEnglishAccentKey) ?? EnglishAccent.gb.rawValue
            return EnglishAccent(rawValue: raw) ?? .gb
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: ttsEnglishAccentKey)
        }
    }

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
        let voice = voiceForLanguage(lang)
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

    /// Chọn giọng: với Tiếng Trung (zh) ưu tiên giọng nam (Kangkang / male) nếu có.
    private func voiceForLanguage(_ language: String) -> AVSpeechSynthesisVoice? {
        if language.hasPrefix("zh") {
            let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("zh") }
            guard !voices.isEmpty else {
                return AVSpeechSynthesisVoice(language: language)
            }
            // Ưu tiên giọng nam: Kangkang = Mandarin male (identifier hoặc name)
            for v in voices {
                let idLower = v.identifier.lowercased()
                let nameLower = v.name.lowercased()
                if idLower.contains("kangkang") || nameLower.contains("kangkang") { return v }
            }
            if #available(macOS 10.15, *) {
                if let male = voices.first(where: { $0.gender == .male }) { return male }
            }
            // Fallback: identifier chứa "male" (một số giọng hệ thống)
            if let male = voices.first(where: { $0.identifier.lowercased().contains("male") }) { return male }
            return voices.first
        }
        return AVSpeechSynthesisVoice(language: language)
            ?? AVSpeechSynthesisVoice(language: preferredEnglishAccent.rawValue)
            ?? AVSpeechSynthesisVoice(language: "en-US")
            ?? AVSpeechSynthesisVoice()
            ?? AVSpeechSynthesisVoice.speechVoices().first
    }

    /// Opens System Settings → Accessibility (user goes to Spoken Content).
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
        if looksLikeVietnamese(text) { return "vi-VN" }
        return preferredEnglishAccent.rawValue
    }

    /// Detects if text is Vietnamese (characteristic chars: ă, â, đ, ê, ô, ơ, ư, tone marks).
    private func looksLikeVietnamese(_ text: String) -> Bool {
        let vietnameseChars = CharacterSet(charactersIn: "ăâđêôơưĂÂĐÊÔƠƯàáảãạèéẻẽệìíỉĩịòóỏõọùúủũụỳýỷỹỵằắẳẵặầấẩẫậờớởỡợừứửữự")
        return text.unicodeScalars.contains { vietnameseChars.contains($0) }
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
