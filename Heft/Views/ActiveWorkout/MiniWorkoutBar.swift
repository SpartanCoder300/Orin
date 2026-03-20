// iOS 26+ only. No #available guards.

import SwiftUI

/// Mini workout bar rendered inside .tabViewBottomAccessory(isEnabled:).
/// The system provides the Liquid Glass capsule — this view supplies only the content layout.
struct MiniWorkoutBar: View {
    let service: ActiveWorkoutService
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        if let vm = service.viewModel {
            HStack(spacing: 0) {
                // ── Left: tap to open full workout ───────────────────────────
                Button {
                    service.isShowingFullWorkout = true
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(service.focusedExerciseName ?? "Workout")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        TimelineView(.periodic(from: vm.openedAt, by: 1.0)) { ctx in
                            Text(vm.elapsedLabel(at: ctx.date))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 28)
                    .padding(.horizontal, 12)

                // ── Right: rest timer ────────────────────────────────────────
                Button {
                    service.isShowingFullWorkout = true
                } label: {
                    RestTimerIndicator(timer: vm.restTimer)
                        .padding(.trailing, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Compact rest timer display for the mini bar.
private struct RestTimerIndicator: View {
    let timer: RestTimerState

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { ctx in
            let _ = timer.tick(at: ctx.date)

            if timer.isActive, let label = timer.remainingLabel(at: ctx.date) {
                let phase = timer.tintColor(at: ctx.date)
                Text(label)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(phaseColor(phase))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
            } else {
                Image(systemName: "timer")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func phaseColor(_ phase: TimerTintPhase) -> Color {
        switch phase {
        case .green: Color.heftGreen
        case .amber: Color.heftAmber
        case .red:   Color.heftRed
        }
    }
}
