//
//  FlashcardDetailView.swift
//  flash-card
//
//  Chi tiết một thẻ từ: flip card, trắc nghiệm, hộp gợi ý, CoreButtonStyle.
//

import SwiftUI

// MARK: - Hint Expandable Box
struct HintExpandableBox: View {
    @Binding var expanded: Bool
    let fromGoc: String
    let hint: String
    let flashcards: [Flashcard]
    var radicalText: String? = nil
    var notesText: String? = nil
    var compact: Bool = false
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isLight = colorScheme == .light
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
        }) {
            VStack(alignment: .leading, spacing: expanded ? 12 : 0) {
                if expanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Từ gốc")
                            .font(.app(.subheadline))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        SmartCopyDefineText(text: fromGoc, flashcards: flashcards)
                            .font(.app(.callout))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .environmentObject(fontSizeManager)
                        if let radical = radicalText, !radical.isEmpty {
                            Text("Bộ thủ")
                                .font(.app(.subheadline))
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(radical)
                                .font(.app(.callout))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if !hint.isEmpty {
                            Text("Gợi ý")
                                .font(.app(.subheadline))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.hintYellow(isLight: isLight))
                            SmartCopyDefineText(text: hint, flashcards: flashcards)
                                .font(.app(.callout))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .environmentObject(fontSizeManager)
                        }
                        if let notes = notesText, !notes.isEmpty {
                            Text("Ghi chú")
                                .font(.app(.subheadline))
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            SmartCopyDefineText(text: notes, flashcards: flashcards)
                                .font(.app(.callout))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .environmentObject(fontSizeManager)
                        }
                    }
                    .padding()
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.app(.title2))
                            .foregroundStyle(.white)
                        Text("Gợi ý")
                            .font(.app(.headline))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCardBackground(isLight: isLight))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.appBorderStrong(isLight: isLight), lineWidth: 1.5)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
    }
}

private struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 400
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Flashcard Detail View
struct FlashcardDetailView: View {
    let flashcard: Flashcard
    let topic: Topic
    let subjectName: String
    var subjectIcon: String? = nil
    var radicalText: String? = nil
    var onEdit: (() -> Void)? = nil
    let onAnswered: ((Bool) -> Void)?
    var onContinueToNext: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var isFlipped = false
    @State private var selectedAnswer: String? = nil
    @State private var showResult = false
    @State private var nextReviewDateString: String? = nil
    @State private var hintExpanded = true
    @State private var contentWidth: CGFloat = 400

    private var isPracticeMode: Bool { onAnswered != nil }

