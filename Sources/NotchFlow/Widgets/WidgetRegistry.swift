//
//  WidgetRegistry.swift
//  NotchFlow
//
//  Holds the registered widgets, keeps them ordered by priority, surfaces the
//  current "primary" (highest-priority live) widget, and multiplexes every
//  widget's event stream into one the notch can subscribe to.
//

import Foundation
import Combine

@MainActor
final class WidgetRegistry: ObservableObject {

    /// Highest-priority widget that currently has live content (or nil).
    @Published private(set) var primaryWidget: (any NotchWidget)?

    private(set) var widgets: [any NotchWidget] = []

    private let eventsSubject = PassthroughSubject<WidgetEnvelope, Never>()
    var events: AnyPublisher<WidgetEnvelope, Never> { eventsSubject.eraseToAnyPublisher() }

    private var cancellables = Set<AnyCancellable>()

    // MARK: Registration

    func register(_ widget: any NotchWidget) {
        widgets.append(widget)
        widgets.sort { $0.metadata.priority > $1.metadata.priority }

        let widgetID = widget.metadata.id
        widget.events
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let self else { return }
                self.eventsSubject.send(WidgetEnvelope(widgetID: widgetID, event: event))
                self.recomputePrimary()
            }
            .store(in: &cancellables)

        recomputePrimary()
    }

    // MARK: Lifecycle

    func activateAll(context: WidgetContext) {
        widgets.forEach { $0.activate(context: context) }
        recomputePrimary()
    }

    func deactivateAll() {
        widgets.forEach { $0.deactivate() }
    }

    // MARK: Primary selection

    private func recomputePrimary() {
        let next = widgets.first { $0.hasLiveContent }
        if next?.metadata.id != primaryWidget?.metadata.id {
            primaryWidget = next
        }
    }
}
