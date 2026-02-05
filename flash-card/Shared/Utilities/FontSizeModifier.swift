//
//  FontSizeModifier.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

// MARK: - Font Size Environment Key
private struct FontSizeMultiplierKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var fontSizeMultiplier: CGFloat {
        get { self[FontSizeMultiplierKey.self] }
        set { self[FontSizeMultiplierKey.self] = newValue }
    }
}

// MARK: - Font Size Modifier for explicit sizes
struct ScaledFont: ViewModifier {
    @Environment(\.fontSizeMultiplier) var fontSizeMultiplier
    let baseSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: baseSize * fontSizeMultiplier))
    }
}

extension View {
    func scaledFont(_ size: CGFloat) -> some View {
        self.modifier(ScaledFont(baseSize: size))
    }
    
    // Apply font size scaling to all text in the view hierarchy
    func applyFontSizeScaling(multiplier: CGFloat) -> some View {
        self.environment(\.fontSizeMultiplier, multiplier)
    }
}

// MARK: - Helper để scale font size tự động
extension Font {
    // Scale font size dựa trên environment multiplier
    static func scaled(_ style: Font.TextStyle, multiplier: CGFloat = 1.0) -> Font {
        let baseSize: CGFloat
        switch style {
        case .largeTitle: baseSize = 34
        case .title: baseSize = 28
        case .title2: baseSize = 22
        case .title3: baseSize = 20
        case .headline: baseSize = 17
        case .body: baseSize = 17
        case .callout: baseSize = 16
        case .subheadline: baseSize = 15
        case .footnote: baseSize = 13
        case .caption: baseSize = 12
        case .caption2: baseSize = 11
        @unknown default: baseSize = 17
        }
        return .system(size: baseSize * multiplier)
    }
}