    private static var nextReviewFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM"
        f.locale = Locale(identifier: "vi_VN")
        return f
    }()

    var body: some View {
        let spacing: CGFloat = isPracticeMode ? 16 : 30
        let inner = VStack(spacing: spacing) {
            HStack {
                Image(systemName: subjectIcon ?? "book.fill")
                    .font(.app(isPracticeMode ? .title3 : .title))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: isPracticeMode ? 2 : 4) {
                    Text(subjectName)
                        .font(.app(isPracticeMode ? .subheadline : .headline))
                        .foregroundStyle(.secondary)
                    Text(topic.name)
                        .font(.app(isPracticeMode ? .headline : .title2))
                        .fontWeight(.semibold)
                    if let dateStr = nextReviewDateString, !isPracticeMode {
                        Text("Ôn lại vào: \(dateStr)")
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if onEdit != nil {
                    Button(action: { onEdit?() }) {
                        Label("Sửa từ vựng", systemImage: "pencil")
                            .font(.app(.subheadline))
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .cursor(.pointingHand)
                    .tint(.primary)
                    .controlSize(.regular)
                }
            }
            if !isPracticeMode { ThemeDivider() }
            if flashcard.isMultipleChoice {
                multipleChoiceView
            } else {
                traditionalFlashcardView
            }
            if !isPracticeMode { Spacer() }
        }
        .padding(EdgeInsets(top: 16, leading: isPracticeMode ? 20 : 16, bottom: 16, trailing: isPracticeMode ? 20 : 16))
        .background(GeometryReader { g in Color.clear.preference(key: WidthPreferenceKey.self, value: g.size.width) })
        .onPreferenceChange(WidthPreferenceKey.self) { contentWidth = $0 }

        ScrollView {
            inner
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(minWidth: 280)
        .onAppear {
            if let progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id), progress.totalReviews > 0 {
                nextReviewDateString = Self.nextReviewFormatter.string(from: progress.nextReviewDate)
            } else {
                nextReviewDateString = nil
            }
        }
    }

    private var traditionalFlashcardView: some View {
        let isLight = colorScheme == .light
        return VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground(isLight: isLight))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appBorderStrong(isLight: isLight), lineWidth: 2)
                    )

                VStack(spacing: 16) {
                    HStack {
                        Text(isFlipped ? "Đáp án" : "Câu hỏi")
                            .font(.app(.body))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        SpeakButton(text: isFlipped ? flashcard.answer : flashcard.question, fontSize: 18)
                    }

                    SmartCopyDefineText(text: isFlipped ? flashcard.answer : flashcard.questionDisplayTextWithPhonetic, flashcards: topic.flashcards)
                        .scaledFont(.xl3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                        .environmentObject(fontSizeManager)
                }
                .padding()
            }
            .frame(minHeight: 250)
            .padding()

            if (flashcard.hint != nil && !(flashcard.hint?.isEmpty ?? true)) || (radicalText != nil && !(radicalText?.isEmpty ?? true)) || (flashcard.notes != nil && !(flashcard.notes?.isEmpty ?? true)) {
                HintExpandableBox(expanded: $hintExpanded, fromGoc: flashcard.question, hint: flashcard.hint ?? "", flashcards: topic.flashcards, radicalText: radicalText, notesText: flashcard.notes)
            }

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isFlipped.toggle()
                }
            }) {
                Label(isFlipped ? "Xem câu hỏi" : "Xem đáp án", systemImage: "arrow.triangle.2.circlepath")
                    .font(.app(.headline))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
            .padding(.horizontal)
            .accessibilityHint(isFlipped ? "Lật thẻ để xem lại câu hỏi" : "Lật thẻ để xem đáp án")

            if isFlipped, let onNext = onContinueToNext {
                Button(action: onNext) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .scaledFont(.xl2)
                        Text("Tiếp tục")
                            .scaledFont(.lg)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .cursor(.pointingHand)
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }

    private var multipleChoiceView: some View {
        let isCompact = contentWidth < 420 || isPracticeMode
        let cardPadding: CGFloat = isCompact ? 12 : 16
        let questionFont: Font.TailwindSize = isCompact ? .xl3 : .display
        let optionPadding: CGFloat = isCompact ? 12 : 16
        let spacing: CGFloat = isCompact ? 12 : 25

        return VStack(spacing: spacing) {
            VStack(spacing: isCompact ? 10 : 16) {
                HStack(alignment: .center) {
                    Text("Câu hỏi")
                        .scaledFont(isCompact ? .lg : .xl)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    SpeakButton(text: flashcard.question, fontSize: isCompact ? 18 : 24)
                        .frame(width: isCompact ? 28 : 32, height: isCompact ? 28 : 32, alignment: .trailing)
                        .contentShape(Rectangle())
                }

                SmartCopyDefineText(text: flashcard.questionDisplayTextWithPhonetic, flashcards: topic.flashcards)
                    .scaledFont(questionFont)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.65)
                    .lineLimit(3)
                    .padding(.horizontal, 8)
                    .padding(.vertical, isCompact ? 8 : 12)
                    .environmentObject(fontSizeManager)
            }
            .padding(cardPadding)
            .frame(maxWidth: .infinity)
            .background(Color.appCardBackground(isLight: colorScheme == .light))
            .overlay(
                RoundedRectangle(cornerRadius: isCompact ? 12 : 16)
                    .stroke(Color.appBorderStrong(isLight: colorScheme == .light), lineWidth: 2)
            )
            .cornerRadius(isCompact ? 12 : 16)

            if ((flashcard.hint != nil && !(flashcard.hint?.isEmpty ?? true)) || (radicalText != nil && !(radicalText?.isEmpty ?? true)) || (flashcard.notes != nil && !(flashcard.notes?.isEmpty ?? true))) && !showResult {
                HintExpandableBox(expanded: $hintExpanded, fromGoc: flashcard.question, hint: flashcard.hint ?? "", flashcards: topic.flashcards, radicalText: radicalText, notesText: flashcard.notes, compact: true)
            }

            VStack(spacing: isCompact ? 10 : 16) {
                ForEach(flashcard.options ?? [], id: \.self) { option in
                    multipleChoiceButton(option: option, horizontalPadding: optionPadding, isCompact: isCompact)
                }
            }

            if showResult {
                resultView
                if onContinueToNext != nil {
                    Button(action: { onContinueToNext?() }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                                .scaledFont(.xl2)
                            Text("Tiếp tục")
                                .scaledFont(.lg)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isCompact ? 12 : 16)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .cursor(.pointingHand)
                    .keyboardShortcut(.return, modifiers: [])
                    .padding(.top, 8)
                }
            }
        }
    }

    private func multipleChoiceButton(option: String, horizontalPadding: CGFloat = 16, isCompact: Bool = false) -> some View {
        let optionLetter = String(option.prefix(1))
        let isSelected = selectedAnswer == optionLetter
        let isCorrect = flashcard.correctAnswer == optionLetter
        let shortcutKey = KeyEquivalent(Character(optionLetter.lowercased()))

        @State var isPressed = false

        let isLight = colorScheme == .light
        let cornerRadius: CGFloat = isCompact ? 10 : 12

        var backgroundColor: Color {
            if !showResult {
                if isSelected {
                    return Color.green.opacity(isLight ? 0.1 : 0.15)
                }
                return Color.appBackgroundControl(isLight: isLight)
            } else {
                if isCorrect {
                    return Color.green.opacity(isLight ? 0.18 : 0.2)
                } else if isSelected && !isCorrect {
                    return Color.red.opacity(isLight ? 0.18 : 0.2)
                }
                return Color.appBackgroundControl(isLight: isLight)
            }
        }

        var borderColor: Color {
            if !showResult {
                return isSelected ? .green : Color.appBorder(isLight: isLight)
            } else {
                if isCorrect {
                    return .green
                } else if isSelected && !isCorrect {
                    return .red
                }
                return Color.appBorder(isLight: isLight)
            }
        }

        var shadowColor: Color {
            if !showResult {
                return isSelected
                    ? Color.green.opacity(isLight ? 0.2 : 0.4)
                    : Color.appBorder(isLight: isLight).opacity(isLight ? 0.8 : 0.6)
            } else {
                if isCorrect {
                    return Color.green.opacity(isLight ? 0.35 : 0.5)
                } else if isSelected && !isCorrect {
                    return Color.red.opacity(isLight ? 0.35 : 0.5)
                }
                return Color.appBorder(isLight: isLight).opacity(0.6)
            }
        }

        return Button(action: {
            if !showResult {
                let isCorrect = optionLetter == flashcard.correctAnswer

                if isCorrect {
                    SoundManager.shared.playCorrectWithHaptic()
                } else {
                    SoundManager.shared.playIncorrectWithHaptic()
                }

                withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.15)) {
                    selectedAnswer = optionLetter
                    showResult = true
                    onAnswered?(isCorrect)
                }
            }
        }) {
            HStack(spacing: isCompact ? 8 : 12) {
                Text(option)
                    .scaledFont(isCompact ? .sm : .base)
                    .fontWeight(.regular)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                if showResult {
                    if isCorrect {
                        GreenCheckmarkView(size: isCompact ? 22 : 28)
                            .shadow(color: .green.opacity(0.5), radius: 4)
                    } else if isSelected && !isCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .scaledFont(isCompact ? .base : .lg)
                            .foregroundStyle(.red)
                            .symbolEffect(.bounce.down, value: showResult)
                            .shadow(color: .red.opacity(0.5), radius: 4)
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, isCompact ? 12 : 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(shadowColor)
                        .offset(y: isPressed ? 2 : 4)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(borderColor, lineWidth: 2)
                        )
                }
            )
            .offset(y: isPressed ? 2 : 0)
        }
        .buttonStyle(CoreButtonStyle(isPressed: $isPressed, isDisabled: showResult))
        .cursor(.pointingHand)
        .keyboardShortcut(shortcutKey, modifiers: [])
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    showResult && isCorrect ? Color.green.opacity(0.6) :
                    (showResult && isSelected && !isCorrect ? Color.red.opacity(0.6) : Color.clear),
                    lineWidth: showResult ? 3 : 0
                )
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showResult)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }

    private var resultView: some View {
        let isCorrect = selectedAnswer == flashcard.correctAnswer
        let accent = isCorrect ? Color.green : Color.red

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(accent)
                    .symbolEffect(.bounce.up, value: showResult)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isCorrect ? "Chính xác!" : "Chưa đúng")
                        .scaledFont(.xl)
                        .fontWeight(.semibold)
                        .foregroundStyle(accent)
                    SmartCopyDefineText(text: flashcard.answer, flashcards: topic.flashcards)
                        .scaledFont(.base)
                        .foregroundStyle(.secondary)
                        .environmentObject(fontSizeManager)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)

            if (flashcard.hint != nil && !(flashcard.hint?.isEmpty ?? true)) || (radicalText != nil && !(radicalText?.isEmpty ?? true)) || (flashcard.notes != nil && !(flashcard.notes?.isEmpty ?? true)) {
                VStack(alignment: .leading, spacing: 8) {
                    resultDetailRow(label: "Từ gốc", value: flashcard.question)
                    if let radical = radicalText, !radical.isEmpty {
                        resultDetailRow(label: "Bộ thủ", value: radical)
                    }
                    if let hint = flashcard.hint, !hint.isEmpty {
                        resultDetailRow(label: "Gợi ý", value: hint)
                    }
                    if let notes = flashcard.notes, !notes.isEmpty {
                        resultDetailRow(label: "Ghi chú", value: notes)
                    }
                }
                .padding(.top, 12)
                .padding(.leading, 2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBackgroundControl(isLight: colorScheme == .light).opacity(colorScheme == .light ? 0.6 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accent.opacity(colorScheme == .light ? 0.25 : 0.4), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showResult)
    }

    private func resultDetailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .scaledFont(.xs)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)
            Text(value)
                .scaledFont(.base)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Core Button Style (press state for option buttons)
struct CoreButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                if !isDisabled {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = newValue
                    }
                }
            }
    }
}
