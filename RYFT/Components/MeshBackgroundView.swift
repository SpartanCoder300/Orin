// iOS 26+ only. No #available guards.

import SwiftUI

/// Living mesh background for Pro users. Renders a 3×3 MeshGradient whose
/// colors are driven by MeshEngine via SwiftUI's animation system.
///
/// No TimelineView, no per-frame ticking. The `.animation(value:)` modifier
/// on MeshGradient lets SwiftUI GPU-interpolate color transitions, making
/// this zero-cost when static.
///
/// Respects Reduce Motion — when enabled, color changes are instant (no transition).
struct MeshBackgroundView: View {
    @Environment(MeshEngine.self) private var engine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// When true, a darkening veil sits over the mesh so event pulses hit harder by contrast.
    var dimmed: Bool = false

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: MeshTheme.gridPoints,
                colors: engine.colors,
                smoothsColors: true
            )
            .animation(
                reduceMotion ? nil : .smooth(duration: engine.transitionDuration),
                value: engine.colors
            )

            if dimmed {
                Color.black.opacity(0.55)
                    .animation(
                        reduceMotion ? nil : .smooth(duration: engine.transitionDuration),
                        value: engine.colors
                    )
            }
        }
        .ignoresSafeArea()
    }
}
