//
//  SimilarLookingPracticeView.swift
//  flash-card
//
//  Mode "Từ dễ nhầm": chọn Hán tự đúng theo nghĩa, các đáp án sai là từ có hình dáng tương tự.
//

import SwiftUI

struct SimilarLookingPracticeView: View {
    let flashcards: [Flashcard]
    let topic: Topic
    let topicId: Int
    let subjectName: String
    var subjectIcon: String? = nil
    var radicalForCharacter: ((String) -> String?)?
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    @State private var srsAlgorithm = SRSAlgorithm()

    /// Flashcard hiển thị cho câu hiện tại (question = nghĩa, options = 4 Hán tự, 1 đúng + 3 dễ nhầm).
    private var displayFlashcard: Flashcard? {
        guard currentIndex < flashcards.count else { return nil }
        return buildDisplayFlashcard(for: flashcards[currentIndex], pool: flashcards)
    }

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Chưa có từ dễ nhầm",
                systemImage: "eye.trianglebadge.exclamationmark",
                description: Text("Thêm từ có chữ giống nhau (vd 未/末, 己/已, 日/目…) để luyện mode này")
            )
        } else if let card = displayFlashcard, currentIndex < flashcards.count {
            questionView(displayCard: card, actualFlashcard: flashcards[currentIndex])
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

    private func questionView(displayCard: Flashcard, actualFlashcard: Flashcard) -> some View {
        let radicalText: String? = {
            guard subjectName == "Tiếng Trung" else { return nil }
            if let r = actualFlashcard.radical, !r.isEmpty { return r }
            return radicalForCharacter?(actualFlashcard.questionDisplayText)
        }()

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Câu \(currentIndex + 1)/\(flashcards.count)")
                        .font(.app(.headline))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Từ dễ nhầm")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(colorScheme == .light ? 0.14 : 0.2))
                        .cornerRadius(6)
                }
                ProgressView(value: Double(currentIndex), total: Double(max(flashcards.count, 1)))
                    .scaleEffect(y: 1.8, anchor: .center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            FlashcardDetailView(
                flashcard: displayCard,
                topic: topic,
                subjectName: subjectName,
                subjectIcon: subjectIcon,
                radicalText: radicalText,
                onEdit: nil,
                onAnswered: { isCorrect in
                    handleAnswer(isCorrect: isCorrect, actualFlashcard: actualFlashcard)
                },
                onContinueToNext: {
                    withAnimation {
                        currentIndex += 1
                    }
                }
            )
            .id(actualFlashcard.id)
        }
    }

    private func handleAnswer(isCorrect: Bool, actualFlashcard: Flashcard) {
        totalAnswered += 1
        if isCorrect { score += 1 }

        if currentIndex < flashcards.count {
            var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: actualFlashcard.id)
                ?? FlashcardProgress(flashcardId: actualFlashcard.id)
            let quality: Double = isCorrect ? 1.0 : 0.0
            progress = srsAlgorithm.calculateNextReview(progress: progress, quality: quality)
            DatabaseManager.shared.saveFlashcardProgress(progress)

            if !isCorrect {
                DatabaseManager.shared.recordMistake(
                    flashcardId: actualFlashcard.id,
                    practiceType: "Từ dễ nhầm",
                    topicId: topicId
                )
            }
        }

        onComplete(score, totalAnswered)
    }

    /// Tạo flashcard để hiển thị: câu hỏi = nghĩa, 4 đáp án = Hán tự (1 đúng + 3 dễ nhầm hoặc random).
    private func buildDisplayFlashcard(for card: Flashcard, pool: [Flashcard]) -> Flashcard {
        let correctHanzi = card.questionDisplayText
        let groups = SimilarLookingData.groupsOverlapping(with: correctHanzi)

        // Ưu tiên từ cùng nhóm dễ nhầm, còn thiếu thì lấy random.
        let sameGroupCandidates = pool.map(\.questionDisplayText)
            .filter { SimilarLookingData.isInSameGroupAs(candidate: $0, groups: groups, excludeText: correctHanzi) }
        let otherCandidates = pool.map(\.questionDisplayText)
            .filter { $0 != correctHanzi && !sameGroupCandidates.contains($0) }
            .shuffled()

        var wrongOptions: [String] = []
        wrongOptions.append(contentsOf: sameGroupCandidates.shuffled().prefix(3))
        if wrongOptions.count < 3 {
            wrongOptions.append(contentsOf: otherCandidates.prefix(3 - wrongOptions.count))
        }
        wrongOptions = Array(wrongOptions.prefix(3))

        var allChoices = wrongOptions + [correctHanzi]
        allChoices.shuffle()

        let labels = ["A", "B", "C", "D"]
        var options: [String] = []
        var correctLabel = "A"
        for (i, hanzi) in allChoices.prefix(4).enumerated() {
            options.append("\(labels[i]). \(hanzi)")
            if hanzi == correctHanzi { correctLabel = labels[i] }
        }

        return Flashcard(
            id: card.id,
            question: card.answer,
            answer: correctHanzi,
            hint: card.hint,
            options: options,
            correctAnswer: correctLabel,
            exerciseType: "Từ dễ nhầm",
            notes: card.notes,
            radical: card.radical,
            phonetic: card.phonetic
        )
    }
}
