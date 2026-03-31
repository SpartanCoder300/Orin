// iOS 26+ only. No #available guards.

import SwiftUI

/// Applies the per-theme background + ambient accent gradient to any root screen.
/// Use `.themedBackground()` on every NavigationStack root view.
struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.ryftTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background {
                if theme == .mesh {
                    MeshBackgroundView()
                } else {
                    ZStack {
                        theme.backgroundColor

                        // Keep the basic themes near-black overall and let the color feel
                        // like restrained top light rather than a full-screen wash.
                        EllipticalGradient(
                            colors: [
                                theme.accentColor.opacity(0.16),
                                theme.accentColor.opacity(0.08),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.5, y: -0.10),
                            startRadiusFraction: 0,
                            endRadiusFraction: 0.50
                        )
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .white.opacity(0.82), location: 0.18),
                                    .init(color: .white.opacity(0.36), location: 0.34),
                                    .init(color: .clear, location: 0.50)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }

                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Color.black.opacity(0.18), location: 0.34),
                                .init(color: Color.black.opacity(0.52), location: 0.54),
                                .init(color: Color.black.opacity(0.86), location: 0.74),
                                .init(color: Color.black.opacity(0.96), location: 0.88),
                                .init(color: Color.black, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .ignoresSafeArea()
                }
            }
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }
}
