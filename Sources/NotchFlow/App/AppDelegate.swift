//
//  AppDelegate.swift
//  NotchFlow
//
//  Owns the top-level object graph and the application lifecycle.
//

import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    /// Shared dependency container (services + view models).
    private let environment = AppEnvironment()

    /// Drives the floating notch panel.
    private var notchController: NotchWindowController?

    /// Optional standalone preferences window.
    private var settingsController: SettingsWindowController?

    /// Status-bar item — the only persistent affordance besides the notch itself.
    private var statusItem: NSStatusItem?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        environment.start()

        notchController = NotchWindowController(environment: environment)
        notchController?.show()

        setUpStatusItem()
        observeScreenChanges()
    }

    func applicationWillTerminate(_ notification: Notification) {
        environment.stop()
        notchController?.hide()
    }

    /// Re-opening from the status item (or Finder) surfaces preferences.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return true
    }

    // MARK: - Status Item

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.topthird.inset.filled",
                accessibilityDescription: "NotchFlow"
            )
            button.image?.isTemplate = true
            button.toolTip = "NotchFlow"
        }
        item.menu = makeMenu()
        statusItem = item
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let settings = NSMenuItem(
            title: "Preferences…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settings.target = self
        menu.addItem(settings)

        let toggleNotch = NSMenuItem(
            title: "Hide Notch Overlay",
            action: #selector(toggleNotchVisibility(_:)),
            keyEquivalent: ""
        )
        toggleNotch.target = self
        menu.addItem(toggleNotch)

        menu.addItem(.separator())

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let about = NSMenuItem(
            title: "About NotchFlow",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(
            title: "Quit NotchFlow",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)

        return menu
    }

    // MARK: - Actions

    @objc private func openSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(environment: environment)
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsController?.showWindow(nil)
    }

    @objc private func openAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "NotchFlow",
            .applicationVersion: AppInfo.version,
            .init(rawValue: "Copyright"): "A Dynamic Island for your Mac."
        ])
    }

    @objc private func toggleNotchVisibility(_ sender: NSMenuItem) {
        guard let controller = notchController else { return }
        if controller.isVisible {
            controller.hide()
            sender.title = "Show Notch Overlay"
        } else {
            controller.show()
            sender.title = "Hide Notch Overlay"
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newValue = !LaunchAtLogin.isEnabled
        LaunchAtLogin.isEnabled = newValue
        sender.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    // MARK: - Screen changes

    /// External display connect/disconnect, resolution changes, and waking from
    /// sleep can all move the notch. Re-anchor the panel when that happens.
    private func observeScreenChanges() {
        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.notchController?.repositionForCurrentScreen()
            }
            .store(in: &cancellables)
    }
}
