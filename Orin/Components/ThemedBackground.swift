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

                    // Ambient accent glow — contained to top, seeps down into content
                    EllipticalGradient(
                        stops: [
                            .init(color: theme.accentColor.opacity(0.22), location: 0),
                            .init(color: theme.accentColor.opacity(0.14), location: 0.25),
                            .init(color: theme.accentColor.opacity(0.07), location: 0.50),
                            .init(color: theme.accentColor.opacity(0.02), location: 0.80),
                            .init(color: .clear, location: 1.0)
                        ],
                        center: UnitPoint(x: 0.5, y: -0.08),
                        startRadiusFraction: 0,
                        endRadiusFraction: 0.30
                    )

                    // Bottom fade to black
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

    func workflowContentBackground() -> some View {
        background(Color.OrinWorkflowBackground)
    }

    func workflowSheetBackground(enabled: Bool = true) -> some View {
        modifier(WorkflowSheetBackgroundModifier(enabled: enabled))
    }
}

/// Applies Orin's stable background to extended modal workflows.
/// Use this for sheet flows that behave like full screens, not small utility sheets.
private struct WorkflowSheetBackgroundModifier: ViewModifier {
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content.presentationBackground(Color.OrinWorkflowBackground)
        } else {
            content
        }
    }
}
