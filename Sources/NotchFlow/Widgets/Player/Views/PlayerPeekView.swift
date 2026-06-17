//
//  PlayerPeekView.swift
//  NotchFlow
//
//  The brief glance shown when a track changes: album art + equalizer flank the
//  notch, with the title/artist revealed just below the camera housing — then it
//  settles back to the persistent compact indicator.
//

import SwiftUI

struct PlayerPeekView: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    @Environment(\.notchGeometry) private var notch

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                AlbumArtView(image: viewModel.artwork, size: artSize, cornerRadius: 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: notch.width)
                AudioBarsView(isPlaying: viewModel.isPlaying, color: viewModel.accentColor, maxHeight: 12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: notch.height)

            VStack(spacing: 1) {
                Text(viewModel.item.title)
                    .font(Theme.Typography.peekTitle)
                    .foregroundColor(Theme.Colors.primaryText)
                    .lineLimit(1)
                if !viewModel.item.artist.isEmpty {
                    Text(viewModel.item.artist)
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .id(viewModel.item.id)
            .transition(.trackChange)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.contentTransition, value: viewModel.item.id)
    }

    private var artSize: CGFloat { max(20, notch.height - 10) }
}
