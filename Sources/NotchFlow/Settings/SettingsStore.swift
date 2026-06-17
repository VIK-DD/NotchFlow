//
//  SettingsStore.swift
//  NotchFlow
//
//  UserDefaults-backed, observable preferences. Property observers persist on
//  change (and are intentionally NOT fired during init, per Swift semantics).
//

import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {

    private enum Key {
        static let pollInterval = "pollInterval"
        static let expandOnTrackChange = "expandOnTrackChange"
        static let reactToWidgetEvents = "reactToWidgetEvents"
        static let useAlbumAccent = "useAlbumAccent"
        static let idleOpacity = "NotchIdleOpacity"
        static let hideDelay = "NotchHideDelay"
        static let alwaysShowOnDesktop = "NotchAlwaysShowOnDesktop"
    }

    private let defaults = UserDefaults.standard

    // MARK: Preferences

    /// Seconds between Spotify polls while idle. 0.5...3.0.
    @Published var pollInterval: TimeInterval {
        didSet { defaults.set(pollInterval, forKey: Key.pollInterval) }
    }

    /// Briefly expand the notch when the track changes.
    @Published var expandOnTrackChange: Bool {
        didSet { defaults.set(expandOnTrackChange, forKey: Key.expandOnTrackChange) }
    }

    /// Master switch for widget-driven auto-peek/expand.
    @Published var reactToWidgetEvents: Bool {
        didSet { defaults.set(reactToWidgetEvents, forKey: Key.reactToWidgetEvents) }
    }

    /// Tint the UI with a colour sampled from the album art.
    @Published var useAlbumAccent: Bool {
        didSet { defaults.set(useAlbumAccent, forKey: Key.useAlbumAccent) }
    }

    /// Opacity of the notch when idle and not hovered (0 to 100).
    @Published var idleOpacity: Double {
        didSet { defaults.set(idleOpacity, forKey: Key.idleOpacity) }
    }

    /// Delay in seconds before the notch hides when idle.
    @Published var hideDelay: TimeInterval {
        didSet { defaults.set(hideDelay, forKey: Key.hideDelay) }
    }

    /// Keep the notch visible when the Desktop (Finder) is active.
    @Published var alwaysShowOnDesktop: Bool {
        didSet { defaults.set(alwaysShowOnDesktop, forKey: Key.alwaysShowOnDesktop) }
    }

    /// Launch-at-login is stored by the system, not UserDefaults.
    @Published var launchAtLogin: Bool {
        didSet { LaunchAtLogin.isEnabled = launchAtLogin }
    }

    // MARK: Init

    init() {
        defaults.register(defaults: [
            Key.pollInterval: 1.0,
            Key.expandOnTrackChange: true,
            Key.reactToWidgetEvents: true,
            Key.useAlbumAccent: true,
            Key.idleOpacity: 100.0,
            Key.hideDelay: 2.0,
            Key.alwaysShowOnDesktop: true
        ])
        pollInterval = defaults.double(forKey: Key.pollInterval)
        expandOnTrackChange = defaults.bool(forKey: Key.expandOnTrackChange)
        reactToWidgetEvents = defaults.bool(forKey: Key.reactToWidgetEvents)
        useAlbumAccent = defaults.bool(forKey: Key.useAlbumAccent)
        idleOpacity = defaults.double(forKey: Key.idleOpacity)
        hideDelay = defaults.double(forKey: Key.hideDelay)
        alwaysShowOnDesktop = defaults.bool(forKey: Key.alwaysShowOnDesktop)
        launchAtLogin = LaunchAtLogin.isEnabled
    }
}
