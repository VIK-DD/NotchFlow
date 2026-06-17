//
//  SystemAudio.swift
//  NotchFlow
//
//  System output volume get/set. MediaRemote doesn't expose per-app volume, so the
//  universal player controls the system output volume instead (works for every
//  source, including YouTube in a browser).
//
//  Uses the Standard Additions `volume settings` commands, which do NOT require an
//  Automation permission prompt.
//

import Foundation

@MainActor
final class SystemAudio {

    private let runner = AppleScriptRunner()

    /// Current output volume, 0...100. Returns nil on failure.
    func outputVolume() -> Int? {
        guard let descriptor = try? runner.run("output volume of (get volume settings)") else {
            return nil
        }
        let value = Int(descriptor.int32Value)
        return value >= 0 ? value : nil
    }

    /// True if the system is muted.
    func isMuted() -> Bool {
        guard let descriptor = try? runner.run("output muted of (get volume settings)") else {
            return false
        }
        return descriptor.booleanValue
    }

    func setOutputVolume(_ value: Int) {
        let clamped = max(0, min(100, value))
        _ = try? runner.run("set volume output volume \(clamped)")
    }
}
