//
//  SmartCopyDefineView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI
import AppKit

// MARK: - Smart Copy & Define Text View
struct SmartCopyDefineText: View {
    let text: String
    let flashcards: [Flashcard]?
    
    @State private var showDefinition: Bool = false
    @State private var definitionResult: (word: String, meaning: String)? = nil
    
    var body: some View {
        Text(text)
            .scaledFont(14)
            .textSelection(.enabled)
            .contextMenu {
                Button(action: {
                    copyToClipboard(text)
                }) {
                    Label("Sao chép", systemImage: "doc.on.doc")
                }
                Button(action: {
                    findDefinitionForText(text)
                }) {
                    Label("Tìm nghĩa", systemImage: "book.fill")
                }
                Divider()
                Button(action: {
                    speakText(text)
                }) {
                    Label("Phát âm", systemImage: "speaker.wave.2")
                }
            }
            .popover(isPresented: $showDefinition, arrowEdge: .bottom) {
                if let result = definitionResult {
                    DefinitionPopover(word: result.word, meaning: result.meaning) {
                        showDefinition = false
                        definitionResult = nil
                    }
                }
            }
            .onTapGesture(count: 2) {
                // Double-click to find definition
                findDefinitionForText(text)
            }
    }
    
    private func findDefinitionForText(_ searchText: String) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Try to find definition in flashcards
        if let flashcards = flashcards {
            // Search for exact match (case insensitive)
            if let match = flashcards.first(where: { flashcard in
                flashcard.question.localizedCaseInsensitiveContains(trimmed) ||
                flashcard.answer.localizedCaseInsensitiveContains(trimmed)
            }) {
                // Determine which field matches
                let isQuestion = match.question.localizedCaseInsensitiveContains(trimmed)
                definitionResult = (
                    word: trimmed,
                    meaning: isQuestion ? match.answer : match.question
                )
                showDefinition = true
                return
            }
            
            // Try to find word in question or answer (word-by-word match)
            for flashcard in flashcards {
                let separatorSet = CharacterSet.whitespaces.union(CharacterSet.punctuationCharacters)
                let questionWords = flashcard.question.components(separatedBy: separatorSet)
                    .filter { !$0.isEmpty }
                let answerWords = flashcard.answer.components(separatedBy: separatorSet)
                    .filter { !$0.isEmpty }
                
                if questionWords.contains(where: { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
                    definitionResult = (word: trimmed, meaning: flashcard.answer)
                    showDefinition = true
                    return
                }
                
                if answerWords.contains(where: { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
                    definitionResult = (word: trimmed, meaning: flashcard.question)
                    showDefinition = true
                    return
                }
            }
            
            // Try partial match
            for flashcard in flashcards {
                if flashcard.question.localizedCaseInsensitiveContains(trimmed) {
                    definitionResult = (word: trimmed, meaning: flashcard.answer)
                    showDefinition = true
                    return
                }
                if flashcard.answer.localizedCaseInsensitiveContains(trimmed) {
                    definitionResult = (word: trimmed, meaning: flashcard.question)
                    showDefinition = true
                    return
                }
            }
        }
        
        // If no match found, show message
        definitionResult = (word: trimmed, meaning: "Không tìm thấy nghĩa trong flashcard")
        showDefinition = true
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

// MARK: - Definition Popover
struct DefinitionPopover: View {
    let word: String
    let meaning: String
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.blue)
                    .scaledFont(20)
                
                Text(word)
                    .scaledFont(14)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Meaning
            VStack(alignment: .leading, spacing: 6) {
                Text("Nghĩa")
                    .scaledFont(14)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text(meaning)
                    .scaledFont(14)
                    .foregroundStyle(.primary)
            }
            
            // Copy button
            Button(action: {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString("\(word): \(meaning)", forType: .string)
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            }) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Sao chép")
                }
                .scaledFont(14)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .frame(minWidth: 250, maxWidth: 350)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light
                    ? Color(nsColor: .controlBackgroundColor)
                    : Color(nsColor: .textBackgroundColor))
        )
    }
}
