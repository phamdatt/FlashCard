//
//  SpeedCardsPracticeView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

struct SpeedCardsPracticeView: View {
    let flashcards: [Flashcard]
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var knownCount: Int = 0
    @State private var unknownCards: [Flashcard] = []
    @State private var timeRemaining: Double = 10
    @State private var timer: Timer?
    @State private var showSummary: Bool = false

    private let totalTime: Double = 10

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Không có flashcard",
                systemImage: "rectangle.on.rectangle.slash",
                description: Text("Chủ đề này chưa có flashcard để luyện tập")
            )
        } else if showSummary {
            summaryView
        } else if currentIndex < flashcards.count {
            cardView
                .id(currentIndex)
        } else {
            summaryView
                .onAppear {
                    showSummary = true
                    onComplete(knownCount, flashcards.count)
                }
        }
    }

    private var cardView: some View {
        let flashcard = flashcards[currentIndex]

        return VStack(spacing: 0) {
            // Progress + Timer
            VStack(spacing: 8) {
                HStack {
                    Text("Thẻ \(currentIndex + 1)/\(flashcards.count)")
                        .font(.headline)

                    Spacer()

                    // Timer
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .foregroundStyle(timeRemaining <= 3 ? .red : .blue)
                        Text(String(format: "%.0f", timeRemaining))
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(timeRemaining <= 3 ? .red : .primary)
                    }
                }

                // Timer progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(timeRemaining <= 3 ? Color.red : Color.blue)
                            .frame(width: geometry.size.width * (timeRemaining / totalTime), height: 6)
                            .animation(.linear(duration: 0.1), value: timeRemaining)
                    }
                }
                .frame(height: 6)

                ProgressView(value: Double(currentIndex), total: Double(flashcards.count))
            }
            .padding()

            Divider()

            // Flashcard
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 20)

                    // Card with flip
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isFlipped
                                  ? Color.green.opacity(colorScheme == .light ? 0.06 : 0.1)
                                  : Color.blue.opacity(colorScheme == .light ? 0.06 : 0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        isFlipped
                                        ? Color.green.opacity(colorScheme == .light ? 0.5 : 0.8)
                                        : Color.blue.opacity(colorScheme == .light ? 0.5 : 0.8),
                                        lineWidth: 2)
                            )

                        VStack(spacing: 16) {
                            Image(systemName: isFlipped ? "lightbulb.fill" : "questionmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(isFlipped ? .yellow : .blue.opacity(0.6))

                            Text(isFlipped ? "Đáp án" : "Câu hỏi")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Text(isFlipped ? flashcard.answer : flashcard.question)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            if !isFlipped, let hint = flashcard.hint {
                                Text(hint)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .italic()
                                    .padding(.horizontal)
                            }
                        }
                        .padding(30)
                    }
                    .frame(minHeight: 220)
                    .padding(.horizontal, 24)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isFlipped.toggle()
                        }
                    }

                    // Tap to flip hint
                    if !isFlipped {
                        Text("Nhấn vào thẻ để xem đáp án")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Action buttons (show after flip)
                    if isFlipped {
                        HStack(spacing: 20) {
                            // Unknown
                            Button(action: { markCard(known: false) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                    Text("Chưa biết")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.red.opacity(colorScheme == .light ? 0.1 : 0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red, lineWidth: 2)
                                )
                                .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)

                            // Known
                            Button(action: { markCard(known: true) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                    Text("Biết rồi")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.green.opacity(colorScheme == .light ? 0.1 : 0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                                .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: 20)
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    // MARK: - Summary View

    private var summaryView: some View {
        VStack(spacing: 0) {
            // Header stats
            PracticeCompletedView(
                score: knownCount,
                totalAnswered: flashcards.count,
                customTitle: "Kết quả ôn tập nhanh",
                knownLabel: "Biết rồi",
                unknownLabel: "Chưa biết",
                onContinue: {
                    currentIndex = 0
                    knownCount = 0
                    unknownCards = []
                    showSummary = false
                    isFlipped = false
                    onReset()
                },
                unknownCards: unknownCards
            )
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timeRemaining = totalTime
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                if timeRemaining > 0 {
                    timeRemaining -= 0.1
                } else {
                    // Time's up - mark as unknown
                    markCard(known: false)
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Logic

    private func markCard(known: Bool) {
        stopTimer()

        let flashcard = flashcards[currentIndex]
        if known {
            knownCount += 1
        } else {
            unknownCards.append(flashcard)
        }

        NSSound(named: known ? "Hero" : "Basso")?.play()
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)

        withAnimation {
            currentIndex += 1
            isFlipped = false
        }

        if currentIndex < flashcards.count {
            startTimer()
        } else {
            showSummary = true
            onComplete(knownCount, flashcards.count)
        }
    }
}
