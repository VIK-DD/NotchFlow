//
//  PlayerModels.swift
//  NotchFlow
//

import Foundation

/// A source-agnostic "now playing" item (Spotify, Music, YouTube, …).
struct NowPlayingItem: Equatable {
    let id: String          // stable identity used to detect track changes
    let title: String
    let artist: String
    let album: String

    var hasContent: Bool { !id.isEmpty && !title.isEmpty }

    static let empty = NowPlayingItem(id: "", title: "", artist: "", album: "")
}
