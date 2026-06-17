//
//  NotchShape.swift
//  NotchFlow
//
//  The signature "island" outline: flush to the screen top, flaring out with a
//  concave curve at the top corners (so it melts into the bezel) and rounded
//  convex bottom corners. Animatable so it morphs smoothly between states.
//

import SwiftUI

struct NotchShape: Shape {
    /// Concave radius where the body flares out to the screen edge.
    var topFlareRadius: CGFloat
    /// Convex radius of the bottom corners.
    var bottomRadius: CGFloat

    /// Let SwiftUI interpolate both radii during state changes.
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topFlareRadius, bottomRadius) }
        set {
            topFlareRadius = newValue.first
            bottomRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tr = min(topFlareRadius, rect.width / 2)
        let br = min(bottomRadius, (rect.width / 2) - tr, rect.height - tr)

        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY

        // Start at the very top-left edge (touching the bezel).
        path.move(to: CGPoint(x: minX, y: minY))

        // Concave top-left flare inward to the body.
        path.addQuadCurve(
            to: CGPoint(x: minX + tr, y: minY + tr),
            control: CGPoint(x: minX + tr, y: minY)
        )

        // Left side down to the bottom corner.
        path.addLine(to: CGPoint(x: minX + tr, y: maxY - br))

        // Convex bottom-left corner.
        path.addQuadCurve(
            to: CGPoint(x: minX + tr + br, y: maxY),
            control: CGPoint(x: minX + tr, y: maxY)
        )

        // Bottom edge.
        path.addLine(to: CGPoint(x: maxX - tr - br, y: maxY))

        // Convex bottom-right corner.
        path.addQuadCurve(
            to: CGPoint(x: maxX - tr, y: maxY - br),
            control: CGPoint(x: maxX - tr, y: maxY)
        )

        // Right side back up.
        path.addLine(to: CGPoint(x: maxX - tr, y: minY + tr))

        // Concave top-right flare out to the bezel.
        path.addQuadCurve(
            to: CGPoint(x: maxX, y: minY),
            control: CGPoint(x: maxX - tr, y: minY)
        )

        path.closeSubpath()
        return path
    }
}
