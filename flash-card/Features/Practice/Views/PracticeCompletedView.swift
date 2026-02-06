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

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                // --- HEADER ---
                VStack(spacing: 16) {
                    ZStack {
                        // Animated background circles
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green.opacity(0.15), .blue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 10)
                        
                        Circle()
                            .fill(.green.opacity(0.1))
                            .frame(width: 110, height: 110)

                        Image(systemName: "trophy.fill")
                            .scaledFont(.display)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.bounce.up, options: .repeat(3))
                            .shadow(color: .yellow.opacity(0.5), radius: 10)
                    }
                    .padding(.top, 30)

                    Text(customTitle)
                        .scaledFont(.xl3)
                        .fontWeight(.black)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Bạn đã hoàn thành bài luyện tập.")
                        .font(.app(.title3))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 24) {
                    let percentage = totalAnswered > 0 ? Int((Double(score) / Double(totalAnswered)) * 100) : 0

                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                        
                        // Progress circle with gradient
                        Circle()
                            .trim(from: 0, to: Double(percentage) / 100)
                            .stroke(
                                LinearGradient(
                                    colors: percentage >= 70 
                                        ? [.green, .mint] 
                                        : [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2), value: percentage)

                        VStack(spacing: 4) {
                            Text("\(percentage)%")
                                .scaledFont(.xl3)
                                .fontWeight(.black)
                                .foregroundStyle(percentage >= 70 ? .green : .orange)
                            Text(knownLabel)
                                .scaledFont(.xs)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)

                    // Stats cards
                    HStack(spacing: 12) {
                        StatItemView(title: knownLabel, value: "\(score)", color: .green, icon: "checkmark.circle.fill")
                        StatItemView(title: unknownLabel, value: "\(totalAnswered - score)", color: .red, icon: "xmark.circle.fill")
                        StatItemView(title: "Tổng", value: "\(totalAnswered)", color: .blue, icon: "list.bullet.circle.fill")
                    }
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal, 24)

                if let unknownCards = unknownCards, !unknownCards.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Cần ôn lại (\(unknownCards.count) thẻ)")
                                .font(.app(.headline))
                        }
                        .padding(.horizontal, 24)

                        ForEach(unknownCards) { card in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.questionDisplayText)
                                        .font(.app(.subheadline))
                                        .fontWeight(.semibold)
                                    Text(card.answer)
                                        .font(.app(.subheadline))
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

                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                                .scaledFont(.xl2)
                            Text("Tiếp tục học tập")
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
                    .frame(maxWidth: 280)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
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
    @EnvironmentObject var fontSizeManager: FontSizeManager

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50 * fontSizeManager.fontSizeMultiplier, height: 50 * fontSizeManager.fontSizeMultiplier)
                
                Image(systemName: icon)
                    .scaledFont(.xl2)
                    .foregroundStyle(color)
            }
            
            Text(value)
                .scaledFont(.xl2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .scaledFont(.sm)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
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
