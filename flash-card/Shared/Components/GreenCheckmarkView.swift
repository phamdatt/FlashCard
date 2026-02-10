//
//  GreenCheckmarkView.swift
//  flash-card
//
//  Icon tick màu xanh: nền xanh, dấu tick trắng bên trong.
//

import SwiftUI

/// Icon checkmark: background xanh, icon bên trong màu trắng.
struct GreenCheckmarkView: View {
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        GreenCheckmarkView(size: 18)
        GreenCheckmarkView(size: 22)
        GreenCheckmarkView(size: 28)
    }
    .padding()
}
