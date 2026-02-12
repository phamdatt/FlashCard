//
//  SmartCopyDefineView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI
import AppKit

// MARK: - Smart Copy Text View (text selection + context menu)
struct SmartCopyDefineText: View {
    let text: String
    let flashcards: [Flashcard]?
    /// Font cho nội dung (dùng ở bài đọc).
    var defineTextFont: Font? = nil
    /// Màu chữ.
    var defineTextColor: Color? = nil

    var body: some View {
        Text(text)
            .font(defineTextFont ?? .body)
            .foregroundStyle(defineTextColor ?? .primary)
            .textSelection(.enabled)
            .contextMenu { contextMenuContent }
    }

    @ViewBuilder private var contextMenuContent: some View {
        Button(action: { copyToClipboard(text) }) {
            Label("Sao chép", systemImage: "doc.on.doc")
        }
        Divider()
        Button(action: { speakText(text) }) {
            Label("Phát âm", systemImage: "speaker.wave.2")
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
    }

    private func speakText(_ text: String) {
        SpeechManager.shared.speak(text: text, language: nil)
    }
}
