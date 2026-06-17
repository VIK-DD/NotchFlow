//
//  NowPlayingViewModel.swift
//  NotchFlow
//
//  Universal media view model, backed by MediaRemote. Surfaces whatever app is
//  currently playing system-wide and drives every player view. Volume maps to the
//  system output volume so it works for any source.
//

import SwiftUI
import Combine
import AppKit
import CryptoKit

@MainActor
final class NowPlayingViewModel: ObservableObject {

    // MARK: Published UI state

    @Published private(set) var isAvailable = false        // is anything playing/loaded?
    @Published private(set) var item: NowPlayingItem = .empty
    @Published private(set) var isPlaying = false
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published var volume: Double = 50

    @Published private(set) var artwork: NSImage?
    @Published private(set) var accentColor: Color = Theme.Colors.fallbackAccent

    /// The app that's playing (for the small source label / icon).
    @Published private(set) var sourceName: String?
    @Published private(set) var sourceIcon: NSImage?

    /// 0...1 fill the progress bar animates toward. Re-anchored on each refresh.
    @Published var displayedFraction: Double = 0
    var isScrubbing = false

    /// Edge the next track slides in from (.trailing for Next, .leading for Previous).
    @Published private(set) var transitionEdge: Edge = .trailing

    /// Unique key of the current artwork. Use as `.id(viewModel.loadedArtworkKey)` on the cover.
    @Published private(set) var loadedArtworkKey: String?

    // MARK: Events (consumed by the widget)

    let events = PassthroughSubject<WidgetEvent, Never>()

    // MARK: Dependencies

    private let media: MediaRemoteController
    private let systemAudio: SystemAudio
    private let settings: SettingsStore

    // MARK: Internals

    private var tickCancellable: AnyCancellable?
    private var isExpanded = false
    private var artworkCache: [String: NSImage] = [:]      // keyed by artwork hash
    private var pendingArtworkReset: DispatchWorkItem?
    private var fallbackArtworkTask: Task<Void, Never>?
    private var requestedFallbackArtworkKey: String?
    private var volumeIsUserDriven = false
    private var lastElapsedSample: (value: TimeInterval, at: TimeInterval) = (0, 0)
    private var cancellables = Set<AnyCancellable>()
    private var pendingEmptyReset: DispatchWorkItem?
    private var ignoreStateUpdatesUntil: TimeInterval = 0

    // MARK: Init

    init(media: MediaRemoteController, systemAudio: SystemAudio, settings: SettingsStore) {
        self.media = media
        self.systemAudio = systemAudio
        self.settings = settings
    }

    // MARK: Lifecycle

    func start() {
        guard media.isAvailable else { return }
        media.startObserving()

        for name in [MediaRemoteController.infoDidChange, MediaRemoteController.isPlayingDidChange] {
            NotificationCenter.default
                .publisher(for: name)
                .sink { [weak self] _ in self?.refresh() }
                .store(in: &cancellables)
        }

        syncVolume()
        refresh()
    }

    func stop() {
        tickCancellable?.cancel()
        tickCancellable = nil
        pendingEmptyReset?.cancel()
        pendingEmptyReset = nil
        cancellables.removeAll()
    }

    /// Smooth elapsed/progress only needs a ticker while the player is on-screen.
    func setExpanded(_ expanded: Bool) {
        guard expanded != isExpanded else { return }
        isExpanded = expanded
        if expanded {
            startTicker()
            syncVolume()
            refresh()
        } else {
            tickCancellable?.cancel()
            tickCancellable = nil
        }
    }

