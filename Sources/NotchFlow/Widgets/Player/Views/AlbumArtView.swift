//
//  AlbumArtView.swift
//  NotchFlow
//

import SwiftUI

struct AlbumArtView: View {
    let image: NSImage?
    var size: CGFloat
    var cornerRadius: CGFloat = Theme.Metrics.albumArtCornerRadius

    private var imageIdentity: ObjectIdentifier? {
        image.map(ObjectIdentifier.init)
    }

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    .id(ObjectIdentifier(image))   // new artwork → animated swap
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: size * 0.06, y: 2)
        .animation(.artworkTransition, value: imageIdentity)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "music.note")
                .font(.system(size: size * 0.34, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(width: size, height: size)
    }
}
