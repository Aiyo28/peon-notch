import SwiftUI

/// Custom shape that mimics the macOS notch with animatable corner radii.
/// Top corners are tight (blending with hardware notch), bottom corners are rounder.
struct NotchShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set {
            topRadius = newValue.first
            bottomRadius = newValue.second
        }
    }

    func path(in rect: NSRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let tr = min(topRadius, w / 2, h / 2)
        let br = min(bottomRadius, w / 2, h / 2)

        // Start at top-left after top-left corner
        path.move(to: CGPoint(x: 0, y: tr))
        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: tr, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        // Top edge
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: w, y: tr),
            control: CGPoint(x: w, y: 0)
        )
        // Right edge
        path.addLine(to: CGPoint(x: w, y: h - br))
        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: w - br, y: h),
            control: CGPoint(x: w, y: h)
        )
        // Bottom edge
        path.addLine(to: CGPoint(x: br, y: h))
        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h - br),
            control: CGPoint(x: 0, y: h)
        )
        path.closeSubpath()
        return path
    }
}