    private func startTicker() {
        tickCancellable = Timer
            .publish(every: 1.0 / 120.0, on: .main, in: .common) // 120 FPS for ultra-smooth progress (ProMotion)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    // MARK: Refresh (MediaRemote)

    func refresh() {
        media.fetchSnapshot { [weak self] snapshot in
            self?.apply(snapshot)
        }
        media.fetchNowPlayingApp { [weak self] app in
            guard let self else { return }
            self.sourceName = app?.localizedName
            self.sourceIcon = app?.icon
            self.requestFallbackArtworkIfNeeded()
        }
    }

    private func apply(_ snapshot: NowPlayingSnapshot?) {
        // Fully ignore "ghost" snapshots (nil or empty title) from MediaRemote.
        guard let snapshot = snapshot, !snapshot.title.isEmpty else {
            guard isAvailable, pendingEmptyReset == nil else { return }
            let resetItem = DispatchWorkItem { [weak self] in
                self?.isAvailable = false
                self?.resetToEmpty()
                self?.events.send(.contentChanged)
            }
            pendingEmptyReset = resetItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: resetItem)
            return
        }

        pendingEmptyReset?.cancel()
        pendingEmptyReset = nil
        
        let wasAvailable = isAvailable
        isAvailable = true
        if !wasAvailable {
            events.send(.contentChanged)
        }
        
        let newItem = NowPlayingItem(
            id: snapshot.identity,
            title: snapshot.title,
            artist: snapshot.artist,
            album: snapshot.album
        )
        
        // MediaRemote often changes "identity" even on Play/Pause.
        // Treat the track as changed ONLY if the title/artist differs — avoids UI flicker.
        let trackChanged = (newItem.title != item.title) || (newItem.artist != item.artist)

        if trackChanged {
            item = newItem
            // Reset the default slide direction to "Next" after a track has settled in.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.transitionEdge = .trailing
            }
            // On a real track change, cancel any "ignore state" window.
            ignoreStateUpdatesUntil = 0
        }
        
        duration = snapshot.duration
        
        let now = CACurrentMediaTime()
        if now > ignoreStateUpdatesUntil {
            isPlaying = snapshot.isPlaying
            elapsed = snapshot.elapsed
            lastElapsedSample = (snapshot.elapsed, now)
        }
        
        anchorProgress(animated: true)

        updateArtwork(data: snapshot.artworkData, trackChanged: trackChanged)

