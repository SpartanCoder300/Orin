// iOS 26+ only. No #available guards.

import SwiftUI

/// Color palette and state arrays for the Pro mesh background.
///
/// Three moments. That's it.
/// 1. Set logged → overhead lights flare
/// 2. PR → amber floods the screen (two-stage: hot flash → sustained bloom)
/// 3. Workout complete → green wash
///
/// Everything else is static dark steel — two light sources (overhead + floor
/// reflection), dark center and sides. Think dim gym at 5 AM, not a nightclub.
enum MeshTheme {

    // MARK: - Charcoal Palette
    // Near-neutral dark gray — blue channel only ~1.15× red, so it reads as
    // cool charcoal rather than blue-black. Clearly distinct from Midnight's
    // indigo cast. Event colors (amber PR, green complete) pop harder against
    // neutral than against a blue background.

    /// Near-black charcoal — corners, sides, shadow regions.
    private static let iron0 = Color(red: 0.038, green: 0.040, blue: 0.044)
    /// Dark charcoal — barely-lit surfaces.
    private static let iron1 = Color(red: 0.062, green: 0.065, blue: 0.072)
    /// Mid charcoal — floor reflection light spill.
    private static let iron2 = Color(red: 0.092, green: 0.097, blue: 0.108)
    /// Light charcoal — overhead light source glow.
    private static let iron3 = Color(red: 0.128, green: 0.135, blue: 0.150)
    /// Bright charcoal — pulse edges and started state.
    private static let iron4 = Color(red: 0.175, green: 0.185, blue: 0.205)
    /// Strong flare — overhead burst during pulse.
    private static let iron5 = Color(red: 0.248, green: 0.262, blue: 0.290)
    /// Peak pulse — absolute ceiling of the set-logged flare.
    private static let iron6 = Color(red: 0.325, green: 0.342, blue: 0.378)

    // MARK: - Amber/PR Palette

    private static let amberDeep = Color(red: 0.100, green: 0.055, blue: 0.008)
    private static let amberMid  = Color(red: 0.220, green: 0.125, blue: 0.015)
    private static let amberGlow = Color(red: 0.310, green: 0.185, blue: 0.020)
    /// Hot flash — the initial PR snap, almost too bright.
    private static let amberHot  = Color(red: 0.460, green: 0.285, blue: 0.030)

    // MARK: - Green/Complete Palette

    private static let greenDeep = Color(red: 0.012, green: 0.072, blue: 0.032)
    private static let greenMid  = Color(red: 0.025, green: 0.145, blue: 0.062)
    private static let greenGlow = Color(red: 0.040, green: 0.220, blue: 0.090)
    /// Peak green — vivid enough to feel like a finish line crossed.
    private static let greenHot  = Color(red: 0.055, green: 0.320, blue: 0.125)

    // MARK: - Session Intensity Interpolation

    /// Linear blend between base (empty session) and intense (20+ sets logged).
    /// Two-source lighting: overhead (top-center) + floor reflection (bottom-center).
    /// Center and sides stay dark for depth.
    private struct RGB {
        let r, g, b: Double
        func blended(with other: RGB, t: Double) -> Color {
            Color(red: r + (other.r - r) * t,
                  green: g + (other.g - g) * t,
                  blue: b + (other.b - b) * t)
        }
    }

    // Two-source gym lighting layout:
    //   TC = overhead light (brightest)
    //   BC = floor reflection (dimmer, cooler)
    //   Center = dark (depth/shadow between the two sources)
    //   Sides = dark (light doesn't reach)
    private static let baseRGB: [RGB] = [
        RGB(r: 0.038, g: 0.040, b: 0.044),  // TL — dark corner
        RGB(r: 0.128, g: 0.135, b: 0.150),  // TC — overhead light (iron3)
        RGB(r: 0.038, g: 0.040, b: 0.044),  // TR — dark corner
        RGB(r: 0.038, g: 0.040, b: 0.044),  // ML — dark side
        RGB(r: 0.062, g: 0.065, b: 0.072),  // center — shadow between sources (iron1)
        RGB(r: 0.038, g: 0.040, b: 0.044),  // MR — dark side
        RGB(r: 0.038, g: 0.040, b: 0.044),  // BL — dark corner
        RGB(r: 0.092, g: 0.097, b: 0.108),  // BC — floor reflection (iron2)
        RGB(r: 0.038, g: 0.040, b: 0.044),  // BR — dark corner
    ]

