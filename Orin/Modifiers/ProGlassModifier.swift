// iOS 26+ only. No #available guards.

import SwiftUI

/// Card surface treatment — adds a subtle border so cards read as distinct surfaces.
struct ProGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = Radius.medium

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
    }
}

extension View {
    func proGlass(exerciseIndex: Int? = nil, cardIndex: Int? = nil, specular: Bool = true, cornerRadius: CGFloat = Radius.medium) -> some View {
        modifier(ProGlassModifier(cornerRadius: cornerRadius))
    }
}
