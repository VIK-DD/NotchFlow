//
//  Widget.swift
//  NotchFlow
//
//  The plugin contract. Every feature surfaced in the notch — Spotify today,
//  Calendar / Weather / Battery / Pomodoro / AI tomorrow — is a `NotchWidget`.
//
//  A widget is responsible for:
//    • its own data + state (it is the source of truth),
//    • telling the host when it wants attention (peek / expand),
//    • vending three SwiftUI views: compact (idle), peek (transient), expanded.
//
//  The host (NotchViewModel) never needs to know what a widget *is* — only this
//  protocol. That keeps the notch shell and the widgets fully decoupled.
//

import SwiftUI
import Combine

/// Static description of a widget.
struct WidgetMetadata {
    let id: String
    let displayName: String
    /// SF Symbol used in settings / menus.
    let symbol: String
    /// Higher wins when several widgets are live at once.
    let priority: Int
    /// Size of the expanded panel this widget prefers.
    let preferredExpandedSize: CGSize
}

/// Things a widget can ask the notch to do, or tell it about.
enum WidgetEvent {
    /// "Something noteworthy happened" — briefly peek (auto-collapses).
    case requestPeek
    /// "Open me fully."
    case requestExpand
    /// "My live-content availability changed" — host re-evaluates what to show.
    case contentChanged
}

/// An event tagged with its originating widget.
struct WidgetEnvelope {
    let widgetID: String
    let event: WidgetEvent
}

/// Injected at activation. A grab-bag for shared services future widgets may need.
struct WidgetContext {
    let settings: SettingsStore
}

/// The plugin protocol. Widgets are UI objects, so the whole protocol is
/// main-actor isolated.
@MainActor
protocol NotchWidget: AnyObject {
    var metadata: WidgetMetadata { get }

    /// Whether the widget currently has something worth showing.
    var hasLiveContent: Bool { get }

    /// Attention requests + content-change notices.
    var events: AnyPublisher<WidgetEvent, Never> { get }

    func activate(context: WidgetContext)
    func deactivate()

    /// Notch opened/closed. Optional — widgets may use it to adjust refresh rate.
    func notchDidChangeOpenState(_ isOpen: Bool)

    /// The collapsed (idle) footprint the widget wants. Return `nil` to blend
    /// invisibly with the bezel; return a size to show a persistent indicator
    /// flanking the notch (e.g. now-playing album art + equalizer).
    func collapsedSize(for metrics: ScreenMetrics) -> CGSize?

    /// Idle representation that hugs the bezel (often empty / minimal).
    func makeCompactView() -> AnyView
    /// Transient pill shown on `.requestPeek`.
    func makePeekView() -> AnyView
    /// Full interactive panel.
    func makeExpandedView() -> AnyView
}

extension NotchWidget {
    func notchDidChangeOpenState(_ isOpen: Bool) {}
    func collapsedSize(for metrics: ScreenMetrics) -> CGSize? { nil }
}