    // At full intensity, both light sources intensify and sides wake up slightly.
    private static let intenseRGB: [RGB] = [
        RGB(r: 0.062, g: 0.065, b: 0.072),  // TL — wakes up
        RGB(r: 0.175, g: 0.185, b: 0.205),  // TC — overhead peaks (iron4)
        RGB(r: 0.062, g: 0.065, b: 0.072),  // TR — wakes up
        RGB(r: 0.062, g: 0.065, b: 0.072),  // ML — wakes up
        RGB(r: 0.092, g: 0.097, b: 0.108),  // center — lifts slightly (iron2)
        RGB(r: 0.062, g: 0.065, b: 0.072),  // MR — wakes up
        RGB(r: 0.038, g: 0.040, b: 0.044),  // BL — stays dark (anchor)
        RGB(r: 0.128, g: 0.135, b: 0.150),  // BC — reflection brightens (iron3)
        RGB(r: 0.038, g: 0.040, b: 0.044),  // BR — stays dark (anchor)
    ]

    /// Returns base colors blended toward the intense palette.
    /// - Parameter intensity: 0 = fresh session, 1.0 = 20+ sets logged.
    static func base(intensity: Double) -> [Color] {
        let t = max(0, min(1, intensity))
        return zip(baseRGB, intenseRGB).map { b, i in b.blended(with: i, t: t) }
    }

    // MARK: - Grid Points (3×3, asymmetric)
    // Top-center and bottom-center are the two light source control points.
    // They're shifted slightly off-grid to break symmetry and feel organic.

    static let gridPoints: [SIMD2<Float>] = [
        SIMD2(0.0, 0.0),    SIMD2(0.48, -0.04),  SIMD2(1.0, 0.0),
        SIMD2(-0.03, 0.46),  SIMD2(0.50, 0.48),   SIMD2(1.03, 0.52),
        SIMD2(0.0, 1.0),    SIMD2(0.52, 1.04),   SIMD2(1.0, 1.0),
    ]

    // MARK: - State Color Arrays (two-source lighting maintained)

    /// Workout started — all lights come on simultaneously. Even illumination,
    /// no directional bias. Settles back to two-source base over 1.5s.
    static let started: [Color] = [
        iron2, iron4, iron2,
        iron3, iron5, iron3,
        iron2, iron4, iron2,
    ]

    /// Set logged — overhead lights blast, reflection surges, whole room wakes up.
    static let pulse: [Color] = [
        iron2, iron6, iron2,
        iron2, iron4, iron2,
        iron1, iron5, iron1,
    ]

    /// PR — initial hot amber flash. Top brighter, bottom cooler.
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

    /// Exercise complete — brief green flash at both light sources only.
    /// Dimmer than workoutComplete; reads as "milestone" not "finished".
    static let exercisePulse: [Color] = [
        iron1,     greenMid,  iron1,
        iron1,     greenGlow, iron1,
        iron0,     greenMid,  iron0,
    ]

    /// Workout complete — green wash. Light sources go green, center fills.
    static let complete: [Color] = [
        greenDeep, greenHot,  greenDeep,
        greenMid,  greenGlow, greenMid,
        greenDeep, greenGlow, greenDeep,
    ]

    // MARK: - Transition Durations

    /// Duration for each state transition. Animation is applied at the view layer.
    static func transitionDuration(for state: MeshState) -> TimeInterval {
        switch state {
        case .base:             return 1.5
        case .workoutStarted:   return 0.5   // deliberate build, not a snap
        case .setLogged:        return 0.15
        case .exerciseComplete: return 0.15  // same snap-in, different color
        case .prBloom:          return 0.20  // stage 1 — prSettle handled separately
        case .workoutComplete:  return 0.8
        }
    }

    /// Bloom down to sustained amber (stage 2 of PR sequence).
    static let prSettle: TimeInterval = 1.20
}

/// Workout events + base.
enum MeshState: Hashable {
    case base
    case workoutStarted
    case setLogged
    case exerciseComplete
    case prBloom
    case workoutComplete
}
