//
//  make_icon.swift
//  Draws the NotchFlow app icon (1024×1024 PNG) with CoreGraphics — no deps.
//  A dark squircle (transparent corners) with a top notch (green dot + camera)
//  and a centered pill framing a misty mountain range. Usage:
//    swift tools/make_icon.swift <out.png>
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

func col(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(deviceRed: r, green: g, blue: b, alpha: a)
}
func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r)
}

// --- Squircle body (transparent outside → proper macOS icon) ---
let corner = S * 0.2237
let body = rrect(0, 0, S, S, corner)
cg.saveGState()
body.addClip()
NSGradient(colors: [col(0.10, 0.10, 0.12), col(0.05, 0.05, 0.07)])!
    .draw(in: NSRect(x: 0, y: 0, width: S, height: S), angle: -90)
NSGradient(colors: [col(1, 1, 1, 0.07), col(1, 1, 1, 0)])!
    .draw(in: NSRect(x: 0, y: S * 0.55, width: S, height: S * 0.45), angle: -90)

// --- Center pill with a mountain range ---
let pillW: CGFloat = 660, pillH: CGFloat = 258
let pillX = (S - pillW) / 2, pillY = S * 0.40
let pill = rrect(pillX, pillY, pillW, pillH, pillH / 2)

cg.saveGState()
pill.addClip()
NSGradient(colors: [col(0.17, 0.21, 0.33), col(0.09, 0.11, 0.19)])!
    .draw(in: NSRect(x: pillX, y: pillY, width: pillW, height: pillH), angle: -90)

func ridge(baseY: CGFloat, heights: [CGFloat], color: NSColor) {
    let n = heights.count
    let step = pillW / CGFloat(n - 1)
    let p = NSBezierPath()
    p.move(to: NSPoint(x: pillX, y: pillY))
    p.line(to: NSPoint(x: pillX, y: baseY + heights[0]))
    for i in 1..<n {
        let px = pillX + step * CGFloat(i)
        let cx = pillX + step * (CGFloat(i) - 0.5)
        let ctrlY = baseY + max(heights[i - 1], heights[i]) + 26
        p.curve(to: NSPoint(x: px, y: baseY + heights[i]),
                controlPoint1: NSPoint(x: cx, y: ctrlY),
                controlPoint2: NSPoint(x: cx, y: ctrlY))
    }
    p.line(to: NSPoint(x: pillX + pillW, y: pillY))
    p.close()
    color.setFill(); p.fill()
}
ridge(baseY: pillY + 20, heights: [120, 165, 95, 150, 110], color: col(0.27, 0.32, 0.46))
ridge(baseY: pillY,      heights: [70, 130, 60, 120, 80],   color: col(0.18, 0.22, 0.34))
ridge(baseY: pillY - 10, heights: [30, 70, 40, 95, 45],     color: col(0.11, 0.14, 0.23))
cg.restoreGState()

col(1, 1, 1, 0.10).setStroke(); pill.lineWidth = 2; pill.stroke()

// --- Top notch (green dot + camera) ---
let nW: CGFloat = 392, nH: CGFloat = 116
let nX = (S - nW) / 2
let nTop = S - S * 0.085           // a little below the icon top
let notch = NSBezierPath()
notch.move(to: NSPoint(x: nX, y: nTop))
notch.line(to: NSPoint(x: nX, y: nTop - nH + 34))
notch.appendArc(withCenter: NSPoint(x: nX + 34, y: nTop - nH + 34), radius: 34, startAngle: 180, endAngle: 270)
notch.line(to: NSPoint(x: nX + nW - 34, y: nTop - nH))
notch.appendArc(withCenter: NSPoint(x: nX + nW - 34, y: nTop - nH + 34), radius: 34, startAngle: 270, endAngle: 360)
notch.line(to: NSPoint(x: nX + nW, y: nTop))
notch.close()
col(0.02, 0.02, 0.03, 1).setFill(); notch.fill()

let camY = nTop - nH / 2 + 6
// green status dot
NSBezierPath(ovalIn: NSRect(x: nX + nW * 0.30 - 15, y: camY - 15, width: 30, height: 30)).fill(col(0.20, 0.80, 0.35))
// camera lens
NSBezierPath(ovalIn: NSRect(x: nX + nW * 0.62 - 19, y: camY - 19, width: 38, height: 38)).fill(col(0.10, 0.12, 0.16))
NSBezierPath(ovalIn: NSRect(x: nX + nW * 0.62 - 9, y: camY - 9 + 4, width: 18, height: 18)).fill(col(0.20, 0.28, 0.42))
NSBezierPath(ovalIn: NSRect(x: nX + nW * 0.62 - 4, y: camY + 2, width: 7, height: 7)).fill(col(0.55, 0.70, 0.95, 0.9))

cg.restoreGState()

// --- Outer rim highlight ---
col(1, 1, 1, 0.06).setStroke(); body.lineWidth = 3; body.stroke()

ctx.flushGraphics()
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")

extension NSBezierPath { func fill(_ c: NSColor) { c.setFill(); self.fill() } }
