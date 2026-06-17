//
//  NotchViewModel.swift
//  NotchFlow
//
//  Owns the notch's state machine and the geometry the views/window observe.
//  Reacts to widget "attention" events (e.g. a Spotify track change) to peek,
//  and to hover to fully expand.
//

import SwiftUI
import Combine

extension Notification.Name {
    static let notchHoverStatusChanged = Notification.Name("notchHoverStatusChanged")
}

@MainActor
final class NotchViewModel: ObservableObject {

    // MARK: Published state

    @Published private(set) var state: NotchState = .collapsed
    @Published private(set) var islandSize: CGSize = .zero
    @Published private(set) var metrics: ScreenMetrics

    /// The widget currently surfaced in the notch (highest-priority live widget).
    @Published private(set) var primaryWidget: (any NotchWidget)?

    // MARK: Dependencies

    private let registry: WidgetRegistry
    private let settings: SettingsStore
    private var cancellables = Set<AnyCancellable>()

    // MARK: Interaction bookkeeping

    private var isHovering = false
    private var collapseWorkItem: DispatchWorkItem?

    private let collapseDelay: TimeInterval = 0.25 // Snappier, more responsive retract
    private let peekDuration: TimeInterval = 3.5

    // MARK: Init

    init(registry: WidgetRegistry, settings: SettingsStore, metrics: ScreenMetrics) {
        self.registry = registry
        self.settings = settings
        self.metrics = metrics
        self.islandSize = metrics.collapsedSize
        self.primaryWidget = registry.primaryWidget

        bind()
    }

    private func bind() {
        // Track which widget should be shown.
        registry.$primaryWidget
            .receive(on: RunLoop.main)
            .sink { [weak self] widget in
                self?.primaryWidget = widget
                self?.refreshSizeForCurrentState()
            }
            .store(in: &cancellables)

        // React to widgets asking for the notch's attention.
        registry.events
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                self?.handle(event: event.event)
            }
            .store(in: &cancellables)
    }

    // MARK: Screen changes

    func updateMetrics(_ metrics: ScreenMetrics) {
        self.metrics = metrics
        refreshSizeForCurrentState()
    }

    // MARK: Hover

    func setHovering(_ hovering: Bool) {
        isHovering = hovering
        NotificationCenter.default.post(name: .notchHoverStatusChanged, object: hovering)
        if hovering {
            cancelScheduledCollapse()
            guard primaryWidget != nil else { return }
            transition(to: .expanded, animation: .notchExpand)
        } else {
            scheduleCollapse(after: collapseDelay)
        }
    }

    // MARK: Widget events

    private func handle(event: WidgetEvent) {
        guard settings.reactToWidgetEvents else { return }
        switch event {
        case .requestPeek:
            guard !isHovering, settings.expandOnTrackChange else { return }
            if state == .peek {
                // Already open (e.g. rapid track skipping) — just extend on-screen time.
                scheduleCollapse(after: peekDuration)
            } else {
                transition(to: .peek, animation: .notchExpand)
                scheduleCollapse(after: peekDuration)
            }
        case .requestExpand:
            transition(to: .expanded, animation: .notchExpand)
            if !isHovering { scheduleCollapse(after: peekDuration + 1) }
        case .contentChanged:
            // Registry already recomputed `primaryWidget`; just keep size in sync.
            refreshSizeForCurrentState()
        }
    }

    // MARK: State transitions

    private func transition(to newState: NotchState, animation: Animation) {
        guard state != newState else { return }
        let wasOpen = state.isOpen
        
        // Springs with mass and natural inertia (Apple Dynamic Island feel).
        let expandSpring: Animation = .spring(response: 0.32, dampingFraction: 0.72, blendDuration: 0)
        withAnimation(expandSpring) {
            state = newState
            islandSize = size(for: newState)
        }
        if newState.isOpen != wasOpen {
            primaryWidget?.notchDidChangeOpenState(newState.isOpen)
        }
    }

    private func collapse() {
        let wasOpen = state.isOpen
        let collapseSpring: Animation = .spring(response: 0.38, dampingFraction: 0.85, blendDuration: 0)
        withAnimation(collapseSpring) {
            state = .collapsed
            islandSize = size(for: .collapsed)
        }
        if wasOpen { primaryWidget?.notchDidChangeOpenState(false) }
    }

    private func refreshSizeForCurrentState() {
        let target = size(for: state)
        guard target != islandSize else { return }
        let expandSpring: Animation = .spring(response: 0.32, dampingFraction: 0.72, blendDuration: 0)
        withAnimation(expandSpring) { islandSize = target }
    }

    private func size(for state: NotchState) -> CGSize {
        switch state {
        case .collapsed:
            // The widget may request a persistent indicator (now-playing flanks);
            // otherwise we collapse to the bare notch and blend with the bezel.
            return primaryWidget?.collapsedSize(for: metrics) ?? metrics.collapsedSize
        case .peek:
            // Flanks the notch, with room below the camera housing for a title.
            let width = max(340, metrics.notchSize.width + 220)
            let height = metrics.notchSize.height + 34
            return CGSize(width: width, height: height)
        case .expanded:
            return primaryWidget?.metadata.preferredExpandedSize ?? Theme.Metrics.expandedSize
        }
    }

    // MARK: Collapse scheduling

    private func scheduleCollapse(after delay: TimeInterval) {
        cancelScheduledCollapse()
        let item = DispatchWorkItem { [weak self] in
            guard let self, !self.isHovering else { return }
            self.collapse()
        }
        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelScheduledCollapse() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
    }
}
