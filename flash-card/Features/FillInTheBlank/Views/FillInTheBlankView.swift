//
//  FillInTheBlankView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

struct FillInTheBlankView: View {
    let flashcards: [Flashcard]
    let topicId: Int
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    @State private var userAnswer: String = ""
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    @State private var showCompletion: Bool = false
    @State private var srsAlgorithm = SRSAlgorithm()
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Không có flashcard",
                systemImage: "rectangle.on.rectangle.slash",
                description: Text("Chủ đề này chưa có flashcard để luyện tập")
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
        let questionWithBlank = createQuestionWithBlank(flashcard: flashcard)
        
        return VStack(spacing: 24) {
            // Progress
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

            Spacer()

            // Question with blank
            VStack(spacing: 20) {
                Text("Điền từ vào chỗ trống:")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)

                // Display question with blank
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(questionWithBlank.components(separatedBy: "\n"), id: \.self) { line in
                        if !line.isEmpty {
                            Text(line)
                                .scaledFont(.display)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .environmentObject(fontSizeManager)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appBackgroundControl(isLight: colorScheme == .light))
                .cornerRadius(16)
                .padding(.horizontal, 40)

                // Answer input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Đáp án của bạn:")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                    
                    TextField("Nhập đáp án...", text: $userAnswer)
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
                            if !showResult && !userAnswer.isEmpty {
                                checkAnswer()
                            }
                        }
                }
                .padding(.horizontal, 40)

                // Result feedback
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
                                Text("Đáp án đúng:")
                                    .font(.app(.subheadline))
                                    .foregroundStyle(.secondary)
                                Text(flashcard.answer)
                                    .font(.app(.body))
                                    .foregroundStyle(.blue)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()

            // Action buttons
            if !showResult {
                Button(action: {
                    checkAnswer()
                }) {
                    Label("Kiểm tra", systemImage: "checkmark.circle.fill")
                        .font(.app(.headline))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(userAnswer.isEmpty ? Color.gray : Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .cursor(.pointingHand)
                .disabled(userAnswer.isEmpty)
                .keyboardShortcut(.return, modifiers: [])
                .padding(.horizontal, 40)
            } else {
                Button(action: {
                    nextCard()
                }) {
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
            }
        }
        .padding(.vertical, 20)
        .onAppear {
            isTextFieldFocused = true
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

    private func createQuestionWithBlank(flashcard: Flashcard) -> String {
        // Replace answer with blank (display 汉字 only)
        let answer = flashcard.answer
        let question = flashcard.questionDisplayText
        
        // Try to find answer in question and replace with blank
        if let range = question.range(of: answer, options: .caseInsensitive) {
            return question.replacingCharacters(in: range, with: "______")
        }
        
        // If answer not found in question, append blank at the end
        return question + " ______"
    }

    private func checkAnswer() {
        guard !userAnswer.isEmpty else { return }
        
        let flashcard = flashcards[currentIndex]
        let userAnswerTrimmed = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correctAnswer = flashcard.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Check if answer is correct (exact match or contains)
        isCorrect = userAnswerTrimmed == correctAnswer || 
                   userAnswerTrimmed.contains(correctAnswer) || 
                   correctAnswer.contains(userAnswerTrimmed)
        
        totalAnswered += 1
        if isCorrect {
            score += 1
        }
        
        // Update SRS
        updateSRSProgress(flashcard: flashcard, isCorrect: isCorrect)
        
        // Record mistake if wrong
        if !isCorrect {
            DatabaseManager.shared.recordMistake(
                flashcardId: flashcard.id,
                practiceType: "Fill in the Blank",
                topicId: topicId
            )
        }
        
        // Play sound
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
            userAnswer = ""
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
