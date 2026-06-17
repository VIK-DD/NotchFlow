//
//  MediaRemote.swift
//  NotchFlow
//
//  Thin bridge to the private MediaRemote framework — the same source macOS uses
//  for "Now Playing" in Control Center and the media keys. It reports whatever app
//  is currently playing (Spotify, Apple Music, YouTube in a browser, etc.) and can
//  send transport commands to it.
//
//  Private API, loaded dynamically via dlopen so there's no link-time dependency.
//  Works on macOS Monterey. If the framework can't be loaded, `isAvailable` is
//  false and the player simply stays empty.
//

import Foundation
import AppKit

/// High-level snapshot built from the MediaRemote info dictionary.
struct NowPlayingSnapshot {
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var elapsed: TimeInterval
    var isPlaying: Bool
    var artworkData: Data?
    /// Stable-ish identity used to detect track changes.
    var identity: String
}

final class MediaRemoteController {

    // MARK: Notification names (also dynamic strings)

    static let infoDidChange = Notification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
    static let isPlayingDidChange = Notification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification")

    // MARK: MediaRemote command codes

    enum Command: Int {
        case togglePlayPause = 2
        case nextTrack = 4
        case previousTrack = 5
    }

    // MARK: Dynamic function signatures

    private typealias GetInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias GetIsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias GetPIDFn = @convention(c) (DispatchQueue, @escaping (Int) -> Void) -> Void
    private typealias SendCommandFn = @convention(c) (Int, [String: Any]?) -> Bool
    private typealias RegisterFn = @convention(c) (DispatchQueue) -> Void
    private typealias SetElapsedFn = @convention(c) (Double) -> Void

    // MARK: Info dictionary keys

    private enum Key {
        static let title = "kMRMediaRemoteNowPlayingInfoTitle"
        static let artist = "kMRMediaRemoteNowPlayingInfoArtist"
        static let album = "kMRMediaRemoteNowPlayingInfoAlbum"
        static let duration = "kMRMediaRemoteNowPlayingInfoDuration"
        static let elapsed = "kMRMediaRemoteNowPlayingInfoElapsedTime"
        static let timestamp = "kMRMediaRemoteNowPlayingInfoTimestamp"
        static let artworkData = "kMRMediaRemoteNowPlayingInfoArtworkData"
        static let playbackRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"
        static let uniqueIdentifier = "kMRMediaRemoteNowPlayingInfoUniqueIdentifier"
        static let contentItemIdentifier = "kMRMediaRemoteNowPlayingInfoContentItemIdentifier"
    }

    // MARK: Resolved symbols (nil when the framework / symbol is unavailable)

    private let getInfoFn: GetInfoFn?
    private let getIsPlayingFn: GetIsPlayingFn?
    private let sendCommandFn: SendCommandFn?
    private let registerFn: RegisterFn?
    private let getPIDFn: GetPIDFn?
    private let setElapsedFn: SetElapsedFn?

    let isAvailable: Bool

    // MARK: Init

    init() {
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_NOW
        ) else {
            self.getInfoFn = nil
            self.getIsPlayingFn = nil
            self.sendCommandFn = nil
            self.registerFn = nil
            self.getPIDFn = nil
            self.setElapsedFn = nil
            self.isAvailable = false
            return
        }

        func symbol<T>(_ name: String, as type: T.Type) -> T? {
            guard let pointer = dlsym(handle, name) else { return nil }
            return unsafeBitCast(pointer, to: T.self)
        }

        let info = symbol("MRMediaRemoteGetNowPlayingInfo", as: GetInfoFn.self)
        let playing = symbol("MRMediaRemoteGetNowPlayingApplicationIsPlaying", as: GetIsPlayingFn.self)
        let send = symbol("MRMediaRemoteSendCommand", as: SendCommandFn.self)
        let register = symbol("MRMediaRemoteRegisterForNowPlayingNotifications", as: RegisterFn.self)

        self.getInfoFn = info
        self.getIsPlayingFn = playing
        self.sendCommandFn = send
        self.registerFn = register
        self.getPIDFn = symbol("MRMediaRemoteGetNowPlayingApplicationPID", as: GetPIDFn.self)
        self.setElapsedFn = symbol("MRMediaRemoteSetElapsedTime", as: SetElapsedFn.self)
        self.isAvailable = (info != nil && playing != nil && send != nil && register != nil)
    }

    // MARK: Reads

    /// Fetch the current now-playing snapshot (delivered on the main queue). The
    /// callbacks capture local function pointers (not `self`) to stay clear of
    /// concurrency-isolation issues.
    func fetchSnapshot(_ completion: @escaping (NowPlayingSnapshot?) -> Void) {
        guard let getInfo = getInfoFn, let getPlaying = getIsPlayingFn else {
            completion(nil); return
        }
        getInfo(DispatchQueue.main) { info in
            // No title → nothing is playing / no media session.
            guard let title = info[Key.title] as? String, !title.isEmpty else {
                completion(nil)
                return
            }
            getPlaying(DispatchQueue.main) { isPlaying in
                completion(MediaRemoteController.makeSnapshot(info: info, isPlaying: isPlaying))
            }
        }
    }

    private static func makeSnapshot(info: [String: Any], isPlaying: Bool) -> NowPlayingSnapshot {
        let title = info[Key.title] as? String ?? ""
        let artist = info[Key.artist] as? String ?? ""
        let album = info[Key.album] as? String ?? ""
        let duration = (info[Key.duration] as? Double) ?? 0

        // Elapsed is sampled at `timestamp`; advance it locally when playing.
        var elapsed = (info[Key.elapsed] as? Double) ?? 0
        let rate = (info[Key.playbackRate] as? Double) ?? (isPlaying ? 1 : 0)
        if rate > 0, let sampledAt = info[Key.timestamp] as? Date {
            elapsed += Date().timeIntervalSince(sampledAt) * rate
        }
        if duration > 0 { elapsed = min(max(0, elapsed), duration) }

        let identity = (info[Key.contentItemIdentifier] as? String)
            ?? (info[Key.uniqueIdentifier].map { "\($0)" })
            ?? "\(title)|\(artist)|\(album)"

        return NowPlayingSnapshot(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            elapsed: elapsed,
            isPlaying: rate > 0,
            artworkData: extractArtworkData(from: info),
            identity: identity
        )
    }

    private static func extractArtworkData(from info: [String: Any]) -> Data? {
        if let data = info[Key.artworkData] as? Data, !data.isEmpty {
            return data
        }
        if let nsData = info[Key.artworkData] as? NSData, nsData.length > 0 {
            return nsData as Data
        }
        if let image = info[Key.artworkData] as? NSImage {
            return image.tiffRepresentation
        }
        return nil
    }

    /// Resolve the bundle identifier of the app currently playing (best effort).
    func fetchNowPlayingApp(_ completion: @escaping (NSRunningApplication?) -> Void) {
        guard isAvailable, let getPID = getPIDFn else { completion(nil); return }
        getPID(DispatchQueue.main) { pid in
            guard pid > 0, pid < 1_000_000,
                  let app = NSRunningApplication(processIdentifier: pid_t(pid)) else {
                completion(nil)
                return
            }
            completion(app)
        }
    }

    // MARK: Commands

    @discardableResult
    func send(_ command: Command) -> Bool {
        guard let sendCommand = sendCommandFn else { return false }
        return sendCommand(command.rawValue, nil)
    }

    func seek(to seconds: TimeInterval) {
        setElapsedFn?(max(0, seconds))
    }

    // MARK: Change notifications

    func startObserving() {
        registerFn?(DispatchQueue.main)
    }
}
