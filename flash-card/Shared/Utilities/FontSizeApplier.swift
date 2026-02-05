//
//  FontSizeApplier.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

// MARK: - Font Size Applier - Tự động scale tất cả font trong app
struct FontSizeApplier: ViewModifier {
    @ObservedObject var fontSizeManager: FontSizeManager
    
    func body(content: Content) -> some View {
        content
            .environment(\.fontSizeMultiplier, fontSizeManager.fontSizeMultiplier)
    }
}

extension View {
    // Áp dụng font size scaling cho toàn bộ view hierarchy
    func applyGlobalFontSize(fontSizeManager: FontSizeManager) -> some View {
        self.modifier(FontSizeApplier(fontSizeManager: fontSizeManager))
    }
}
