// iOS 26+ only. No #available guards.

import SwiftUI

enum AccentTheme: String, CaseIterable, Identifiable {
    case midnight
    case graphite
    case ember

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .midnight: "Midnight"
        case .graphite: "Graphite"
        case .ember:    "Copper"
        }
    }

    var accentColor: Color {
        switch self {
        case .midnight: Color("Accent")
        case .graphite: Color("AccentGraphite")
        case .ember:    Color("AccentEmber")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .midnight: Color("BackgroundMidnight")
        case .graphite: Color("BackgroundGraphite")
        case .ember:    Color("BackgroundEmber")
        }
    }

    /// Raw sRGB doubles for encoding into Live Activity ContentState.
    /// Color is not Codable so the widget reconstructs it from these values.
    var accentRGB: (r: Double, g: Double, b: Double) {
        switch self {
        case .midnight: return (0.290, 0.482, 0.800) // #4A7BCC steel navy
        case .graphite: return (0.498, 0.714, 0.761) // #7FB6C2 washed cyan
        case .ember:    return (0.722, 0.455, 0.196) // #B87432 burnished copper
        }
    }

    /// Reads the current theme from UserDefaults without needing SwiftUI observation.
    /// Safe to call from any non-UI context (ViewModels, services, background tasks).
    static var currentAccentRGB: (r: Double, g: Double, b: Double) {
        let raw = UserDefaults.standard.string(forKey: "Orin.accentTheme") ?? ""
        return (AccentTheme(rawValue: raw) ?? .midnight).accentRGB
    }
}

// Inject active theme into the SwiftUI environment so any view can read it
// without going through AppState directly.
private struct OrinThemeKey: EnvironmentKey {
    static let defaultValue: AccentTheme = .midnight
}

// Card material — regularMaterial by default.
private struct OrinCardMaterialKey: EnvironmentKey {
    static let defaultValue: Material = .regularMaterial
}

extension EnvironmentValues {
    var OrinTheme: AccentTheme {
        get { self[OrinThemeKey.self] }
        set { self[OrinThemeKey.self] = newValue }
    }

    var OrinCardMaterial: Material {
        get { self[OrinCardMaterialKey.self] }
        set { self[OrinCardMaterialKey.self] = newValue }
    }
}
