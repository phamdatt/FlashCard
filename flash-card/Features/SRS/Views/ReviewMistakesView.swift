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
                    subjectId: section.subjectId,
                    subjectName: section.subjectName,
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
                .scaledFont(.xl)
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
                        .scaledFont(.sm)
                        .foregroundStyle(.secondary)
                    Text("\(daysFilter) ngày")
                        .scaledFont(.sm)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.down")
                        .scaledFont(.xs)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.appBorder(isLight: colorScheme == .light), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
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
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .scaledFont(.hero)
                    .foregroundStyle(.secondary)
                    .symbolEffect(.pulse)
            }
            VStack(spacing: 10) {
                Text("Không có từ đã sai")
                    .scaledFont(.xl2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(String(format: "Bạn chưa có từ nào sai trong %d ngày qua!", daysFilter))
                    .scaledFont(.sm)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
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
            let subject = viewModel.subjects.first(where: { $0.id == data.topic.subjectId })
            return MistakeSection(
                topicId: topicId,
                topicName: data.topic.name,
                subjectId: data.topic.subjectId,
                subjectName: subject?.name ?? "",
                flashcards: data.flashcards.shuffled()
            )
        }.sorted { $0.topicName < $1.topicName }
    }
}

// MARK: - Custom: Summary Card
private struct MistakeSummaryCard: View {
    let totalWords: Int
    let totalTopics: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "text.book.closed.fill")
                        .scaledFont(.xl2)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tổng số từ cần ôn")
                        .scaledFont(.sm)
                        .foregroundStyle(.secondary)
                    Text("\(totalWords)")
                        .scaledFont(.xl2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appDivider(isLight: colorScheme == .light), lineWidth: 1)
                    )
            )

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "folder.fill")
                        .scaledFont(.xl)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Số chủ đề")
                        .scaledFont(.sm)
                        .foregroundStyle(.secondary)
                    Text("\(totalTopics)")
                        .scaledFont(.xl2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appDivider(isLight: colorScheme == .light), lineWidth: 1)
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
                        .scaledFont(.xl)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.topicName)
                        .scaledFont(.sm)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(section.flashcards.count) từ cần ôn")
                        .scaledFont(.sm)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .scaledFont(.sm)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appBackgroundControl(isLight: isLight))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isHovering ? Color.appBorder(isLight: isLight).opacity(0.8) : Color.appBorder(isLight: isLight).opacity(0.5),
                                lineWidth: isHovering ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovering)
    }
}

// MARK: - Mistake Section Model
struct MistakeSection: Identifiable {
    let id: Int
    let topicId: Int
    let topicName: String
    let subjectId: Int
    let subjectName: String
    let flashcards: [Flashcard]

    init(topicId: Int, topicName: String, subjectId: Int, subjectName: String, flashcards: [Flashcard]) {
        self.id = topicId
        self.topicId = topicId
        self.topicName = topicName
        self.subjectId = subjectId
        self.subjectName = subjectName
        self.flashcards = flashcards
    }
}

// MARK: - Flashcard Review View (multiple choice UI, same as practice)
struct FlashcardReviewView: View {
    let flashcards: [Flashcard]
    let sectionName: String
    let topicId: Int
    let subjectId: Int
    let subjectName: String
    let viewModel: ContentViewModel
    let onBack: () -> Void

    @State private var flashcardsWithOptions: [Flashcard] = []
    @State private var currentIndex: Int = 0
    @State private var completedCount: Int = 0
    @State private var correctCount: Int = 0
    @State private var showCompletion: Bool = false
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme

    private var topic: Topic {
        Topic(id: topicId, name: sectionName, subjectId: subjectId, flashcards: flashcardsWithOptions, readings: [])
    }

    var body: some View {
        VStack(spacing: 0) {
            reviewHeaderView
            if showCompletion || currentIndex >= flashcardsWithOptions.count {
                reviewCompletionView
            } else {
                multipleChoiceReviewView
            }
        }
        .onAppear {
            if flashcardsWithOptions.isEmpty {
                flashcardsWithOptions = flashcards.count >= 4
                    ? DatabaseManager.makeFlashcardsWithOptions(flashcards)
                    : flashcards
            }
        }
    }

