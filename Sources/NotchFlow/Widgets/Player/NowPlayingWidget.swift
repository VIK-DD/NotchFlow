//
//  NowPlayingWidget.swift
//  NotchFlow
//
//  Universal media widget (MediaRemote-backed). Surfaces any app's playback —
//  Spotify, Apple Music, YouTube in a browser, etc. — and shows a persistent
//  now-playing indicator in the idle notch, just like iPhone's Dynamic Island.
//

import SwiftUI
import Combine

@MainActor
final class NowPlayingWidget: NotchWidget {

    let metadata = WidgetMetadata(
        id: "com.notchflow.widget.nowplaying",
        displayName: "Now Playing",
        symbol: "play.circle.fill",
        priority: 100,
        preferredExpandedSize: Theme.Metrics.expandedSize
    )

    private let viewModel: NowPlayingViewModel

    init(viewModel: NowPlayingViewModel) {
        self.viewModel = viewModel
    }

    var hasLiveContent: Bool { viewModel.isAvailable && viewModel.item.hasContent }

    var events: AnyPublisher<WidgetEvent, Never> {
        viewModel.events.eraseToAnyPublisher()
    }

    func activate(context: WidgetContext) { viewModel.start() }
    func deactivate() { viewModel.stop() }

    func notchDidChangeOpenState(_ isOpen: Bool) {
        viewModel.setExpanded(isOpen)
    }

    /// Persistent flanks while something is playing; blend with the bezel otherwise.
    func collapsedSize(for metrics: ScreenMetrics) -> CGSize? {
        guard hasLiveContent else { return nil }
        if metrics.hasNotch {
            // Album art + equalizer hugging each side of the camera housing.
            let flank: CGFloat = 64
            return CGSize(width: metrics.notchSize.width + flank * 2,
                          height: metrics.notchSize.height)
        } else {
            // No notch: a small inline pill.
            return CGSize(width: 188, height: max(metrics.notchSize.height, 30))
        }
    }

    func makeCompactView() -> AnyView { AnyView(PlayerCompactView(viewModel: viewModel)) }
    func makePeekView() -> AnyView { AnyView(PlayerPeekView(viewModel: viewModel)) }
    func makeExpandedView() -> AnyView { AnyView(NowPlayingView(viewModel: viewModel)) }
}
