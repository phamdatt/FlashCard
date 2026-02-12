//
//  WordOfDayPracticeFlowView.swift
//  flash-card
//
//  Từ của ngày: luyện theo step — Lật thẻ → Trắc nghiệm → Nối từ → Nghĩa→Hán tự (Tiếng Trung).
//

import SwiftUI

private struct StepItem: Identifiable {
    let id: Int
    let index: Int
    let step: WordOfDayStep
    let isActive: Bool
    let isDone: Bool
    init(index: Int, step: WordOfDayStep, currentStepIndex: Int) {
        self.id = index
        self.index = index
        self.step = step
        self.isActive = index == currentStepIndex
        self.isDone = index < currentStepIndex
    }
}

/// Bước trong flow từ của ngày.
private enum WordOfDayStep: Int, CaseIterable {
    case flipCard = 0
    case multipleChoice = 1
    case matching = 2
    case meaningToHanzi = 3  // Chỉ Tiếng Trung

    var title: String {
        switch self {
        case .flipCard: return "Lật thẻ"
        case .multipleChoice: return "Trắc nghiệm"
        case .matching: return "Nối từ"
        case .meaningToHanzi: return "Nghĩa → Hán tự"
        }
    }

    /// Các bước cho Tiếng Trung (có Nghĩa→Hán tự).
    static func steps(for subjectName: String?) -> [WordOfDayStep] {
        if subjectName == "Tiếng Trung" {
            return [.flipCard, .multipleChoice, .matching, .meaningToHanzi]
        }
        return [.flipCard, .multipleChoice, .matching]
    }
}

struct WordOfDayPracticeFlowView: View {
    let flashcards: [Flashcard]
    let topic: Topic
    let subjectName: String
    var subjectIcon: String? = nil
    var radicalForCharacter: ((String) -> String?)?
    let topicId: Int
    let onComplete: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var currentStepIndex: Int = 0
    @State private var lastScore: Int = 0
    @State private var lastTotal: Int = 0

    private let steps: [WordOfDayStep]
    private var currentStep: WordOfDayStep { steps[currentStepIndex] }
    private var isLastStep: Bool { currentStepIndex >= steps.count - 1 }

    private var stepItems: [StepItem] {
        steps.enumerated().map { StepItem(index: $0.offset, step: $0.element, currentStepIndex: currentStepIndex) }
    }

    init(flashcards: [Flashcard], topic: Topic, subjectName: String, subjectIcon: String? = nil,
         radicalForCharacter: ((String) -> String?)? = nil, topicId: Int, onComplete: @escaping () -> Void) {
        self.flashcards = flashcards
        self.topic = topic
        self.subjectName = subjectName
        self.subjectIcon = subjectIcon
        self.radicalForCharacter = radicalForCharacter
        self.topicId = topicId
        self.onComplete = onComplete
        self.steps = WordOfDayStep.steps(for: subjectName)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Thanh step: Bước 1/4 - Lật thẻ
            stepProgressBar
            ThemeDivider()

            // Nội dung practice theo step
            practiceContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stepProgressBar: some View {
        HStack(spacing: 8) {
            ForEach(stepItems) { item in
                stepChip(item: item)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appBackgroundControl(isLight: colorScheme == .light))
    }

    private func stepChip(item: StepItem) -> some View {
        HStack(spacing: 4) {
            if item.index > 0 {
                Image(systemName: "chevron.right")
                    .font(.app(.caption2))
                    .foregroundStyle(item.isDone ? .green : .secondary)
            }
            Text(item.step.title)
                .font(.app(.caption))
                .fontWeight(item.isActive ? .semibold : .regular)
                .foregroundStyle(item.isActive ? Color.primary : (item.isDone ? Color.green : Color.secondary))
        }
    }

    @ViewBuilder
    private var practiceContent: some View {
        let cards = flashcards
        switch currentStep {
        case .flipCard:
            FlipCardPracticeView(
                flashcards: cards,
                topic: topic,
                topicId: topicId,
                subjectName: subjectName,
                subjectIcon: subjectIcon,
                radicalForCharacter: radicalForCharacter,
                onComplete: { s, t in lastScore = s; lastTotal = t },
                onReset: advanceOrComplete
            )
        case .multipleChoice:
            MultipleChoicePracticeView(
                flashcards: cards,
                topic: topic,
                topicId: topicId,
                subjectName: subjectName,
                subjectIcon: subjectIcon,
                radicalForCharacter: radicalForCharacter,
                onComplete: { s, t in lastScore = s; lastTotal = t },
                onReset: advanceOrComplete
            )
        case .matching:
            MatchingPracticeView(
                flashcards: cards,
                topicId: topicId,
                onComplete: { s, t in lastScore = s; lastTotal = t },
                onReset: advanceOrComplete
            )
        case .meaningToHanzi:
            MeaningToHanziPracticeView(
                flashcards: cards,
                topicId: topicId,
                onComplete: { s, t in lastScore = s; lastTotal = t },
                onReset: advanceOrComplete
            )
        }
    }

    private func advanceOrComplete() {
        // Ghi practice session cho bước vừa xong
        let typeName: String
        switch currentStep {
        case .flipCard: typeName = "Thẻ lật"
        case .multipleChoice: typeName = "Trắc nghiệm"
        case .matching: typeName = "Nối cặp"
        case .meaningToHanzi: typeName = "Nghĩa → Hán tự"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        DatabaseManager.shared.recordPracticeSession(
            practiceDate: today,
            practiceType: "Từ của ngày · \(typeName)",
            topicId: topicId,
            correct: lastScore,
            total: max(lastTotal, 1)
        )

        if isLastStep {
            onComplete()
        } else {
            currentStepIndex += 1
        }
    }
}
