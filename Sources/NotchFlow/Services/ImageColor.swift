//
//  ImageColor.swift
//  NotchFlow
//
//  Derives a single representative accent colour from album artwork so the UI can
//  subtly tint itself to the current track. Uses Core Image's area-average for a
//  cheap, good-enough result.
//

import AppKit
import CoreImage
import SwiftUI

extension NSImage {
    /// Average colour of the image, nudged toward vividness so it reads as an
    /// accent rather than a muddy grey. Returns nil on failure.
    func dominantAccentColor() -> Color? {
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let cgImage = bitmap.cgImage else { return nil }

        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: ciImage,
            kCIInputExtentKey: CIVector(cgRect: extent)
        ]), let output = filter.outputImage else { return nil }

        var bitmapPixel = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        context.render(
            output,
            toBitmap: &bitmapPixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        var r = CGFloat(bitmapPixel[0]) / 255.0
        var g = CGFloat(bitmapPixel[1]) / 255.0
        var b = CGFloat(bitmapPixel[2]) / 255.0

        // Boost saturation a touch and ensure a minimum brightness so the accent
        // stays legible on the dark island.
        let nsColor = NSColor(red: r, green: g, blue: b, alpha: 1)
        if let hsb = nsColor.usingColorSpace(.deviceRGB) {
            var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, a: CGFloat = 0
            hsb.getHue(&h, saturation: &s, brightness: &br, alpha: &a)
            s = min(1.0, s * 1.35 + 0.08)
            br = max(0.65, br)
            let boosted = NSColor(hue: h, saturation: s, brightness: br, alpha: 1)
            r = boosted.redComponent
            g = boosted.greenComponent
            b = boosted.blueComponent
        }

        return Color(red: r, green: g, blue: b)
    }
}
