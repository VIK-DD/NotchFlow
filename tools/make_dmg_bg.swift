//
//  make_dmg_bg.swift
//  Draws the DMG window background (660×420 pt, rendered @2x = 1320×840 px).
//  Usage: swift tools/make_dmg_bg.swift <out.png>
//

import AppKit

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/dmg-bg.png"
let scale: CGFloat = 2
let W: CGFloat = 660 * scale
let H: CGFloat = 420 * scale

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("rep") }

let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx

func col(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(deviceRed: r, green: g, blue: b, alpha: a)
}
// Convert a top-left point (in 660×420 space) to this bitmap's bottom-left pixels.
func pt(_ x: CGFloat, _ yTop: CGFloat) -> NSPoint { NSPoint(x: x * scale, y: (420 - yTop) * scale) }

// Background gradient.
let grad = NSGradient(colors: [col(0.11, 0.11, 0.14), col(0.05, 0.05, 0.07)])!
grad.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

// Title + subtitle.
let titleStyle = NSMutableParagraphStyle(); titleStyle.alignment = .center
let title = NSAttributedString(string: "NotchFlow", attributes: [
    .font: NSFont.systemFont(ofSize: 34 * scale, weight: .bold),
    .foregroundColor: NSColor.white,
    .paragraphStyle: titleStyle
])
title.draw(in: NSRect(x: 0, y: pt(330, 70).y, width: W, height: 50 * scale))

let sub = NSAttributedString(string: "Drag NotchFlow into Applications to install", attributes: [
    .font: NSFont.systemFont(ofSize: 14 * scale, weight: .regular),
    .foregroundColor: NSColor.white.withAlphaComponent(0.55),
    .paragraphStyle: titleStyle
])
sub.draw(in: NSRect(x: 0, y: pt(330, 112).y, width: W, height: 24 * scale))

// Arrow between the two icons (icons sit at x≈165 and x≈495, y≈230).
let arrowY: CGFloat = 230
let path = NSBezierPath()
path.lineWidth = 6 * scale
path.lineCapStyle = .round
let aStart = pt(285, arrowY)
let aEnd = pt(375, arrowY)
path.move(to: aStart)
path.line(to: aEnd)
// arrowhead
path.move(to: NSPoint(x: aEnd.x - 16 * scale, y: aEnd.y + 14 * scale))
path.line(to: aEnd)
path.line(to: NSPoint(x: aEnd.x - 16 * scale, y: aEnd.y - 14 * scale))
col(1, 1, 1, 0.45).setStroke()
path.stroke()

ctx.flushGraphics()
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
