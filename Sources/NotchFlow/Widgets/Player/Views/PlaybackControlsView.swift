//
//  PlaybackControlsView.swift
//  NotchFlow
//

import SwiftUI

struct PlaybackControlsView: View {
    @ObservedObject var viewModel: NowPlayingViewModel

    var body: some View {
        HStack(spacing: 8) {
            ControlButton(symbol: "backward.fill", iconSize: 13) {
                viewModel.previous()
            }
            ControlButton(
                symbol: viewModel.isPlaying ? "pause.fill" : "play.fill",
                iconSize: 17,
                prominent: true
            ) {
                viewModel.togglePlayPause()
            }
            ControlButton(symbol: "forward.fill", iconSize: 13) {
                viewModel.next()
            }
        }
    }
}

/// A circular, hover-highlighting transport button. Press feedback comes from a
/// `ButtonStyle` (not a gesture) so a single tap always registers — important on
/// a non-activating panel.
struct ControlButton: View {
    let symbol: String
    var iconSize: CGFloat = 14
    var prominent: Bool = false
    let action: () -> Void

    @State private var hovering = false
    @GestureState private var pressing = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundColor(.white.opacity(prominent ? 1.0 : 0.82))
            .frame(width: Theme.Metrics.controlButtonSize, height: Theme.Metrics.controlButtonSize)
            .background(
                Circle()
                    .fill(Theme.Colors.controlSurface)
                    .opacity(hovering ? 1 : 0)
            )
            .contentShape(Circle())
            .scaleEffect(pressing ? 0.86 : (hovering ? 1.08 : 1.0))
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: pressing)
            .animation(.notchHover, value: hovering)
            .gesture(pressGesture)
        .onHover { hovering in
            withAnimation(.notchHover) { self.hovering = hovering }
        }
        // Force-clear hover state when the cursor leaves the island entirely.
        .onReceive(NotificationCenter.default.publisher(for: .notchHoverStatusChanged)) { notif in
            if let isGlobalHover = notif.object as? Bool, !isGlobalHover {
                withAnimation(.notchHover) { self.hovering = false }
            }
        }
        .accessibilityAddTraits(.isButton)
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($pressing) { value, state, _ in
                state = hitBounds.contains(value.location)
            }
            .onEnded { value in
                if hitBounds.contains(value.location) {
                    action()
                }
            }
    }

    private var hitBounds: CGRect {
        CGRect(origin: .zero, size: CGSize(
            width: Theme.Metrics.controlButtonSize,
            height: Theme.Metrics.controlButtonSize
        ))
    }
}
