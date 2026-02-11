//
//  OnboardingView.swift
//  flash-card
//
//  Onboarding: mỗi lần mở app hiện màn chào mừng trước khi vào.
//

import SwiftUI

private let accent = Color.blue

struct OnboardingView: View {
    var onComplete: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let steps = [
        (icon: "book.fill", title: "Chọn môn học", detail: "Chọn môn từ sidebar bên trái"),
        (icon: "folder.fill", title: "Chọn chủ đề", detail: "Mở một chủ đề để xem danh sách thẻ"),
        (icon: "rectangle.stack.fill", title: "Xem thẻ & ôn tập", detail: "Học từ vựng và ôn SRS khi cần")
    ]

    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        ZStack {
            Color.appBackgroundPage(isLight: isLight)
                .ignoresSafeArea()
            content
        }
        .frame(minWidth: 540, minHeight: 580)
    }

    private var content: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 56)
            heroSection
            Spacer()
                .frame(height: 44)
            stepsSection
            Spacer(minLength: 0)
            ctaSection
        }
    }

    private var heroSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(accent)

            VStack(spacing: 10) {
                Text("Chào mừng đến với FlashCard")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text("Học từ vựng đơn giản: chọn môn, chọn chủ đề, xem thẻ và ôn tập.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 48)
        }
    }

    private var stepsSection: some View {
        VStack(spacing: 10) {
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                stepRow(step: step)
            }
        }
        .padding(.horizontal, 48)
    }

    private func stepRow(step: (icon: String, title: String, detail: String)) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: step.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(step.detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBackground(isLight: isLight))
        )
    }

    private var ctaSection: some View {
        VStack(spacing: 14) {
            Button(action: onComplete) {
                Text("Bắt đầu")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
            .padding(.horizontal, 48)

            Button(action: onComplete) {
                Text("Bỏ qua")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
        }
        .padding(.bottom, 52)
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onComplete: {})
            .frame(width: 560, height: 600)
    }
}
#endif
