// iOS 26+ only. No #available guards.

import SwiftUI

/// Color palette and state arrays for the Pro mesh background.
///
/// Three moments. That's it.
/// 1. Set logged → steel-blue overhead flare
/// 2. PR → amber floods the screen (two-stage: hot flash → sustained bloom)
/// 3. Workout complete → gold wash
///
/// Everything else is warm-neutral charcoal — aged concrete and raw iron,
/// not colored. Events fire against that neutral so each rep has something
/// to push against.
enum MeshTheme {

    // MARK: - Warm-Neutral Rest Palette (stone)
    // Used for the ambient base state and session intensity blend.
    // No hue bias — like concrete under tungsten. Slightly warm so it
    // doesn't feel clinical, but reads as "off" compared to any event color.

    /// Near-black warm concrete — corners and shadow regions.
    private static let stone0 = Color(red: 0.038, green: 0.036, blue: 0.032)
    /// Center shadow — gap between the two light sources.
    private static let stone1 = Color(red: 0.052, green: 0.050, blue: 0.046)
    /// Floor reflection — cool-ish, barely visible at rest.
    private static let stone2 = Color(red: 0.075, green: 0.072, blue: 0.068)
    /// Overhead tungsten — the single visible light source at rest.
    private static let stone3 = Color(red: 0.120, green: 0.110, blue: 0.095)
    /// Bright tungsten — overhead at full draw during a pulse. Same warmth, more output.
    private static let stoneBright = Color(red: 0.195, green: 0.178, blue: 0.152)
    /// Peak tungsten — every overhead at full draw. Only used for workout complete.
    private static let stonePeak = Color(red: 0.285, green: 0.260, blue: 0.222)

    // MARK: - Steel-Blue Event Palette (iron)
    // Two sub-groups:
    //
    // "steel" — gym-light color-temperature shift. Same luminance as the stone
    //   sources but warm tungsten → cool steel. TC and BC shift color; corners
    //   barely move. Used for set-logged and exercise-complete.
    //
    // "iron" — high-intensity burst. Much brighter. Reserved for workout-started
    //   and any future peak-intensity moments.

    // Steel tints: ≈ stone luma, just blue-cast.
    // steelCorner   ≈ stone0 (2%)  — barely blue, corners stay dark
    // steelCenter   ≈ stone1 (3%)  — slight blue lift, center shadow
    // steelFloor    ≈ stone2 (7%)  — floor reflection shifts cool
    // steelOverhead ≈ stone3 (11%) — overhead shifts from tungsten to steel
    private static let steelCorner   = Color(red: 0.038, green: 0.042, blue: 0.080)
    private static let steelCenter   = Color(red: 0.050, green: 0.058, blue: 0.092)
    private static let steelFloor    = Color(red: 0.058, green: 0.072, blue: 0.122)
    private static let steelOverhead = Color(red: 0.088, green: 0.108, blue: 0.188)

    // One tier brighter — exercise-complete. Clearly visible step up from set-logged.
    private static let steelFloorBright    = Color(red: 0.078, green: 0.098, blue: 0.165)
    private static let steelOverheadBright = Color(red: 0.125, green: 0.155, blue: 0.265)

    // Iron — high-output burst for workout-started / peak moments.
    private static let iron0 = Color(red: 0.035, green: 0.040, blue: 0.075)
    private static let iron1 = Color(red: 0.065, green: 0.080, blue: 0.145)
    private static let iron2 = Color(red: 0.110, green: 0.135, blue: 0.230)
    private static let iron3 = Color(red: 0.175, green: 0.210, blue: 0.355)
    private static let iron4 = Color(red: 0.260, green: 0.305, blue: 0.490)
    private static let iron5 = Color(red: 0.360, green: 0.415, blue: 0.600)

    // MARK: - Amber/PR Palette

    private static let amberDeep = Color(red: 0.100, green: 0.055, blue: 0.008)
    private static let amberMid  = Color(red: 0.220, green: 0.125, blue: 0.015)
    private static let amberGlow = Color(red: 0.310, green: 0.185, blue: 0.020)
    /// Hot flash — the initial PR snap, almost too bright.
    private static let amberHot  = Color(red: 0.460, green: 0.285, blue: 0.030)

