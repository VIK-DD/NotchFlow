//
//  ScreenMetrics.swift
//  NotchFlow
//
//  Detects the physical notch on a given screen and derives the geometry the
//  overlay needs. Gracefully falls back to a top-centre pill on Macs (or external
//  displays) without a notch.
//

import AppKit

struct ScreenMetrics {

    let screen: NSScreen
    let hasNotch: Bool
    /// Size of the physical notch (or the synthetic fallback pill area).
    let notchSize: CGSize

    init(screen: NSScreen) {
        self.screen = screen

        let safeTop = screen.safeAreaInsets.top
        if safeTop > 0,
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            // The notch width is whatever the menu-bar areas don't cover.
            let notchWidth = screen.frame.width - left.width - right.width
            self.hasNotch = true
            self.notchSize = CGSize(width: max(notchWidth, 120), height: safeTop)
        } else {
            self.hasNotch = false
            self.notchSize = Theme.Metrics.fallbackCompactSize
        }
    }

    // MARK: - Window geometry

    /// The overlay window is a fixed region near the top-centre, sized large
    /// enough to contain the fully expanded panel (plus margin for shadow and
    /// spring overshoot). The island is laid out top-anchored inside it; only the
    /// island itself is interactive — everything else passes mouse events through.
    var windowSize: CGSize {
        let expanded = Theme.Metrics.expandedSize
        return CGSize(
            width: max(expanded.width, notchSize.width) + 120,
            height: expanded.height + notchSize.height + 80
        )
    }

    /// Frame (in screen coordinates, bottom-left origin) for the overlay window:
    /// horizontally centred and visually docked to the menu bar.
    var windowFrame: CGRect {
        let size = windowSize
        let originX = screen.frame.midX - size.width / 2
        let menuBarHeight = max(0, screen.frame.maxY - screen.visibleFrame.maxY)
        let overlap = menuBarHeight > 0 ? Theme.Metrics.menuBarDockOverlap : 0
        let originY = screen.frame.maxY - size.height - menuBarHeight + overlap
        return CGRect(x: originX, y: originY, width: size.width, height: size.height)
    }

    /// Collapsed island size — matches the notch so it disappears into the bezel.
    var collapsedSize: CGSize { notchSize }
}
