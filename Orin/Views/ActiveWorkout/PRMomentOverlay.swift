// iOS 26+ only. No #available guards.

import SwiftUI

/// Centered overlay that celebrates a new personal record.
/// Auto-dismisses after 3 seconds; tap Continue to dismiss early.
/// Dismissing starts the rest timer.
struct PRMomentOverlay: View {
    let moment: ActiveWorkoutViewModel.PRMoment
    let onDismiss: () -> Void

    @State private var symbolAnimated = false
    /// Drives the countdown bar: 1.0 → 0.0 over 3 seconds.
    @State private var dismissProgress: Double = 1.0

    private let autoDismissDuration: Double = 3.0

    var body: some View {
        VStack(spacing: 20) {

            // ── Trophy ──────────────────────────────────────────────────────────
            Image(systemName: "trophy.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.OrinGold)
                .symbolEffect(.bounce, value: symbolAnimated)
                .padding(.bottom, 4)

            // ── Labels ──────────────────────────────────────────────────────────
            VStack(spacing: 6) {
                Text("Personal Record")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.OrinGold)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text(moment.exerciseName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }

            // ── Numbers ─────────────────────────────────────────────────────────
            VStack(spacing: 4) {
                Text("\(moment.formattedWeight) lbs × \(moment.reps) reps")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text("~\(moment.formattedE1RM) lbs estimated 1RM")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // ── Dismiss ─────────────────────────────────────────────────────────
            VStack(spacing: 10) {
                Button("Continue", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Color.OrinGold)

                // Countdown bar — drains left-to-right over autoDismissDuration
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.OrinGold.opacity(0.35))
                        .frame(width: geo.size.width * dismissProgress)
                        .animation(.linear(duration: autoDismissDuration), value: dismissProgress)
                }
                .frame(height: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            }
            .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: 320)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onAppear { symbolAnimated = true }
        .task {
            // Start countdown bar one frame after appear so animation is visible
            await Task.yield()
            dismissProgress = 0.0
            // Auto-dismiss after the full duration
            try? await Task.sleep(for: .seconds(autoDismissDuration))
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PRMomentOverlay(
            moment: ActiveWorkoutViewModel.PRMoment(
                exerciseName: "Bench Press",
                weight: 225,
                reps: 5,
                estimatedOneRepMax: 262.5
            ),
            onDismiss: {}
        )
    }
}
