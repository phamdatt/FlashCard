//
//  MultipleChoicePracticeView.swift
//  flash-card
//
//  Trắc nghiệm: hiển thị từng câu với 4 đáp án, chấm đúng/sai, bấm Tiếp tục sang câu tiếp.
//

import SwiftUI

struct MultipleChoicePracticeView: View {
    let flashcards: [Flashcard]
    let topic: Topic
    let topicId: Int
    let subjectName: String
    var subjectIcon: String? = nil
    /// Chỉ dùng khi subject là Tiếng Trung: lấy bộ thủ cho ký tự (questionDisplayText).
    var radicalForCharacter: ((String) -> String?)?
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    @State private var srsAlgorithm = SRSAlgorithm()

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Không có flashcard",
                systemImage: "rectangle.on.rectangle.slash",
                description: Text("Chủ đề này chưa có flashcard để luyện tập")
            )
        } else if currentIndex < flashcards.count {
            questionView
        } else {
            PracticeCompletedView(
                score: score,
                totalAnswered: totalAnswered,
                onContinue: {
                    withAnimation {
                        currentIndex = 0
                        score = 0
                        totalAnswered = 0
                    }
                    onReset()
                }
            )
        }
    }

    private var questionView: some View {
        let flashcard = flashcards[currentIndex]
        let radicalText: String? = {
            guard subjectName == "Tiếng Trung" else { return nil }
            if let r = flashcard.radical, !r.isEmpty { return r }
            return radicalForCharacter?(flashcard.questionDisplayText)
        }()

        return VStack {
            VStack(spacing: 8) {
                HStack {
                    Text("Câu \(currentIndex + 1)/\(flashcards.count)")
                        .font(.app(.headline))
                    Spacer()
                    Text(Flashcard.exerciseTypeLabel)
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(colorScheme == .light ? 0.14 : 0.2))
                        .cornerRadius(6)
                }
                ProgressView(value: Double(currentIndex), total: Double(flashcards.count))
            }
            .padding()

            FlashcardDetailView(
                flashcard: flashcard,
                topic: topic,
                subjectName: subjectName,
                subjectIcon: subjectIcon,
                radicalText: radicalText,
                onEdit: nil,
                onAnswered: { isCorrect in
                    handleAnswer(isCorrect: isCorrect)
                },
                onContinueToNext: {
                    withAnimation {
                        currentIndex += 1
                    }
                }
            )
            .id(flashcard.id)
        }
    }

    private func handleAnswer(isCorrect: Bool) {
        totalAnswered += 1
        if isCorrect {
            score += 1
        }

        if currentIndex < flashcards.count {
            let flashcard = flashcards[currentIndex]
            var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ??
                FlashcardProgress(flashcardId: flashcard.id)
            let quality: Double = isCorrect ? 1.0 : 0.0
            progress = srsAlgorithm.calculateNextReview(progress: progress, quality: quality)
            DatabaseManager.shared.saveFlashcardProgress(progress)

            if !isCorrect {
                DatabaseManager.shared.recordMistake(
                    flashcardId: flashcard.id,
                    practiceType: "Multiple Choice",
                    topicId: topicId
                )
            }
        }

        onComplete(score, totalAnswered)
    }
}
