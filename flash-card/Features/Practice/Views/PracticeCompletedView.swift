//
//  PracticeCompletedView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

struct PracticeCompletedView: View {
    let score: Int
    let totalAnswered: Int
    var customTitle: String = "Tuyệt vời!"
    var knownLabel: String = "Đúng"
    var unknownLabel: String = "Sai"
    let onContinue: () -> Void
    var unknownCards: [Flashcard]? = nil
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme

    private var isLight: Bool { colorScheme == .light }
    private var percentage: Int { totalAnswered > 0 ? Int((Double(score) / Double(totalAnswered)) * 100) : 0 }

    /// Mức độ: tốt (≥70%), giữa (40–69%), thấp (&lt;40%)
    private var completionLevel: CompletionLevel {
        switch percentage {
        case 70...100: return .good
        case 40..<70: return .average
        default: return .poor
        }
    }

    private var completionTitle: String {
        switch completionLevel {
        case .good: return "Tuyệt vời!"
        case .average: return "Cần cải thiện"
        case .poor: return "Quá tệ"
        }
    }

    private var completionSubtitle: String {
        switch completionLevel {
        case .good: return "Bạn đã hoàn thành bài luyện tập."
        case .average: return "Ôn lại để làm tốt hơn nhé."
        case .poor: return "Hãy ôn lại và thử lại."
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 36) {
                // --- HEADER: theo mức độ hoàn thành ---
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.appBorder(isLight: isLight).opacity(0.25))
                            .frame(width: 88, height: 88)

                        Image(systemName: completionLevel.iconName)
                            .scaledFont(.display)
                            .foregroundStyle(completionLevel.accent(isLight: isLight))
                            .symbolEffect(.bounce.up, options: .repeat(3))
                    }
                    .padding(.top, 24)

                    Text(completionTitle)
                        .scaledFont(.xl3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(completionSubtitle)
                        .font(.app(.title3))
                        .foregroundStyle(Color.appTextSecondary(isLight: isLight))
                }

                // --- SCORE CARD: clean card with ring ---
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.appBorder(isLight: isLight).opacity(0.4), lineWidth: 10)

                        Circle()
                            .trim(from: 0, to: Double(percentage) / 100)
                            .stroke(
                                completionLevel.accent(isLight: isLight),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.15), value: percentage)

                        VStack(spacing: 2) {
                            Text("\(percentage)%")
                                .scaledFont(.xl3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(knownLabel)
                                .scaledFont(.xs)
                                .foregroundStyle(Color.appTextSecondary(isLight: isLight))
                        }
                    }
                    .frame(width: 112, height: 112)

                    HStack(spacing: 10) {
                        StatItemView(title: knownLabel, value: "\(score)", semantic: .correct, isLight: isLight)
                        StatItemView(title: unknownLabel, value: "\(totalAnswered - score)", semantic: .incorrect, isLight: isLight)
                        StatItemView(title: "Tổng", value: "\(totalAnswered)", semantic: .total, isLight: isLight)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appCardBackground(isLight: isLight))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appBorder(isLight: isLight), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(isLight ? 0.04 : 0.2), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 28)

                if let unknownCards = unknownCards, !unknownCards.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .font(.app(.subheadline))
                                .foregroundStyle(completedAccentNeutral(isLight: isLight))
                            Text("Cần ôn lại (\(unknownCards.count) thẻ)")
                                .font(.app(.headline))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 20)

                        ForEach(unknownCards) { card in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.questionDisplayText)
                                        .font(.app(.subheadline))
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text(card.answer)
                                        .font(.app(.subheadline))
                                        .foregroundStyle(Color.appTextSecondary(isLight: isLight))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appBackgroundControl(isLight: isLight))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appBorder(isLight: isLight), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }

                Button(action: onContinue) {
                    HStack(spacing: 10) {
                        Text("Tiếp tục học tập")
                            .scaledFont(.lg)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.app(.body).weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
                .cursor(.pointingHand)
                .frame(maxWidth: 260)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            SoundManager.shared.playSuccessWithHaptic()
        }
    }

    private func completedAccentSuccess(isLight: Bool) -> Color {
        isLight ? Color(red: 0.22, green: 0.55, blue: 0.49) : Color(red: 0.35, green: 0.72, blue: 0.65)
    }

    private func completedAccentNeutral(isLight: Bool) -> Color {
        isLight ? Color(red: 0.45, green: 0.45, blue: 0.50) : Color(red: 0.55, green: 0.55, blue: 0.60)
    }
}

private enum CompletionLevel {
    case good   // ≥70%
    case average // 40–69%
    case poor   // <40%

    var iconName: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .average: return "exclamationmark.triangle.fill"
        case .poor: return "xmark.circle.fill"
        }
    }

    func accent(isLight: Bool) -> Color {
        switch self {
        case .good:
            return isLight ? Color(red: 0.22, green: 0.55, blue: 0.49) : Color(red: 0.35, green: 0.72, blue: 0.65)
        case .average:
            return isLight ? Color(red: 0.45, green: 0.45, blue: 0.50) : Color(red: 0.55, green: 0.55, blue: 0.60)
        case .poor:
            return isLight ? Color(red: 0.70, green: 0.35, blue: 0.35) : Color(red: 0.85, green: 0.45, blue: 0.45)
        }
    }
}

private enum StatSemantic {
    case correct
    case incorrect
    case total

    var icon: String {
        switch self {
        case .correct: return "checkmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        case .total: return "list.bullet.circle.fill"
        }
    }

    func color(isLight: Bool) -> Color {
        switch self {
        case .correct:
            return isLight ? Color(red: 0.22, green: 0.55, blue: 0.49) : Color(red: 0.35, green: 0.72, blue: 0.65)
        case .incorrect:
            return isLight ? Color(red: 0.70, green: 0.35, blue: 0.35) : Color(red: 0.85, green: 0.45, blue: 0.45)
        case .total:
            return isLight ? Color(red: 0.38, green: 0.38, blue: 0.45) : Color(red: 0.55, green: 0.55, blue: 0.62)
        }
    }

    func backgroundTint(isLight: Bool) -> Color {
        color(isLight: isLight).opacity(isLight ? 0.08 : 0.15)
    }
}

struct StatItemView: View {
    let title: String
    let value: String
    fileprivate let semantic: StatSemantic
    let isLight: Bool
    @EnvironmentObject var fontSizeManager: FontSizeManager

    var body: some View {
        let color = semantic.color(isLight: isLight)
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(semantic.backgroundTint(isLight: isLight))
                    .frame(width: 44, height: 44)

                Image(systemName: semantic.icon)
                    .scaledFont(.lg)
                    .foregroundStyle(color)
            }

            Text(value)
                .scaledFont(.xl2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(title)
                .scaledFont(.sm)
                .foregroundStyle(Color.appTextSecondary(isLight: isLight))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBackgroundControl(isLight: isLight))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder(isLight: isLight).opacity(0.6), lineWidth: 1)
        )
    }
}

struct PracticeGrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
