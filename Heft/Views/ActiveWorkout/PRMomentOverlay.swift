// iOS 26+ only. No #available guards.

import SwiftUI

/// Centered Liquid Glass overlay that celebrates a new personal record.
/// Appears immediately when a PR is logged. Dismissing it starts the rest timer.
struct PRMomentOverlay: View {
    let moment: ActiveWorkoutViewModel.PRMoment
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {

            // ── Trophy + label ─────────────────────────────────────────────────
            VStack(spacing: Spacing.sm) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.heftGold, Color.heftAmber],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.heftGold.opacity(0.5), radius: 16)

                Text("NEW PR")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(3.0)
                    .foregroundStyle(Color.heftGold)
            }

            // ── Exercise name ──────────────────────────────────────────────────
            Text(moment.exerciseName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            // ── Set + e1RM ─────────────────────────────────────────────────────
            VStack(spacing: Spacing.xs) {
                Text("\(moment.formattedWeight) lbs × \(moment.reps) reps")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)

                Text("~\(moment.formattedE1RM) lbs estimated 1RM")
                    .font(.subheadline)
                    .foregroundStyle(Color.heftAmber.opacity(0.8))
            }

            // ── Dismiss ────────────────────────────────────────────────────────
            Button(action: onDismiss) {
                Text("Let's Go")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.heftGold, Color.heftAmber],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: 340)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.heftGold.opacity(0.6),
                            Color.heftAmber.opacity(0.3),
                            Color.heftGold.opacity(0.4),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.heftGold.opacity(0.2), radius: 48, x: 0, y: 8)
        .shadow(color: Color.heftAmber.opacity(0.1), radius: 80, x: 0, y: 0)
        .padding(.horizontal, Spacing.lg)
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
