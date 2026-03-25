// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

struct HomeRecentSection: View {
    let sessions: [WorkoutSession]
    let onRepeat: (WorkoutSession) -> Void

    var body: some View {
        if !sessions.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Recent")
                ForEach(sessions) { session in
                    RecentWorkoutListRow(session: session) {
                        onRepeat(session)
                    }
                }
            }
        }
    }
}

// MARK: - Recent Workout Row

private struct RecentWorkoutListRow: View {
    let session: WorkoutSession
    let onRepeat: () -> Void

    @Environment(\.ryftCardMaterial) private var cardMaterial

    var body: some View {
        Button(action: onRepeat) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(dateLabel)
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    if let summary = exerciseSummary {
                        Text(summary)
                            .font(Typography.caption)
                            .foregroundStyle(Color.textMuted)
                            .lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    if let d = durationLabel {
                        Text(d)
                            .font(Typography.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                    Text("Repeat →")
                        .font(Typography.caption)
                        .foregroundStyle(Color.textFaint)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
            .proGlass()
        }
        .buttonStyle(.plain)
    }

    private var dateLabel: String {
        let date = session.completedAt ?? session.startedAt ?? .now
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private var durationLabel: String? {
        guard let start = session.startedAt, let end = session.completedAt else { return nil }
        let minutes = Int(end.timeIntervalSince(start) / 60)
        return "\(minutes) min"
    }

    private var exerciseSummary: String? {
        let names = session.exercises
            .sorted { $0.order < $1.order }
            .prefix(3)
            .map { $0.exerciseName }
        return names.isEmpty ? nil : names.joined(separator: " · ")
    }
}

#Preview("Empty") {
    NavigationStack {
        ScrollView {
            HomeRecentSection(sessions: [], onRepeat: { _ in })
                .padding()
        }
    }
    .environment(MeshEngine())
    .modelContainer(HomePreviewData.container)
    .preferredColorScheme(.dark)
}

#Preview("With recent") {
    NavigationStack {
        ScrollView {
            HomeRecentSection(sessions: HomePreviewData.recentSessions, onRepeat: { _ in })
                .padding()
        }
    }
    .environment(MeshEngine())
    .modelContainer(HomePreviewData.container)
    .preferredColorScheme(.dark)
}
