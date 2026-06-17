//
//  make_dmg_bg.swift
//  Draws the DMG window background. Finder maps the image 1pt = 1px (it does NOT
//  scale it to the window), so this MUST match the DMG window size exactly
//  (660×420). Classic, clean dark-grey backdrop with a small caption + arrow.
//  Usage: swift tools/make_dmg_bg.swift <out.png>
//

import AppKit

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/dmg-bg.png"
let W: CGFloat = 660
let H: CGFloat = 420

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
// top-left point → bitmap bottom-left
func y(_ top: CGFloat) -> CGFloat { H - top }

// Plain, elegant dark-grey gradient.
NSGradient(colors: [col(0.16, 0.16, 0.18), col(0.10, 0.10, 0.12)])!
    .draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

// Caption (centered, fits within the window).
let p = NSMutableParagraphStyle(); p.alignment = .center
NSAttributedString(string: "Drag NotchFlow into Applications", attributes: [
    .font: NSFont.systemFont(ofSize: 15, weight: .medium),
    .foregroundColor: col(1, 1, 1, 0.55),
    .paragraphStyle: p
]).draw(in: NSRect(x: 0, y: y(70), width: W, height: 22))

// Arrow between the two icons (icons sit at x≈165 and x≈495, y≈230).
let arrowY = y(230)
let path = NSBezierPath()
path.lineWidth = 5
path.lineCapStyle = .round
path.move(to: NSPoint(x: 286, y: arrowY))
path.line(to: NSPoint(x: 374, y: arrowY))
path.move(to: NSPoint(x: 358, y: arrowY + 13))
path.line(to: NSPoint(x: 374, y: arrowY))
path.line(to: NSPoint(x: 358, y: arrowY - 13))
col(1, 1, 1, 0.35).setStroke()
path.stroke()

ctx.flushGraphics()
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath) (\(Int(W))x\(Int(H)))")
