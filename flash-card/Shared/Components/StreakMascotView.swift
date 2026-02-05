//
//  StreakMascotView.swift
//  flash-card
//
//  Nhân vật animated kiểu Duolingo cho streak.
//

import SwiftUI

struct StreakMascotView: View {
    let currentStreak: Int
    let didPracticeToday: Bool
    let isLight: Bool

    private var mood: Mood {
        if currentStreak > 0 && didPracticeToday { return .happy }
        if currentStreak > 0 { return .encouraging }
        return .sad
    }

    enum Mood {
        case happy, encouraging, sad
    }

    @State private var bounceOffset: CGFloat = 0
    @State private var droopRotation: Double = 0
    @State private var glowOpacity: Double = 0.4

    // Màu ấm, dễ thương (Duolingo-style)
    private var greenMain: Color {
        Color(red: 0.45, green: 0.82, blue: 0.38)
    }
    private var greenShadow: Color {
        Color(red: 0.28, green: 0.65, blue: 0.28)
    }
    private var greenHighlight: Color {
        Color(red: 0.55, green: 0.9, blue: 0.5)
    }
    private var cream: Color {
        Color(red: 1, green: 0.99, blue: 0.95)
    }
    private var outline: Color {
        Color(red: 0.22, green: 0.52, blue: 0.22)
    }
    private var pupilColor: Color {
        Color(red: 0.15, green: 0.18, blue: 0.22)
    }

    var body: some View {
        ZStack {
            // Bóng mờ nhẹ (happy)
            if mood == .happy {
                Circle()
                    .fill(greenMain.opacity(glowOpacity))
                    .frame(width: 42, height: 42)
                    .blur(radius: 6)
                    .offset(y: bounceOffset + 2)
            }

            // Thân dạng blob (một khối tròn dễ thương)
            ZStack(alignment: .top) {
                // Thân dưới (bầu)
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [greenMain, greenShadow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 32, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(outline.opacity(0.35), lineWidth: 1.2)
                    )
                    .offset(y: 18)

                // Đầu (tròn, to hơn thân)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [greenHighlight, greenMain],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(outline.opacity(0.4), lineWidth: 1.2)
                        )

                    // Bụng trắng (nửa dưới mặt)
                    Ellipse()
                        .fill(cream.opacity(0.9))
                        .frame(width: 26, height: 18)
                        .offset(y: 12)
                        .clipShape(Circle())

                    // Mắt trái
                    eyeView
                        .offset(x: -8, y: -4)

                    // Mắt phải
                    eyeView
                        .offset(x: 8, y: -4)

                    // Má hồng (happy)
                    if mood == .happy {
                        Circle()
                            .fill(Color.pink.opacity(0.35))
                            .frame(width: 5, height: 5)
                            .offset(x: -14, y: 4)
                        Circle()
                            .fill(Color.pink.opacity(0.35))
                            .frame(width: 5, height: 5)
                            .offset(x: 14, y: 4)
                    }

                    // Miệng
                    mouthView
                        .offset(y: 8)
                }
                .offset(y: bounceOffset)
                .rotationEffect(.degrees(droopRotation))
            }
        }
        .frame(width: 48, height: 58)
        .onAppear { startAnimations() }
        .onChange(of: mood) { _, _ in startAnimations() }
    }

    private var eyeView: some View {
        ZStack {
            // Lòng trắng mắt
            RoundedRectangle(cornerRadius: 6)
                .fill(cream)
                .frame(width: mood == .sad ? 12 : 14, height: mood == .sad ? 5 : 14)

            // Con ngươi
            if mood != .sad {
                Circle()
                    .fill(pupilColor)
                    .frame(width: 5, height: 5)
                    .offset(y: 1)
                // Highlight (chấm sáng)
                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 1.5, height: 1.5)
                    .offset(x: 1, y: -0.5)
            }
        }
    }

    @ViewBuilder
    private var mouthView: some View {
        switch mood {
        case .happy:
            // Cười to (hình lưỡi liềm)
            ArcShape(startAngle: .degrees(15), endAngle: .degrees(165))
                .stroke(outline.opacity(0.6), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                .frame(width: 14, height: 7)
        case .encouraging:
            ArcShape(startAngle: .degrees(25), endAngle: .degrees(155))
                .stroke(outline.opacity(0.5), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 12, height: 5)
        case .sad:
            ArcShape(startAngle: .degrees(195), endAngle: .degrees(345))
                .stroke(outline.opacity(0.45), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 12, height: 5)
        }
    }

    private func startAnimations() {
        switch mood {
        case .happy:
            droopRotation = 0
            withAnimation(.easeInOut(duration: 0.32).repeatForever(autoreverses: true)) {
                bounceOffset = -4
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowOpacity = 0.25
            }
        case .encouraging:
            droopRotation = 0
            glowOpacity = 0.25
            withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
                bounceOffset = -2
            }
        case .sad:
            bounceOffset = 0
            glowOpacity = 0.25
            withAnimation(.easeInOut(duration: 0.45)) {
                droopRotation = -8
            }
        }
    }
}

private struct ArcShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) / 2
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: r,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return p
    }
}

struct StreakMascotView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 32) {
            VStack(spacing: 8) {
                StreakMascotView(currentStreak: 7, didPracticeToday: true, isLight: true)
                Text("Happy").font(.caption).foregroundStyle(.secondary)
            }
            VStack(spacing: 8) {
                StreakMascotView(currentStreak: 3, didPracticeToday: false, isLight: true)
                Text("Encouraging").font(.caption).foregroundStyle(.secondary)
            }
            VStack(spacing: 8) {
                StreakMascotView(currentStreak: 0, didPracticeToday: false, isLight: true)
                Text("Sad").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .background(Color.gray.opacity(0.1))
    }
}
