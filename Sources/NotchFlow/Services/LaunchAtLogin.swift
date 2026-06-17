//
//  LaunchAtLogin.swift
//  NotchFlow
//
//  Launch-at-login that works across macOS versions:
//    • Ventura (13)+ : the modern `SMAppService.mainApp` API.
//    • Monterey (12) : a user LaunchAgent plist in ~/Library/LaunchAgents.
//
//  Intended to be used from the bundled .app (so the agent launches the app with
//  its Info.plist / LSUIElement behaviour). See scripts/make_app_bundle.sh.
//

import Foundation
import ServiceManagement

enum LaunchAtLogin {

    private static let label = AppInfo.bundleIdentifier

    private static var plistURL: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    // MARK: - Public

    static var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                return FileManager.default.fileExists(atPath: plistURL.path)
            }
        }
        set {
            if #available(macOS 13.0, *) {
                setModern(newValue)
            } else {
                setLegacy(newValue)
            }
        }
    }

    // MARK: - Ventura+

    @available(macOS 13.0, *)
    private static func setModern(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("[LaunchAtLogin] SMAppService failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Monterey

    private static func setLegacy(_ enabled: Bool) {
        // Use the modern `bootstrap`/`bootout` domain API. The legacy
        // `load -w` / `unload -w` is unreliable on Monterey+ (fails with EIO).
        let domain = "gui/\(getuid())"
        if enabled {
            writeLegacyPlist()
            // Remove any stale registration first so bootstrap can't conflict.
            runLaunchctl(["bootout", "\(domain)/\(label)"])
            runLaunchctl(["bootstrap", domain, plistURL.path])
        } else {
            runLaunchctl(["bootout", "\(domain)/\(label)"])
            try? FileManager.default.removeItem(at: plistURL)
        }
    }

    private static func writeLegacyPlist() {
        let executable = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executable],
            "RunAtLoad": true,
            "ProcessType": "Interactive"
        ]
        do {
            let dir = plistURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: plistURL)
        } catch {
            NSLog("[LaunchAtLogin] Could not write LaunchAgent: \(error.localizedDescription)")
        }
    }

    private static func runLaunchctl(_ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            NSLog("[LaunchAtLogin] launchctl \(arguments) failed: \(error.localizedDescription)")
        }
    }
}
