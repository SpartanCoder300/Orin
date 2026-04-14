// iOS 26+ only. No #available guards.

import SwiftUI

/// Applies the per-theme background + ambient accent gradient to any root screen.
/// Use `.themedBackground()` on every NavigationStack root view.
struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.OrinTheme) private var theme
    var dimmed: Bool = false

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    theme.backgroundColor

                    // Gradient lighting — smooth multi-stop falloffs
                    Group {
                        // Ambient accent lift
                        EllipticalGradient(
                            colors: [
                                theme.accentColor.opacity(0.13),
                                theme.accentColor.opacity(0.10),
                                theme.accentColor.opacity(0.07),
                                theme.accentColor.opacity(0.04),
                                theme.accentColor.opacity(0.02),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.5, y: -0.15),
                            startRadiusFraction: 0,
                            endRadiusFraction: 0.42
                        )
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .white.opacity(0.72), location: 0.08),
                                    .init(color: .white.opacity(0.42), location: 0.16),
                                    .init(color: .white.opacity(0.18), location: 0.24),
                                    .init(color: .white.opacity(0.06), location: 0.30),
                                    .init(color: .clear, location: 0.38)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }

                        // Depth lift — soft brightening at top-center
                        EllipticalGradient(
                            colors: [
                                Color.white.opacity(0.03),
                                Color.white.opacity(0.015),
                                Color.white.opacity(0.005),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.5, y: 0.0),
                            startRadiusFraction: 0,
                            endRadiusFraction: 0.22
                        )

                        // Micro indigo tint — breaks single-hue flatness
                        EllipticalGradient(
                            colors: [
                                Color.indigo.opacity(0.05),
                                Color.indigo.opacity(0.03),
                                Color.indigo.opacity(0.01),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.35, y: -0.05),
                            startRadiusFraction: 0,
                            endRadiusFraction: 0.26
                        )
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .white.opacity(0.50), location: 0.10),
                                    .init(color: .white.opacity(0.15), location: 0.18),
                                    .init(color: .clear, location: 0.24)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }

                        // Edge vignette — center lifts, sides recede
                        LinearGradient(
                            stops: [
                                .init(color: Color.black.opacity(0.22), location: 0),
                                .init(color: Color.black.opacity(0.12), location: 0.08),
                                .init(color: Color.black.opacity(0.04), location: 0.18),
                                .init(color: .clear, location: 0.30),
                                .init(color: .clear, location: 0.70),
                                .init(color: Color.black.opacity(0.04), location: 0.82),
                                .init(color: Color.black.opacity(0.12), location: 0.92),
                                .init(color: Color.black.opacity(0.22), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .white.opacity(0.50), location: 0.12),
                                    .init(color: .white.opacity(0.15), location: 0.22),
                                    .init(color: .clear, location: 0.32)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
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

extension View {
    func themedBackground(dimmed: Bool = false) -> some View {
        modifier(ThemedBackgroundModifier(dimmed: dimmed))
    }
}
