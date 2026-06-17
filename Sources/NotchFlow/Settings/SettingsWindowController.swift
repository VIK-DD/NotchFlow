//
//  SettingsWindowController.swift
//  NotchFlow
//
//  Hosts the SwiftUI Settings view in a standard titled window. We manage it in
//  AppKit (rather than a SwiftUI `Settings` scene) because the app runs without
//  the SwiftUI App lifecycle.
//

import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {

    init(environment: AppEnvironment) {
        let view = SettingsView(
            settings: environment.settings,
            registry: environment.widgetRegistry
        )
        let hosting = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hosting)
        window.title = "NotchFlow Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
    }
}
