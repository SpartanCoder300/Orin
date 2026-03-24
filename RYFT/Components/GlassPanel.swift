// iOS 26+ only. No #available guards.

import SwiftUI

/// A content container with a thin material background — used for placeholder and informational panels.
/// Not for chrome/overlay controls; those use system-provided Liquid Glass automatically.
struct GlassPanel<Content: View>: View {
    @ViewBuilder private let content: Content
    @Environment(\.ryftCardMaterial) private var cardMaterial

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .frame(minHeight: DesignTokens.Layout.placeholderPanelHeight)
            .background(cardMaterial, in: RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
            .proGlass(cornerRadius: Radius.sheet)
    }
}
