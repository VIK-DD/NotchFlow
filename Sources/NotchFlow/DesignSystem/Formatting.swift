//
//  Formatting.swift
//  NotchFlow
//

import SwiftUI

enum Format {
    /// Seconds → "m:ss" (or "h:mm:ss" for long tracks).
    static func timecode(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        let s = total % 60
        let m = (total / 60) % 60
        let h = total / 3600
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Notch inset environment

/// Vertical space at the top of the expanded panel occupied by the physical
/// notch. Widget content reads this to lay itself out *below* the camera housing.
private struct NotchTopInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 32
}

extension EnvironmentValues {
    var notchTopInset: CGFloat {
        get { self[NotchTopInsetKey.self] }
        set { self[NotchTopInsetKey.self] = newValue }
    }
}

// MARK: - Notch geometry environment

/// Physical notch dimensions, so flanking views can leave the centre clear for
/// the camera housing.
struct NotchGeometry: Equatable {
    var width: CGFloat
    var height: CGFloat
    var hasNotch: Bool
}

private struct NotchGeometryKey: EnvironmentKey {
    static let defaultValue = NotchGeometry(width: 160, height: 32, hasNotch: false)
}

extension EnvironmentValues {
    var notchGeometry: NotchGeometry {
        get { self[NotchGeometryKey.self] }
        set { self[NotchGeometryKey.self] = newValue }
    }
}
