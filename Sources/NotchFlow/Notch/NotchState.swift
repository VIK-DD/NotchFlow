//
//  NotchState.swift
//  NotchFlow
//
//  The notch is a tiny state machine. Each state maps to a size + content layout.
//

import Foundation

enum NotchState: Equatable {
    /// Bare notch. Blends with the bezel; effectively invisible.
    case collapsed
    /// Transient pill shown when a widget asks for attention (e.g. track change).
    case peek
    /// Full interactive panel (hover / click).
    case expanded

    var isOpen: Bool { self != .collapsed }
}
