//
//  make_shots.swift
//  Renders polished promo screenshots of NotchFlow's states (CoreGraphics, no deps).
//  Usage: swift tools/make_shots.swift <out-dir>
//

import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs/screenshots"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// MARK: - Helpers

func C(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(deviceRed: r, green: g, blue: b, alpha: a)
}
// top-left → bitmap bottom-left, within a canvas of height H
func image(_ w: CGFloat, _ h: CGFloat, _ name: String, draw: (CGContext, CGFloat) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(w), pixelsHigh: Int(h),
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                              colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    draw(ctx.cgContext, h)
    ctx.flushGraphics()
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    print("wrote \(outDir)/\(name)")
}

func text(_ s: String, _ x: CGFloat, _ yTop: CGFloat, H: CGFloat, size: CGFloat,
          weight: NSFont.Weight = .regular, color: NSColor, align: NSTextAlignment = .left,
          width: CGFloat = 4000) {
    let p = NSMutableParagraphStyle(); p.alignment = align
    let a = NSAttributedString(string: s, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color, .paragraphStyle: p
    ])
    a.draw(in: NSRect(x: x, y: H - yTop - size * 1.3, width: width, height: size * 1.4))
}

func roundRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r)
}

// Island shape: square top (flush to bezel), rounded bottom. yTop = top edge from canvas top.
func islandPath(cx: CGFloat, yTop: CGFloat, w: CGFloat, h: CGFloat, br: CGFloat, H: CGFloat) -> NSBezierPath {
    let x = cx - w / 2
    let top = H - yTop          // bottom-left coords: top edge
    let bottom = top - h
    let p = NSBezierPath()
    p.move(to: NSPoint(x: x, y: top))
    p.line(to: NSPoint(x: x, y: bottom + br))
    p.appendArc(withCenter: NSPoint(x: x + br, y: bottom + br), radius: br, startAngle: 180, endAngle: 270)
    p.line(to: NSPoint(x: x + w - br, y: bottom))
    p.appendArc(withCenter: NSPoint(x: x + w - br, y: bottom + br), radius: br, startAngle: 270, endAngle: 360)
    p.line(to: NSPoint(x: x + w, y: top))
    p.close()
    return p
}

func albumArt(_ x: CGFloat, _ yTop: CGFloat, _ s: CGFloat, H: CGFloat) {
    let y = H - yTop - s
    let clip = roundRect(x, y, s, s, s * 0.18); clip.addClip()
    NSGradient(colors: [C(0.40, 0.55, 1.0), C(0.30, 0.85, 0.78)])!
        .draw(in: NSRect(x: x, y: y, width: s, height: s), angle: -45)
    let note = NSAttributedString(string: "♪", attributes: [
        .font: NSFont.systemFont(ofSize: s * 0.42, weight: .bold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.92)])
    note.draw(at: NSPoint(x: x + s * 0.28, y: y + s * 0.22))
    NSGraphicsContext.current?.cgContext.resetClip()
}

func equalizer(_ x: CGFloat, _ yMidTop: CGFloat, H: CGFloat, color: NSColor, scale: CGFloat = 1) {
    let heights: [CGFloat] = [16, 30, 12, 24].map { $0 * scale }
    let bw: CGFloat = 5 * scale, gap: CGFloat = 5 * scale
    var bx = x
    let midY = H - yMidTop
    for hgt in heights {
        roundRect(bx, midY - hgt / 2, bw, hgt, bw / 2).fill()
        bx += bw + gap
    }
}

// Transport glyphs
func playGlyph(_ cx: CGFloat, _ cyTop: CGFloat, _ s: CGFloat, H: CGFloat, color: NSColor) {
    let cy = H - cyTop
    color.setFill()
    let p = NSBezierPath()
    p.move(to: NSPoint(x: cx - s * 0.32, y: cy + s * 0.5))
    p.line(to: NSPoint(x: cx - s * 0.32, y: cy - s * 0.5))
    p.line(to: NSPoint(x: cx + s * 0.5, y: cy))
    p.close(); p.fill()
}
func pauseGlyph(_ cx: CGFloat, _ cyTop: CGFloat, _ s: CGFloat, H: CGFloat, color: NSColor) {
    let cy = H - cyTop; color.setFill()
    let bw = s * 0.26
    roundRect(cx - s * 0.34, cy - s * 0.5, bw, s, bw * 0.4).fill()
    roundRect(cx + s * 0.08, cy - s * 0.5, bw, s, bw * 0.4).fill()
}
func skipGlyph(_ cx: CGFloat, _ cyTop: CGFloat, _ s: CGFloat, H: CGFloat, color: NSColor, forward: Bool) {
    let cy = H - cyTop; color.setFill()
    let dir: CGFloat = forward ? 1 : -1
    for i in 0..<2 {
        let ox = cx + dir * (CGFloat(i) * s * 0.42 - s * 0.28)
        let p = NSBezierPath()
        p.move(to: NSPoint(x: ox - dir * s * 0.28, y: cy + s * 0.42))
        p.line(to: NSPoint(x: ox - dir * s * 0.28, y: cy - s * 0.42))
        p.line(to: NSPoint(x: ox + dir * s * 0.30, y: cy))
        p.close(); p.fill()
    }
    roundRect(cx + dir * s * 0.46 - 2, cy - s * 0.42, 4, s * 0.84, 2).fill()
}

