// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

struct HomeRootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.heftTheme) private var theme

    @Query(sort: \RoutineTemplate.createdAt, order: .reverse)
    private var routines: [RoutineTemplate]

    @Query(sort: \WorkoutSession.startedAt, order: .reverse)
    private var sessions: [WorkoutSession]

    @State private var stats = HomeStatsViewModel()

    private var featuredRoutine: RoutineTemplate? { routines.first }
    private var remainingRoutines: [RoutineTemplate] { Array(routines.dropFirst()) }

    var body: some View {
        @Bindable var appState = appState

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {

                // ── Greeting ───────────────────────────────────────────
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide)))
                        .font(Typography.caption)
                        .foregroundStyle(Color.textFaint)
                        .textCase(.uppercase)
                        .tracking(1)
                    Text("Ready to lift?")
                        .font(Typography.display)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)
                }

                // ── Stat Chips ─────────────────────────────────────────
                HStack(spacing: Spacing.sm) {
                    StatChip(label: "Day Streak", value: stats.streakLabel)
                    StatChip(label: "This Week", value: stats.thisWeekLabel)
                    StatChip(label: "PRs", value: stats.prCountLabel, valueColor: Color.heftAmber)
                }

                // ── Quick Start ────────────────────────────────────────
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SectionHeader(title: "Quick Start")

                    if let featured = featuredRoutine {
                        FeaturedRoutineCard(routine: featured) {
                            appState.pendingRoutineID = featured.id
                            appState.isShowingActiveWorkout = true
                        }
                    } else {
                        EmptyRoutinesPrompt()
                    }

                    // Secondary option — spec requires a direct empty-start path
                    Button {
                        appState.pendingRoutineID = nil
                        appState.isShowingActiveWorkout = true
                    } label: {
                        Text("or start empty workout")
                            .font(Typography.caption)
                            .foregroundStyle(Color.textFaint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xs)
                    }
                    .buttonStyle(.plain)
                }

                // ── All Routines ───────────────────────────────────────
                if !routines.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        SectionHeader(title: "All Routines")

                        ForEach(remainingRoutines) { routine in
                            RoutineListRow(routine: routine) {
                                appState.pendingRoutineID = routine.id
                                appState.isShowingActiveWorkout = true
                            }
                        }

                        NewRoutineCard()
                    }
                }

                // ── Recent Workouts ────────────────────────────────────
                if !stats.recentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        SectionHeader(title: "Recent")
                        ForEach(stats.recentSessions) { session in
                            RecentWorkoutListRow(session: session)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .navigationTitle("Heft")
        .navigationBarTitleDisplayMode(.inline)
        .themedBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // §7 Routine Builder — wired when built
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $appState.isShowingActiveWorkout) {
            // §8 Active Workout Screen — placeholder until built
            Text("Active Workout")
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.heftBackground.ignoresSafeArea())
        }
        .onChange(of: sessions, initial: true) {
            stats.update(from: sessions, container: modelContext.container)
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textFaint)
                .textCase(.uppercase)
                .tracking(0.8)
            Spacer()
            if let detail {
                Text(detail)
                    .font(Typography.caption)
                    .foregroundStyle(Color.textFaint)
            }
        }
    }
}

// MARK: - Stat Chip

private struct StatChip: View {
    let label: String
    let value: String
    var valueColor: Color = Color.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Typography.title)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.textFaint)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
    }
}

// MARK: - Featured Routine Card

private struct FeaturedRoutineCard: View {
    let routine: RoutineTemplate
    let onTap: () -> Void
    @Environment(\.heftTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(routine.name)
                        .font(Typography.heading)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    if let label = lastUsedLabel {
                        Text(label)
                            .font(Typography.caption)
                            .foregroundStyle(Color.textFaint)
                    }
                }

                HStack(spacing: Spacing.md) {
                    MetadataPill(value: "\(routine.entries.count)", label: "exercises")
                    MetadataPill(value: "—", label: "min avg")  // §15 analytics — placeholder
                    MetadataPill(value: "\(totalSets)", label: "sets")
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                    .strokeBorder(theme.accentColor.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var lastUsedLabel: String? {
        guard let date = routine.lastUsedAt else { return nil }
        return date.formatted(.relative(presentation: .named, unitsStyle: .wide))
    }

    private var totalSets: Int {
        routine.entries.reduce(0) { $0 + $1.targetSets }
    }
}

private struct MetadataPill: View {
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .foregroundStyle(Color.textMuted)
        }
        .font(Typography.caption)
    }
}

// MARK: - Routine List Row

private struct RoutineListRow: View {
    let routine: RoutineTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(routine.name)
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    if !muscleGroupSummary.isEmpty {
                        Text(muscleGroupSummary)
                            .font(Typography.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("\(routine.entries.count) exercises")
                        .font(Typography.caption)
                        .foregroundStyle(Color.textMuted)
                    Text("— min avg")      // §15 analytics — placeholder
                        .font(Typography.caption)
                        .foregroundStyle(Color.textFaint)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// Unique muscle groups from this routine's exercise definitions, up to 3.
    private var muscleGroupSummary: String {
        var seen = Set<String>()
        var ordered: [String] = []
        for entry in routine.entries {
            for group in (entry.exerciseDefinition?.muscleGroups ?? []) {
                if seen.insert(group).inserted { ordered.append(group) }
            }
        }
        return ordered.prefix(3).joined(separator: " · ")
    }
}

// MARK: - New Routine Card

private struct NewRoutineCard: View {
    @Environment(\.heftTheme) private var theme

    var body: some View {
        Button {
            // §7 Routine Builder — wired when built
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                Text("New Routine")
                    .font(Typography.body)
                    .fontWeight(.medium)
            }
            .foregroundStyle(theme.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(theme.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                    .strokeBorder(
                        theme.accentColor.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Workout Row

private struct RecentWorkoutListRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(dateLabel)
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if let d = durationLabel {
                    Text(d)
                        .font(Typography.caption)
                        .foregroundStyle(Color.textMuted)
                }
            }
            if let summary = exerciseSummary {
                Text(summary)
                    .font(Typography.caption)
                    .foregroundStyle(Color.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
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

// MARK: - Empty State

private struct EmptyRoutinesPrompt: View {
    @Environment(\.heftTheme) private var theme

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: DesignTokens.Icon.placeholder * 0.75))
                .foregroundStyle(theme.accentColor)
            Text("Create your first routine")
                .font(Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            Text("Tap + to build a routine and launch sessions faster.")
                .font(Typography.caption)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        HomeRootView()
    }
    .environment(AppState())
    .modelContainer(PersistenceController.previewContainer)
}
