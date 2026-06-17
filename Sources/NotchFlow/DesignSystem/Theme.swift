//
//  Theme.swift
//  NotchFlow
//
//  Central design tokens. The "island" itself is always rendered on a very dark
//  material so it blends with the physical notch bezel (just like the iPhone
//  Dynamic Island, which is always black). Light/Dark mode is fully respected in
//  the Settings window and in any tint/secondary colours.
//

import SwiftUI

enum Theme {

    // MARK: - Colours

    enum Colors {
        /// The island body. Near-black with a hint of warmth so it reads as a
        /// surface rather than a void, while still merging with the bezel.
        static let islandBackground = Color(red: 0.04, green: 0.04, blue: 0.05)

        /// A subtle top highlight used to give the island a glassy edge.
        static let islandHighlight = Color.white.opacity(0.06)

        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.62)
        static let tertiaryText = Color.white.opacity(0.40)

        /// Control surfaces (buttons) on the dark island.
        static let controlSurface = Color.white.opacity(0.08)
        static let controlSurfaceHover = Color.white.opacity(0.16)

        static let progressTrack = Color.white.opacity(0.16)
        static let progressFill = Color.white.opacity(0.92)

        /// Default accent when no album-art colour is available (Apple system blue).
        static let fallbackAccent = Color(red: 0.04, green: 0.52, blue: 1.0)
    }

    // MARK: - Metrics

    enum Metrics {
        /// Concave radius where the island flares out to meet the screen bezel.
        static let topFlareRadius: CGFloat = 9

        /// Convex radius of the island's bottom corners.
        static let collapsedBottomRadius: CGFloat = 10
        static let expandedBottomRadius: CGFloat = 20

        /// Horizontal breathing room around content inside the expanded panel.
        static let expandedHPadding: CGFloat = 18
        static let expandedVPadding: CGFloat = 16
        static let menuBarDockOverlap: CGFloat = 2

        static let albumArtSize: CGFloat = 92
        static let albumArtCornerRadius: CGFloat = 12

        static let controlButtonSize: CGFloat = 34
        static let controlIconSize: CGFloat = 14

        /// Default expanded panel size for the Spotify player.
        static let expandedSize = CGSize(width: 420, height: 176)

        /// Transient "peek" pill shown on track change.
        static let peekSize = CGSize(width: 280, height: 44)

        /// Fallback compact pill for Macs without a notch.
        static let fallbackCompactSize = CGSize(width: 150, height: 30)
    }

    // MARK: - Shadows

    enum Shadow {
        static let expandedColor = Color.black.opacity(0.45)
        static let expandedRadius: CGFloat = 22
        static let expandedY: CGFloat = 12
    }

    // MARK: - Typography

    enum Typography {
        static let trackTitle = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let artist = Font.system(size: 13, weight: .regular, design: .rounded)
        static let timecode = Font.system(size: 10, weight: .medium, design: .rounded).monospacedDigit()
        static let peekTitle = Font.system(size: 12, weight: .semibold, design: .rounded)
    }
}
