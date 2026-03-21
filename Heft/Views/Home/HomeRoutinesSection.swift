// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

struct HomeRoutinesSection: View {
    let routines: [RoutineTemplate]
    let avgMinutes: [UUID: Int]
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
                ForEach(routines) { routine in
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

// MARK: - Routine List Row

private struct RoutineListRow: View {
    let routine: RoutineTemplate
    let avgMinutes: Int?
    let onTap: () -> Void
    let onEdit: () -> Void

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
                    Text(avgMinutes.map { "\($0) min avg" } ?? "— min avg")
                        .font(Typography.caption)
                        .foregroundStyle(Color.textFaint)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { onEdit() } label: {
                Label("Edit Routine", systemImage: "pencil")
            }
        }
    }

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
    let action: () -> Void
    @Environment(\.heftTheme) private var theme

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
    @Environment(\.heftTheme) private var theme

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
        onStart: { _ in },
        onEdit: { _ in },
        onNew: {},
        onStartEmpty: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("With routines") {
    NavigationStack {
        HomeRoutinesSection(
            routines: [],
            avgMinutes: [:],
            onStart: { _ in },
            onEdit: { _ in },
            onNew: {},
            onStartEmpty: {}
        )
        .padding()
    }
    .modelContainer(PersistenceController.previewContainer)
    .preferredColorScheme(.dark)
}
