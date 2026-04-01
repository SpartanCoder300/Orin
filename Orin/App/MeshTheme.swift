// iOS 26+ only. No #available guards.

import SwiftUI

/// Color palette and state arrays for the Pro mesh background.
///
/// Two intertwining galaxy clouds form the base — electric blue (left) and
/// teal-green (right), blending at the top and falling to void below.
///
/// Four event moments:
/// 1. Set logged       → stellar flare (pale blue-white burst)
/// 2. Exercise done    → brighter flare
/// 3. PR               → amber supernova (two-stage: hot flash → sustained bloom)
/// 4. Workout complete / theme intro → electric violet bloom
enum MeshTheme {

    // MARK: - Void

    private static let void0 = Color(red: 0.022, green: 0.020, blue: 0.048)  // near-black
    private static let void1 = Color(red: 0.035, green: 0.032, blue: 0.068)  // slight lift

    // MARK: - Galaxy Base Palette

    // Blue cloud — left side
    private static let blueCorner = Color(red: 0.080, green: 0.085, blue: 0.440)  // TL peak
    private static let blueBlend  = Color(red: 0.095, green: 0.185, blue: 0.430)  // TC midpoint
    private static let blueDrip   = Color(red: 0.040, green: 0.050, blue: 0.220)  // ML

    // Teal-green cloud — right side
    private static let tealCorner = Color(red: 0.035, green: 0.255, blue: 0.255)  // TR peak
    private static let tealDrip   = Color(red: 0.018, green: 0.138, blue: 0.148)  // MR

    // Bright versions — used in started state and intenseRGB ceiling
    private static let blueCornerBright = Color(red: 0.115, green: 0.120, blue: 0.580)
    private static let blueBlendBright  = Color(red: 0.130, green: 0.250, blue: 0.560)
    private static let tealCornerBright = Color(red: 0.052, green: 0.348, blue: 0.348)
    private static let blueDripBright   = Color(red: 0.062, green: 0.075, blue: 0.308)
    private static let tealDripBright   = Color(red: 0.028, green: 0.198, blue: 0.212)

    // Workout-start boost — same Nova hue family, but with a clearer launch flash.
    private static let blueCornerStart = Color(red: 0.170, green: 0.185, blue: 0.760)
    private static let blueBlendStart  = Color(red: 0.215, green: 0.365, blue: 0.760)
    private static let tealCornerStart = Color(red: 0.095, green: 0.455, blue: 0.445)
    private static let blueDripStart   = Color(red: 0.085, green: 0.110, blue: 0.405)
    private static let tealDripStart   = Color(red: 0.050, green: 0.260, blue: 0.270)

    // MARK: - Stellar Flare (set logged / exercise complete)
    // Blue-white burst — cuts clearly against the cool galaxy base.

    private static let flareCorner          = Color(red: 0.045, green: 0.042, blue: 0.100)
    private static let flareCornerTop       = Color(red: 0.148, green: 0.110, blue: 0.320)
    private static let flareCenter          = Color(red: 0.068, green: 0.060, blue: 0.138)
    private static let flareOverhead        = Color(red: 0.268, green: 0.395, blue: 0.630)
    private static let flareCornerTopBright = Color(red: 0.198, green: 0.148, blue: 0.420)
    private static let flareOverheadBright  = Color(red: 0.348, green: 0.498, blue: 0.740)

    // MARK: - Amber / PR Palette
    // Warm amber against the cold galaxy — maximum temperature contrast.

    private static let amberDeep = Color(red: 0.100, green: 0.055, blue: 0.008)
    private static let amberMid  = Color(red: 0.220, green: 0.125, blue: 0.015)
    private static let amberGlow = Color(red: 0.310, green: 0.185, blue: 0.020)
    private static let amberHot  = Color(red: 0.460, green: 0.285, blue: 0.030)

    // MARK: - Violet Palette (workout complete + theme intro)
    // Electric violet bloom — distinct from amber PR, distinct from the cold galaxy base.

    private static let violetDeep   = Color(red: 0.055, green: 0.018, blue: 0.165)
    private static let violetCorner = Color(red: 0.115, green: 0.038, blue: 0.345)
    private static let violetCore   = Color(red: 0.320, green: 0.065, blue: 0.680)

    // MARK: - Session Intensity Interpolation

    private struct RGB {
        let r, g, b: Double
        func blended(with other: RGB, t: Double) -> Color {
            Color(red: r + (other.r - r) * t,
                  green: g + (other.g - g) * t,
                  blue: b + (other.b - b) * t)
        }
    }

