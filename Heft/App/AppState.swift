// iOS 26+ only. No #available guards.

import Observation
import SwiftData
import Foundation

enum AppTab: Hashable {
    case home
    case history
    case settings
}

@Observable @MainActor
final class AppState {
    var selectedTab: AppTab = .home
    let workout = ActiveWorkoutService()

    var accentTheme: AccentTheme = {
        let raw = UserDefaults.standard.string(forKey: "heft.accentTheme") ?? ""
        return AccentTheme(rawValue: raw) ?? .midnightStrength
    }() {
        didSet {
            UserDefaults.standard.set(accentTheme.rawValue, forKey: "heft.accentTheme")
        }
    }
}
