//
//  ReviewMistakesView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

struct ReviewMistakesView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var mistakeFlashcards: [Flashcard] = []
    @State private var currentIndex: Int = 0
    @State private var showAnswer: Bool = false
    @State private var isCorrect: Bool? = nil
    @State private var completedCount: Int = 0
    @State private var correctCount: Int = 0
    @State private var showCompletion: Bool = false
    @State private var daysFilter: Int = 30
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with filter
            HStack {
                Text("Ôn lại từ đã sai")
                    .scaledFont(24)
                    .fontWeight(.bold)
                Spacer()
                Menu {
                    Button("7 ngày qua") { daysFilter = 7; loadMistakeFlashcards() }
                    Button("30 ngày qua") { daysFilter = 30; loadMistakeFlashcards() }
                    Button("90 ngày qua") { daysFilter = 90; loadMistakeFlashcards() }
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("\(daysFilter) ngày")
                    }
                    .scaledFont(14)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            if mistakeFlashcards.isEmpty {
                ContentUnavailableView(
                    "Không có từ đã sai",
                    systemImage: "checkmark.circle.fill",
                    description: Text("Bạn chưa có từ nào sai trong \(daysFilter) ngày qua!")
                )
            } else if showCompletion {
                completionView
            } else if currentIndex < mistakeFlashcards.count {
                reviewCardView
            } else {
                completionView
                    .onAppear {
                        showCompletion = true
                    }
            }
        }
        .onAppear {
            loadMistakeFlashcards()
        }
    }
    
    private var reviewCardView: some View {
        VStack(spacing: 20) {
            // Progress
            HStack {
                Text("\(currentIndex + 1)/\(mistakeFlashcards.count)")
                    .scaledFont(16)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ProgressView(value: Double(currentIndex), total: Double(mistakeFlashcards.count))
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Flashcard
            let flashcard = mistakeFlashcards[currentIndex]
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
                    // Answer buttons
                    HStack(spacing: 16) {
                        Button(action: { submitAnswer(false) }) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .scaledFont(24)
                                Text("Sai")
                                    .scaledFont(16)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .cornerRadius(12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: { submitAnswer(true) }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .scaledFont(24)
                                Text("Đúng")
                                    .scaledFont(16)
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
            
            Text("Hoàn thành!")
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
                loadMistakeFlashcards()
                showCompletion = false
                currentIndex = 0
                completedCount = 0
                correctCount = 0
            }) {
                Label("Ôn lại", systemImage: "arrow.clockwise")
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
    
    private func loadMistakeFlashcards() {
        let mistakeIds = DatabaseManager.shared.getMistakeFlashcards(days: daysFilter)
        var flashcards: [Flashcard] = []
        
        // Load flashcards from all subjects
        for subject in viewModel.subjects {
            for topic in subject.topics {
                for flashcard in topic.flashcards {
                    if mistakeIds.contains(flashcard.id) {
                        flashcards.append(flashcard)
                    }
                }
            }
        }
        
        mistakeFlashcards = flashcards.shuffled()
        currentIndex = 0
        showAnswer = false
        isCorrect = nil
    }
    
    private func submitAnswer(_ correct: Bool) {
        guard currentIndex < mistakeFlashcards.count else { return }
        
        let flashcard = mistakeFlashcards[currentIndex]
        
        // Update SRS progress
        var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ?? 
            FlashcardProgress(flashcardId: flashcard.id)
        
        let quality: Double = correct ? 1.0 : 0.0
        let srsAlgorithm = SRSAlgorithm()
        progress = srsAlgorithm.calculateNextReview(progress: progress, quality: quality)
        DatabaseManager.shared.saveFlashcardProgress(progress)
        
        // Record mistake if still wrong
        if !correct {
            if let topic = findTopic(for: flashcard) {
                DatabaseManager.shared.recordMistake(
                    flashcardId: flashcard.id,
                    practiceType: "Review Mistakes",
                    topicId: topic.id
                )
            }
        }
        
        // Update counts
        completedCount += 1
        if correct {
            correctCount += 1
        }
        
        // Play sound
        if correct {
            SoundManager.shared.playCorrectWithHaptic()
        } else {
            SoundManager.shared.playIncorrectWithHaptic()
        }
        
        // Move to next card
        withAnimation(.spring()) {
            showAnswer = false
            isCorrect = nil
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
