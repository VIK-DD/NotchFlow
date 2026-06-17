//
//  AppEnvironment.swift
//  NotchFlow
//
//  Lightweight dependency container. Constructs and owns the long-lived
//  services and view models, and registers the built-in widgets.
//
//  Adding a new widget later is a one-line registration here (see `registerWidgets`).
//

import Foundation
import Combine

@MainActor
final class AppEnvironment: ObservableObject {

    // MARK: Services

    let settings: SettingsStore
    let widgetRegistry: WidgetRegistry

    // MARK: Built-in widgets

    let nowPlaying: NowPlayingWidget

    // MARK: Init

    init() {
        let settings = SettingsStore()
        self.settings = settings
        self.widgetRegistry = WidgetRegistry()

        // --- Universal player (highest priority) ----------------------------
        // MediaRemote surfaces whatever app is playing: Spotify, Apple Music,
        // YouTube in a browser, etc. Volume maps to system output volume.
        let media = MediaRemoteController()
        let systemAudio = SystemAudio()
        let nowPlayingViewModel = NowPlayingViewModel(
            media: media,
            systemAudio: systemAudio,
            settings: settings
        )
        self.nowPlaying = NowPlayingWidget(viewModel: nowPlayingViewModel)

        registerWidgets()
    }

    /// Register every widget the notch can surface. Ordered by `priority`
    /// (higher wins when several widgets want attention at once).
    private func registerWidgets() {
        widgetRegistry.register(nowPlaying)

        // Future widgets plug in here, e.g.:
        //   widgetRegistry.register(CalendarWidget(...))
        //   widgetRegistry.register(BatteryWidget(...))
        //   widgetRegistry.register(WeatherWidget(...))
    }

    // MARK: Lifecycle

    func start() {
        widgetRegistry.activateAll(context: WidgetContext(settings: settings))
    }

    func stop() {
        widgetRegistry.deactivateAll()
    }
}

/// Static app metadata used in a couple of UI surfaces.
enum AppInfo {
    static let name = "NotchFlow"
    static let bundleIdentifier = "com.notchflow.NotchFlow"
    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
