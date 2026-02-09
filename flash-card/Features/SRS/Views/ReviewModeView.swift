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
    @State private var dueTopicIds: [Int] = []

    var body: some View {
        VStack(spacing: 0) {
            if dueFlashcards.isEmpty {
                emptyStateView
            } else {
                FlashcardReviewView(
                    flashcards: dueFlashcards,
                    sectionName: "Cần ôn hôm nay",
                    topicId: 0,
                    subjectId: 0,
                    subjectName: "",
                    topicIds: dueTopicIds.isEmpty ? nil : dueTopicIds,
                    viewModel: viewModel,
                    onBack: { viewModel.switchToLearningMode() },
                    practiceType: "Review"
                )
            }
        }
        .onAppear { loadDueFlashcards() }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .scaledFont(.hero)
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)
            
            VStack(spacing: 8) {
                Text("Không có từ cần ôn")
                    .scaledFont(.xl2)
                    .fontWeight(.semibold)
                
                Text("Tất cả các từ đã được ôn đầy đủ!")
                    .scaledFont(.sm)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
    }
    
    // MARK: - Functions
    private func loadDueFlashcards() {
        let dueIds = DatabaseManager.shared.getDueFlashcards()
        var flashcards: [Flashcard] = []
        var topicIds: [Int] = []

        for subject in viewModel.subjects {
            for topic in subject.topics {
                for flashcard in topic.flashcards {
                    if dueIds.contains(flashcard.id) {
                        flashcards.append(flashcard)
                        topicIds.append(topic.id)
                    }
                }
            }
        }

        let pairs = Array(zip(flashcards, topicIds)).shuffled()
        dueFlashcards = pairs.map(\.0)
        dueTopicIds = pairs.map(\.1)
    }
}
