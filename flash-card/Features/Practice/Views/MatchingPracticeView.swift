//
//  MatchingPracticeView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

struct MatchingPracticeView: View {
    let flashcards: [Flashcard]
    let topicId: Int
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var srsAlgorithm = SRSAlgorithm()

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
                        .font(.app(.headline))
                    Spacer()
                    HStack(spacing: 8) {
Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                        Text("\(matchedPairs.count)/\(currentBatch.count)")
                            .font(.app(.subheadline))
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
                    .font(.app(.subheadline))
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
                            .font(.app(.headline))
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
                            .font(.app(.headline))
                            .foregroundStyle(.secondary)
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
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    selectedQuestion = flashcard.id
                }
            }
        }) {
            SmartCopyDefineText(text: flashcard.question, flashcards: flashcards)
                .scaledFont(14)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 60)
                .environmentObject(fontSizeManager)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(questionBackground(isMatched: isMatched, isSelected: isSelected, isWrong: isWrong))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(questionBorder(isMatched: isMatched, isSelected: isSelected, isWrong: isWrong), lineWidth: isSelected ? 3 : 2)
                )
                // Sử dụng opacity thay vì scale để tránh tràn
                .opacity(isMatched ? 0.5 : (isWrong ? 0.7 : 1.0))
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isWrong)
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
            SmartCopyDefineText(text: answer, flashcards: flashcards)
                .scaledFont(14)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 60)
                .environmentObject(fontSizeManager)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(answerBackground(isMatched: isMatched, isWrong: isWrong))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(answerBorder(isMatched: isMatched, isWrong: isWrong), lineWidth: isMatched ? 3 : 2)
                )
                // Sử dụng opacity và shadow thay vì scale để tránh tràn
                .shadow(color: isMatched ? .green.opacity(0.3) : (isWrong ? .red.opacity(0.2) : .clear), radius: isMatched ? 8 : (isWrong ? 4 : 0))
                .opacity(isMatched ? 0.6 : (isWrong ? 0.7 : 1.0))
        }
        .buttonStyle(.plain)
        .disabled(isMatched || selectedQuestion == nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isMatched)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isWrong)
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
        let isCorrect = flashcard.answer == selectedAnswer

        if isCorrect {
            totalCorrect += 1
            // Improved animation với spring effect mượt mà hơn
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)) {
                matchedPairs.insert(questionId)
                selectedQuestion = nil
            }
            SoundManager.shared.playCorrectWithHaptic()
            
            // Update SRS progress
            updateSRSProgress(flashcard: flashcard, isCorrect: true)
            
            // Check if batch is complete
            if matchedPairs.count == currentBatch.count {
                SoundManager.shared.playSuccessWithHaptic()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        batchIndex += 1
                        loadBatch()
                    }
                }
            }
        } else {
            // Wrong match với animation rõ ràng hơn
            SoundManager.shared.playIncorrectWithHaptic()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                wrongPair = (questionId, selectedAnswer)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    wrongPair = nil
                    selectedQuestion = nil
                }
            }
            
            // Update SRS progress and record mistake
            updateSRSProgress(flashcard: flashcard, isCorrect: false)
            DatabaseManager.shared.recordMistake(
                flashcardId: flashcard.id,
                practiceType: "Matching",
                topicId: topicId
            )
        }

        onComplete(totalCorrect, totalAttempts)
    }
    
    private func updateSRSProgress(flashcard: Flashcard, isCorrect: Bool) {
        var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ?? 
            FlashcardProgress(flashcardId: flashcard.id)
        
        let quality: Double = isCorrect ? 1.0 : 0.0
        progress = srsAlgorithm.calculateNextReview(progress: progress, quality: quality)
        DatabaseManager.shared.saveFlashcardProgress(progress)
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
