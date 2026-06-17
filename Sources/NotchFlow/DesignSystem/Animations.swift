//
//  Animations.swift
//  NotchFlow
//
//  Named spring presets tuned to feel like Apple's Dynamic Island. Keeping them
//  in one place makes the whole app's motion consistent and easy to retune.
//

import SwiftUI

extension Animation {

    /// The hero expand. A lively spring with a touch of overshoot.
    static let notchExpand = Animation.spring(response: 0.44, dampingFraction: 0.76, blendDuration: 0)

    /// Collapse is slightly calmer and more damped so it settles cleanly.
    static let notchCollapse = Animation.spring(response: 0.34, dampingFraction: 0.90, blendDuration: 0)

    /// Subtle hover scale / peek nudges.
    static let notchHover = Animation.spring(response: 0.28, dampingFraction: 0.78, blendDuration: 0)

    /// Cross-fading content (compact ⇄ expanded, track ⇄ track).
    static let contentTransition = Animation.easeInOut(duration: 0.20)

    /// Album-art swap on track change.
    static let artworkTransition = Animation.spring(response: 0.46, dampingFraction: 0.80, blendDuration: 0)

    /// Continuous, near-zero-cost progress advance (Core Animation interpolates).
    static func progressAdvance(over interval: TimeInterval) -> Animation {
        .linear(duration: interval)
    }
}

extension AnyTransition {
    /// Compact / peek / expanded swaps keep a little vertical momentum.
    static var islandContentSwap: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: 0.985, anchor: .top))
                .combined(with: .offset(y: 4)),
            removal: .opacity
                .combined(with: .scale(scale: 0.98, anchor: .top))
        )
    }

    /// Content swap used when a track changes: fade + a small vertical drift.
    static var trackChange: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .offset(y: 6))
                .combined(with: .scale(scale: 0.99, anchor: .center)),
            removal: .opacity.combined(with: .offset(y: -4))
        )
    }
}
