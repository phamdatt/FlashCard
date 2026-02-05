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

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {

                // --- HEADER ---
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.green.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "trophy.fill")
                            .font(.system(size: 45))
                            .foregroundStyle(.yellow)
                            .symbolEffect(.bounce, options: .repeat(3))
                    }
                    .padding(.top, 20)

                    Text(customTitle)
                        .font(.system(size: 28, weight: .black, design: .rounded))

                    Text("Bạn đã hoàn thành bài luyện tập.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // --- BẢNG KẾT QUẢ ---
                VStack(spacing: 20) {
                    let percentage = totalAnswered > 0 ? Int((Double(score) / Double(totalAnswered)) * 100) : 0

                    // Vòng tròn tỷ lệ %
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: Double(percentage) / 100)
                            .stroke(percentage >= 70 ? Color.green : Color.orange,
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.2).delay(0.3), value: percentage)

                        VStack {
                            Text("\(percentage)%")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                            Text(knownLabel)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 90, height: 90)

                    Divider()

                    HStack(spacing: 0) {
                        StatItemView(title: knownLabel, value: "\(score)", color: .green, icon: "checkmark.circle.fill")
                        StatItemView(title: unknownLabel, value: "\(totalAnswered - score)", color: .red, icon: "xmark.circle.fill")
                        StatItemView(title: "Tổng", value: "\(totalAnswered)", color: .blue, icon: "list.bullet.circle.fill")
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 24)

                // --- UNKNOWN CARDS LIST (for Speed Cards) ---
                if let unknownCards = unknownCards, !unknownCards.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Cần ôn lại (\(unknownCards.count) thẻ)")
                                .font(.headline)
                        }
                        .padding(.horizontal, 24)

                        ForEach(unknownCards) { card in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.question)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(card.answer)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                        }
                    }
                }

                // --- NÚT ĐIỀU KHIỂN ---
                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        HStack {
                            Text("Tiếp tục học tập")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .padding(.vertical, 14)
                        .frame(maxWidth: 260)
                        .background(RoundedRectangle(cornerRadius: 14).fill(.blue))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(PracticeGrowingButton())
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        }
    }
}

struct StatItemView: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PracticeGrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
