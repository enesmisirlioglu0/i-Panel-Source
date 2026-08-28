//
//  PanelStatusImage.swift
//  i-Panel
//

import AppKit

enum PanelStatusImage {
    @MainActor
    static func make() -> NSImage {
        let side: CGFloat = 17
        let gap: CGFloat = 1.7
        let panelHeight = (side - (gap * 2)) / 3
        let colors = [
            NSColor(calibratedRed: 0.94, green: 0.27, blue: 0.30, alpha: 1),
            NSColor(calibratedRed: 0.18, green: 0.52, blue: 0.96, alpha: 1),
            NSColor(calibratedRed: 0.20, green: 0.73, blue: 0.39, alpha: 1)
        ]

        let image = NSImage(size: NSSize(width: side, height: side))
        image.lockFocus()

        for (index, color) in colors.enumerated() {
            let offset = CGFloat(index) * (panelHeight + gap)
            let rect = NSRect(x: 0, y: side - panelHeight - offset, width: side, height: panelHeight)
            let path = NSBezierPath(roundedRect: rect, xRadius: 2.2, yRadius: 2.2)

            color.setFill()
            path.fill()

            NSColor.white.withAlphaComponent(0.45).setStroke()
            path.lineWidth = 0.6
            path.stroke()
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