    private var reviewHeaderView: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .scaledFont(.sm)
                    Text("Quay lại")
                        .scaledFont(.sm)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.appBackgroundControl(isLight: colorScheme == .light)))
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)

            Spacer()
            Text(sectionName)
                .scaledFont(.sm)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .scaledFont(.sm)
                    .foregroundStyle(.secondary)
                Text("\(min(currentIndex + 1, flashcardsWithOptions.count)) / \(flashcardsWithOptions.count)")
                    .scaledFont(.sm)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(colorScheme == .light ? 0.08 : 0.12)))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
    }

    private var multipleChoiceReviewView: some View {
        VStack(spacing: 0) {
            if currentIndex < flashcardsWithOptions.count {
                let flashcard = flashcardsWithOptions[currentIndex]
                VStack(spacing: 8) {
                    HStack {
                        Text("Câu \(currentIndex + 1)/\(flashcardsWithOptions.count)")
                            .font(.app(.headline))
                        Spacer()
                        Text(Flashcard.exerciseTypeLabel)
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(colorScheme == .light ? 0.14 : 0.2))
                            .cornerRadius(6)
                    }
                    ProgressView(value: Double(currentIndex), total: Double(max(flashcardsWithOptions.count, 1)))
                }
                .padding()

                FlashcardDetailView(
                    flashcard: flashcard,
                    topic: topic,
                    subjectName: subjectName,
                    subjectIcon: viewModel.subjects.first(where: { $0.name == subjectName })?.displayIcon,
                    radicalText: subjectName == "Tiếng Trung" ? (flashcard.radical.flatMap { $0.isEmpty ? nil : $0 } ?? viewModel.radicalForCharacter(flashcard.questionDisplayText)) : nil,
                    onEdit: nil,
                    onAnswered: { isCorrect in recordAnswer(isCorrect) },
                    onContinueToNext: {
                        withAnimation {
                            currentIndex += 1
                            if currentIndex >= flashcardsWithOptions.count {
                                showCompletion = true
                            }
                        }
                    }
                )
                .id(flashcard.id)
            }
        }
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
                    .scaledFont(.hero)
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce)
            }
            VStack(spacing: 10) {
                Text("Hoàn thành ôn tập!")
                    .scaledFont(.xl3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(String(format: "Đã ôn %d từ", completedCount))
                    .scaledFont(.sm)
                    .foregroundStyle(.secondary)
            }
            if completedCount > 0 {
                VStack(spacing: 8) {
                    Text("\(accuracy)%")
                        .scaledFont(.xl5)
                        .fontWeight(.bold)
                        .foregroundStyle(accuracy >= 70 ? .green : .orange)
                    Text("Độ chính xác")
                        .scaledFont(.sm)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)
            }
            Button(action: onBack) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .scaledFont(.xl2)
                    Text("Quay lại danh sách")
                        .scaledFont(.lg)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: 280)
                .padding(.vertical, 16)
                .background(Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            .cursor(.pointingHand)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
    }

    private func recordAnswer(_ isCorrect: Bool) {
        guard currentIndex < flashcardsWithOptions.count else { return }
        let flashcard = flashcardsWithOptions[currentIndex]
        var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ?? FlashcardProgress(flashcardId: flashcard.id)
        let quality: Double = isCorrect ? 1.0 : 0.0
        progress = SRSAlgorithm().calculateNextReview(progress: progress, quality: quality)
        DatabaseManager.shared.saveFlashcardProgress(progress)
        if !isCorrect {
            DatabaseManager.shared.recordMistake(flashcardId: flashcard.id, practiceType: "Review Mistakes", topicId: topicId)
        }
        completedCount += 1
        if isCorrect { correctCount += 1 }
        if isCorrect { SoundManager.shared.playCorrectWithHaptic() } else { SoundManager.shared.playIncorrectWithHaptic() }
    }
}
