//
//  ReviewMistakesView.swift
//  flash-card
//
//  Custom UI: summary card, section cards; icons gray; green only for correct/success actions.
//

import SwiftUI
import AppKit

struct ReviewMistakesView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var mistakeSections: [MistakeSection] = []
    @State private var selectedSection: MistakeSection? = nil
    @State private var daysFilter: Int = 30

    var body: some View {
        VStack(spacing: 0) {
            headerView
            if let section = selectedSection {
                FlashcardReviewView(
                    flashcards: section.flashcards,
                    sectionName: section.topicName,
                    topicId: section.topicId,
                    viewModel: viewModel,
                    onBack: {
                        selectedSection = nil
                        loadMistakeSections()
                    }
                )
            } else if mistakeSections.isEmpty {
                emptyStateView
            } else {
                sectionsListView
            }
        }
        .onAppear { loadMistakeSections() }
    }

    // MARK: - Header (custom)
    private var headerView: some View {
        HStack(spacing: 16) {
            Text("Ôn lại từ đã sai")
                .scaledFont(20)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer()

            Menu {
                Button("7 ngày qua") { daysFilter = 7; loadMistakeSections() }
                Button("30 ngày qua") { daysFilter = 30; loadMistakeSections() }
                Button("90 ngày qua") { daysFilter = 90; loadMistakeSections() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .scaledFont(14)
                        .foregroundStyle(.secondary)
                    Text("\(daysFilter) ngày")
                        .scaledFont(14)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.down")
                        .scaledFont(11)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Sections List (custom summary + section cards)
    private var sectionsListView: some View {
        ScrollView {
            VStack(spacing: 20) {
                MistakeSummaryCard(
                    totalWords: mistakeSections.reduce(0) { $0 + $1.flashcards.count },
                    totalTopics: mistakeSections.count
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)

                VStack(spacing: 12) {
                    ForEach(mistakeSections) { section in
                        MistakeSectionCard(
                            section: section,
                            isLight: colorScheme == .light
                        ) {
                            selectedSection = section
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .scaledFont(56)
                    .foregroundStyle(.secondary)
                    .symbolEffect(.pulse)
            }
            VStack(spacing: 10) {
                Text("Không có từ đã sai")
                    .scaledFont(24)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(String(format: "Bạn chưa có từ nào sai trong %d ngày qua!", daysFilter))
                    .scaledFont(14)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func loadMistakeSections() {
        let mistakeIds = DatabaseManager.shared.getMistakeFlashcards(days: daysFilter)
        var sectionsDict: [Int: (topic: Topic, flashcards: [Flashcard])] = [:]

        for subject in viewModel.subjects {
            for topic in subject.topics {
                let topicFlashcards = topic.flashcards.filter { mistakeIds.contains($0.id) }
                if !topicFlashcards.isEmpty {
                    sectionsDict[topic.id] = (topic, topicFlashcards)
                }
            }
        }

        mistakeSections = sectionsDict.map { (topicId, data) in
            MistakeSection(
                topicId: topicId,
                topicName: data.topic.name,
                flashcards: data.flashcards.shuffled()
            )
        }.sorted { $0.topicName < $1.topicName }
    }
}

// MARK: - Custom: Summary Card
private struct MistakeSummaryCard: View {
    let totalWords: Int
    let totalTopics: Int

    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "text.book.closed.fill")
                        .scaledFont(22)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tổng số từ cần ôn")
                        .scaledFont(13)
                        .foregroundStyle(.secondary)
                    Text("\(totalWords)")
                        .scaledFont(22)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
            )

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "folder.fill")
                        .scaledFont(20)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Số chủ đề")
                        .scaledFont(13)
                        .foregroundStyle(.secondary)
                    Text("\(totalTopics)")
                        .scaledFont(22)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Custom: Section Card (tap to open review)
private struct MistakeSectionCard: View {
    let section: MistakeSection
    let isLight: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(isLight ? 0.1 : 0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "book.fill")
                        .scaledFont(20)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.topicName)
                        .scaledFont(14)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(section.flashcards.count) từ cần ôn")
                        .scaledFont(13)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .scaledFont(14)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isHovering ? Color.gray.opacity(0.35) : Color.gray.opacity(0.12),
                                lineWidth: isHovering ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }
}

// MARK: - Mistake Section Model
struct MistakeSection: Identifiable {
    let id: Int
    let topicId: Int
    let topicName: String
    let flashcards: [Flashcard]

    init(topicId: Int, topicName: String, flashcards: [Flashcard]) {
        self.id = topicId
        self.topicId = topicId
        self.topicName = topicName
        self.flashcards = flashcards
    }
}

// MARK: - Flashcard Review View (refined)
struct FlashcardReviewView: View {
    let flashcards: [Flashcard]
    let sectionName: String
    let topicId: Int
    let viewModel: ContentViewModel
    let onBack: () -> Void

    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var completedCount: Int = 0
    @State private var correctCount: Int = 0
    @State private var showCompletion: Bool = false
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            reviewHeaderView
            if showCompletion {
                reviewCompletionView
            } else if currentIndex < flashcards.count {
                reviewFlashcardView
            } else {
                reviewCompletionView
                    .onAppear { showCompletion = true }
            }
        }
        .onKeyPress(.space) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isFlipped.toggle() }
            return .handled
        }
    }

    private var reviewHeaderView: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .scaledFont(14)
                    Text("Quay lại")
                        .scaledFont(14)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }
            .buttonStyle(.plain)

            Spacer()
            Text(sectionName)
                .scaledFont(14)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .scaledFont(14)
                    .foregroundStyle(.secondary)
                Text("\(currentIndex + 1) / \(flashcards.count)")
                    .scaledFont(14)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(colorScheme == .light ? 0.08 : 0.12))
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var reviewFlashcardView: some View {
        let flashcard = flashcards[currentIndex]
        let progress = Double(currentIndex) / Double(max(flashcards.count, 1))

        return VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 5)
                    Capsule()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: max(0, geometry.size.width * progress), height: 5)
                        .animation(.easeOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 24)
            .padding(.top, 16)

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                    reviewCard(flashcard: flashcard)
                    Spacer(minLength: 100)
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private func reviewCard(flashcard: Flashcard) -> some View {
        VStack(spacing: 24) {
            ZStack {
                if isFlipped {
                    answerSide(flashcard: flashcard)
                } else {
                    questionSide(flashcard: flashcard)
                }
            }
            .frame(minHeight: 260)
            .padding(.horizontal, 32)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isFlipped.toggle() }
            }

            if !isFlipped {
                HStack(spacing: 6) {
                    Image(systemName: "space")
                        .scaledFont(12)
                    Text("Nhấn Space hoặc chạm để lật thẻ")
                        .scaledFont(13)
                }
                .foregroundStyle(.secondary)
            }

            if isFlipped {
                VStack(spacing: 16) {
                    Text("Bạn đã nhớ chưa?")
                        .scaledFont(12)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    HStack(spacing: 16) {
                        reviewActionButton(
                            icon: "xmark",
                            label: "Sai",
                            color: .orange,
                            action: { submitAnswer(false) }
                        )
                        reviewActionButton(
                            icon: "checkmark",
                            label: "Đúng",
                            color: .green,
                            action: { submitAnswer(true) }
                        )
                    }
                    .padding(.horizontal, 24)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func questionSide(flashcard: Flashcard) -> some View {
        VStack(spacing: 16) {
            Text(flashcard.question)
                .scaledFont(28)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .foregroundStyle(.primary)
                .frame(maxWidth: 560)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 44)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1.5)
                )
        )
    }

    private func answerSide(flashcard: Flashcard) -> some View {
        VStack(spacing: 16) {
            Text(flashcard.answer)
                .scaledFont(28)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .foregroundStyle(.primary)
                .frame(maxWidth: 560)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 44)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.35), lineWidth: 1.5)
                )
        )
    }

    private func reviewActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon == "checkmark" ? "checkmark.circle.fill" : icon)
                    .scaledFont(22)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(color.opacity(0.12)))
                Text(label)
                    .scaledFont(13)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(color.opacity(0.25), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var reviewCompletionView: some View {
        let accuracy = completedCount > 0 ? Int((Double(correctCount) / Double(completedCount)) * 100) : 0

        return VStack(spacing: 36) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .scaledFont(64)
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce)
            }
            VStack(spacing: 10) {
                Text("Hoàn thành ôn tập!")
                    .scaledFont(26)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(String(format: "Đã ôn %d từ", completedCount))
                    .scaledFont(14)
                    .foregroundStyle(.secondary)
            }
            if completedCount > 0 {
                VStack(spacing: 8) {
                    Text("\(accuracy)%")
                        .scaledFont(44)
                        .fontWeight(.bold)
                        .foregroundStyle(accuracy >= 70 ? .green : .orange)
                    Text("Độ chính xác")
                        .scaledFont(14)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)
            }
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .scaledFont(14)
                        .foregroundStyle(.white)
                    Text("Quay lại danh sách")
                        .scaledFont(14)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .frame(width: 220)
                .padding(.vertical, 14)
                .background(Color.green)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func submitAnswer(_ correct: Bool) {
        guard currentIndex < flashcards.count else { return }
        let flashcard = flashcards[currentIndex]

        var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ?? FlashcardProgress(flashcardId: flashcard.id)
        let quality: Double = correct ? 1.0 : 0.0
        progress = SRSAlgorithm().calculateNextReview(progress: progress, quality: quality)
        DatabaseManager.shared.saveFlashcardProgress(progress)

        if !correct, let topic = findTopic(for: flashcard) {
            DatabaseManager.shared.recordMistake(flashcardId: flashcard.id, practiceType: "Review Mistakes", topicId: topic.id)
        }

        completedCount += 1
        if correct { correctCount += 1 }
        if correct { SoundManager.shared.playCorrectWithHaptic() } else { SoundManager.shared.playIncorrectWithHaptic() }

        withAnimation(.easeInOut(duration: 0.2)) {
            isFlipped = false
            currentIndex += 1
        }
    }

    private func findTopic(for flashcard: Flashcard) -> Topic? {
        for subject in viewModel.subjects {
            for topic in subject.topics where topic.id == topicId {
                if topic.flashcards.contains(where: { $0.id == flashcard.id }) { return topic }
            }
        }
        return nil
    }
}
