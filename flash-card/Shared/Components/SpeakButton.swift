//
//  SpeakButton.swift
//  flash-card
//
//  TTS button: dùng SpeechManager.shared (giữ synthesizer để phát âm không bị cắt).
//

import SwiftUI
import AVFoundation

struct SpeakButton: View {
    let text: String
    /// Optional: "vi-VN", "en-US", "zh-CN". If nil, inferred from content.
    var language: String? = nil
    var fontSize: CGFloat = 14

    @ObservedObject private var speechManager = SpeechManager.shared

    var body: some View {
        Button(action: speak) {
            Image(systemName: speechManager.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(.system(size: fontSize))
                .foregroundStyle(speechManager.isSpeaking ? .green : .secondary)
                .symbolEffect(.variableColor, isActive: speechManager.isSpeaking)
        }
        .buttonStyle(.plain)
        .help("Phát âm")
    }

    private func speak() {
        speechManager.speak(text: text, language: language)
    }
}
