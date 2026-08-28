import AppKit
import Foundation

/// Generates the i-Panel Finder/DMG icon from the three coloured-card mark.
/// The menu-bar icon remains the native monochrome system symbol.

private struct IconAsset {
    let pixelSize: Int
    let filename: String
}

private enum IconGenerationError: LocalizedError {
    case invalidArguments
    case bitmapCreationFailed
    case pngEncodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidArguments:
            return "Usage: swift scripts/generate-app-icon.swift <AppIcon.appiconset directory> <preview PNG path>"
        case .bitmapCreationFailed:
            return "Could not create an AppKit bitmap context."
        case .pngEncodingFailed:
            return "Could not encode the app icon as PNG."
        }
    }
}

private let appIconAssets = [
    IconAsset(pixelSize: 16, filename: "Icon-16.png"),
    IconAsset(pixelSize: 32, filename: "Icon-16@2x.png"),
    IconAsset(pixelSize: 32, filename: "Icon-32.png"),
    IconAsset(pixelSize: 64, filename: "Icon-32@2x.png"),
    IconAsset(pixelSize: 128, filename: "Icon-128.png"),
    IconAsset(pixelSize: 256, filename: "Icon-128@2x.png"),
    IconAsset(pixelSize: 256, filename: "Icon-256.png"),
    IconAsset(pixelSize: 512, filename: "Icon-256@2x.png"),
    IconAsset(pixelSize: 512, filename: "Icon-512.png"),
    IconAsset(pixelSize: 1024, filename: "Icon-512@2x.png")
]

private func makeBitmap(pixelSize: Int) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: .alphaFirst,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw IconGenerationError.bitmapCreationFailed
    }

    return bitmap
}

private func drawIcon(in bitmap: NSBitmapImageRep) {
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    let side = CGFloat(bitmap.pixelsWide)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }

    context.cgContext.clear(CGRect(x: 0, y: 0, width: side, height: side))
    context.cgContext.setShouldAntialias(true)
    context.cgContext.interpolationQuality = .high

    let outerInset = side * 0.07
    let baseRect = NSRect(
        x: outerInset,
        y: outerInset,
        width: side - (outerInset * 2),
        height: side - (outerInset * 2)
    )
    let basePath = NSBezierPath(
        roundedRect: baseRect,
        xRadius: side * 0.19,
        yRadius: side * 0.19
    )
    let backgroundGradient = NSGradient(
        starting: NSColor(calibratedRed: 0.07, green: 0.22, blue: 0.30, alpha: 1),
        ending: NSColor(calibratedRed: 0.12, green: 0.49, blue: 0.49, alpha: 1)
    )!
    backgroundGradient.draw(in: basePath, angle: -42)

    NSColor.white.withAlphaComponent(0.28).setStroke()
    basePath.lineWidth = max(1, side * 0.006)
    basePath.stroke()

    let colors = [
        NSColor(calibratedRed: 0.94, green: 0.27, blue: 0.30, alpha: 1),
        NSColor(calibratedRed: 0.18, green: 0.52, blue: 0.96, alpha: 1),
        NSColor(calibratedRed: 0.20, green: 0.73, blue: 0.39, alpha: 1)
    ]
    let cardWidth = side * 0.57
    let cardHeight = side * 0.145
    let cardGap = side * 0.073
    let firstY = (side - cardHeight) / 2 + cardHeight + cardGap
    let cardX = (side - cardWidth) / 2
    let cardRadius = side * 0.052

    for (index, color) in colors.enumerated() {
        let y = firstY - CGFloat(index) * (cardHeight + cardGap)
        let cardPath = NSBezierPath(
            roundedRect: NSRect(x: cardX, y: y, width: cardWidth, height: cardHeight),
            xRadius: cardRadius,
            yRadius: cardRadius
        )
        let cardHighlight = color.blended(withFraction: 0.25, of: .white) ?? color
        NSGradient(starting: cardHighlight, ending: color)!.draw(in: cardPath, angle: -90)

        NSColor.white.withAlphaComponent(0.42).setStroke()
        cardPath.lineWidth = max(0.75, side * 0.004)
        cardPath.stroke()
    }
}

private func writeIcon(pixelSize: Int, to destination: URL) throws {
    let bitmap = try makeBitmap(pixelSize: pixelSize)
    drawIcon(in: bitmap)

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw IconGenerationError.pngEncodingFailed
    }

    try png.write(to: destination, options: .atomic)
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    throw IconGenerationError.invalidArguments
}

let iconsetDirectory = URL(fileURLWithPath: arguments[1], isDirectory: true)
let previewDestination = URL(fileURLWithPath: arguments[2])
let fileManager = FileManager.default

try fileManager.createDirectory(at: iconsetDirectory, withIntermediateDirectories: true)
try fileManager.createDirectory(
    at: previewDestination.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

for asset in appIconAssets {
    try writeIcon(pixelSize: asset.pixelSize, to: iconsetDirectory.appendingPathComponent(asset.filename))
}

try writeIcon(pixelSize: 1024, to: previewDestination)
