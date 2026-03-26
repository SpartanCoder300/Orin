// iOS 26+ only. No #available guards.

import SwiftUI

struct SetDetailRow: View {
    let setNumber: Int
    let record: SetRecord

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(setNumber)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.tertiary)
                        .frame(width: 24, alignment: .leading)

                    if record.setType != .normal {
                        SetTypeLabel(setType: record.setType)
                    }

                    if record.isPersonalRecord {
                        Text("PR")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.ryftAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.ryftAmber.opacity(0.14), in: Capsule())
                    }
                }

                if record.isPersonalRecord {
                    let e1rm = ExerciseDefinition.estimatedOneRepMax(weight: record.weight, reps: record.reps)
                    if e1rm > 0 {
                        Text("e1RM \(formattedE1RM(e1rm))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 30)
                    }
                }
            }

            Spacer()

            // Weight × Reps
            HStack(spacing: 6) {
                if record.weight > 0 {
                    HStack(spacing: 2) {
                        Text(formattedWeight)
                            .foregroundStyle(.primary)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }
                    .font(.body.monospacedDigit().weight(.medium))
                } else {
                    Text("Bodyweight")
                        .font(.body.monospacedDigit().weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Text("×")
                    .font(.body)
                    .foregroundStyle(.tertiary)

                Text("\(record.reps)")
                    .font(.body.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 11)
    }

    private var formattedWeight: String {
        let w = record.weight
        return w.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(w))" : String(format: "%.1f", w)
    }

    private func formattedE1RM(_ v: Double) -> String {
        "\(Int(v.rounded()))"
    }
}
