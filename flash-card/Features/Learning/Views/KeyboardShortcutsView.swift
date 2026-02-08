//
//  KeyboardShortcutsView.swift
//  flash-card
//
//  Lists in-app keyboard shortcuts (Cmd+/-, Cmd+0, Space/Return in SRS).
//

import SwiftUI

struct KeyboardShortcutsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let shortcuts: [(keys: String, description: String)] = [
        ("⌘ +", "Tăng kích thước chữ"),
        ("⌘ −", "Giảm kích thước chữ"),
        ("⌘ 0", "Đặt lại kích thước chữ"),
        ("Space / Return", "Trong ôn SRS: xem đáp án / chuyển thẻ tiếp theo")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Phím tắt")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            ThemeDivider()

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(shortcuts.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .center, spacing: 20) {
                        Text(item.keys)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.5))
                            )
                            .frame(width: 160, alignment: .leading)
                        Text(item.description)
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    if index < shortcuts.count - 1 {
                        ThemeDivider()
                            .padding(.leading, 24)
                    }
                }
            }
            .padding(.vertical, 8)

            Spacer(minLength: 0)
        }
        .frame(width: 440, height: 280)
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
    }
}

#if DEBUG
struct KeyboardShortcutsView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutsView()
    }
}
#endif
