// iOS 26+ only. No #available guards.

import SwiftUI

/// Centered overlay that celebrates a new personal record.
/// Appears immediately when a PR is logged. Dismissing starts the rest timer.
struct PRMomentOverlay: View {
    let moment: ActiveWorkoutViewModel.PRMoment
    let onDismiss: () -> Void

    @State private var symbolAnimated = false

    var body: some View {
        VStack(spacing: 20) {

            // ── Trophy ──────────────────────────────────────────────────────────
            Image(systemName: "trophy.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.heftGold)
                .symbolEffect(.bounce, value: symbolAnimated)
                .padding(.bottom, 4)

            // ── Labels ──────────────────────────────────────────────────────────
            VStack(spacing: 6) {
                Text("Personal Record")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.heftGold)
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
            Button("Continue", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color.heftGold)
                .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: 320)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onAppear { symbolAnimated = true }
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
