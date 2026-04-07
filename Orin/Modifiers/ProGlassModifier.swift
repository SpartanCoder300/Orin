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

/// Standard elevated content surface: shared card material with the standard border.
struct CardSurfaceModifier: ViewModifier {
    @Environment(\.OrinCardMaterial) private var cardMaterial
    var cornerRadius: CGFloat = Radius.medium
    var border: Bool = true

    func body(content: Content) -> some View {
        let base = content
            .background(cardMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

        if border {
            base.proGlass(specular: false, cornerRadius: cornerRadius)
        } else {
            base
        }
    }
}

extension View {
    func proGlass(exerciseIndex: Int? = nil, cardIndex: Int? = nil, specular: Bool = true, cornerRadius: CGFloat = Radius.medium) -> some View {
        modifier(ProGlassModifier(cornerRadius: cornerRadius))
    }

    func cardSurface(cornerRadius: CGFloat = Radius.medium, border: Bool = true) -> some View {
        modifier(CardSurfaceModifier(cornerRadius: cornerRadius, border: border))
    }
}
