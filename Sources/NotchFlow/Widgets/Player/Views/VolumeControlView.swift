//
//  VolumeControlView.swift
//  NotchFlow
//
//  Compact custom volume slider (capsule track + drag), matching the progress
//  bar's visual language rather than the default AppKit slider.
//

import SwiftUI

struct VolumeControlView: View {
    @ObservedObject var viewModel: NowPlayingViewModel

    @State private var hovering = false
    @State private var isDragging = false

    private let trackWidth: CGFloat = 78
    private let barHeight: CGFloat = 4

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: speakerSymbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.Colors.secondaryText)
                .frame(width: 14, alignment: .leading)
                .animation(.contentTransition, value: speakerSymbol)

            GeometryReader { geo in
                let width = geo.size.width
                let fraction = CGFloat(viewModel.volume / 100.0)
                let fill = max(0, min(width, fraction * width))

                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Colors.progressTrack)
                    Capsule().fill(Theme.Colors.secondaryText).frame(width: fill)
                    Circle()
                        .fill(.white)
                        .frame(width: 9, height: 9)
                        .opacity(hovering || isDragging ? 1 : 0)
                        .scaleEffect(isDragging ? 1.35 : (hovering ? 1.0 : 0.72))
                        .offset(x: fill - 4.5)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isDragging)
                }
                .frame(height: barHeight)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let v = Double(max(0, min(1, value.location.x / width))) * 100
                            viewModel.commitVolume(v)
                        }
                        .onEnded { _ in
                            isDragging = false
                            viewModel.endVolumeInteraction()
                        }
                )
                .onHover { hovering in
                    withAnimation(.notchHover) { self.hovering = hovering }
                }
            }
            .frame(width: trackWidth, height: 12)
        }
    }

    private var speakerSymbol: String {
        switch viewModel.volume {
        case ..<1: return "speaker.slash.fill"
        case ..<34: return "speaker.fill"
        case ..<67: return "speaker.wave.1.fill"
        default: return "speaker.wave.2.fill"
        }
    }
}
