//
//  NotchContainerView.swift
//  NotchFlow
//
//  The bridge between the borderless window and the SwiftUI island. It does two
//  jobs AppKit is better at than SwiftUI here:
//
//   1. Hit-test pass-through — only the island's current rect is interactive;
//      clicks anywhere else fall through to whatever is behind (menu bar, apps).
//   2. Hosts the interactive CGPath region that the NotchWindowController polls 
//      to determine hover state without requiring Accessibility permissions.
//
//  Uses a flipped coordinate system so the island anchors to the *top* (y == 0).
//

import AppKit
import SwiftUI

final class NotchContainerView: NSView {

    /// Current interactive rect (top-centred), in this view's flipped coords.
    private var interactiveRect: CGRect = .zero
    private var interactivePath: CGPath?
    private var interactiveBottomRadius: CGFloat = 0

    override var isFlipped: Bool { true }

    // Act on the very first click even though the app is a non-activating
    // accessory — otherwise the first tap would just be swallowed by activation.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: - Interactive region

    /// Update the interactive island rect from the SwiftUI island size.
    func updateInteractiveRegion(_ size: CGSize, bottomRadius: CGFloat) {
        let rect = CGRect(
            x: (bounds.width - size.width) / 2,
            y: 0,
            width: size.width,
            height: size.height
        )
        guard rect != interactiveRect || interactivePath == nil || interactiveBottomRadius != bottomRadius else { return }
        interactiveRect = rect
        interactiveBottomRadius = bottomRadius
        interactivePath = Self.makeInteractivePath(in: rect, bottomRadius: bottomRadius)
    }

    // MARK: - Hit testing (pass-through)

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard containsInteractivePoint(point) else { return nil }
        return super.hitTest(point)
    }

    func containsInteractivePoint(_ point: NSPoint) -> Bool {
        guard interactiveRect.contains(point) else { return false }
        return interactivePath?.contains(point) ?? true
    }

    private static func makeInteractivePath(in rect: CGRect, bottomRadius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        guard !rect.isEmpty else { return path }

        let tr = min(Theme.Metrics.topFlareRadius, rect.width / 2)
        let br = min(bottomRadius, (rect.width / 2) - tr, rect.height - tr)

        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY

        path.move(to: CGPoint(x: minX, y: minY))
        path.addQuadCurve(
            to: CGPoint(x: minX + tr, y: minY + tr),
            control: CGPoint(x: minX + tr, y: minY)
        )
        path.addLine(to: CGPoint(x: minX + tr, y: maxY - br))
        path.addQuadCurve(
            to: CGPoint(x: minX + tr + br, y: maxY),
            control: CGPoint(x: minX + tr, y: maxY)
        )
        path.addLine(to: CGPoint(x: maxX - tr - br, y: maxY))
        path.addQuadCurve(
            to: CGPoint(x: maxX - tr, y: maxY - br),
            control: CGPoint(x: maxX - tr, y: maxY)
        )
        path.addLine(to: CGPoint(x: maxX - tr, y: minY + tr))
        path.addQuadCurve(
            to: CGPoint(x: maxX, y: minY),
            control: CGPoint(x: maxX - tr, y: minY)
        )
        path.closeSubpath()
        return path
    }
}

/// Hosting view that also accepts the first click, so SwiftUI controls inside the
/// non-activating panel respond to a single tap (no "click once to focus, again
/// to act").
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
