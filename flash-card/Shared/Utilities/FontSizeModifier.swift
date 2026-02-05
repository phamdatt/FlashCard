//
//  FontSizeModifier.swift
//  flash-card
//
//  Tailwind-style breakpoint scale: discrete scale factors (sm/base/lg/xl/2xl)
//  and type scale (text-xs … text-5xl). User multiplier maps to nearest breakpoint.
//

import SwiftUI

// MARK: - Tailwind-style breakpoint scale (ratio ~1.125)
/// Scale factors like Tailwind responsive steps: 0.75rem → 1.25rem
private enum TailwindScale {
    /// 0.75 (text-sm equivalent)
    static let sm: CGFloat = 0.75
    /// 0.875
    static let md: CGFloat = 0.875
    /// 1.0 (base)
    static let base: CGFloat = 1.0
    /// 1.125
    static let lg: CGFloat = 1.125
    /// 1.25
    static let xl: CGFloat = 1.25
    /// 1.5 (2xl)
    static let xxl: CGFloat = 1.5

    /// Breakpoint scale factors in order (sm → 2xl)
    static let steps: [CGFloat] = [sm, md, base, lg, xl, xxl]

    /// Map user multiplier (0.5…2.0) to nearest Tailwind step
    static func scaleFactor(for multiplier: CGFloat) -> CGFloat {
        let clamped = max(0.5, min(2.0, multiplier))
        let index = Int(round((clamped - 0.5) / 1.5 * CGFloat(steps.count - 1)))
        return steps[min(max(0, index), steps.count - 1)]
    }
}

// MARK: - Tailwind type scale (base 16px = 1rem)
/// Font sizes matching Tailwind text-xs … text-5xl (in points for SwiftUI)
private enum TailwindTypeScale {
    static let xs: CGFloat = 12   // 0.75rem
    static let sm: CGFloat = 14   // 0.875rem
    static let base: CGFloat = 16 // 1rem
    static let lg: CGFloat = 18   // 1.125rem
    static let xl: CGFloat = 20   // 1.25rem
    static let xl2: CGFloat = 24  // 1.5rem
    static let xl3: CGFloat = 30  // 1.875rem
    static let xl4: CGFloat = 36  // 2.25rem
    static let xl5: CGFloat = 48  // 3rem

    static func size(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return xl5
        case .title: return xl4
        case .title2: return xl3
        case .title3: return xl2
        case .headline: return base
        case .body: return base
        case .callout: return lg
        case .subheadline: return sm
        case .footnote: return sm
        case .caption: return xs
        case .caption2: return 11
        @unknown default: return base
        }
    }
}

// MARK: - Environment
private struct FontSizeMultiplierKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var fontSizeMultiplier: CGFloat {
        get { self[FontSizeMultiplierKey.self] }
        set { self[FontSizeMultiplierKey.self] = newValue }
    }
}

// MARK: - Scaled font modifier (breakpoint-based)
struct ScaledFont: ViewModifier {
    @Environment(\.fontSizeMultiplier) var fontSizeMultiplier
    let baseSize: CGFloat

    func body(content: Content) -> some View {
        let scale = TailwindScale.scaleFactor(for: fontSizeMultiplier)
        content
            .font(.system(size: baseSize * scale))
    }
}

extension View {
    /// Apply Tailwind-style breakpoint scaling to a base size (e.g. 16 → text-base at current zoom)
    func scaledFont(_ size: CGFloat) -> some View {
        modifier(ScaledFont(baseSize: size))
    }

    func applyFontSizeScaling(multiplier: CGFloat) -> some View {
        environment(\.fontSizeMultiplier, multiplier)
    }
}

// MARK: - Semantic Tailwind font sizes
extension Font {
    /// Tailwind-style text sizes (xs, sm, base, lg, xl, 2xl–5xl). Use with scaledFont or apply multiplier.
    enum TailwindSize {
        case xs, sm, base, lg, xl, xl2, xl3, xl4, xl5
        var pointSize: CGFloat {
            switch self {
            case .xs: return TailwindTypeScale.xs
            case .sm: return TailwindTypeScale.sm
            case .base: return TailwindTypeScale.base
            case .lg: return TailwindTypeScale.lg
            case .xl: return TailwindTypeScale.xl
            case .xl2: return TailwindTypeScale.xl2
            case .xl3: return TailwindTypeScale.xl3
            case .xl4: return TailwindTypeScale.xl4
            case .xl5: return TailwindTypeScale.xl5
            }
        }
    }

    /// Font scaled by Tailwind breakpoint (multiplier 0.5–2.0 → nearest step)
    static func scaled(_ style: Font.TextStyle, multiplier: CGFloat = 1.0) -> Font {
        let base = TailwindTypeScale.size(for: style)
        let scale = TailwindScale.scaleFactor(for: multiplier)
        return .system(size: base * scale)
    }

    /// Font for a Tailwind semantic size, with optional breakpoint scale
    static func tailwind(_ size: TailwindSize, multiplier: CGFloat = 1.0) -> Font {
        let scale = TailwindScale.scaleFactor(for: multiplier)
        return .system(size: size.pointSize * scale)
    }
}
