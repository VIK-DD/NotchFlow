//
//  PlayerCompactView.swift
//  NotchFlow
//
//  The persistent idle indicator — album art on one side of the notch, a live
//  equalizer on the other — exactly like iPhone's Dynamic Island while music
//  plays. Falls back to a small inline pill on Macs without a notch.
//

import SwiftUI

struct PlayerCompactView: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    @Environment(\.notchGeometry) private var notch

    var body: some View {
        Group {
            if notch.hasNotch {
                flanking
            } else {
                inline
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Art left of the notch, equalizer right of it, centre kept clear.
    private var flanking: some View {
        HStack(spacing: 0) {
            AlbumArtView(image: viewModel.artwork, size: artSize, cornerRadius: 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: notch.width)
            AudioBarsView(isPlaying: viewModel.isPlaying, color: viewModel.accentColor, maxHeight: 11)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 10)
    }

    private var inline: some View {
        HStack(spacing: 8) {
            AlbumArtView(image: viewModel.artwork, size: artSize, cornerRadius: 6)
            Text(viewModel.item.title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Theme.Colors.primaryText)
                .lineLimit(1)
            AudioBarsView(isPlaying: viewModel.isPlaying, color: viewModel.accentColor, maxHeight: 10)
        }
        .padding(.horizontal, 12)
    }

    private var artSize: CGFloat { max(18, notch.height - 12) }
}
