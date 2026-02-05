//
//  TrueFalsePracticeView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

struct TrueFalsePracticeView: View {
    let flashcards: [Flashcard]
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    @State private var showResult: Bool = false
    @State private var userAnsweredTrue: Bool = false
    @State private var currentIsTrue: Bool = true
    @State private var displayedAnswer: String = ""

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Không có flashcard",
                systemImage: "rectangle.on.rectangle.slash",
                description: Text("Chủ đề này chưa có flashcard để luyện tập")
            )
        } else if currentIndex < flashcards.count {
            cardView
                .id(currentIndex)
        } else {
            completedView
        }
    }

    private var cardView: some View {
        let flashcard = flashcards[currentIndex]

        return VStack(spacing: 0) {
            // Progress
            VStack(spacing: 8) {
                HStack {
                    Text("Câu \(currentIndex + 1)/\(flashcards.count)")
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(score)/\(totalAnswered)")
                            .font(.subheadline)
                    }
                }
                ProgressView(value: Double(currentIndex), total: Double(flashcards.count))
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 20)

                    // Question
                    VStack(spacing: 12) {
                        Text("Câu hỏi")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Text(flashcard.question)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(colorScheme == .light ? 0.05 : 0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(colorScheme == .light ? 0.3 : 0.6), lineWidth: 2)
                    )
                    .padding(.horizontal, 24)

                    // Arrow
                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    // Displayed answer (may be correct or wrong)
                    VStack(spacing: 12) {
                        Text("Đáp án")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Text(displayedAnswer)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(answerCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(answerCardBorder, lineWidth: 2)
                    )
                    .padding(.horizontal, 24)

                    // True/False buttons
                    if !showResult {
                        HStack(spacing: 20) {
                            // TRUE button
                            Button(action: { answerTapped(true) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                    Text("Đúng")
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

                            // FALSE button
                            Button(action: { answerTapped(false) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                    Text("Sai")
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
                        }
                        .padding(.horizontal, 24)
                    }

                    // Result feedback
                    if showResult {
                        resultFeedback(flashcard: flashcard)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: 20)
                }
            }
        }
        .onAppear { setupQuestion() }
    }

    private var answerCardBackground: Color {
        let isLight = colorScheme == .light
        if !showResult {
            return Color.orange.opacity(isLight ? 0.05 : 0.1)
        }
        if currentIsTrue {
            return Color.green.opacity(isLight ? 0.08 : 0.12)
        }
        return Color.red.opacity(isLight ? 0.08 : 0.12)
    }

    private var answerCardBorder: Color {
        if !showResult {
            return Color.orange.opacity(colorScheme == .light ? 0.3 : 0.6)
        }
        return currentIsTrue ? .green : .red
    }

    private func resultFeedback(flashcard: Flashcard) -> some View {
        let userCorrect = (userAnsweredTrue == currentIsTrue)

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: userCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(userCorrect ? .green : .red)
                    .symbolEffect(.bounce, value: showResult)

                VStack(alignment: .leading, spacing: 4) {
                    Text(userCorrect ? "Chính xác!" : "Chưa đúng")
                        .font(.headline)
                        .foregroundStyle(userCorrect ? .green : .red)

                    if !currentIsTrue {
                        Text("Đáp án đúng: \(flashcard.answer)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(userCorrect
                          ? Color.green.opacity(colorScheme == .light ? 0.08 : 0.1)
                          : Color.red.opacity(colorScheme == .light ? 0.08 : 0.1))
            )
        }
        .padding(.horizontal, 24)
    }

    private var completedView: some View {
        PracticeCompletedView(
            score: score,
            totalAnswered: totalAnswered,
            onContinue: {
                currentIndex = 0
                score = 0
                totalAnswered = 0
                showResult = false
                onReset()
            }
        )
    }

    // MARK: - Logic

    private func setupQuestion() {
        guard currentIndex < flashcards.count else { return }
        let flashcard = flashcards[currentIndex]

        currentIsTrue = Bool.random()

        if currentIsTrue {
            displayedAnswer = flashcard.answer
        } else {
            let otherAnswers = flashcards.filter { $0.id != flashcard.id }.map { $0.answer }
            displayedAnswer = otherAnswers.randomElement() ?? flashcard.answer
            if displayedAnswer == flashcard.answer {
                currentIsTrue = true
            }
        }
    }

    private func answerTapped(_ userSaidTrue: Bool) {
        userAnsweredTrue = userSaidTrue
        let isCorrect = (userSaidTrue == currentIsTrue)
        totalAnswered += 1
        if isCorrect { score += 1 }

        NSSound(named: isCorrect ? "Hero" : "Basso")?.play()
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showResult = true
        }

        onComplete(score, totalAnswered)

        // Auto advance
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                currentIndex += 1
                showResult = false
                setupQuestion()
            }
        }
    }
}
