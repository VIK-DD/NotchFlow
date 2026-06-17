//
//  NowPlayingView.swift
//  NotchFlow
//
//  The expanded universal player. Album art + metadata + scrubber + transport +
//  volume, laid out below the physical notch (see `notchTopInset`). Shows the
//  source app (Spotify, YouTube, Music, …) as a small badge.
//

import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    @Environment(\.notchTopInset) private var topInset

    var body: some View {
        HStack(spacing: 14) {
            AlbumArtView(image: viewModel.artwork, size: Theme.Metrics.albumArtSize)

            VStack(alignment: .leading, spacing: 8) {
                metadata
                ProgressBarView(viewModel: viewModel)
                HStack(spacing: 0) {
                    PlaybackControlsView(viewModel: viewModel)
                    Spacer(minLength: 10)
                    VolumeControlView(viewModel: viewModel)
                }
            }
        }
        .padding(.horizontal, Theme.Metrics.expandedHPadding + Theme.Metrics.topFlareRadius)
        .padding(.top, topInset)
        .padding(.bottom, Theme.Metrics.expandedVPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .tint(viewModel.accentColor)
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                sourceBadge
                Text(titleText)
                    .font(Theme.Typography.trackTitle)
                    .foregroundColor(Theme.Colors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Text(subtitleText)
                .font(Theme.Typography.artist)
                .foregroundColor(Theme.Colors.secondaryText)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(viewModel.item.id.isEmpty ? "idle" : viewModel.item.id)
        .transition(.trackChange)
        .animation(.contentTransition, value: viewModel.item.id)
    }

    @ViewBuilder
    private var sourceBadge: some View {
        if let icon = viewModel.sourceIcon {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 14, height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        }
    }

    private var titleText: String {
        viewModel.item.title.isEmpty ? "Nothing Playing" : viewModel.item.title
    }

    private var subtitleText: String {
        if viewModel.item.title.isEmpty {
            return "Play something to begin"
        }
        if viewModel.item.artist.isEmpty {
            return viewModel.sourceName ?? ""
        }
        return viewModel.item.artist
    }
}
