//
//  FlashcardMainView.swift
//  learn-macos
//
//  Created by Dat Pham on 31/1/26.
//

import SwiftUI

// Combined Flashcard List and Detail View with Practice Mode
struct FlashcardMainView: View {
    @ObservedObject var viewModel: ContentViewModel
    let topic: Topic
    @State private var practiceMode: Bool = false
    @State private var shuffledFlashcards: [Flashcard] = []
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode Toggle and Stats
            HStack {
                // Mode switch
                Picker("Chế độ", selection: $practiceMode) {
                    Text("Danh sách").tag(false)
                    Text("Luyện tập").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
                
                // Stats in practice mode
                if practiceMode && totalAnswered > 0 {
                    HStack(spacing: 16) {
                        Label("\(score)/\(totalAnswered)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        
                        let percentage = totalAnswered > 0 ? Int((Double(score) / Double(totalAnswered)) * 100) : 0
                        Text("\(percentage)%")
                            .font(.headline)
                            .foregroundStyle(percentage >= 70 ? .green : .orange)
                    }
                    .padding(.horizontal)
                }
                
                // Reset button in practice mode
                if practiceMode {
                    Button(action: resetPractice) {
                        Label("Làm lại", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Content based on mode
            if practiceMode {
                practiceView
            } else {
                listView
            }
        }
        .onChange(of: practiceMode) { _, newValue in
            if newValue {
                startPractice()
            }
        }
    }
    
    // List mode view
    private var listView: some View {
        HSplitView {
            List(topic.flashcards, selection: $viewModel.selectedFlashcard) { flashcard in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(flashcard.exerciseType.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                    
                    Text(flashcard.question)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let hint = flashcard.hint {
                        Text("💡 \(hint)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(flashcard)
                .padding(.vertical, 4)
            }
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            .listStyle(.sidebar)
            
            if let flashcard = viewModel.selectedFlashcard {
                FlashcardDetailView(flashcard: flashcard, topic: topic, onAnswered: nil)
            } else {
                ContentUnavailableView(
                    "Chọn một flashcard",
                    systemImage: "rectangle.portrait.on.rectangle.portrait",
                    description: Text("Chọn một flashcard để xem chi tiết")
                )
            }
        }
    }
    
    // Practice mode view
    private var practiceView: some View {
        VStack {
            if currentIndex < shuffledFlashcards.count {
                let flashcard = shuffledFlashcards[currentIndex]
                
                // Progress indicator
                VStack(spacing: 8) {
                    HStack {
                        Text("Câu \(currentIndex + 1)/\(shuffledFlashcards.count)")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(flashcard.exerciseType.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(6)
                    }
                    
                    ProgressView(value: Double(currentIndex), total: Double(shuffledFlashcards.count))
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                
                // Flashcard with auto-advance - use id to force view recreation
                FlashcardDetailView(
                    flashcard: flashcard,
                    topic: topic,
                    onAnswered: { isCorrect in
                        handleAnswer(isCorrect: isCorrect)
                    }
                )
                .id(flashcard.id) // This ensures a new view for each flashcard
            } else {
                // Practice completed
                practiceCompletedView
            }
        }
    }
    
    private var practiceCompletedView: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Hoàn thành!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Text("Kết quả của bạn:")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 40) {
                    VStack {
                        Text("\(score)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.green)
                        Text("Đúng")
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Text("\(totalAnswered - score)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.red)
                        Text("Sai")
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        let percentage = totalAnswered > 0 ? Int((Double(score) / Double(totalAnswered)) * 100) : 0
                        Text("\(percentage)%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(percentage >= 70 ? .green : .orange)
                        Text("Tỷ lệ")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Button(action: resetPractice) {
                Label("Làm lại", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 300)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func startPractice() {
        shuffledFlashcards = topic.flashcards.shuffled()
        currentIndex = 0
        score = 0
        totalAnswered = 0
    }
    
    private func resetPractice() {
        startPractice()
    }
    
    private func handleAnswer(isCorrect: Bool) {
        totalAnswered += 1
        if isCorrect {
            score += 1
        }
        
        // Auto advance after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                currentIndex += 1
            }
        }
    }
}
