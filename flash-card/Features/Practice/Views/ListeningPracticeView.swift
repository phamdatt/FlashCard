//
//  ListeningPracticeView.swift
//  flash-card
//
//  Nghe → chọn nghĩa: phát âm từ, user chọn đáp án đúng trong 4 nghĩa. Luyện kỹ năng nghe.
//

import SwiftUI

struct ListeningPracticeView: View {
    let flashcards: [Flashcard]
    let topic: Topic
    let topicId: Int
    let subjectName: String
    var subjectIcon: String? = nil
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var speechManager = SpeechManager.shared
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    @State private var selectedAnswer: String? = nil
    @State private var showResult: Bool = false
    @State private var srsAlgorithm = SRSAlgorithm()
    /// Đáp án cố định cho câu hiện tại (tính 1 lần khi vào câu, tránh shuffle lại khi re-render).
    @State private var currentQuestionOptions: [(label: String, meaning: String)] = []

    private var currentFlashcard: Flashcard? {
        guard currentIndex < flashcards.count else { return nil }
        return flashcards[currentIndex]
    }

    private func computeOptions(for card: Flashcard) -> [(label: String, meaning: String)] {
        let correct = card.answer
        let others = flashcards.map(\.answer).filter { $0 != correct }.shuffled()
        let wrong = Array(others.prefix(3))
        var list = wrong + [correct]
        list.shuffle()
        let labels = ["A", "B", "C", "D"]
        return list.prefix(4).enumerated().map { (labels[$0], $1) }
    }

    private var languageForTTS: String? {
        subjectName == "Tiếng Trung" ? "zh" : "en"
    }

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Không có flashcard",
                systemImage: "speaker.slash",
                description: Text("Chủ đề này chưa có từ để luyện nghe")
            )
        } else if currentIndex < flashcards.count, let card = currentFlashcard {
            listeningQuestionView(card: card)
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

    private func listeningQuestionView(card: Flashcard) -> some View {
        let options = currentQuestionOptions
        let correctMeaning = card.answer

        return VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Câu \(currentIndex + 1)/\(flashcards.count)")
                        .font(.app(.headline))
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Nghe → chọn nghĩa")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(colorScheme == .light ? 0.14 : 0.2))
                        .cornerRadius(6)
                }
                ProgressView(value: Double(currentIndex), total: Double(max(flashcards.count, 1)))
                    .scaleEffect(y: 1.8, anchor: .center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            VStack(spacing: 24) {
                Text("Nghe và chọn nghĩa đúng")
                    .font(.app(.title3))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Button(action: {
                    speechManager.speak(text: card.questionDisplayText, language: languageForTTS)
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: speechManager.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 28))
                        Text(speechManager.isSpeaking ? "Đang phát..." : "Phát âm")
                            .font(.app(.body))
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.appBackgroundControl(isLight: colorScheme == .light))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
                .disabled(speechManager.isSpeaking)

                VStack(spacing: 12) {
                    ForEach(options, id: \.label) { opt in
                        optionButton(
                            label: opt.label,
                            meaning: opt.meaning,
                            correctMeaning: correctMeaning,
                            selected: selectedAnswer == opt.label,
                            showResult: showResult
                        ) {
                            guard !showResult else { return }
                            selectedAnswer = opt.label
                            showResult = true
                            let isCorrect = opt.meaning == correctMeaning
                            handleAnswer(isCorrect: isCorrect, card: card)
                        }
                    }
                }
                .padding(.top, 8)

                if showResult {
                    Button(action: {
                        withAnimation { currentIndex += 1 }
                        selectedAnswer = nil
                        showResult = false
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                            Text("Tiếp tục")
                                .font(.app(.body))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .cursor(.pointingHand)
                    .padding(.top, 8)
                }
            }
            .padding(24)
        }
        .onAppear {
            if currentIndex < flashcards.count {
                currentQuestionOptions = computeOptions(for: flashcards[currentIndex])
            }
        }
        .onChange(of: currentIndex) { _, newIndex in
            if newIndex < flashcards.count {
                currentQuestionOptions = computeOptions(for: flashcards[newIndex])
            } else {
                currentQuestionOptions = []
            }
        }
    }

    private func optionButton(
        label: String,
        meaning: String,
        correctMeaning: String,
        selected: Bool,
        showResult: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let isCorrect = meaning == correctMeaning
        let isWrong = selected && !isCorrect
        let bg: Color = {
            if !showResult {
                return selected ? Color.purple.opacity(colorScheme == .light ? 0.12 : 0.2) : Color.appBackgroundControl(isLight: colorScheme == .light)
            }
            if isCorrect { return Color.green.opacity(colorScheme == .light ? 0.18 : 0.2) }
            if isWrong { return Color.red.opacity(colorScheme == .light ? 0.18 : 0.2) }
            return Color.appBackgroundControl(isLight: colorScheme == .light)
        }()
        let border: Color = {
            if !showResult { return selected ? .purple : Color.appBorder(isLight: colorScheme == .light) }
            if isCorrect { return .green }
            if isWrong { return .red }
            return Color.appBorder(isLight: colorScheme == .light)
        }()

        return Button(action: action) {
            HStack(spacing: 12) {
                Text("\(label).")
                    .font(.app(.body))
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .leading)
                Text(meaning)
                    .font(.app(.body))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if showResult && isCorrect {
                    GreenCheckmarkView(size: 22)
                } else if showResult && selected && !isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(border, lineWidth: showResult && (isCorrect || isWrong) ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
    }

    private func handleAnswer(isCorrect: Bool, card: Flashcard) {
        totalAnswered += 1
        if isCorrect { score += 1 }

        var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: card.id)
            ?? FlashcardProgress(flashcardId: card.id)
        let quality: Double = isCorrect ? 1.0 : 0.0
        progress = srsAlgorithm.calculateNextReview(progress: progress, quality: quality)
        DatabaseManager.shared.saveFlashcardProgress(progress)

        if !isCorrect {
            DatabaseManager.shared.recordMistake(
                flashcardId: card.id,
                practiceType: "Nghe → chọn",
                topicId: topicId
            )
        }

        if isCorrect {
            SoundManager.shared.playCorrectWithHaptic()
        } else {
            SoundManager.shared.playIncorrectWithHaptic()
        }

        onComplete(score, totalAnswered)
    }
}
