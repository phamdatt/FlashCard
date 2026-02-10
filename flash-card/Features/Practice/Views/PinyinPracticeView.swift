//
//  PinyinPracticeView.swift
//  flash-card
//
//  Fill-in-pinyin mode: show 汉字, user types pinyin. Uses cột phonetic (hoặc pinyin trong question) để kiểm tra.
//

import SwiftUI

struct PinyinPracticeView: View {
    let flashcards: [Flashcard]
    let topicId: Int
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    @State private var userPinyin: String = ""
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    @State private var showCompletion: Bool = false
    @State private var srsAlgorithm = SRSAlgorithm()
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Không có từ có pinyin",
                systemImage: "character.bubble",
                description: Text("Chủ đề này chưa có từ vựng Tiếng Trung có pinyin (cột Phiên âm hoặc dạng \"汉字 (pinyin)\") để luyện điền pinyin.")
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
        let correctPinyin = flashcard.displayPhonetic ?? ""
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    pinyinProgressSection
                    pinyinCharacterAndInputSection(flashcard: flashcard)
                    pinyinResultSection(correctPinyin: correctPinyin)
                    pinyinActionButtonsSection
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

    private var pinyinProgressSection: some View {
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

    private func pinyinCharacterAndInputSection(flashcard: Flashcard) -> some View {
        VStack(spacing: 24) {
            Text("Điền pinyin cho chữ Hán:")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)

            Text(flashcard.questionDisplayText)
                .scaledFont(.display)
                .fontWeight(.bold)
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
                Text("Pinyin của bạn:")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
                TextField("Ví dụ: nǐ hǎo", text: $userPinyin)
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
                        if !showResult && !userPinyin.isEmpty { checkAnswer() }
                    }
            }
            .padding(.horizontal, 40)
        }
    }

    private func pinyinResultSection(correctPinyin: String) -> some View {
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
                            Text("Pinyin đúng:")
                                .font(.app(.subheadline))
                                .foregroundStyle(.secondary)
                            Text(correctPinyin)
                                .font(.app(.body))
                                .foregroundStyle(.blue)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
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
    private var pinyinActionButtonsSection: some View {
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
                    .background(userPinyin.isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            .cursor(.pointingHand)
            .disabled(userPinyin.isEmpty)
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
    }

    private func normalizeForPinyinComparison(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let collapsed = trimmed.split(separator: " ").joined(separator: " ")
        return collapsed.folding(options: .diacriticInsensitive, locale: .current)
    }

    private func checkAnswer() {
        guard !userPinyin.isEmpty else { return }

        let flashcard = flashcards[currentIndex]
        guard let correctPinyin = flashcard.displayPhonetic, !correctPinyin.isEmpty else { return }

        let userNorm = normalizeForPinyinComparison(userPinyin)
        let correctNorm = normalizeForPinyinComparison(correctPinyin)
        isCorrect = userNorm == correctNorm || userNorm.contains(correctNorm) || correctNorm.contains(userNorm)

        totalAnswered += 1
        if isCorrect {
            score += 1
        }

        updateSRSProgress(flashcard: flashcard, isCorrect: isCorrect)
        if !isCorrect {
            DatabaseManager.shared.recordMistake(
                flashcardId: flashcard.id,
                practiceType: "Fill in Pinyin",
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
            userPinyin = ""
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
