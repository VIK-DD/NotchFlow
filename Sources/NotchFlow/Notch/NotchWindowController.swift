//
//  NotchWindowController.swift
//  NotchFlow
//
//  Builds and positions the notch overlay: the panel, its SwiftUI content, the
//  hit-test/hover container, and the view model. Re-anchors on screen changes.
//

import AppKit
import SwiftUI
import Combine

@MainActor
final class NotchWindowController {

    private let environment: AppEnvironment
    private let viewModel: NotchViewModel

    private var window: NotchWindow?
    private var container: NotchContainerView?
    private var hostingView: FirstMouseHostingView<NotchRootView>?

    private var cancellables = Set<AnyCancellable>()
    private var pointerPoller: AnyCancellable?
    private var isCursorInsideIsland = false

    private var isDesktopActive = false
    private var fadeOutWorkItem: DispatchWorkItem?
    private var desktopWakeWorkItem: DispatchWorkItem?
    private var isDesktopWakeActive = false
    private var collapseAnimationWorkItem: DispatchWorkItem?
    private var isAnimatingCollapse = false
    private var ignoreMouseWorkItem: DispatchWorkItem?

    private(set) var isVisible = false

    init(environment: AppEnvironment) {
        self.environment = environment
        let metrics = ScreenMetrics(screen: Self.preferredScreen())
        self.viewModel = NotchViewModel(
            registry: environment.widgetRegistry,
            settings: environment.settings,
            metrics: metrics
        )
        build(with: metrics)
        bind()
    }

    // MARK: - Build

    private func build(with metrics: ScreenMetrics) {
        let window = NotchWindow(contentRect: metrics.windowFrame)

        let container = NotchContainerView(frame: CGRect(origin: .zero, size: metrics.windowSize))
        container.autoresizingMask = [.width, .height]

        let hosting = FirstMouseHostingView(rootView: NotchRootView(viewModel: viewModel))
        hosting.frame = container.bounds
        hosting.autoresizingMask = [.width, .height]
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = []
        }
        container.addSubview(hosting)

        window.contentView = container
        container.updateInteractiveRegion(
            viewModel.islandSize,
            bottomRadius: currentBottomRadius(for: viewModel.state)
        )
        window.ignoresMouseEvents = true