    // TL, TC, TR, ML, MC, MR, BL, BC, BR
    private static let baseRGB: [RGB] = [
        RGB(r: 0.080, g: 0.085, b: 0.440),  // TL — blue cloud peak
        RGB(r: 0.095, g: 0.185, b: 0.430),  // TC — blue-teal blend
        RGB(r: 0.035, g: 0.255, b: 0.255),  // TR — teal cloud peak
        RGB(r: 0.040, g: 0.050, b: 0.220),  // ML — blue drip
        RGB(r: 0.035, g: 0.032, b: 0.068),  // MC — void center
        RGB(r: 0.018, g: 0.138, b: 0.148),  // MR — teal drip
        RGB(r: 0.022, g: 0.020, b: 0.048),  // BL — void anchor
        RGB(r: 0.022, g: 0.020, b: 0.048),  // BC — void anchor
        RGB(r: 0.022, g: 0.020, b: 0.048),  // BR — void anchor
    ]

    private static let intenseRGB: [RGB] = [
        RGB(r: 0.115, g: 0.120, b: 0.580),  // TL — blue peaks
        RGB(r: 0.130, g: 0.250, b: 0.560),  // TC — blend brightens
        RGB(r: 0.052, g: 0.348, b: 0.348),  // TR — teal peaks
        RGB(r: 0.062, g: 0.075, b: 0.308),  // ML — blue drip deepens
        RGB(r: 0.035, g: 0.032, b: 0.068),  // MC — stays void
        RGB(r: 0.028, g: 0.198, b: 0.212),  // MR — teal drip deepens
        RGB(r: 0.022, g: 0.020, b: 0.048),  // BL — void anchor
        RGB(r: 0.022, g: 0.020, b: 0.048),  // BC — void anchor
        RGB(r: 0.022, g: 0.020, b: 0.048),  // BR — void anchor
    ]

    /// Returns base colors blended toward the intense palette.
    /// - Parameter intensity: 0 = fresh session, 1.0 = 20+ sets logged.
    static func base(intensity: Double) -> [Color] {
        let t = max(0, min(1, intensity))
        return zip(baseRGB, intenseRGB).map { b, i in b.blended(with: i, t: t) }
    }

    // MARK: - Grid Points (3×3, asymmetric)

    static let gridPoints: [SIMD2<Float>] = [
        SIMD2(0.0, 0.0),     SIMD2(0.48, -0.04),  SIMD2(1.0, 0.0),
        SIMD2(-0.03, 0.46),  SIMD2(0.50, 0.48),   SIMD2(1.03, 0.52),
        SIMD2(0.0, 1.0),     SIMD2(0.52, 1.04),   SIMD2(1.0, 1.0),
    ]

    // MARK: - State Color Arrays

    /// Workout started — both galaxy clouds surge brighter than the steady-state base.
    static let started: [Color] = [
        blueCornerStart, blueBlendStart, tealCornerStart,
        blueDripStart,   void1,           tealDripStart,
        void0,            void0,           void0,
    ]

    /// Set logged — stellar flare. Overhead ignites blue-white; corners lift.
    static let pulse: [Color] = [
        flareCornerTop,  flareOverhead,      flareCornerTop,
        flareCorner,     flareCenter,        flareCorner,
        flareCorner,     flareCorner,        flareCorner,
    ]

    /// Exercise complete — same flare, one clear tier brighter.
    static let exercisePulse: [Color] = [
        flareCornerTopBright,  flareOverheadBright,  flareCornerTopBright,
        flareCorner,           flareCenter,           flareCorner,
        flareCorner,           flareCorner,           flareCorner,
    ]

    /// PR — initial hot amber flash. Warm supernova against the cold galaxy.
    static let prPeak: [Color] = [
        amberMid,  amberHot,  amberMid,
        amberMid,  amberHot,  amberMid,
        amberDeep, amberMid,  amberDeep,
    ]

    /// PR — sustained amber bloom after the flash settles.
    static let prBloom: [Color] = [
        amberDeep, amberGlow, amberDeep,
        amberDeep, amberMid,  amberDeep,
        amberDeep, amberMid,  amberDeep,
    ]

    /// Workout complete / theme intro — electric violet bloom.
    static let complete: [Color] = [
        violetCorner, violetCore,   violetCorner,
        violetDeep,   violetDeep,   violetDeep,
        void0,        void0,        void0,
    ]

    // MARK: - Transition Durations

    static func transitionDuration(for state: MeshState) -> TimeInterval {
        switch state {
        case .base:             return 1.5
        case .themeIntro:       return 1.5
        case .workoutStarted:   return 0.9
        case .setLogged:        return 0.15
        case .exerciseComplete: return 0.15
        case .prBloom:          return 0.20
        case .workoutComplete:  return 0.8
        }
    }

    /// Bloom down to sustained amber (stage 2 of PR sequence).
    static let prSettle: TimeInterval = 1.20
}

/// Workout events + base.
enum MeshState: Hashable {
    case base
    case themeIntro
    case workoutStarted
    case setLogged
    case exerciseComplete
    case prBloom
    case workoutComplete
}
