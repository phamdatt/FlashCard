//
//  StrokeDrawSuggestView.swift
//  flash-card
//
//  Vẽ nét trên canvas → gợi ý từ theo số nét (Tiếng Trung).
//

import SwiftUI
import AppKit

// MARK: - Drawing Canvas (NSView)

final class DrawingCanvasNSView: NSView {
    var strokes: [[CGPoint]] = [] {
        didSet { needsDisplay = true }
    }
    var currentStroke: [CGPoint] = [] {
        didSet { needsDisplay = true }
    }
    var strokeColor: NSColor = .labelColor
    var strokeWidth: CGFloat = 3
    var onStrokesChanged: (() -> Void)?

    override var isFlipped: Bool { true }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        currentStroke = [p]
    }

    override func mouseDragged(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        currentStroke.append(p)
    }

    override func mouseUp(with event: NSEvent) {
        if currentStroke.count > 1 {
            strokes.append(currentStroke)
            onStrokesChanged?()
        }
        currentStroke = []
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        for stroke in strokes {
            guard let first = stroke.first else { continue }
            ctx.move(to: first)
            for p in stroke.dropFirst() {
                ctx.addLine(to: p)
            }
            ctx.strokePath()
        }
        if !currentStroke.isEmpty, let first = currentStroke.first {
            ctx.move(to: first)
            for p in currentStroke.dropFirst() {
                ctx.addLine(to: p)
            }
            ctx.strokePath()
        }
    }
}

// MARK: - SwiftUI wrapper

struct DrawingCanvasView: NSViewRepresentable {
    @Binding var strokes: [[CGPoint]]
    var strokeCount: Int { strokes.count }
    @Environment(\.colorScheme) private var colorScheme

    func makeNSView(context: Context) -> DrawingCanvasNSView {
        let v = DrawingCanvasNSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.appBackgroundText(isLight: colorScheme == .light).cgColor
        return v
    }

    func updateNSView(_ nsView: DrawingCanvasNSView, context: Context) {
        nsView.layer?.backgroundColor = NSColor.appBackgroundText(isLight: colorScheme == .light).cgColor
        nsView.strokes = strokes
        nsView.onStrokesChanged = { [weak nsView] in
            guard let v = nsView else { return }
            DispatchQueue.main.async {
                strokes = v.strokes
            }
        }
    }
}

// MARK: - Main View: Canvas + Suggest

struct StrokeDrawSuggestView: View {
    @ObservedObject var viewModel: ContentViewModel
    let onDismiss: () -> Void

    @State private var strokes: [[CGPoint]] = []
    @State private var suggestedFlashcards: [(topic: Topic, flashcard: Flashcard)] = []
    @State private var showSuggestions = false
    @Environment(\.colorScheme) private var colorScheme

    private var chineseFlashcards: [(topic: Topic, flashcard: Flashcard)] {
        var result: [(Topic, Flashcard)] = []
        for subject in viewModel.subjects where subject.name == "Tiếng Trung" {
            for topic in subject.topics {
                for fc in topic.flashcards {
                    result.append((topic, fc))
                }
            }
        }
        return result
    }

    private func suggestWords() {
        let count = strokes.count
        guard count > 0 else {
            suggestedFlashcards = []
            showSuggestions = true
            return
        }
        suggestedFlashcards = chineseFlashcards.filter { _, fc in
            StrokeCountData.containsCharacter(withStrokeCount: count, in: fc.questionDisplayText)
        }
        showSuggestions = true
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Vẽ nét → Gợi ý từ")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
            }
            .padding()

            Text("Vẽ từng nét chữ lên ô dưới. Nhấn \"Gợi ý từ\" để tìm từ có chữ cùng số nét.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appBackgroundText(isLight: colorScheme == .light))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appBorder(isLight: colorScheme == .light), lineWidth: 1)
                    )
                DrawingCanvasView(strokes: $strokes)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(height: 280)
            .padding()

            HStack(spacing: 12) {
                Text("Số nét: \(strokes.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Button("Xoá hết") {
                    strokes = []
                    showSuggestions = false
                }
                .buttonStyle(.bordered)
                .cursor(.pointingHand)
                Button("Hoàn tác") {
                    if !strokes.isEmpty {
                        strokes.removeLast()
                        showSuggestions = false
                    }
                }
                .buttonStyle(.bordered)
                .cursor(.pointingHand)
                .disabled(strokes.isEmpty)
                Spacer()
                Button(action: suggestWords) {
                    Label("Gợi ý từ", systemImage: "lightbulb.fill")
                        .font(.app(.body))
                }
                .buttonStyle(.borderedProminent)
                .cursor(.pointingHand)
                .tint(Color.hintYellow(isLight: colorScheme == .light))
            }
            .padding(.horizontal)

            if showSuggestions {
                ThemeDivider()
                    .padding(.vertical, 8)
                if suggestedFlashcards.isEmpty {
                    Text(strokes.isEmpty ? "Vẽ vài nét rồi nhấn \"Gợi ý từ\"." : "Không có từ nào có chữ đúng \(strokes.count) nét trong bộ từ của bạn.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    List {
                        ForEach(suggestedFlashcards, id: \.flashcard.id) { item in
                            Button(action: {
                                viewModel.selectedSubject = viewModel.subjects.first(where: { $0.id == item.topic.subjectId })
                                viewModel.selectedTopic = item.topic
                                viewModel.selectedFlashcard = item.flashcard
                                viewModel.showStatistics = false
                                onDismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.flashcard.questionDisplayText)
                                            .font(.headline)
                                        Text(item.flashcard.answer)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(item.topic.name)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .cursor(.pointingHand)
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 260)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 480, height: 620)
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
    }
}
