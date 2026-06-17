//
//  make_icon.swift
//  Draws the NotchFlow app icon (1024×1024 PNG) with CoreGraphics — no deps.
//  Usage: swift tools/make_icon.swift <out.png>
//

import AppKit

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/AppIcon.png"
let S: CGFloat = 1024

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("rep") }

let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
let cg = ctx.cgContext

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(deviceRed: r, green: g, blue: b, alpha: a)
}

// --- Squircle background (macOS icon corner radius ≈ 22.37%) ---
let corner: CGFloat = S * 0.2237
let bg = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: S, height: S),
                      xRadius: corner, yRadius: corner)
bg.addClip()

let grad = NSGradient(colors: [color(0.13, 0.13, 0.16), color(0.04, 0.04, 0.06)])!
grad.draw(in: NSRect(x: 0, y: 0, width: S, height: S), angle: -90)

// Soft top sheen
let sheen = NSGradient(colors: [color(1, 1, 1, 0.10), color(1, 1, 1, 0)])!
sheen.draw(in: NSRect(x: 0, y: S * 0.55, width: S, height: S * 0.45), angle: -90)

// --- Dynamic-Island pill (the app's signature shape) ---
let pillW: CGFloat = 600
let pillH: CGFloat = 188
let pillX = (S - pillW) / 2
let pillY = (S - pillH) / 2 + 24
let pill = NSBezierPath(roundedRect: NSRect(x: pillX, y: pillY, width: pillW, height: pillH),
                        xRadius: pillH / 2, yRadius: pillH / 2)
color(0, 0, 0, 1).setFill()
pill.fill()
// subtle glass rim
color(1, 1, 1, 0.08).setStroke()
pill.lineWidth = 2
pill.stroke()

// --- Album square (left inside pill) ---
let artSize: CGFloat = 120
let artX = pillX + 40
let artY = pillY + (pillH - artSize) / 2
let art = NSBezierPath(roundedRect: NSRect(x: artX, y: artY, width: artSize, height: artSize),
                       xRadius: 26, yRadius: 26)
let artGrad = NSGradient(colors: [color(0.40, 0.55, 1.0), color(0.30, 0.85, 0.78)])!
art.addClip()
artGrad.draw(in: NSRect(x: artX, y: artY, width: artSize, height: artSize), angle: -45)
// reset clip to pill region
NSGraphicsContext.current = ctx   // (clip is path-based; re-establish full bg clip)
cg.resetClip()
bg.addClip()

// music glyph on the art
let note = NSAttributedString(string: "♪", attributes: [
    .font: NSFont.systemFont(ofSize: 78, weight: .bold),
    .foregroundColor: NSColor.white.withAlphaComponent(0.92)
])
note.draw(at: NSPoint(x: artX + 34, y: artY + 14))

// --- Equalizer bars (right inside pill) ---
let barW: CGFloat = 22
let gap: CGFloat = 16
let heights: [CGFloat] = [70, 120, 54, 96]
let totalW = CGFloat(heights.count) * barW + CGFloat(heights.count - 1) * gap
var bx = pillX + pillW - 40 - totalW
let baseY = pillY + (pillH - 120) / 2
for h in heights {
    let bar = NSBezierPath(roundedRect: NSRect(x: bx, y: baseY + (120 - h) / 2, width: barW, height: h),
                           xRadius: barW / 2, yRadius: barW / 2)
    color(1, 1, 1, 0.95).setFill()
    bar.fill()
    bx += barW + gap
}

ctx.flushGraphics()

guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
