//
//  TrueFalsePracticeView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI
import AppKit

struct TrueFalsePracticeView: View {
    let flashcards: [Flashcard]
    let topicId: Int
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var currentIndex: Int = 0
    @State private var srsAlgorithm = SRSAlgorithm()
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
        let progress = Double(currentIndex) / Double(max(flashcards.count, 1))

        return VStack(spacing: 0) {
            // Clean Header
            VStack(spacing: 0) {
                HStack {
                    Text("Câu \(currentIndex + 1) / \(flashcards.count)")
                        .scaledFont(.sm)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if totalAnswered > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .scaledFont(.sm)
                                .foregroundStyle(.secondary)
                            Text("\(score)/\(totalAnswered)")
                                .scaledFont(.sm)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 4)
                            .animation(.easeOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .background(Color(nsColor: .controlBackgroundColor))

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                    
                    // Question Card - Premium Design
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .scaledFont(.xl)
                                .foregroundStyle(.secondary)
                            Text("Câu hỏi")
                                .scaledFont(.sm)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                        
                        SmartCopyDefineText(text: flashcard.questionDisplayText, flashcards: flashcards)
                            .scaledFont(.xl3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .frame(maxWidth: 600)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .light ? Color.appCardBackground(isLight: true) : Color(nsColor: .textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.appBorder(isLight: colorScheme == .light), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 32)
                    
                    // Arrow with animation
                    Image(systemName: "arrow.down")
                        .scaledFont(.xl2)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 20)
                        .symbolEffect(.pulse, options: .repeat(2))
                    
                    // Answer Card - Premium Design
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "text.bubble.fill")
                                .scaledFont(.xl)
                                .foregroundStyle(answerCardIconColor)
                            Text("Đáp án")
                                .scaledFont(.sm)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                        
                        SmartCopyDefineText(text: displayedAnswer, flashcards: flashcards)
                            .scaledFont(.xl3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .frame(maxWidth: 600)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(answerCardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(answerCardBorder, lineWidth: 2.5)
                            )
                    )
                    .shadow(color: answerCardShadowColor, radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 32)
                    
                    // True/False Buttons - Premium Design
                    if !showResult {
                        VStack(spacing: 16) {
                            Text("Đánh giá")
                                .scaledFont(.sm)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.top, 32)
                            
                            HStack(spacing: 16) {
                                // TRUE button
                                trueFalseButton(
                                    isTrue: true,
                                    icon: "checkmark.circle.fill",
                                    label: "Đúng",
                                    color: .green,
                                    action: { answerTapped(true) }
                                )
                                
                                // FALSE button
                                trueFalseButton(
                                    isTrue: false,
                                    icon: "xmark.circle.fill",
                                    label: "Sai",
                                    color: .red,
                                    action: { answerTapped(false) }
                                )
                            }
                            .padding(.horizontal, 32)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Result feedback
                    if showResult {
                        resultFeedback(flashcard: flashcard)
                            .padding(.horizontal, 32)
                            .padding(.top, 24)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: 60)
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .onAppear { setupQuestion() }
    }
    
    // MARK: - True/False Button - Modern Design
    @ViewBuilder
    private func trueFalseButton(
        isTrue: Bool,
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .scaledFont(.xl2)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                
                Text(label)
                    .scaledFont(.lg)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(ModernPressButtonStyle(color: color))
    }
    
    // MARK: - Modern Press Button Style
    struct ModernPressButtonStyle: ButtonStyle {
        let color: Color
        @State private var isPressed = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .offset(y: isPressed ? 3 : 0)
                .shadow(
                    color: isPressed ? color.opacity(0.15) : color.opacity(0.25),
                    radius: isPressed ? 4 : 8,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
                .onChange(of: configuration.isPressed) { _, newValue in
                    isPressed = newValue
                }
        }
    }

    private var answerCardBackground: Color {
        let isLight = colorScheme == .light
        if !showResult {
            return Color.orange.opacity(isLight ? 0.05 : 0.08)
        }
        if currentIsTrue {
            return Color.green.opacity(isLight ? 0.1 : 0.12)
        }
        return Color.orange.opacity(isLight ? 0.1 : 0.12)
    }

    private var answerCardBorder: Color {
        if !showResult {
            return Color.orange.opacity(0.3)
        }
        return currentIsTrue ? .green : .orange
    }
    
    private var answerCardIconColor: Color {
        if !showResult {
            return .orange
        }
        return currentIsTrue ? .green : .orange
    }
    
    private var answerCardShadowColor: Color {
        if !showResult {
            return .orange.opacity(0.1)
        }
        return currentIsTrue ? .green.opacity(0.1) : .orange.opacity(0.1)
    }

    private func resultFeedback(flashcard: Flashcard) -> some View {
        let userCorrect = (userAnsweredTrue == currentIsTrue)

        return VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(userCorrect ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: userCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .scaledFont(.xl3)
                        .foregroundStyle(userCorrect ? .green : .orange)
                        .symbolEffect(.bounce.up, value: showResult)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(userCorrect ? "Chính xác! 🎉" : "Chưa đúng")
                        .scaledFont(.xl)
                        .fontWeight(.bold)
                        .foregroundStyle(userCorrect ? .green : .orange)

                    if !currentIsTrue {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Đáp án đúng:")
                                .scaledFont(.sm)
                                .foregroundStyle(.secondary)
                            SmartCopyDefineText(text: flashcard.answer, flashcards: flashcards)
                                .scaledFont(.sm)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(userCorrect
                          ? Color.green.opacity(colorScheme == .light ? 0.1 : 0.12)
                          : Color.orange.opacity(colorScheme == .light ? 0.1 : 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(userCorrect ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 2)
                    )
            )
        }
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
        
        // Update SRS progress
        let flashcard = flashcards[currentIndex]
        updateSRSProgress(flashcard: flashcard, isCorrect: isCorrect)
        
        // Record mistake if wrong
        if !isCorrect {
            DatabaseManager.shared.recordMistake(
                flashcardId: flashcard.id,
                practiceType: "True/False",
                topicId: topicId
            )
        }

        if isCorrect {
            SoundManager.shared.playCorrectWithHaptic()
        } else {
            SoundManager.shared.playIncorrectWithHaptic()
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.2)) {
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
    
    private func updateSRSProgress(flashcard: Flashcard, isCorrect: Bool) {
        var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ?? 
            FlashcardProgress(flashcardId: flashcard.id)
        
        let quality: Double = isCorrect ? 1.0 : 0.0
        progress = srsAlgorithm.calculateNextReview(progress: progress, quality: quality)
        DatabaseManager.shared.saveFlashcardProgress(progress)
    }
}
