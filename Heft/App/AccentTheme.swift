// iOS 26+ only. No #available guards.

import SwiftUI

enum AccentTheme: String, CaseIterable, Identifiable {
    case midnightStrength
    case ember
    case graphite
    case abyss
    case mesh           // Pro only

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .midnightStrength: "Midnight Strength"
        case .ember:            "Ember"
        case .graphite:         "Graphite"
        case .abyss:            "Abyss"
        case .mesh:             "Dynamic Mesh"
        }
    }

    var accentColor: Color {
        switch self {
        case .midnightStrength: Color("Accent")
        case .ember:            Color("AccentEmber")
        case .graphite:         Color("AccentGraphite")
        case .abyss:            Color("AccentAbyss")
        case .mesh:             Color("AccentMesh")
        }
    }

    var isPro: Bool { self == .mesh }
}

// Inject active theme into the SwiftUI environment so any view can read it
// without going through AppState directly.
private struct HeftThemeKey: EnvironmentKey {
    static let defaultValue: AccentTheme = .midnightStrength
}

extension EnvironmentValues {
    var heftTheme: AccentTheme {
        get { self[HeftThemeKey.self] }
        set { self[HeftThemeKey.self] = newValue }
    }
}
