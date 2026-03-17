// iOS 26+ only. No #available guards.

import SwiftUI

/// Applies the Obsidian base + themed ambient gradient background to any root screen.
/// Also sets the navigation bar to ultraThinMaterial so the gradient glows through it.
/// Use `.themedBackground()` on every NavigationStack root view.
struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.heftTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack(alignment: .top) {
                    Color.heftBackground
                    LinearGradient(
                        colors: [theme.accentColor.opacity(0.18), Color.clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.42)
                    )
                }
                .ignoresSafeArea()
            )
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }
}
