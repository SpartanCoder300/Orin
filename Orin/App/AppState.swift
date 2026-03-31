// iOS 26+ only. No #available guards.

import Observation
import SwiftData
import Foundation

enum AppTab: Hashable {
    case home
    case progress
    case library
    case settings
}

@Observable @MainActor
final class AppState {
    var selectedTab: AppTab = .home
    let workout = ActiveWorkoutService()

    var accentTheme: AccentTheme = {
        let raw = UserDefaults.standard.string(forKey: "Orin.accentTheme") ?? ""
        return AccentTheme(rawValue: raw) ?? .midnight
    }() {
        didSet {
            UserDefaults.standard.set(accentTheme.rawValue, forKey: "Orin.accentTheme")
        }
    }
}