        if trackChanged {
            events.send(.contentChanged)
            if snapshot.isPlaying { events.send(.requestPeek) }
        }
    }

    /// Local interpolation between MediaRemote updates (0.5s ticker while open).
    private func tick() {
        guard isPlaying, duration > 0, !isScrubbing else { return }
        let now = CACurrentMediaTime()
        let advanced = lastElapsedSample.value + (now - lastElapsedSample.at)
        elapsed = min(advanced, duration)
        anchorProgress(animated: false)
    }

    private func anchorProgress(animated: Bool) {
        guard !isScrubbing else { return }
        let safeDuration = max(duration, 0.001)
        let fraction = min(1, max(0, elapsed / safeDuration))
        // No prediction / jumpy animation — compute exactly and draw each frame.
        displayedFraction = fraction
    }

    private func resetToEmpty() {
        item = .empty
        isPlaying = false
        duration = 0
        elapsed = 0
        displayedFraction = 0
        artwork = nil
        loadedArtworkKey = nil
        pendingArtworkReset?.cancel()
        pendingArtworkReset = nil
        fallbackArtworkTask?.cancel()
        fallbackArtworkTask = nil
        requestedFallbackArtworkKey = nil
        accentColor = Theme.Colors.fallbackAccent
        sourceName = nil
        sourceIcon = nil
    }

    // MARK: Commands

    func togglePlayPause() {
        isPlaying.toggle() // Reflect visually right away
        ignoreStateUpdatesUntil = CACurrentMediaTime() + 1.0 // Ignore macOS's delayed state echoes for 1s
        media.send(.togglePlayPause)
    }

    func next() {
        transitionEdge = .trailing
        ignoreStateUpdatesUntil = CACurrentMediaTime() + 1.5 // Ignore chaotic transition states
        media.send(.nextTrack)
    }

    func previous() {
        transitionEdge = .leading
        ignoreStateUpdatesUntil = CACurrentMediaTime() + 1.5 // Ignore chaotic transition states
        media.send(.previousTrack)
    }

    func commitVolume(_ value: Double) {
        volumeIsUserDriven = true
        volume = value
        systemAudio.setOutputVolume(Int(value.rounded()))
    }

    func endVolumeInteraction() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.volumeIsUserDriven = false
        }
    }

    func beginScrub() { isScrubbing = true }

    func scrub(toFraction fraction: Double) {
        displayedFraction = min(1, max(0, fraction))
        elapsed = displayedFraction * duration
    }

    func commitScrub(toFraction fraction: Double) {
        let target = min(1, max(0, fraction)) * duration
        media.seek(to: target)
        
        // Spotify & Music often ignore MediaRemote's native seek on Mac, so seek via their
        // own AppleScript. `Process` (osascript) avoids NSAppleScript bugs on background threads.
        let source = sourceName?.lowercased() ?? ""
        if source.contains("spotify") {
            let script = "tell application \"Spotify\" to set player position to \(target)"
            Task.detached {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]
                try? process.run()
            process.waitUntilExit()
            }
        } else if source.contains("music") {
            let script = "tell application \"Music\" to set player position to \(target)"
            Task.detached {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]
                try? process.run()
            process.waitUntilExit()
            }
        }
        
        elapsed = target
        lastElapsedSample = (target, CACurrentMediaTime())
        displayedFraction = fraction
        isScrubbing = false
        ignoreStateUpdatesUntil = CACurrentMediaTime() + 1.5 // Prevent the bar from snapping back
    }

    private func scheduleQuickRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.refresh()
        }
    }

    private func syncVolume() {
        guard !volumeIsUserDriven, let v = systemAudio.outputVolume() else { return }
        volume = Double(v)
    }

    // MARK: Artwork

    private func updateArtwork(data: Data?, trackChanged: Bool) {
        pendingArtworkReset?.cancel()
        pendingArtworkReset = nil

        guard let data, !data.isEmpty else {
            if trackChanged {
                fallbackArtworkTask?.cancel()
                fallbackArtworkTask = nil
                requestedFallbackArtworkKey = nil
                let reset = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    self.loadedArtworkKey = nil
                    withAnimation(.artworkTransition) { self.artwork = nil }
                    withAnimation(.contentTransition) {
                        self.accentColor = Theme.Colors.fallbackAccent
                    }
                    self.requestFallbackArtworkIfNeeded()
                }
                pendingArtworkReset = reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: reset)
            } else {
                requestFallbackArtworkIfNeeded()
            }
            return
        }

        // Key by the full payload so a late/stale image never sticks across skips.
        let digest = SHA256.hash(data: data)
        let key = digest.compactMap { String(format: "%02x", $0) }.joined()
        guard key != loadedArtworkKey else { return }
        loadedArtworkKey = key

        if let cached = artworkCache[key] {
            setArtwork(cached)
            return
        }
        guard let image = NSImage(data: data) else { return }
        artworkCache[key] = image
        setArtwork(image)
    }

    private func setArtwork(_ image: NSImage) {
        fallbackArtworkTask?.cancel()
        fallbackArtworkTask = nil
        withAnimation(.artworkTransition) { artwork = image }
        let accent = settings.useAlbumAccent
            ? (image.dominantAccentColor() ?? Theme.Colors.fallbackAccent)
            : Theme.Colors.fallbackAccent
        withAnimation(.contentTransition) { accentColor = accent }
    }

    private func requestFallbackArtworkIfNeeded() {
        guard artwork == nil, item.hasContent, let sourceName else { return }
        guard let fallback = fallbackStrategy(for: sourceName) else { return }

        let key = "\(sourceName)|\(item.id)"
        guard requestedFallbackArtworkKey != key else { return }

        requestedFallbackArtworkKey = key
        fallbackArtworkTask?.cancel()

        fallbackArtworkTask = Task { [weak self] in
            guard let self else { return }
            let trackID = self.item.id
            guard let image = await self.loadFallbackArtwork(using: fallback) else { return }
            guard !Task.isCancelled else { return }
            guard self.item.id == trackID,
                  self.requestedFallbackArtworkKey == key,
                  self.artwork == nil else { return }
            self.setArtwork(image)
        }
    }

    private func fallbackStrategy(for sourceName: String) -> FallbackArtworkStrategy? {
        switch sourceName {
        case "Spotify":
            return .spotifyArtworkURL
        default:
            return nil
        }
    }

    private func loadFallbackArtwork(using strategy: FallbackArtworkStrategy) async -> NSImage? {
        switch strategy {
        case .spotifyArtworkURL:
            guard let url = await spotifyArtworkURL() else { return nil }
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  !Task.isCancelled else { return nil }
            return NSImage(data: data)
        }
    }

    private func spotifyArtworkURL() async -> URL? {
        let script = """
        tell application "Spotify"
            if it is running then
                try
                    return artwork url of current track
                on error
                    return ""
                end try
            end if
        end tell
        return ""
        """

        let value = await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            let pipe = Pipe()
            process.standardOutput = pipe
            try? process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }.value
        
        guard let stringValue = value, !stringValue.isEmpty else { return nil }
        return URL(string: stringValue)
    }
}

private enum FallbackArtworkStrategy {
    case spotifyArtworkURL
}
