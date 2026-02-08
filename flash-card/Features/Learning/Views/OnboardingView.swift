//
//  OnboardingView.swift
//  flash-card
//
//  Onboarding on first launch: choose subject → topic → view cards.
//

import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private let steps = [
        (icon: "book.fill", title: "Chọn môn học", detail: "Chọn môn từ sidebar bên trái"),
        (icon: "folder.fill", title: "Chọn chủ đề", detail: "Mở một chủ đề để xem danh sách thẻ"),
        (icon: "rectangle.stack.fill", title: "Xem thẻ & ôn tập", detail: "Học từ vựng và ôn SRS khi cần")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 28) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                Text("Chào mừng đến với FlashCard")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("Học từ vựng đơn giản: chọn môn, chọn chủ đề, xem thẻ và ôn tập.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(colorScheme == .dark ? 0.25 : 0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: step.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(.green)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.headline)
                            Text(step.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 36)

            Spacer()

            HStack(spacing: 16) {
                Button("Bỏ qua") {
                    onComplete()
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
                .foregroundStyle(.secondary)
                Spacer()
                Button("Bắt đầu") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .cursor(.pointingHand)
                .tint(.green)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(minWidth: 480, minHeight: 520)
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onComplete: {})
            .frame(width: 520, height: 560)
    }
}
#endif