// MARK: - Scene chrome

func backdrop(_ cg: CGContext, _ w: CGFloat, _ h: CGFloat) {
    NSGradient(colors: [C(0.16, 0.18, 0.32), C(0.10, 0.10, 0.20), C(0.18, 0.12, 0.26)])!
        .draw(in: NSRect(x: 0, y: 0, width: w, height: h), angle: -60)
    // soft glow blobs
    for (bx, by, br, col) in [(w * 0.25, h * 0.7, w * 0.5, C(0.35, 0.45, 0.95, 0.25)),
                              (w * 0.8, h * 0.35, w * 0.45, C(0.30, 0.80, 0.75, 0.18))] {
        NSGradient(colors: [col, col.withAlphaComponent(0)])!
            .draw(in: NSRect(x: bx - br/2, y: by - br/2, width: br, height: br),
                  relativeCenterPosition: NSPoint(x: 0, y: 0))
    }
}

func menuBar(_ w: CGFloat, H: CGFloat, barH: CGFloat) {
    C(0, 0, 0, 0.30).setFill()
    NSRect(x: 0, y: H - barH, width: w, height: barH).fill()
    text("", 18, (barH - 15) / 2, H: H, size: 15, weight: .bold, color: C(1,1,1,0.9))
    text("Finder", 46, (barH - 13) / 2, H: H, size: 13, weight: .semibold, color: C(1,1,1,0.85))
    text("File   Edit   View   Go", 110, (barH - 12) / 2 + 1, H: H, size: 12, color: C(1,1,1,0.6))
    text("100%   Fri 9:41", w - 150, (barH - 12) / 2 + 1, H: H, size: 12, color: C(1,1,1,0.75))
}

func speakerGlyph(_ x: CGFloat, _ yMidTop: CGFloat, _ s: CGFloat, H: CGFloat, color: NSColor) {
    let cy = H - yMidTop
    color.setFill()
    let p = NSBezierPath()
    p.move(to: NSPoint(x: x, y: cy - s * 0.18))
    p.line(to: NSPoint(x: x + s * 0.22, y: cy - s * 0.18))
    p.line(to: NSPoint(x: x + s * 0.5, y: cy - s * 0.42))
    p.line(to: NSPoint(x: x + s * 0.5, y: cy + s * 0.42))
    p.line(to: NSPoint(x: x + s * 0.22, y: cy + s * 0.18))
    p.line(to: NSPoint(x: x, y: cy + s * 0.18))
    p.close(); p.fill()
    let wave = NSBezierPath()
    wave.appendArc(withCenter: NSPoint(x: x + s * 0.5, y: cy), radius: s * 0.55, startAngle: -32, endAngle: 32)
    color.setStroke(); wave.lineWidth = s * 0.11; wave.stroke()
}

func notchHardware(cx: CGFloat, w: CGFloat, h: CGFloat, H: CGFloat) {
    C(0, 0, 0, 1).setFill()
    islandPath(cx: cx, yTop: 0, w: w, h: h, br: h * 0.42, H: H).fill()
}

// Expanded player content inside an island of given geometry.
func expandedPlayer(cx: CGFloat, yTop: CGFloat, w: CGFloat, h: CGFloat, H: CGFloat, notchH: CGFloat) {
    let pad: CGFloat = 26
    let contentTop = yTop + notchH + 6
    let artS = h - notchH - pad - 14
    let left = cx - w / 2 + pad
    albumArt(left, contentTop, artS, H: H)

    let tx = left + artS + 22
    text("Blinding Lights", tx, contentTop + 2, H: H, size: 21, weight: .bold, color: .white)
    text("The Weeknd", tx, contentTop + 30, H: H, size: 16, color: C(1,1,1,0.6))

    // progress
    let barY = contentTop + 64
    let barW = (cx + w / 2 - pad) - tx
    C(1,1,1,0.18).setFill(); roundRect(tx, H - barY - 5, barW, 5, 2.5).fill()
    C(1,1,1,0.95).setFill(); roundRect(tx, H - barY - 5, barW * 0.42, 5, 2.5).fill()
    text("1:24", tx, barY + 8, H: H, size: 12, color: C(1,1,1,0.45))
    text("-2:01", tx + barW - 60, barY + 8, H: H, size: 12, color: C(1,1,1,0.45), align: .right, width: 60)

    // controls
    let cY = contentTop + 104
    let acc = C(1,1,1,0.9)
    skipGlyph(tx + 16, cY, 16, H: H, color: acc, forward: false)
    pauseGlyph(tx + 70, cY, 22, H: H, color: .white)
    skipGlyph(tx + 124, cY, 16, H: H, color: acc, forward: true)
    // volume
    let vol = cx + w/2 - pad - 100
    speakerGlyph(vol - 24, cY, 14, H: H, color: C(1,1,1,0.6))
    C(1,1,1,0.18).setFill(); roundRect(vol, H - cY - 2.5, 100, 5, 2.5).fill()
    C(1,1,1,0.7).setFill(); roundRect(vol, H - cY - 2.5, 64, 5, 2.5).fill()
}

