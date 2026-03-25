// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

struct HomeRoutinesSection: View {
    let routines: [RoutineTemplate]
    let avgMinutes: [UUID: Int]
    let featured: FeaturedRoutineSuggestion?
    let onStart: (UUID) -> Void
    let onEdit: (RoutineTemplate) -> Void
    let onNew: () -> Void
    let onStartEmpty: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Routines")

            if routines.isEmpty {
                EmptyRoutinesPrompt(onTap: onNew)
            } else {
                // Featured card appears above the full list when a suggestion exists
                if let featured,
                   let featuredRoutine = routines.first(where: { $0.id == featured.routineID }) {
                    FeaturedRoutineCard(
                        routine: featuredRoutine,
                        suggestion: featured,
                        avgMinutes: avgMinutes[featured.routineID],
                        onTap: { onStart(featured.routineID) },
                        onEdit: { onEdit(featuredRoutine) }
                    )
                }

                ForEach(routines.filter { $0.id != featured?.routineID }) { routine in
                    RoutineListRow(
                        routine: routine,
                        avgMinutes: avgMinutes[routine.id],
                        onTap: { onStart(routine.id) },
                        onEdit: { onEdit(routine) }
                    )
                }
                NewRoutineCard(action: onNew)
            }

            Button(action: onStartEmpty) {
                Text("or start empty workout")
                    .font(Typography.caption)
                    .foregroundStyle(Color.textFaint)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Featured Routine Card

private struct FeaturedRoutineCard: View {
    let routine: RoutineTemplate
    let suggestion: FeaturedRoutineSuggestion
    let avgMinutes: Int?
    let onTap: () -> Void
    let onEdit: () -> Void

    @Environment(\.ryftCardMaterial) private var cardMaterial

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Up Next")
                        .font(Typography.caption.weight(.medium))
                        .foregroundStyle(Color.textFaint)
                        .textCase(.uppercase)

                    Text(suggestion.routineName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)

                    if !muscleGroupSummary.isEmpty {
                        Text(muscleGroupSummary)
                            .font(Typography.caption)
                            .foregroundStyle(Color.textMuted)
                            .lineLimit(1)
                    }

                    Text(summaryLine)
                        .font(Typography.caption)
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
            .proGlass()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { onEdit() } label: {
                Label("Edit Routine", systemImage: "pencil")
            }
        }
    }

    private var summaryLine: String {
        var parts = ["\(suggestion.exerciseCount) exercises"]

        if let avgMinutes {
            parts.append("\(avgMinutes) min avg")
        }

        return parts.joined(separator: " • ")
    }

    private var muscleGroupSummary: String {
        routine.muscleGroupSummary
    }
}

// MARK: - Routine List Row

private struct RoutineListRow: View {
    let routine: RoutineTemplate
    let avgMinutes: Int?
    let onTap: () -> Void
    let onEdit: () -> Void

    @Environment(\.ryftCardMaterial) private var cardMaterial

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
                    Text(avgMinutes.map { "\($0) min avg" } ?? "No history yet")
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
        .contextMenu {
            Button { onEdit() } label: {
                Label("Edit Routine", systemImage: "pencil")
            }
        }
    }

    private var muscleGroupSummary: String {
        routine.muscleGroupSummary
    }
}

private extension RoutineTemplate {
    var muscleGroupSummary: String {
        var seen = Set<String>()
        var ordered: [String] = []
        for entry in entries {
            for group in (entry.exerciseDefinition?.muscleGroups ?? []) {
                if seen.insert(group).inserted { ordered.append(group) }
            }
        }
        return ordered.prefix(3).joined(separator: " · ")
    }
}

// MARK: - New Routine Card

private struct NewRoutineCard: View {
    let action: () -> Void
    @Environment(\.ryftTheme) private var theme

    var body: some View {
        Button(action: action) {
            Label("New Routine", systemImage: "plus.circle.fill")
                .font(Typography.body.weight(.medium))
                .foregroundStyle(theme.accentColor)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

private struct EmptyRoutinesPrompt: View {
    let onTap: () -> Void
    @Environment(\.ryftTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: DesignTokens.Icon.placeholder * 0.75))
                    .foregroundStyle(theme.accentColor)
                Text("Create your first routine")
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text("Tap here to build a routine and launch sessions faster.")
                    .font(Typography.caption)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Routine")
                        .fontWeight(.semibold)
                }
                .font(Typography.caption)
                .foregroundStyle(theme.accentColor)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(theme.accentColor.opacity(0.12), in: Capsule())
                .padding(.top, Spacing.xs)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                    .strokeBorder(theme.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Empty state") {
    HomeRoutinesSection(
        routines: [],
        avgMinutes: [:],
        featured: nil,
        onStart: { _ in },
        onEdit: { _ in },
        onNew: {},
        onStartEmpty: {}
    )
    .padding()
    .environment(MeshEngine())
    .preferredColorScheme(.dark)
}

#Preview("With routines") {
    let scenario = HomePreviewData.featured

    NavigationStack {
        HomeRoutinesSection(
            routines: scenario.routines,
            avgMinutes: scenario.avgMinutes,
            featured: scenario.featuredSuggestion,
            onStart: { _ in },
            onEdit: { _ in },
            onNew: {},
            onStartEmpty: {}
        )
        .padding()
    }
    .environment(MeshEngine())
    .modelContainer(scenario.container)
    .preferredColorScheme(.dark)
}
