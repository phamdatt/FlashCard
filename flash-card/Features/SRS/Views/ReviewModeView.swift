//
//  ReviewModeView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI
import AppKit

struct ReviewModeView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var dueFlashcards: [Flashcard] = []
    @State private var currentIndex: Int = 0
    @State private var showAnswer: Bool = false
    @State private var quality: Double? = nil
    @State private var completedCount: Int = 0
    @State private var correctCount: Int = 0
    @State private var showCompletion: Bool = false
    @State private var srsAlgorithm = SRSAlgorithm()
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if dueFlashcards.isEmpty {
                emptyStateView
            } else if showCompletion {
                completionView
            } else if currentIndex < dueFlashcards.count {
                reviewCardView
            } else {
                completionView
                    .onAppear {
                        showCompletion = true
                    }
            }
        }
        .onAppear {
            loadDueFlashcards()
            isFocused = true
        }
        .onKeyPress(.space) {
            if showAnswer {
                return .ignored
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                showAnswer = true
            }
            return .handled
        }
        .onKeyPress(.return) {
            if !showAnswer {
                return .ignored
            }
            // Auto submit correct if Return pressed
            submitQuality(1.0)
            return .handled
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .scaledFont(64)
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)
            
            VStack(spacing: 8) {
                Text("review.no_cards".localized)
                    .scaledFont(24)
                    .fontWeight(.semibold)
                
                Text("review.all_reviewed".localized)
                    .scaledFont(16)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .light ? Color.appCardBackground(isLight: true) : Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Review Card View
    private var reviewCardView: some View {
        let flashcard = dueFlashcards[currentIndex]
        let progress = Double(currentIndex) / Double(max(dueFlashcards.count, 1))
        
        return VStack(spacing: 0) {
            // Clean Header
            VStack(spacing: 0) {
                HStack {
                    Text("review.title".localized)
                        .scaledFont(20)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(dueFlashcards.count)")
                        .scaledFont(14)
                        .foregroundStyle(.secondary)
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
                            .fill(Color.green)
                            .frame(width: geometry.size.width * progress, height: 4)
                            .animation(.easeOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            
            // Main Content
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                    
                    // Flashcard Card
                    VStack(spacing: 0) {
                        // Question Section
                        VStack(spacing: 20) {
                            Text(flashcard.question)
                                .scaledFont(32)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: 600)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 32)
                        
                        // Answer Section
                        if showAnswer {
                            VStack(spacing: 20) {
                                Divider()
                                    .padding(.vertical, 24)
                                
                                Text(flashcard.answer)
                                    .scaledFont(28)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(6)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: 600)
                            }
                            .padding(.horizontal, 40)
                            .padding(.bottom, 48)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, 24)
                    
                    // Action Hint
                    if !showAnswer {
                        HStack(spacing: 6) {
                            Image(systemName: "space")
                                .scaledFont(12)
                            Text("Nhấn Space để xem đáp án")
                                .scaledFont(13)
                        }
                        .foregroundStyle(.tertiary)
                        .padding(.top, 24)
                        .transition(.opacity)
                    }
                    
                    // Quality Buttons
                    if showAnswer {
                        VStack(spacing: 16) {
                            Text("Đánh giá")
                                .scaledFont(13)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                                .padding(.top, 32)
                            
                            HStack(spacing: 12) {
                                qualityButton(
                                    quality: 0.0,
                                    icon: "xmark",
                                    label: "review.wrong".localized,
                                    color: .red,
                                    action: { submitQuality(0.0) }
                                )
                                
                                qualityButton(
                                    quality: 0.5,
                                    icon: "minus",
                                    label: "review.hard".localized,
                                    color: .orange,
                                    action: { submitQuality(0.5) }
                                )
                                
                                qualityButton(
                                    quality: 1.0,
                                    icon: "checkmark",
                                    label: "review.correct".localized,
                                    color: .green,
                                    action: { submitQuality(1.0) }
                                )
                            }
                            .padding(.horizontal, 32)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    Spacer(minLength: 60)
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
    
    // MARK: - Quality Button
    @ViewBuilder
    private func qualityButton(
        quality: Double,
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .scaledFont(20)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                Text(label)
                    .scaledFont(13)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        let accuracy = completedCount > 0 ? Int((Double(correctCount) / Double(completedCount)) * 100) : 0
        
        return VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "checkmark.circle.fill")
                .scaledFont(64)
                .foregroundStyle(.secondary)
                .symbolEffect(.bounce)
            
            // Title
            VStack(spacing: 8) {
                Text("review.completed".localized)
                    .scaledFont(28)
                    .fontWeight(.semibold)
                
                Text(String(format: "review.reviewed_count".localized, completedCount))
                    .scaledFont(16)
                    .foregroundStyle(.secondary)
            }
            
            // Accuracy
            if completedCount > 0 {
                VStack(spacing: 12) {
                    Text("\(accuracy)%")
                        .scaledFont(48)
                        .fontWeight(.bold)
                        .foregroundStyle(accuracy >= 70 ? .green : .orange)
                    
                    Text("review.accuracy".localized)
                        .scaledFont(14)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 24)
            }
            
            // Action Button
            Button(action: {
                loadDueFlashcards()
                showCompletion = false
                currentIndex = 0
                completedCount = 0
                correctCount = 0
            }) {
                Text("review.review_more".localized)
                    .scaledFont(16)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Functions
    private func loadDueFlashcards() {
        let dueIds = DatabaseManager.shared.getDueFlashcards()
        var flashcards: [Flashcard] = []
        
        for subject in viewModel.subjects {
            for topic in subject.topics {
                for flashcard in topic.flashcards {
                    if dueIds.contains(flashcard.id) {
                        flashcards.append(flashcard)
                    }
                }
            }
        }
        
        dueFlashcards = flashcards.shuffled()
        currentIndex = 0
        showAnswer = false
        quality = nil
    }
    
    private func submitQuality(_ q: Double) {
        guard currentIndex < dueFlashcards.count else { return }
        
        let flashcard = dueFlashcards[currentIndex]
        
        // Get or create progress
        var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ?? 
            FlashcardProgress(flashcardId: flashcard.id)
        
        // Update with SRS algorithm
        progress = srsAlgorithm.calculateNextReview(progress: progress, quality: q)
        
        // Save progress
        DatabaseManager.shared.saveFlashcardProgress(progress)
        
        // Record mistake if wrong
        if q < 0.5 {
            if let topic = findTopic(for: flashcard) {
                DatabaseManager.shared.recordMistake(
                    flashcardId: flashcard.id,
                    practiceType: "Review",
                    topicId: topic.id
                )
            }
        }
        
        // Update counts
        completedCount += 1
        if q >= 0.8 {
            correctCount += 1
        }
        
        // Play sound
        if q >= 0.8 {
            SoundManager.shared.playCorrectWithHaptic()
        } else {
            SoundManager.shared.playIncorrectWithHaptic()
        }
        
        // Move to next card
        withAnimation(.easeInOut(duration: 0.2)) {
            showAnswer = false
            quality = nil
            currentIndex += 1
        }
    }
    
    private func findTopic(for flashcard: Flashcard) -> Topic? {
        for subject in viewModel.subjects {
            for topic in subject.topics {
                if topic.flashcards.contains(where: { $0.id == flashcard.id }) {
                    return topic
                }
            }
        }
        return nil
    }
}
