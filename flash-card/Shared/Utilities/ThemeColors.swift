//
//  ThemeColors.swift
//  flash-card
//
//  Chuẩn theme light/dark: Divider, Border, Text, Background.
//

import SwiftUI
import AppKit

// MARK: - Layout constants (đồng bộ radius, spacing)
enum AppLayout {
    static let cornerRadiusSmall: CGFloat = 6
    static let cornerRadiusMedium: CGFloat = 8
    static let cornerRadiusLarge: CGFloat = 10
    static let cornerRadiusCard: CGFloat = 12
    static let sidebarRowPaddingH: CGFloat = 8
    static let sidebarSectionSpacing: CGFloat = 6
    /// Padding đồng nhất cho cột sidebar: trái, phải, trên, dưới.
    static let sidebarPadding: CGFloat = 8
    /// Chiều rộng vùng icon/chevron để padding trái-phải cân đối.
    static let sidebarIconAreaWidth: CGFloat = 24
}

extension Color {
    // MARK: - Light mode
    static let appCardBackgroundLight = Color(red: 252/255, green: 251/255, blue: 249/255)
    static let appBorderLight = Color(red: 228/255, green: 226/255, blue: 222/255)
    /// Viền đậm cho nút / card (light mode) — rõ hơn appBorderLight.
    static let appBorderStrongLight = Color(red: 0.55, green: 0.55, blue: 0.58)
    static let appDividerLight = Color(red: 224/255, green: 222/255, blue: 218/255)
    static let appTintLight = Color(red: 236/255, green: 242/255, blue: 234/255)

    // MARK: - Dark mode
    /// Nền trang chung (không dùng pure black).
    static let appDarkBackground = Color(red: 0.12, green: 0.12, blue: 0.14)
    /// Nền card / panel trong dark.
    static let appCardBackgroundDark = Color(red: 0.16, green: 0.16, blue: 0.18)
    /// Viền trong dark.
    static let appBorderDark = Color(red: 0.28, green: 0.28, blue: 0.30)
    /// Viền đậm cho nút / card (dark mode).
    static let appBorderStrongDark = Color(red: 0.42, green: 0.42, blue: 0.45)
    /// Đường kẻ ngăn cách trong dark.
    static let appDividerDark = Color(white: 0.18)
    /// Nền control (input, list row) trong dark.
    static let appControlBackgroundDark = Color(red: 0.14, green: 0.14, blue: 0.16)
    /// Nền vùng text (TextField, TextEditor) trong dark.
    static let appTextBackgroundDark = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let appTintDark = Color(red: 56/255, green: 62/255, blue: 56/255)

    /// Nền popup/sheet (sửa tên, xoá chủ đề) — dark gray giống reference (#3A3A3C).
    static let appPopupBackgroundDark = Color(red: 58/255, green: 58/255, blue: 60/255)

    /// Vàng nhạt cho bóng đèn / gợi ý (icon + chữ).
    static let hintYellowLight = Color(red: 0.85, green: 0.72, blue: 0.22)
    static let hintYellowDark = Color(red: 0.92, green: 0.82, blue: 0.35)
    static func hintYellow(isLight: Bool) -> Color { isLight ? hintYellowLight : hintYellowDark }

    // MARK: - Semantic (isLight = true khi colorScheme == .light)
    static func appCardBackground(isLight: Bool) -> Color {
        isLight ? appCardBackgroundLight : appCardBackgroundDark
    }
    static func appBorder(isLight: Bool) -> Color {
        isLight ? appBorderLight : appBorderDark
    }
    /// Viền nút/card đậm, rõ ở cả light và dark.
    static func appBorderStrong(isLight: Bool) -> Color {
        isLight ? appBorderStrongLight : appBorderStrongDark
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
    /// Nền row được chọn trong sidebar — xám nhẹ, không xanh nhạt.
    static func appSidebarSelected(isLight: Bool) -> Color {
        isLight ? Color.primary.opacity(0.06) : Color.white.opacity(0.09)
    }
    /// Nền row khi hover (sidebar / list).
    static func appRowHover(isLight: Bool) -> Color {
        isLight ? Color.primary.opacity(0.04) : Color.white.opacity(0.06)
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

