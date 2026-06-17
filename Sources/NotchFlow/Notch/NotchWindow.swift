//
//  NotchWindow.swift
//  NotchFlow
//
//  A borderless, non-activating panel that floats above the menu bar so it can
//  draw over the physical notch. It never steals focus from the user's frontmost
//  app.
//

import AppKit

final class NotchWindow: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .statusBar               // above the menu bar / notch region
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false                // the island draws its own soft shadow
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        ignoresMouseEvents = false

        // Stay put across spaces and over fullscreen apps; never cycle with ⌘`.
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
    }

    // Allow controls inside (sliders, buttons) to interact without activating.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
