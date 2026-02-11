//
//  MeaningToHanziPracticeView.swift
//  flash-card
//
//  Mode: câu hỏi là ý nghĩa, user nhập hán tự. Chỉ dùng cho Tiếng Trung.
//

import SwiftUI

struct MeaningToHanziPracticeView: View {
    let flashcards: [Flashcard]
    let topicId: Int
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    @State private var userHanzi: String = ""
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    @State private var showCompletion: Bool = false
    @State private var srsAlgorithm = SRSAlgorithm()
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Không có từ vựng",
                systemImage: "character.book.closed",
                description: Text("Chủ đề này chưa có từ vựng để luyện Nghĩa → Hán tự.")
            )
        } else if showCompletion {
            completionView
        } else if currentIndex < flashcards.count {
            practiceView
        } else {
            completionView
                .onAppear {
                    showCompletion = true
                }
        }
    }

    private var practiceView: some View {
        let flashcard = flashcards[currentIndex]
        let correctHanzi = flashcard.questionDisplayText
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    progressSection
                    meaningAndInputSection(flashcard: flashcard)
                    resultSection(correctHanzi: correctHanzi)
                    actionButtonsSection
                }
                .padding(.vertical, 20)
            }
            .onChange(of: showResult) { _, newValue in
                if newValue {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("resultBlock", anchor: .center)
                    }
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Câu \(currentIndex + 1)/\(flashcards.count)")
                    .font(.app(.headline))
                Spacer()
                if totalAnswered > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("\(score)/\(totalAnswered)")
                            .font(.app(.subheadline))
                    }
                }
            }
            ProgressView(value: Double(currentIndex), total: Double(flashcards.count))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private func meaningAndInputSection(flashcard: Flashcard) -> some View {
        VStack(spacing: 24) {
            Text("Ý nghĩa (viết hán tự):")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)

            Text(flashcard.answer)
                .scaledFont(.xl2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.appCardBackground(isLight: colorScheme == .light))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appBorder(isLight: colorScheme == .light), lineWidth: 1.5)
                )
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 8) {
                Text("Hán tự của bạn:")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
                TextField("Ví dụ: 你好", text: $userHanzi)
                    .scaledFont(.xl2)
                    .fontWeight(.medium)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.appBackgroundText(isLight: colorScheme == .light))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTextFieldFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    .focused($isTextFieldFocused)
                    .disabled(showResult)
                    .onSubmit {
                        if !showResult && !userHanzi.isEmpty { checkAnswer() }
                    }
            }
            .padding(.horizontal, 40)
        }
    }

    private func resultSection(correctHanzi: String) -> some View {
        Group {
            if showResult {
                VStack(spacing: 12) {
                    HStack {
                        if isCorrect {
                            GreenCheckmarkView(size: 28)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .font(.app(.title2))
                                .foregroundStyle(.red)
                        }
                        Text(isCorrect ? "Chính xác! 🎉" : "Chưa đúng")
                            .font(.app(.title2))
                            .fontWeight(.semibold)
                            .foregroundStyle(isCorrect ? .green : .red)
                    }
                    if !isCorrect {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hán tự đúng:")
                                .font(.app(.subheadline))
                                .foregroundStyle(.secondary)
                            Text(correctHanzi)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.blue)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(colorScheme == .light ? Color.green.opacity(0.06) : Color.green.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCorrect ? Color.green.opacity(0.4) : Color.red.opacity(0.4), lineWidth: 2)
                )
                .id("resultBlock")
            }
        }
        .padding(.horizontal, 40)
        .animation(.easeInOut(duration: 0.25), value: showResult)
    }

    @ViewBuilder
    private var actionButtonsSection: some View {
        if showResult {
            Button(action: { nextCard() }) {
                Label("Tiếp theo", systemImage: "arrow.right.circle.fill")
                    .font(.app(.headline))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            .cursor(.pointingHand)
            .keyboardShortcut(.return, modifiers: [])
            .padding(.horizontal, 40)
            .padding(.top, 8)
        } else {
            Button(action: { checkAnswer() }) {
                Label("Kiểm tra", systemImage: "checkmark.circle.fill")
                    .font(.app(.headline))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(userHanzi.isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            .cursor(.pointingHand)
            .disabled(userHanzi.isEmpty)
            .keyboardShortcut(.return, modifiers: [])
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
    }

    private var completionView: some View {
        PracticeCompletedView(
            score: score,
            totalAnswered: totalAnswered,
            onContinue: {
                showCompletion = false
                currentIndex = 0
                score = 0
                totalAnswered = 0
                onReset()
            }
        )
        .onAppear {
            onComplete(score, totalAnswered)
        }
    }

    private func normalizeHanzi(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func checkAnswer() {
        guard !userHanzi.isEmpty else { return }

        let flashcard = flashcards[currentIndex]
        let correctHanzi = flashcard.questionDisplayText
        let userNorm = normalizeHanzi(userHanzi)
        let correctNorm = normalizeHanzi(correctHanzi)
        isCorrect = userNorm == correctNorm

        totalAnswered += 1
        if isCorrect {
            score += 1
        }

        updateSRSProgress(flashcard: flashcard, isCorrect: isCorrect)
        if !isCorrect {
            DatabaseManager.shared.recordMistake(
                flashcardId: flashcard.id,
                practiceType: "Meaning to Hanzi",
                topicId: topicId
            )
        }

        if isCorrect {
            SoundManager.shared.playCorrectWithHaptic()
        } else {
            SoundManager.shared.playIncorrectWithHaptic()
        }

        withAnimation(.spring()) {
            showResult = true
            isTextFieldFocused = false
        }
    }

    private func nextCard() {
        withAnimation(.spring()) {
            currentIndex += 1
            userHanzi = ""
            showResult = false
            isCorrect = false
            isTextFieldFocused = true
        }
    }

    private func updateSRSProgress(flashcard: Flashcard, isCorrect: Bool) {
        var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ??
            FlashcardProgress(flashcardId: flashcard.id)
        let quality: Double = isCorrect ? 1.0 : 0.0
        progress = srsAlgorithm.calculateNextReview(progress: progress, quality: quality)
        DatabaseManager.shared.saveFlashcardProgress(progress)
    }
}
