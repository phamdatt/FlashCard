//
//  ReviewModeView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

struct ReviewModeView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var dueFlashcards: [Flashcard] = []
    @State private var currentIndex: Int = 0
    @State private var showAnswer: Bool = false
    @State private var quality: Double? = nil // 0.0 = wrong, 0.5 = hard, 1.0 = correct
    @State private var completedCount: Int = 0
    @State private var correctCount: Int = 0
    @State private var showCompletion: Bool = false
    @State private var srsAlgorithm = SRSAlgorithm()
    
    var body: some View {
        VStack(spacing: 0) {
            if dueFlashcards.isEmpty {
                ContentUnavailableView(
                    "Không có từ cần ôn",
                    systemImage: "checkmark.circle.fill",
                    description: Text("Tất cả các từ đã được ôn đầy đủ!")
                )
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
        }
    }
    
    private var reviewCardView: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Ôn tập")
                    .scaledFont(24)
                    .fontWeight(.bold)
                Spacer()
                Text("\(currentIndex + 1)/\(dueFlashcards.count)")
                    .scaledFont(16)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            ProgressView(value: Double(currentIndex), total: Double(dueFlashcards.count))
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Flashcard
            let flashcard = dueFlashcards[currentIndex]
            VStack(spacing: 20) {
                // Question side
                VStack(spacing: 16) {
                    Text(flashcard.question)
                        .scaledFont(32)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    if showAnswer {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text(flashcard.answer)
                            .scaledFont(28)
                            .foregroundStyle(.blue)
                            .multilineTextAlignment(.center)
                            .padding()
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 40)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showAnswer.toggle()
                    }
                }
                
                if showAnswer {
                    // Quality buttons
                    HStack(spacing: 16) {
                        Button(action: { submitQuality(0.0) }) {
                            VStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .scaledFont(32)
                                Text("Sai")
                                    .scaledFont(14)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: { submitQuality(0.5) }) {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .scaledFont(32)
                                Text("Khó")
                                    .scaledFont(14)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: { submitQuality(1.0) }) {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .scaledFont(32)
                                Text("Đúng")
                                    .scaledFont(14)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Text("Nhấn để xem đáp án")
                        .scaledFont(14)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            }
            
            Spacer()
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .scaledFont(60)
                .foregroundStyle(.green)
                .symbolEffect(.bounce, options: .repeat(3))
            
            Text("Hoàn thành ôn tập!")
                .scaledFont(28)
                .fontWeight(.bold)
            
            Text("Đã ôn \(completedCount) từ")
                .scaledFont(18)
                .foregroundStyle(.secondary)
            
            if completedCount > 0 {
                let accuracy = Int((Double(correctCount) / Double(completedCount)) * 100)
                VStack(spacing: 8) {
                    Text("\(accuracy)%")
                        .scaledFont(36)
                        .fontWeight(.heavy)
                        .foregroundStyle(accuracy >= 70 ? .green : .orange)
                    Text("Độ chính xác")
                        .scaledFont(14)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: 200)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
            }
            
            Button(action: {
                loadDueFlashcards()
                showCompletion = false
                currentIndex = 0
                completedCount = 0
                correctCount = 0
            }) {
                Label("Ôn tiếp", systemImage: "arrow.clockwise")
                    .scaledFont(16)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func loadDueFlashcards() {
        let dueIds = DatabaseManager.shared.getDueFlashcards()
        var flashcards: [Flashcard] = []
        
        // Load flashcards from all subjects
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
        withAnimation(.spring()) {
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
