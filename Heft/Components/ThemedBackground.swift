// iOS 26+ only. No #available guards.

import SwiftUI

/// Applies the per-theme background + ambient accent gradient to any root screen.
/// Use `.themedBackground()` on every NavigationStack root view.
struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.heftTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack(alignment: .top) {
                    theme.backgroundColor
                    LinearGradient(
                        colors: [theme.accentColor.opacity(0.15), Color.clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.4)
                    )
                }
                .ignoresSafeArea()
            )
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }
}
