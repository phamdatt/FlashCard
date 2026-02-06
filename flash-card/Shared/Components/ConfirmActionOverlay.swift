//
//  ConfirmActionOverlay.swift
//  flash-card
//
//  Light/dark friendly confirmation overlay (replaces confirmationDialog for delete etc.).
//

import SwiftUI
import AppKit

/// Full-window overlay: dimmed background + centered card with title, message, Cancel and destructive action.
struct ConfirmActionOverlay: View {
    let title: String
    let message: String
    let destructiveTitle: String
    let cancelTitle: String
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if isPresented {
            ZStack {
                Color(nsColor: .windowBackgroundColor).opacity(0.7)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 20)

                    HStack(spacing: 12) {
                        Spacer()
                        Button(cancelTitle) {
                            isPresented = false
                        }
                        .keyboardShortcut(.escape)
                        .buttonStyle(.bordered)

                        Button(destructiveTitle, role: .destructive) {
                            onConfirm()
                            isPresented = false
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding(24)
                .frame(width: 380, alignment: .topLeading)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 20, x: 0, y: 8)
            }
        }
    }
}
