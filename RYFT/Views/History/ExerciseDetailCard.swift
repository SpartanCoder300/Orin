// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

struct ExerciseDetailCard: View {
    let snapshot: ExerciseSnapshot
    @Environment(\.ryftCardMaterial) private var cardMaterial

    private var sortedSets: [SetRecord] {
        snapshot.sets.sorted { $0.loggedAt < $1.loggedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ─────────────────────────────────────────────────
            HStack(alignment: .firstTextBaseline) {
                Text(snapshot.exerciseName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: Spacing.sm)
                if let best = bestSetLabel {
                    Text(best)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm + 2)

            Divider().opacity(0.3)

            // ── Set rows ───────────────────────────────────────────────
            ForEach(Array(sortedSets.enumerated()), id: \.element.id) { idx, record in
                SetDetailRow(setNumber: idx + 1, record: record)
                if idx < sortedSets.count - 1 {
                    Divider()
                        .opacity(0.15)
                        .padding(.leading, Spacing.md)
                }
            }
        }
        .background(cardMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        .proGlass()
    }

    /// "185 lbs × 5" — heaviest working set, excluding warmups.
    private var bestSetLabel: String? {
        let working = sortedSets.filter { $0.setType != .warmup && $0.weight > 0 }
        guard let top = working.max(by: { $0.weight < $1.weight }) else { return nil }
        let w = top.weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(top.weight))" : String(format: "%.1f", top.weight)
        return "\(w) lbs × \(top.reps)"
    }
}

// MARK: - Preview

#Preview {
    {
        let snapshot = HistoryRootPreviewData.detailPreviewSession.exercises
            .sorted { $0.order < $1.order }.first!
        return ExerciseDetailCard(snapshot: snapshot)
            .padding()
            .environment(\.ryftCardMaterial, .regularMaterial)
            .modelContainer(HistoryRootPreviewData.populatedContainer)
            .preferredColorScheme(.dark)
    }()
}
