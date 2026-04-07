// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

struct ExerciseHistorySessionCard: View {
    let snapshot: ExerciseSnapshot
    var showTime: Bool = false

    private var sortedSets: [SetRecord] {
        snapshot.sets.sorted { $0.loggedAt < $1.loggedAt }
    }

    private var dateLabel: String {
        guard let date = snapshot.workoutSession?.completedAt else { return "Unknown Date" }
        let cal = Calendar.current
        let time = showTime ? " · \(date.formatted(date: .omitted, time: .shortened))" : ""
        if cal.isDateInToday(date)     { return "Today\(time)" }
        if cal.isDateInYesterday(date) { return "Yesterday\(time)" }
        let sameYear = cal.component(.year, from: date) == cal.component(.year, from: .now)
        let base = sameYear
            ? date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
            : date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
        return "\(base)\(time)"
    }

    /// ID of the heaviest PR set in this session — only this one shows the badge.
    private var topPRSetID: UUID? {
        sortedSets
            .filter { $0.isPersonalRecord }
            .max { a, b in a.weight != b.weight ? a.weight < b.weight : a.reps < b.reps }?
            .id
    }

    private var maxWeightLabel: String? {
        let w = sortedSets.filter { $0.setType != .warmup }.map(\.weight).max() ?? 0
        guard w > 0 else { return nil }
        return w.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(w)) lbs" : String(format: "%.1f lbs", w)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ─────────────────────────────────────────────────
            HStack(alignment: .firstTextBaseline) {
                Text(dateLabel)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer(minLength: Spacing.sm)
                if let label = maxWeightLabel {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm + 2)

            Divider().opacity(0.3)

            // ── Set rows ───────────────────────────────────────────────
            let prID = topPRSetID
            ForEach(Array(sortedSets.enumerated()), id: \.element.id) { idx, record in
                SetDetailRow(setNumber: idx + 1, record: record, showPRBadge: record.id == prID)
                if idx < sortedSets.count - 1 {
                    Divider()
                        .opacity(0.15)
                        .padding(.leading, Spacing.md)
                }
            }
        }
        .cardSurface(border: true)
    }
}

// MARK: - Preview

#Preview {
    {
        let snapshot = HistoryRootPreviewData.exerciseHistorySnapshots.first!
        return ExerciseHistorySessionCard(snapshot: snapshot)
            .padding()
            .environment(\.OrinCardMaterial, .regularMaterial)
            .modelContainer(HistoryRootPreviewData.exerciseHistoryContainer)
            .preferredColorScheme(.dark)
    }()
}
