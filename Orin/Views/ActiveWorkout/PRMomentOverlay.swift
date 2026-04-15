// iOS 26+ only. No #available guards.

import SwiftUI

/// Centered overlay that celebrates a new personal record.
/// Auto-dismisses after 3 seconds; tap Continue to dismiss early.
/// Dismissing starts the rest timer.
struct PRMomentOverlay: View {
    let moment: ActiveWorkoutViewModel.PRMoment
    let onDismiss: () -> Void

    @State private var symbolAnimated = false
    /// Controls the hero number and unit line together.
    @State private var numberVisible = false
    /// Controls the delta label and exercise name together, slightly delayed.
    @State private var deltaVisible = false
    /// Drives the countdown line: 1.0 → 0.0 over the auto-dismiss duration.
    @State private var dismissProgress: Double = 1.0

    private let autoDismissDuration: Double = 4.0

    var body: some View {
        VStack(spacing: 0) {

            // ── Trophy + eyebrow (tight pair) ────────────────────────────────────
            Image(systemName: "trophy.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.OrinGold.opacity(0.88))
                .symbolEffect(.bounce.up, value: symbolAnimated)
                .padding(.bottom, 7)

            Text("Personal Record")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.OrinGold.opacity(0.72))
                .textCase(.uppercase)
                .tracking(1.6)
                .padding(.bottom, 22)

            // ── Hero number (first beat) ─────────────────────────────────────────
            Text(moment.formattedWeight)
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .offset(y: numberVisible ? 0 : 5)
                .opacity(numberVisible ? 1 : 0)

            Text("lbs  ·  \(moment.reps) reps")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.primary.opacity(0.60))
                .opacity(numberVisible ? 1 : 0)
                .padding(.top, 3)
                .padding(.bottom, 12)

            // ── Delta (second beat, ~200ms later) ───────────────────────────────
            Label(moment.deltaText, systemImage: "arrow.up")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.OrinGold.opacity(0.88))
                .offset(y: deltaVisible ? 0 : 3)
                .opacity(deltaVisible ? 1 : 0)
                .padding(.bottom, 18)

            // ── Exercise name (supporting context) ───────────────────────────────
            Text(moment.exerciseName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary.opacity(0.84))
                .multilineTextAlignment(.center)
                .opacity(deltaVisible ? 1 : 0)
                .padding(.bottom, 26)

            // ── Continue button ──────────────────────────────────────────────────
            Button("Continue", action: onDismiss)
                .buttonStyle(.plain)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.white.opacity(0.10), in: Capsule())

            // ── Countdown line — thin, architectural, separate from button ────────
            Capsule()
                .fill(Color.OrinGold.opacity(0.30))
                .frame(maxWidth: .infinity, maxHeight: 1.5)
                .scaleEffect(x: dismissProgress, y: 1, anchor: .leading)
                .animation(.linear(duration: autoDismissDuration), value: dismissProgress)
                .padding(.top, 14)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 30)
        .frame(maxWidth: 320)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onAppear {
            // Trophy
            symbolAnimated = true

            // First beat: hero number lifts in
            withAnimation(.spring(response: 0.26, dampingFraction: 0.68).delay(0.06)) {
                numberVisible = true
            }

            // Second beat: delta + exercise name fade up
            withAnimation(.easeOut(duration: 0.22).delay(0.22)) {
                deltaVisible = true
            }

            AccessibilityNotification.Announcement(
                "Personal Record! \(moment.exerciseName). \(moment.formattedWeight) pounds, \(moment.reps) reps. \(moment.deltaText)."
            ).post()
        }
        .task {
            // Start countdown one frame after appear so animation is visible from full width
            await Task.yield()
            dismissProgress = 0.0
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
                previousWeight: 195,
                previousReps: 5
            ),
            onDismiss: {}
        )
    }
}