// MARK: - Shots

let mbH: CGFloat = 38
let notchW: CGFloat = 230
let notchH: CGFloat = mbH

// 1) Banner / hero — desktop with the expanded player open under the notch.
image(1600, 1000, "banner.png") { cg, H in
    backdrop(cg, 1600, 1000)
    let cx: CGFloat = 800
    menuBar(1600, H: H, barH: mbH)
    let pw: CGFloat = 560, ph: CGFloat = 250
    // island body
    C(0.03, 0.03, 0.05, 1).setFill()
    islandPath(cx: cx, yTop: 0, w: pw, h: ph, br: 30, H: H).fill()
    notchHardware(cx: cx, w: notchW, h: notchH, H: H)
    expandedPlayer(cx: cx, yTop: 0, w: pw, h: ph, H: H, notchH: notchH)
    // wordmark lower
    text("NotchFlow", 0, 760, H: H, size: 64, weight: .bold, color: .white, align: .center, width: 1600)
    text("A Dynamic Island for your Mac", 0, 840, H: H, size: 24, weight: .regular, color: C(1,1,1,0.6), align: .center, width: 1600)
}

// 2) Expanded close-up
image(1200, 520, "expanded.png") { cg, H in
    backdrop(cg, 1200, 520)
    let cx: CGFloat = 600
    menuBar(1200, H: H, barH: mbH)
    let pw: CGFloat = 580, ph: CGFloat = 250
    C(0.03, 0.03, 0.05, 1).setFill()
    islandPath(cx: cx, yTop: 0, w: pw, h: ph, br: 30, H: H).fill()
    notchHardware(cx: cx, w: notchW, h: notchH, H: H)
    expandedPlayer(cx: cx, yTop: 0, w: pw, h: ph, H: H, notchH: notchH)
}

// 3) Idle — persistent flanks around the notch
image(1200, 360, "idle.png") { cg, H in
    backdrop(cg, 1200, 360)
    let cx: CGFloat = 600
    menuBar(1200, H: H, barH: mbH)
    let pw = notchW + 150
    C(0.03, 0.03, 0.05, 1).setFill()
    islandPath(cx: cx, yTop: 0, w: pw, h: notchH, br: notchH * 0.42, H: H).fill()
    notchHardware(cx: cx, w: notchW, h: notchH, H: H)
    albumArt(cx - pw/2 + 14, 8, notchH - 16, H: H)
    NSColor.white.setFill()
    equalizer(cx + pw/2 - 50, mbH/2, H: H, color: C(0.40, 0.85, 0.78))
    text("Persistent now-playing — album art + live equalizer, just like iPhone",
         0, 230, H: H, size: 20, weight: .medium, color: C(1,1,1,0.65), align: .center, width: 1200)
}

// 4) Peek — track change glance
image(1200, 420, "peek.png") { cg, H in
    backdrop(cg, 1200, 420)
    let cx: CGFloat = 600
    menuBar(1200, H: H, barH: mbH)
    let pw = notchW + 260, ph = notchH + 56
    C(0.03, 0.03, 0.05, 1).setFill()
    islandPath(cx: cx, yTop: 0, w: pw, h: ph, br: 26, H: H).fill()
    notchHardware(cx: cx, w: notchW, h: notchH, H: H)
    albumArt(cx - pw/2 + 18, 7, notchH - 14, H: H)
    equalizer(cx + pw/2 - 54, mbH/2, H: H, color: C(0.40, 0.85, 0.78))
    text("Now Playing", 0, mbH + 10, H: H, size: 16, weight: .semibold, color: .white, align: .center, width: 1200)
    text("The Weeknd — Blinding Lights", 0, mbH + 32, H: H, size: 13, color: C(1,1,1,0.6), align: .center, width: 1200)
    text("A quick glance when the track changes", 0, 300, H: H, size: 20, weight: .medium, color: C(1,1,1,0.65), align: .center, width: 1200)
}
