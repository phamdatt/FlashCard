//
//  ThemeColors.swift
//  flash-card
//
//  Minimal theme: system colors for lists/inputs; custom only for cards.
//  Green = correct, Red = wrong (unchanged).
//

import SwiftUI
import AppKit

extension Color {
    // MARK: - Light mode (cards only – lists use system)
    static let appCardBackgroundLight = Color(red: 252/255, green: 251/255, blue: 249/255)
    static let appBorderLight = Color(red: 228/255, green: 226/255, blue: 222/255)
    /// Badge / subtle tint (e.g. exercise type)
    static let appTintLight = Color(red: 236/255, green: 242/255, blue: 234/255)

    // MARK: - Dark mode
    static let appCardBackgroundDark = Color(red: 40/255, green: 40/255, blue: 42/255)
    static let appBorderDark = Color(red: 72/255, green: 72/255, blue: 76/255)
    static let appTintDark = Color(red: 56/255, green: 62/255, blue: 56/255)

    static func appCardBackground(isLight: Bool) -> Color {
        isLight ? appCardBackgroundLight : appCardBackgroundDark
    }
    static func appBorder(isLight: Bool) -> Color {
        isLight ? appBorderLight : appBorderDark
    }
    static func appTint(isLight: Bool) -> Color {
        isLight ? appTintLight : appTintDark
    }
}
