//
//  SpeakingPracticeView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI
import AppKit

struct SpeakingPracticeView: View {
    let flashcards: [Flashcard]
    let topicId: Int
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    @State private var isRecording: Bool = false
    @State private var recognizedText: String = ""
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    @State private var showCompletion: Bool = false
    @State private var srsAlgorithm = SRSAlgorithm()

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

            // Question card
            VStack(spacing: 20) {
                Image(systemName: "mic.fill")
                    .scaledFont(.xl4)
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, isActive: isRecording)

                Text("Đọc to câu sau:")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)

                Text(flashcard.questionDisplayText)
                    .scaledFont(.display)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.appBackgroundControl(isLight: colorScheme == .light))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)

                if showResult {
                    ThemeDivider()
                        .padding(.vertical, 8)

                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.app(.title2))
                                .foregroundStyle(isCorrect ? .green : .red)
                            Text(isCorrect ? "Chính xác!" : "Chưa đúng")
                                .font(.app(.title2))
                                .fontWeight(.semibold)
                                .foregroundStyle(isCorrect ? .green : .red)
                        }

                        if !recognizedText.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bạn đã nói:")
                                    .font(.app(.subheadline))
                                    .foregroundStyle(.secondary)
                                Text(recognizedText)
                                    .font(.app(.body))
                                    .foregroundStyle(.primary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.appBackgroundControl(isLight: colorScheme == .light))
                                    .cornerRadius(8)
                            }
                        }

                        Text("Đáp án đúng: \(flashcard.answer)")
                            .font(.app(.body))
                            .foregroundStyle(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()

            // Action buttons
            if !showResult {
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .scaledFont(.xl2)
                        Text(isRecording ? "Dừng ghi âm" : "Bắt đầu ghi âm")
                            .font(.app(.headline))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .cursor(.pointingHand)
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
                .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, 20)
        .onDisappear {
            if isRecording {
                isRecording = false
            }
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

    private func startRecording() {
        isRecording = true
        recognizedText = ""
        showResult = false
        
        // Show text input dialog directly (macOS doesn't have built-in speech recognition)
        showTextInputDialog { text in
            recognizedText = text
            stopRecording()
        }
    }

    private func stopRecording() {
        isRecording = false
        
        guard !recognizedText.isEmpty else { return }
        
        // Check answer
        let flashcard = flashcards[currentIndex]
        let userAnswer = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correctAnswer = flashcard.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Simple comparison (could improve with fuzzy matching)
        isCorrect = userAnswer == correctAnswer || 
                   userAnswer.contains(correctAnswer) || 
                   correctAnswer.contains(userAnswer)
        
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
                practiceType: "Speaking",
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
        }
    }
    
    private func showTextInputDialog(completion: @escaping (String) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Nhập câu bạn đã đọc"
        alert.informativeText = "Trên macOS chưa hỗ trợ nhận diện giọng nói tự động. Bạn hãy gõ lại câu bạn vừa đọc (đáp án) để kiểm tra."
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 400, height: 24))
        input.placeholderString = "Gõ đáp án..."
        alert.accessoryView = input
        alert.addButton(withTitle: "Xác nhận")
        alert.addButton(withTitle: "Hủy")
        
        alert.window.initialFirstResponder = input
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completion(input.stringValue)
        } else {
            isRecording = false
            completion("")
        }
    }

    private func nextCard() {
        withAnimation(.spring()) {
            currentIndex += 1
            showResult = false
            recognizedText = ""
            isCorrect = false
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

