//
//  MatchingPracticeView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

struct MatchingPracticeView: View {
    let flashcards: [Flashcard]
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // Batch of 5 pairs at a time
    private let batchSize = 5

    @State private var batchIndex: Int = 0
    @State private var currentBatch: [Flashcard] = []
    @State private var shuffledAnswers: [String] = []
    @State private var selectedQuestion: Int? = nil // flashcard id
    @State private var matchedPairs: Set<Int> = [] // matched flashcard ids
    @State private var wrongPair: (Int, String)? = nil // (flashcard id, answer) for wrong highlight
    @State private var totalCorrect: Int = 0
    @State private var totalAttempts: Int = 0
    @State private var isCompleted: Bool = false

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Không có flashcard",
                systemImage: "rectangle.on.rectangle.slash",
                description: Text("Chủ đề này chưa có flashcard để luyện tập")
            )
        } else if isCompleted {
            completedView
        } else {
            matchingView
        }
    }

    private var matchingView: some View {
        VStack(spacing: 0) {
            // Progress header
            VStack(spacing: 8) {
                HStack {
                    Text("Nhóm \(batchIndex + 1)/\(totalBatches)")
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(matchedPairs.count)/\(currentBatch.count)")
                            .font(.subheadline)
                    }
                }
                ProgressView(value: Double(batchIndex * batchSize + matchedPairs.count),
                             total: Double(min(flashcards.count, totalBatches * batchSize)))
            }
            .padding()

            Divider()

            // Instructions
            HStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .foregroundStyle(.blue)
                Text("Chọn câu hỏi bên trái, rồi chọn đáp án đúng bên phải")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Matching grid
            ScrollView {
                HStack(alignment: .top, spacing: 20) {
                    // Questions column (left)
                    VStack(spacing: 12) {
                        Text("Câu hỏi")
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)

                        ForEach(currentBatch) { flashcard in
                            questionCard(flashcard: flashcard)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Answers column (right)
                    VStack(spacing: 12) {
                        Text("Đáp án")
                            .font(.headline)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity)

                        ForEach(shuffledAnswers, id: \.self) { answer in
                            answerCard(answer: answer)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
        .onAppear { loadBatch() }
    }

    private func questionCard(flashcard: Flashcard) -> some View {
        let isMatched = matchedPairs.contains(flashcard.id)
        let isSelected = selectedQuestion == flashcard.id
        let isWrong = wrongPair?.0 == flashcard.id

        return Button(action: {
            if !isMatched {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedQuestion = flashcard.id
                }
            }
        }) {
            Text(flashcard.question)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(questionBackground(isMatched: isMatched, isSelected: isSelected, isWrong: isWrong))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(questionBorder(isMatched: isMatched, isSelected: isSelected, isWrong: isWrong), lineWidth: 2)
                )
                .opacity(isMatched ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
    }

    private func answerCard(answer: String) -> some View {
        let matchedFlashcard = currentBatch.first(where: { $0.answer == answer && matchedPairs.contains($0.id) })
        let isMatched = matchedFlashcard != nil
        let isWrong = wrongPair?.1 == answer

        return Button(action: {
            if !isMatched, let questionId = selectedQuestion {
                checkMatch(questionId: questionId, selectedAnswer: answer)
            }
        }) {
            Text(answer)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(answerBackground(isMatched: isMatched, isWrong: isWrong))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(answerBorder(isMatched: isMatched, isWrong: isWrong), lineWidth: 2)
                )
                .opacity(isMatched ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isMatched || selectedQuestion == nil)
    }

    // MARK: - Colors

    private func questionBackground(isMatched: Bool, isSelected: Bool, isWrong: Bool) -> Color {
        let isLight = colorScheme == .light
        if isMatched { return Color.green.opacity(isLight ? 0.1 : 0.15) }
        if isWrong { return Color.red.opacity(isLight ? 0.1 : 0.15) }
        if isSelected { return Color.blue.opacity(isLight ? 0.1 : 0.15) }
        return isLight ? Color(nsColor: .controlBackgroundColor) : Color.gray.opacity(0.08)
    }

    private func questionBorder(isMatched: Bool, isSelected: Bool, isWrong: Bool) -> Color {
        if isMatched { return .green }
        if isWrong { return .red }
        if isSelected { return .blue }
        return Color.gray.opacity(colorScheme == .light ? 0.25 : 0.4)
    }

    private func answerBackground(isMatched: Bool, isWrong: Bool) -> Color {
        let isLight = colorScheme == .light
        if isMatched { return Color.green.opacity(isLight ? 0.1 : 0.15) }
        if isWrong { return Color.red.opacity(isLight ? 0.1 : 0.15) }
        return isLight ? Color(nsColor: .controlBackgroundColor) : Color.gray.opacity(0.08)
    }

    private func answerBorder(isMatched: Bool, isWrong: Bool) -> Color {
        if isMatched { return .green }
        if isWrong { return .red }
        return Color.gray.opacity(colorScheme == .light ? 0.25 : 0.4)
    }

    // MARK: - Logic

    private var totalBatches: Int {
        max(1, Int(ceil(Double(flashcards.count) / Double(batchSize))))
    }

    private func loadBatch() {
        let start = batchIndex * batchSize
        let end = min(start + batchSize, flashcards.count)
        guard start < flashcards.count else {
            isCompleted = true
            onComplete(totalCorrect, totalAttempts)
            return
        }
        currentBatch = Array(flashcards[start..<end])
        shuffledAnswers = currentBatch.map { $0.answer }.shuffled()
        matchedPairs = []
        selectedQuestion = nil
        wrongPair = nil
    }

    private func checkMatch(questionId: Int, selectedAnswer: String) {
        guard let flashcard = currentBatch.first(where: { $0.id == questionId }) else { return }

        totalAttempts += 1

        if flashcard.answer == selectedAnswer {
            totalCorrect += 1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                matchedPairs.insert(questionId)
                selectedQuestion = nil
            }
            NSSound(named: "Hero")?.play()
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)

            // Check if batch is complete
            if matchedPairs.count == currentBatch.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        batchIndex += 1
                        loadBatch()
                    }
                }
            }
        } else {
            // Wrong match
            NSSound(named: "Basso")?.play()
            withAnimation(.easeInOut(duration: 0.2)) {
                wrongPair = (questionId, selectedAnswer)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    wrongPair = nil
                    selectedQuestion = nil
                }
            }
        }

        onComplete(totalCorrect, totalAttempts)
    }

    private var completedView: some View {
        PracticeCompletedView(
            score: totalCorrect,
            totalAnswered: totalAttempts,
            onContinue: {
                batchIndex = 0
                totalCorrect = 0
                totalAttempts = 0
                isCompleted = false
                onReset()
                loadBatch()
            }
        )
    }
}
