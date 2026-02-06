//
//  FontSizeApplier.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

// MARK: - Font Size Applier
struct FontSizeApplier: ViewModifier {
    @ObservedObject var fontSizeManager: FontSizeManager
    
    func body(content: Content) -> some View {
        content
            .environment(\.fontSizeMultiplier, fontSizeManager.fontSizeMultiplier)
    }
}

extension View {
    // Apply font size scaling to entire view hierarchy
    func applyGlobalFontSize(fontSizeManager: FontSizeManager) -> some View {
        self.modifier(FontSizeApplier(fontSizeManager: fontSizeManager))
    }
}
