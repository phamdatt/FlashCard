//
//  CursorModifier.swift
//  flash-card
//
//  Cursor appearance on hover (macOS). Use .cursor(.pointingHand) on buttons and clickable views.
//

import SwiftUI
import AppKit

extension View {
    /// Sets the mouse cursor when hovering over this view (macOS). Use for buttons, links, list rows.
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
