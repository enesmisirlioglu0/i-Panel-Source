//
//  PanelMark.swift
//  i-Panel
//

import SwiftUI

/// The compact i-Panel mark: three coloured, stacked mini-windows.
struct PanelMark: View {
    let width: CGFloat

    private var gap: CGFloat {
        max(1, width * 0.10)
    }

    private var panelHeight: CGFloat {
        (width - (gap * 2)) / 3
    }

    var body: some View {
        VStack(spacing: gap) {
            miniWindow(color: Color(red: 0.94, green: 0.27, blue: 0.30))
            miniWindow(color: Color(red: 0.18, green: 0.52, blue: 0.96))
            miniWindow(color: Color(red: 0.20, green: 0.73, blue: 0.39))
        }
        .frame(width: width, height: width)
        .accessibilityHidden(true)
    }

    private func miniWindow(color: Color) -> some View {
        RoundedRectangle(cornerRadius: max(1.5, width * 0.12), style: .continuous)
            .fill(color.gradient)
            .frame(height: panelHeight)
            .overlay {
                RoundedRectangle(cornerRadius: max(1.5, width * 0.12), style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 0.6)
            }
    }
}
