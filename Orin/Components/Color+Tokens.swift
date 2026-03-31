// iOS 26+ only. No #available guards.

import SwiftUI

extension Color {
    // ── Theme accents ─────────────────────────────────────────────────────────
    static var OrinAccent: Color          { Color("Accent") }
    static var OrinAccentGraphite: Color  { Color("AccentGraphite") }
    static var OrinAccentEmber: Color     { Color("AccentEmber") }
    static var OrinAccentMesh: Color      { Color("AccentMesh") }

    // ── Theme backgrounds ─────────────────────────────────────────────────────
    // Use theme.backgroundColor in views rather than these directly.
    static var OrinBackground: Color      { Color("BackgroundMidnight") }

    // ── Shared surfaces ───────────────────────────────────────────────────────
    static var OrinSurface: Color         { Color("Surface") }

    // ── Semantic ──────────────────────────────────────────────────────────────
    static var OrinRed: Color             { Color("OrinRed") }
    static var OrinGreen: Color           { Color("OrinGreen") }
    static var OrinAmber: Color           { Color("OrinAmber") }
    static var OrinWarmup: Color          { Color("OrinWarmup") }
    static var OrinGold: Color            { Color("OrinGold") }
    static var OrinBlue: Color            { Color(red: 0.302, green: 0.490, blue: 0.996) }

    // ── Text ──────────────────────────────────────────────────────────────────
    static var textPrimary: Color { .white.opacity(DesignTokens.Opacity.textPrimary) }
    static var textMuted: Color   { .white.opacity(DesignTokens.Opacity.textMuted) }
    static var textFaint: Color   { .white.opacity(DesignTokens.Opacity.textFaint) }
}