    // MARK: - Session Intensity Interpolation

    private struct RGB {
        let r, g, b: Double
        func blended(with other: RGB, t: Double) -> Color {
            Color(red: r + (other.r - r) * t,
                  green: g + (other.g - g) * t,
                  blue: b + (other.b - b) * t)
        }
    }

    // Resting layout — two warm sources, everything else near-black:
    //   TC = overhead tungsten (brightest)
    //   BC = floor reflection (dimmer, cooler)
    //   Center = shadow between sources
    //   Corners/sides = near-black concrete
    private static let baseRGB: [RGB] = [
        RGB(r: 0.038, g: 0.036, b: 0.032),  // TL — dark corner (stone0)
        RGB(r: 0.120, g: 0.110, b: 0.095),  // TC — overhead tungsten (stone3)
        RGB(r: 0.038, g: 0.036, b: 0.032),  // TR — dark corner (stone0)
        RGB(r: 0.038, g: 0.036, b: 0.032),  // ML — dark side (stone0)
        RGB(r: 0.052, g: 0.050, b: 0.046),  // center — shadow (stone1)
        RGB(r: 0.038, g: 0.036, b: 0.032),  // MR — dark side (stone0)
        RGB(r: 0.038, g: 0.036, b: 0.032),  // BL — dark corner (stone0)
        RGB(r: 0.075, g: 0.072, b: 0.068),  // BC — floor reflection (stone2)
        RGB(r: 0.038, g: 0.036, b: 0.032),  // BR — dark corner (stone0)
    ]

    // At full intensity both sources brighten — still warm, just more presence.
    private static let intenseRGB: [RGB] = [
        RGB(r: 0.065, g: 0.060, b: 0.053),  // TL — wakes up
        RGB(r: 0.185, g: 0.168, b: 0.145),  // TC — overhead peaks
        RGB(r: 0.065, g: 0.060, b: 0.053),  // TR — wakes up
        RGB(r: 0.060, g: 0.057, b: 0.052),  // ML — wakes up
        RGB(r: 0.082, g: 0.078, b: 0.070),  // center — lifts slightly
        RGB(r: 0.060, g: 0.057, b: 0.052),  // MR — wakes up
        RGB(r: 0.038, g: 0.036, b: 0.032),  // BL — stays dark (anchor)
        RGB(r: 0.115, g: 0.108, b: 0.098),  // BC — reflection brightens
        RGB(r: 0.038, g: 0.036, b: 0.032),  // BR — stays dark (anchor)
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

    /// Workout started — warm overhead flares wide, like gym lights coming on.
    /// More spread than a set pulse; settles back over 0.5s.
    static let started: [Color] = [
        stone1, stoneBright, stone1,
        stone1, stone2,      stone1,
        stone0, stone2,      stone0,
    ]

    /// Set logged — overhead and floor shift from warm tungsten to cool steel.
    /// Same brightness as base; only the color temperature changes. Subtle but physical.
    static let pulse: [Color] = [
        steelCorner,  steelOverhead,       steelCorner,
        steelCorner,  steelCenter,         steelCorner,
        steelCorner,  steelFloor,          steelCorner,
    ]

    /// Exercise complete — same color shift, one clear tier brighter.
    static let exercisePulse: [Color] = [
        steelCorner,  steelOverheadBright, steelCorner,
        steelCorner,  steelCenter,         steelCorner,
        steelCorner,  steelFloorBright,    steelCorner,
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

    /// Workout complete — every overhead at full draw. The room fully lit, warm white.
    static let complete: [Color] = [
        stone1,       stonePeak,   stone1,
        stone2,       stoneBright, stone2,
        stone1,       stoneBright, stone1,
    ]

    // MARK: - Transition Durations

    static func transitionDuration(for state: MeshState) -> TimeInterval {
        switch state {
        case .base:             return 1.5
        case .themeIntro:       return 1.5   // slow, deliberate bloom
        case .workoutStarted:   return 0.5
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
