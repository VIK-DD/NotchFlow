//
//  ProgressBarView.swift
//  NotchFlow
//
//  Live, draggable scrubber. The fill is advanced by the view model via an
//  implicit Core-Animation tween, so it glides at 60fps between updates with no
//  per-frame timer.
//

import SwiftUI

struct ProgressBarView: View {
    @ObservedObject var viewModel: NowPlayingViewModel

    @State private var hovering = false

    private let barHeight: CGFloat = 4

    var body: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                let width = geo.size.width
                let fill = max(0, min(width, CGFloat(viewModel.displayedFraction) * width))

                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Colors.progressTrack)
                    Capsule()
                        .fill(Theme.Colors.progressFill)
                        .frame(width: fill)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 9, height: 9)
                        .opacity(hovering || viewModel.isScrubbing ? 1 : 0)
                        .scaleEffect(viewModel.isScrubbing ? 1.35 : (hovering ? 1.0 : 0.72))
                        .offset(x: fill - 4.5)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: viewModel.isScrubbing)
                }
                .frame(height: barHeight)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .animation(.notchHover, value: hovering)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            viewModel.beginScrub()
                            viewModel.scrub(toFraction: value.location.x / width)
                        }
                        .onEnded { value in
                            viewModel.commitScrub(toFraction: value.location.x / width)
                        }
                )
                .onHover { hovering in
                    withAnimation(.notchHover) { self.hovering = hovering }
                }
            }
            .frame(height: 12)

            HStack {
                Text(Format.timecode(viewModel.elapsed))
                Spacer()
                Text("-" + Format.timecode(max(0, viewModel.duration - viewModel.elapsed)))
            }
            .font(Theme.Typography.timecode)
            .foregroundColor(Theme.Colors.tertiaryText)
        }
    }
}
