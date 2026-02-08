//
//  ThemeColors.swift
//  flash-card
//
//  Chuẩn theme light/dark: Divider, Border, Text, Background.
//

import SwiftUI
import AppKit

extension Color {
    // MARK: - Light mode
    static let appCardBackgroundLight = Color(red: 252/255, green: 251/255, blue: 249/255)
    static let appBorderLight = Color(red: 228/255, green: 226/255, blue: 222/255)
    static let appDividerLight = Color(red: 224/255, green: 222/255, blue: 218/255)
    static let appTintLight = Color(red: 236/255, green: 242/255, blue: 234/255)

    // MARK: - Dark mode
    /// Nền trang chung (không dùng pure black).
    static let appDarkBackground = Color(red: 0.12, green: 0.12, blue: 0.14)
    /// Nền card / panel trong dark.
    static let appCardBackgroundDark = Color(red: 0.16, green: 0.16, blue: 0.18)
    /// Viền trong dark.
    static let appBorderDark = Color(red: 0.28, green: 0.28, blue: 0.30)
    /// Đường kẻ ngăn cách trong dark.
    static let appDividerDark = Color(white: 0.18)
    /// Nền control (input, list row) trong dark.
    static let appControlBackgroundDark = Color(red: 0.14, green: 0.14, blue: 0.16)
    /// Nền vùng text (TextField, TextEditor) trong dark.
    static let appTextBackgroundDark = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let appTintDark = Color(red: 56/255, green: 62/255, blue: 56/255)

    // MARK: - Semantic (isLight = true khi colorScheme == .light)
    static func appCardBackground(isLight: Bool) -> Color {
        isLight ? appCardBackgroundLight : appCardBackgroundDark
    }
    static func appBorder(isLight: Bool) -> Color {
        isLight ? appBorderLight : appBorderDark
    }
    static func appDivider(isLight: Bool) -> Color {
        isLight ? appDividerLight : appDividerDark
    }
    static func appTint(isLight: Bool) -> Color {
        isLight ? appTintLight : appTintDark
    }
    /// Nền trang / cửa sổ chính.
    static func appBackgroundPage(isLight: Bool) -> Color {
        isLight ? Color(nsColor: .windowBackgroundColor) : appDarkBackground
    }
    /// Nền control (list, button area, search bar).
    static func appBackgroundControl(isLight: Bool) -> Color {
        isLight ? Color(nsColor: .controlBackgroundColor) : appControlBackgroundDark
    }
    /// Nền vùng nhập chữ (TextField, TextEditor).
    static func appBackgroundText(isLight: Bool) -> Color {
        isLight ? Color(nsColor: .textBackgroundColor) : appTextBackgroundDark
    }
    /// Chữ phụ (secondary) – dùng khi cần đồng bộ với theme.
    static func appTextSecondary(isLight: Bool) -> Color {
        isLight ? Color(nsColor: .secondaryLabelColor) : Color(white: 0.65)
    }
}

// MARK: - NSColor (cho NSView / AppKit)
extension NSColor {
    static func appBackgroundText(isLight: Bool) -> NSColor {
        isLight ? .textBackgroundColor : NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1)
    }
}

// MARK: - Theme Divider (dùng thay Divider() để đồng bộ light/dark)
struct ThemeDivider: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Rectangle()
            .fill(Color.appDivider(isLight: colorScheme == .light))
            .frame(height: 1)
    }
}

