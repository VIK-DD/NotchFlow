//
//  AudioBarsView.swift
//  NotchFlow
//
//  A tiny equalizer. Each bar runs its own gentle, autoreversing spring so the
//  group looks organic. Bars settle to a flat resting state when paused.
//

import SwiftUI

struct AudioBarsView: View {
    var isPlaying: Bool
    var color: Color = .white
    var maxHeight: CGFloat = 13

    // (minScale, maxScale, duration) per bar — varied for an organic feel.
    private let specs: [(CGFloat, CGFloat, Double)] = [
        (0.30, 0.85, 0.52),
        (0.45, 1.00, 0.43),
        (0.25, 0.70, 0.61),
        (0.50, 0.95, 0.48)
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 2.5) {
            ForEach(specs.indices, id: \.self) { i in
                EqualizerBar(
                    isPlaying: isPlaying,
                    minScale: specs[i].0,
                    maxScale: specs[i].1,
                    duration: specs[i].2,
                    maxHeight: maxHeight,
                    color: color
                )
            }
        }
        .frame(height: maxHeight)
    }
}

private struct EqualizerBar: View {
    let isPlaying: Bool
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    let maxHeight: CGFloat
    let color: Color

    @State private var oscillate = false

    var body: some View {
        Capsule(style: .continuous)
            .fill(color)
            .frame(width: 2.5, height: maxHeight)
            .scaleEffect(y: scaleY, anchor: .center)
            .animation(motion, value: oscillate)
            .animation(.easeOut(duration: 0.2), value: isPlaying)
            .onAppear { oscillate = true }
    }

    private var scaleY: CGFloat {
        guard isPlaying else { return 0.22 }      // flat resting line when paused
        return oscillate ? maxScale : minScale
    }

    private var motion: Animation {
        isPlaying
            ? .easeInOut(duration: duration).repeatForever(autoreverses: true)
            : .easeOut(duration: 0.2)
    }
}
