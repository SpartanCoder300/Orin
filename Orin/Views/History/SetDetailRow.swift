// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData
import SwiftData

struct SetDetailRow: View {
    let setNumber: Int
    let record: SetRecord
    /// Overrides `record.isPersonalRecord` for badge display. Nil = use record flag.
    var showPRBadge: Bool? = nil

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

                    if showPRBadge ?? record.isPersonalRecord {
                        PRBadge()
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

}

// MARK: - Previews

#Preview("Normal set") {
    {
        let snapshot = HistoryRootPreviewData.detailPreviewSession.exercises
            .sorted { $0.order < $1.order }.first!
        let record = snapshot.sets.sorted { $0.loggedAt < $1.loggedAt }.first!
        return SetDetailRow(setNumber: 1, record: record)
            .modelContainer(HistoryRootPreviewData.populatedContainer)
            .preferredColorScheme(.dark)
    }()
}

#Preview("PR set") {
    {
        let snapshot = HistoryRootPreviewData.detailPreviewSession.exercises
            .sorted { $0.order < $1.order }[1]
        let record = snapshot.sets.sorted { $0.loggedAt < $1.loggedAt }
            .first(where: { $0.isPersonalRecord }) ?? snapshot.sets[0]
        return SetDetailRow(setNumber: 1, record: record)
            .modelContainer(HistoryRootPreviewData.populatedContainer)
            .preferredColorScheme(.dark)
    }()
}
