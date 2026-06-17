//
//  AppleScriptRunner.swift
//  NotchFlow
//
//  Thin, cached wrapper around NSAppleScript. Compiled scripts are reused so the
//  per-poll cost is just an Apple Event round-trip (a few ms), keeping CPU low.
//
//  NSAppleScript is not thread-safe and is exercised here only from the main
//  actor, which is fine because our calls are infrequent and batched.
//

import Foundation
import AppKit

enum AppleScriptError: Error {
    case compilationFailed(String)
    case executionFailed(String)
}

@MainActor
final class AppleScriptRunner {

    private var compiledCache: [String: NSAppleScript] = [:]

    /// Compile-once, run-many. Returns the result descriptor or throws.
    @discardableResult
    func run(_ source: String) throws -> NSAppleEventDescriptor {
        let script: NSAppleScript
        if let cached = compiledCache[source] {
            script = cached
        } else {
            guard let compiled = NSAppleScript(source: source) else {
                throw AppleScriptError.compilationFailed("Could not create NSAppleScript")
            }
            var compileError: NSDictionary?
            if !compiled.compileAndReturnError(&compileError) {
                throw AppleScriptError.compilationFailed(Self.message(from: compileError))
            }
            compiledCache[source] = compiled
            script = compiled
        }

        var execError: NSDictionary?
        let result = script.executeAndReturnError(&execError)
        if let execError {
            throw AppleScriptError.executionFailed(Self.message(from: execError))
        }
        return result
    }

    private static func message(from error: NSDictionary?) -> String {
        (error?[NSAppleScript.errorMessage] as? String) ?? "Unknown AppleScript error"
    }
}
