import SwiftUI

extension View {
    /// Use on a `Button` label (after frames/backgrounds) so taps match a rounded rectangle.
    func buttonLabelHitRoundRect(cornerRadius: CGFloat) -> some View {
        contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func buttonLabelHitCapsule() -> some View {
        contentShape(Capsule(style: .continuous))
    }

    func buttonLabelHitCircle() -> some View {
        contentShape(Circle())
    }

    /// Full axis-aligned bounds of the label (row buttons, icon bars).
    func buttonLabelHitRect() -> some View {
        contentShape(Rectangle())
    }
}