        self.window = window
        self.container = container
        self.hostingView = hosting
    }

    private func bind() {
        // Keep the interactive/hover region in sync with the animated island.
        Publishers.CombineLatest(viewModel.$islandSize, viewModel.$state)
            .receive(on: RunLoop.main)
            .sink { [weak self] size, state in
                self?.container?.updateInteractiveRegion(
                    size,
                    bottomRadius: self?.currentBottomRadius(for: state) ?? Theme.Metrics.expandedBottomRadius
                )
                self?.syncPointerInteractivity()
                
                // Prevent flicker / abrupt disappearance during the collapse animation.
                if state == .collapsed {
                    self?.isAnimatingCollapse = true
                    self?.collapseAnimationWorkItem?.cancel()
                    let item = DispatchWorkItem { [weak self] in
                        self?.isAnimatingCollapse = false
                        self?.evaluateVisibility()
                    }
                    self?.collapseAnimationWorkItem = item
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.30, execute: item)
                } else {
                    self?.isAnimatingCollapse = false
                    self?.collapseAnimationWorkItem?.cancel()
                }
                
                self?.evaluateVisibility()
            }
            .store(in: &cancellables)

        // Track the active app to detect when the Desktop (Finder) is frontmost.
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    let wasDesktop = self?.isDesktopActive ?? false
                    let isNowDesktop = (app.bundleIdentifier == "com.apple.finder")
                    self?.isDesktopActive = isNowDesktop
                    
                    if isNowDesktop && !wasDesktop {
                        self?.triggerDesktopWake()
                    } else {
                        self?.evaluateVisibility()
                    }
                }
            }
            .store(in: &cancellables)

        if let app = NSWorkspace.shared.frontmostApplication {
            self.isDesktopActive = (app.bundleIdentifier == "com.apple.finder")
        }

        // React to settings changes to update the window instantly.
        environment.settings.$idleOpacity
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.evaluateVisibility(immediateIdle: true) }
            .store(in: &cancellables)

        environment.settings.$hideDelay
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.evaluateVisibility(immediateIdle: false) }
            .store(in: &cancellables)

        environment.settings.$alwaysShowOnDesktop
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.evaluateVisibility(immediateIdle: false) }
            .store(in: &cancellables)
    }

    // MARK: - Visibility

    func show() {
        guard let window else { return }
        window.orderFrontRegardless()
        isVisible = true
        startPointerPolling()
        syncPointerInteractivity()
        evaluateVisibility()
    }

    func hide() {
        isVisible = false
        pointerPoller?.cancel()
        pointerPoller = nil
        window?.orderOut(nil)
    }

    // MARK: - Screen changes

    func repositionForCurrentScreen() {
        let metrics = ScreenMetrics(screen: Self.preferredScreen())
        viewModel.updateMetrics(metrics)
        window?.setFrame(metrics.windowFrame, display: true)
        container?.frame = CGRect(origin: .zero, size: metrics.windowSize)
        container?.updateInteractiveRegion(
            viewModel.islandSize,
            bottomRadius: currentBottomRadius(for: viewModel.state)
        )
        syncPointerInteractivity()
    }

    // MARK: - Screen selection

    /// Prefer the built-in display that actually has a notch; otherwise the main
    /// screen (where a top-centre fallback pill is shown).
    private static func preferredScreen() -> NSScreen {
        if let notched = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            return notched
        }
        // A running GUI app always has at least one screen.
        return NSScreen.main ?? NSScreen.screens[0]
    }

    private func currentBottomRadius(for state: NotchState) -> CGFloat {
        state == .collapsed
            ? Theme.Metrics.collapsedBottomRadius
            : Theme.Metrics.expandedBottomRadius
    }

    private func startPointerPolling() {
        guard pointerPoller == nil else { return }
        pointerPoller = Timer
            .publish(every: 1.0 / 60.0, on: .main, in: .common) // 60 FPS — energy-efficient for pointer polling
            .autoconnect()
            .sink { [weak self] _ in
                self?.syncPointerInteractivity()
            }
    }

    /// Transparent regions of the overlay window must ignore the mouse entirely,
    /// otherwise AppKit will still swallow clicks even if no subview handles them.
    private func syncPointerInteractivity() {
        guard let window, let container, isVisible else { return }
        let screenPoint = NSEvent.mouseLocation
        let windowPoint = window.convertPoint(fromScreen: screenPoint)
        let localPoint = container.convert(windowPoint, from: nil)
        let isInside = container.containsInteractivePoint(localPoint)

        if isCursorInsideIsland != isInside {
            isCursorInsideIsland = isInside
            viewModel.setHovering(isInside)
            evaluateVisibility()
        }

        let shouldIgnoreMouse = !isInside
        if shouldIgnoreMouse {
            // When the cursor leaves, wait briefly before disabling events so SwiftUI
            // still receives "mouseExited" and clears the buttons' hover state.
            if window.ignoresMouseEvents == false && ignoreMouseWorkItem == nil {
                let item = DispatchWorkItem { [weak window] in
                    window?.ignoresMouseEvents = true
                }
                ignoreMouseWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: item) // Increased delay for SwiftUI to register mouseExited
            }
        } else {
            ignoreMouseWorkItem?.cancel()
            ignoreMouseWorkItem = nil
            if window.ignoresMouseEvents == true {
                window.ignoresMouseEvents = false
            }
        }
    }

    private func triggerDesktopWake() {
        isDesktopWakeActive = true
        desktopWakeWorkItem?.cancel()
        evaluateVisibility() // Wake to full opacity immediately
        
        let item = DispatchWorkItem { [weak self] in
            self?.isDesktopWakeActive = false
            self?.evaluateVisibility() // Return to idle / hidden after the timer
        }
        desktopWakeWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay, execute: item)
    }

    private func evaluateVisibility(immediateIdle: Bool = false) {
        guard window != nil else { return }
        
        let isDoingSomething = viewModel.state != .collapsed || isAnimatingCollapse
        let isOnDesktop = alwaysShowOnDesktop && isDesktopActive
        let isHovered = isCursorInsideIsland

        fadeOutWorkItem?.cancel()

        if isHovered || isDoingSomething || isDesktopWakeActive {
            // ACTIVE: fully visible.
            setWindowAlpha(1.0, animated: !immediateIdle)
        } else {
            // IDLE: apply the user-configured transparency.
            let shouldAnimateDim = !immediateIdle
            setWindowAlpha(idleOpacity, animated: shouldAnimateDim)

            // Optionally fade fully out (0%) after the timer.
            let keepVisibleOnDesktop = alwaysShowOnDesktop && isOnDesktop
            
            if !keepVisibleOnDesktop {
                let item = DispatchWorkItem { [weak self] in
                    self?.setWindowAlpha(0.0, animated: true)
                }
                fadeOutWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay, execute: item)
            }
        }
    }

    private func setWindowAlpha(_ alpha: CGFloat, animated: Bool) {
        guard let window else { return }
        if window.alphaValue == alpha { return }
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                // Snappy-in, smooth-out curve for a luxurious fade.
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1.0, 0.2, 1.0)
                window.animator().alphaValue = alpha
            }
        } else {
            window.alphaValue = alpha
        }
    }

    // MARK: - Settings (UserDefaults)
    
    private var idleOpacity: CGFloat {
        CGFloat(environment.settings.idleOpacity) / 100.0
    }
    
    private var hideDelay: TimeInterval {
        environment.settings.hideDelay
    }
    
    private var alwaysShowOnDesktop: Bool {
        environment.settings.alwaysShowOnDesktop
    }
}
