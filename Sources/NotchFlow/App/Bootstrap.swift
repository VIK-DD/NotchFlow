//
//  Bootstrap.swift
//  NotchFlow
//
//  Entry point. We boot AppKit directly (rather than the SwiftUI `App`
//  lifecycle) so we have full control over a borderless, non-activating panel
//  positioned over the physical notch.
//
//  The app runs as an "accessory" (agent) app: no Dock icon, no app menu — it
//  lives entirely in the notch plus a status-bar item.
//

import AppKit

@main
struct NotchFlowApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate                     // NSApplication.delegate is weak…
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) {            // …so keep it alive for the run loop.
            app.run()
        }
    }
}
