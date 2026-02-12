//
//  FlipCardPracticeView.swift
//  flash-card
//
//  Chế độ thẻ lật: xem câu hỏi → chạm để lật → chọn Đã thuộc / Chưa thuộc. Giống Anki, đơn giản để ôn nhanh.
//

import SwiftUI
import AppKit

struct FlipCardPracticeView: View {
    let flashcards: [Flashcard]
    let topic: Topic
    let topicId: Int
    let subjectName: String
    var subjectIcon: String? = nil
    var radicalForCharacter: ((String) -> String?)?
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var currentIndex: Int = 0
    @State private var knownCount: Int = 0
    @State private var unknownCards: [Flashcard] = []
    @State private var isFlipped: Bool = false
    @State private var srsAlgorithm = SRSAlgorithm()

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Không có flashcard",
                systemImage: "rectangle.on.rectangle.slash",
                description: Text("Chủ đề này chưa có flashcard để luyện tập")
            )
        } else if currentIndex >= flashcards.count {
            PracticeCompletedView(
                score: knownCount,
                totalAnswered: flashcards.count,
                customTitle: "Kết quả thẻ lật",
                knownLabel: "Đã thuộc",
                unknownLabel: "Chưa thuộc",
                onContinue: {
                    currentIndex = 0
                    knownCount = 0
                    unknownCards = []
                    isFlipped = false
                    onReset()
                },
                unknownCards: unknownCards
            )
        } else {
            cardView
                .id(currentIndex)
                .onChange(of: currentIndex) { _, _ in isFlipped = false }
        }
    }

    private var cardView: some View {
        let flashcard = flashcards[currentIndex]
        let radicalText: String? = {
            guard subjectName == "Tiếng Trung" else { return nil }
            if let r = flashcard.radical, !r.isEmpty { return r }
            return radicalForCharacter?(flashcard.questionDisplayText)
        }()

        return VStack(spacing: 0) {
            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Thẻ \(currentIndex + 1)/\(flashcards.count)")
                        .font(.app(.headline))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Thẻ lật")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(colorScheme == .light ? 0.14 : 0.2))
                        .cornerRadius(6)
                }
                ProgressView(value: Double(currentIndex), total: Double(max(flashcards.count, 1)))
                    .scaleEffect(y: 1.8, anchor: .center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ThemeDivider()

            // Card
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 20)

                    // Flip card
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appCardBackground(isLight: colorScheme == .light))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        isFlipped
                                        ? Color.green.opacity(colorScheme == .light ? 0.5 : 0.8)
                                        : Color.appBorder(isLight: colorScheme == .light),
                                        lineWidth: 2)
                            )

                        VStack(spacing: 16) {
                            Image(systemName: isFlipped ? "lightbulb.fill" : "questionmark.circle.fill")
                                .font(.app(.largeTitle))
                                .foregroundStyle(isFlipped ? .yellow : .secondary)

                            Text(isFlipped ? "Đáp án" : "Câu hỏi")
                                .font(.app(.caption))
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            SmartCopyDefineText(
                                text: isFlipped ? flashcard.answer : flashcard.questionDisplayTextWithPhonetic,
                                flashcards: topic.flashcards
                            )
                            .scaledFont(.display)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .environmentObject(fontSizeManager)

                            if isFlipped, let radical = radicalText, !radical.isEmpty {
                                Text("Bộ thủ: \(radical)")
                                    .font(.app(.subheadline))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(30)
                    }
                    .frame(minHeight: 220)
                    .padding(.horizontal, 24)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.2)) {
                            isFlipped.toggle()
                        }
                    }

                    if !isFlipped {
                        Text("Nhấn vào thẻ để xem đáp án")
                            .font(.app(.caption))
                            .foregroundStyle(.secondary)
                    }

                    // Action buttons (show after flip)
                    if isFlipped {
                        HStack(spacing: 20) {
                            Button(action: { markCard(known: false) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.app(.title2))
                                    Text("Chưa thuộc")
                                        .font(.app(.title3))
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
                            .buttonStyle(ScaleButtonStyle())
                            .cursor(.pointingHand)

                            Button(action: { markCard(known: true) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.app(.title2))
                                    Text("Đã thuộc")
                                        .font(.app(.title3))
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
                            .buttonStyle(ScaleButtonStyle())
                            .cursor(.pointingHand)
                        }
                        .padding(.horizontal, 24)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: 20)
                }
            }
        }
    }

    private func markCard(known: Bool) {
        let flashcard = flashcards[currentIndex]
        if known {
            knownCount += 1
            SoundManager.shared.playCorrectWithHaptic()
        } else {
            unknownCards.append(flashcard)
            DatabaseManager.shared.recordMistake(
                flashcardId: flashcard.id,
                practiceType: "Thẻ lật",
                topicId: topicId
            )
            SoundManager.shared.playIncorrectWithHaptic()
        }

        var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ??
            FlashcardProgress(flashcardId: flashcard.id)
        let quality: Double = known ? 1.0 : 0.0
        progress = srsAlgorithm.calculateNextReview(progress: progress, quality: quality)
        DatabaseManager.shared.saveFlashcardProgress(progress)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentIndex += 1
            isFlipped = false
        }

        if currentIndex >= flashcards.count {
            onComplete(knownCount, flashcards.count)
        }
    }
}
