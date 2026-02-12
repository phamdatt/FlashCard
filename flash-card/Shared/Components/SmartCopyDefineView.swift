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
    /// Bật nhấn một lần vào từ để xem nghĩa (dùng NSTextView trên macOS để lấy từ tại vị trí nhấn).
    var singleTapToDefine: Bool = false
    /// Font cho nội dung khi singleTapToDefine = true (để khớp với giao diện bài đọc).
    var defineTextFont: Font? = nil
    /// Màu chữ khi singleTapToDefine = true.
    var defineTextColor: Color? = nil

    @State private var showDefinition: Bool = false
    @State private var definitionResult: (word: String, meaning: String)? = nil

    var body: some View {
        Group {
            if singleTapToDefine {
                WordTappableTextView(
                    text: text,
                    font: defineTextFont ?? .body,
                    textColor: defineTextColor ?? .primary,
                    lineSpacing: 12,
                    onWordTapped: { word in
                        findDefinitionForText(word)
                    }
                )
            } else {
                Text(text)
                    .textSelection(.enabled)
                    .contextMenu { contextMenuContent }
                    .onTapGesture(count: 2) { findDefinitionForText(text) }
            }
        }
        .contextMenu { contextMenuContent }
        .popover(isPresented: $showDefinition, arrowEdge: .bottom) {
            if let result = definitionResult {
                DefinitionPopover(word: result.word, meaning: result.meaning) {
                    showDefinition = false
                    definitionResult = nil
                }
            }
        }
    }

    @ViewBuilder private var contextMenuContent: some View {
        Button(action: { copyToClipboard(text) }) {
            Label("Sao chép", systemImage: "doc.on.doc")
        }
        Button(action: { findDefinitionForText(text) }) {
            Label("Tìm nghĩa", systemImage: "book.fill")
        }
        Divider()
        Button(action: { speakText(text) }) {
            Label("Phát âm", systemImage: "speaker.wave.2")
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

// MARK: - Word-tappable text (macOS: single tap to get word at point and show definition)
#if os(macOS)
private struct WordTappableTextView: NSViewRepresentable {
    let text: String
    var font: Font = .body
    var textColor: Color = .primary
    var lineSpacing: CGFloat = 12
    var onWordTapped: (String) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isRichText = false
        textView.string = text
        textView.font = nsFont(from: font)
        textView.textColor = nsTextColor
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.containerSize = NSSize(width: 400, height: CGFloat.greatestFiniteMagnitude)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes = [
            .font: textView.font ?? NSFont.systemFont(ofSize: 19),
            .foregroundColor: textView.textColor ?? .labelColor,
            .paragraphStyle: paragraphStyle
        ]

        scrollView.documentView = textView
        let gesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        gesture.delegate = context.coordinator
        textView.addGestureRecognizer(gesture)

        context.coordinator.textView = textView
        context.coordinator.onWordTapped = onWordTapped
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        textView.font = nsFont(from: font)
        textView.textColor = nsTextColor
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        textView.defaultParagraphStyle = paragraphStyle
        context.coordinator.onWordTapped = onWordTapped
        // Cập nhật frame documentView theo nội dung để nội dung hiển thị đủ và scroll được
        let width = max(400, scrollView.bounds.width)
        textView.textContainer?.containerSize = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = false
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        let used = textView.layoutManager?.usedRect(for: textView.textContainer!) ?? .zero
        let contentHeight = max(used.height + 20, 200)
        textView.frame = CGRect(x: 0, y: 0, width: width, height: contentHeight)
    }

    /// Dùng màu hệ thống để chữ luôn thấy (tránh lỗi chuyển SwiftUI Color -> NSColor).
    private var nsTextColor: NSColor {
        NSColor.labelColor
    }

    private func nsFont(from font: Font) -> NSFont {
        switch font {
        case .body: return .systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        case .title: return .systemFont(ofSize: 22, weight: .bold)
        case .title2: return .systemFont(ofSize: 20, weight: .bold)
        case .title3: return .systemFont(ofSize: 18, weight: .semibold)
        case .headline: return .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        case .callout: return .systemFont(ofSize: 15, weight: .regular)
        case .subheadline: return .systemFont(ofSize: 14, weight: .regular)
        case .footnote: return .systemFont(ofSize: 12, weight: .regular)
        case .caption: return .systemFont(ofSize: 11, weight: .regular)
        default: return .systemFont(ofSize: 19, weight: .regular)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, NSGestureRecognizerDelegate {
        var textView: NSTextView?
        var onWordTapped: (String) -> Void = { _ in }

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let textView = textView, gesture.state == .ended else { return }
            let location = gesture.location(in: textView)
            let idx = textView.characterIndexForInsertion(at: location)
            guard idx >= 0, idx < (textView.string as NSString).length else { return }
            let nsString = textView.string as NSString
            var word: String?
            nsString.enumerateSubstrings(in: NSRange(location: 0, length: nsString.length), options: [.byWords, .localized]) { substring, range, _, stop in
                if NSLocationInRange(idx, range) || (range.length > 0 && idx == range.upperBound) {
                    word = substring
                    stop.pointee = true
                }
            }
            if let w = word?.trimmingCharacters(in: .whitespacesAndNewlines), !w.isEmpty {
                onWordTapped(w)
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: NSGestureRecognizer) -> Bool {
            true
        }
    }
}

#endif

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
                    .scaledFont(.xl)
                
                Text(word)
                    .scaledFont(.sm)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
            }
            
            ThemeDivider()
            
            // Meaning
            VStack(alignment: .leading, spacing: 6) {
                Text("Nghĩa")
                    .scaledFont(.sm)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text(meaning)
                    .scaledFont(.sm)
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
                .scaledFont(.sm)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .cursor(.pointingHand)
        }
        .padding(16)
        .frame(minWidth: 250, maxWidth: 350)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
        )
    }
}
