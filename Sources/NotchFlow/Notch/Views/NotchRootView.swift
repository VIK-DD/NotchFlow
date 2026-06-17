//
//  NotchRootView.swift
//  NotchFlow
//
//  The morphing island. Renders the current widget's compact / peek / expanded
//  content inside an animatable `NotchShape`, anchored top-centre in the overlay
//  window. All sizing comes from the view model so the shape, shadow and content
//  animate together as one spring.
//

import SwiftUI

struct NotchRootView: View {
    @ObservedObject var viewModel: NotchViewModel

    var body: some View {
        VStack(spacing: 0) {
            island
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // Mouse tracking + hit-testing pass-through are handled at the AppKit
        // layer (NotchContainerView); this view is purely presentational.
    }

    private var island: some View {
        let shape = NotchShape(
            topFlareRadius: Theme.Metrics.topFlareRadius,
            bottomRadius: viewModel.state == .collapsed
                ? Theme.Metrics.collapsedBottomRadius
                : Theme.Metrics.expandedBottomRadius
        )

        return content
            .frame(width: viewModel.islandSize.width, height: viewModel.islandSize.height)
            .background(Theme.Colors.islandBackground)
            .clipShape(shape)
            .overlay(glassEdge(shape))
            .shadow(
                color: viewModel.state.isOpen ? Theme.Shadow.expandedColor : .clear,
                radius: viewModel.state.isOpen ? Theme.Shadow.expandedRadius : 0,
                y: viewModel.state.isOpen ? Theme.Shadow.expandedY : 0
            )
            .compositingGroup()
    }

    /// A faint top-down highlight that reads as a glassy rim when the island is
    /// open, and fades away entirely when collapsed (for a clean bezel blend).
    private func glassEdge(_ shape: NotchShape) -> some View {
        shape
            .stroke(
                LinearGradient(
                    colors: [Theme.Colors.islandHighlight, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
            .opacity(viewModel.state.isOpen ? 1 : 0)
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            switch viewModel.state {
            case .collapsed:
                compact.transition(.islandContentSwap)
            case .peek:
                peek.transition(.islandContentSwap)
            case .expanded:
                expanded.transition(.islandContentSwap)
            }
        }
        .environment(\.notchTopInset, max(viewModel.metrics.notchSize.height - 4, 16))
        .environment(\.notchGeometry, NotchGeometry(
            width: viewModel.metrics.notchSize.width,
            height: viewModel.metrics.notchSize.height,
            hasNotch: viewModel.metrics.hasNotch
        ))
    }

    @ViewBuilder
    private var compact: some View {
        if let widget = viewModel.primaryWidget { widget.makeCompactView() } else { Color.clear }
    }

    @ViewBuilder
    private var peek: some View {
        if let widget = viewModel.primaryWidget { widget.makePeekView() } else { Color.clear }
    }

    @ViewBuilder
    private var expanded: some View {
        if let widget = viewModel.primaryWidget { widget.makeExpandedView() } else { Color.clear }
    }
}
