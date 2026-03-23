// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

private let allMuscleGroups = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Forearms", "Legs", "Core"]

struct ExercisePicker: View {
    let onSelect: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.heftTheme) private var theme

    @Query(sort: \ExerciseDefinition.name) private var allExercises: [ExerciseDefinition]

    @State private var vm = ExercisePickerViewModel()
    @State private var editorTarget: ExerciseEditorTarget? = nil

    private let filterOptions: [PickerFilter] =
        allMuscleGroups.map { .muscleGroup($0) } + [.custom, .edited]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {

                    // ── Filter chips (horizontal scroll, multi-select) ─────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            // "All" clears all active filters
                            let isAll = vm.selectedFilters.isEmpty
                            Button { vm.selectedFilters.removeAll() } label: {
                                Text("All")
                                    .font(.system(size: 12, weight: isAll ? .semibold : .regular))
                                    .foregroundStyle(isAll ? theme.accentColor : Color.textMuted)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: Capsule())

                            ForEach(filterOptions, id: \.self) { option in
                                let isSelected = vm.selectedFilters.contains(option)
                                Button {
                                    if isSelected {
                                        vm.selectedFilters.remove(option)
                                    } else {
                                        vm.selectedFilters.insert(option)
                                    }
                                } label: {
                                    Text(option.label)
                                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                        .foregroundStyle(isSelected ? theme.accentColor : Color.textMuted)
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                                .glassEffect(.regular.interactive(), in: Capsule())
                            }
                        }
                        .padding(.horizontal, 1)
                    }

                    // ── Recents (hidden during search) ──────────────────────────────────────
                    let recents = vm.recentExercises(from: allExercises, filters: vm.selectedFilters)
                    if vm.searchText.isEmpty && !recents.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            pickerSectionLabel("Recent")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.xs) {
                                    ForEach(recents) { exercise in
                                        RecentTile(exercise: exercise) {
                                            select(exercise)
                                        }
                                    }
                                }
                                .padding(.horizontal, 1) // prevent clipping on glass effect
                            }
                        }
                    }

                    // ── Full Library ────────────────────────────────────────
                    let library = vm.libraryExercises(from: allExercises)
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        pickerSectionLabel(vm.searchText.isEmpty && vm.selectedFilters.isEmpty
                                           ? "All Exercises"
                                           : "Results (\(library.count))")

                        if library.isEmpty {
                            Text("No exercises found")
                                .font(Typography.caption)
                                .foregroundStyle(Color.textFaint)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.lg)
                        } else {
                            LazyVStack(spacing: 2) {
                                ForEach(library) { exercise in
                                    LibraryRow(
                                        exercise: exercise,
                                        matchRanges: vm.matchRanges(query: vm.searchText, in: exercise.name),
                                        accentColor: theme.accentColor,
                                        onTap: { select(exercise) },
                                        onEdit: { editorTarget = .edit(exercise) }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $vm.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { editorTarget = .new } label: {
                        Label("New Exercise", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $editorTarget) { target in
                ExerciseEditorView(exercise: target.exercise)
            }
        }
        .onAppear {
            vm.load(container: modelContext.container)
        }
    }

    // MARK: - Private

    private func select(_ exercise: ExerciseDefinition) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        onSelect(exercise)
        dismiss()
    }

    @ViewBuilder
    private func pickerSectionLabel(_ title: String) -> some View {
        Text(title)
            .font(Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.textFaint)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

// MARK: - Recent Tile

private struct RecentTile: View {
    let exercise: ExerciseDefinition
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(exercise.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 9)
                .background(.thinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library Row

private struct LibraryRow: View {
    let exercise: ExerciseDefinition
    let matchRanges: [Range<String.Index>]
    let accentColor: Color
    let onTap: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    HighlightedText(
                        text: exercise.name,
                        ranges: matchRanges,
                        highlightColor: accentColor
                    )
                    .font(Typography.body)

                    if !exercise.muscleGroups.isEmpty {
                        Text(exercise.muscleGroups.prefix(2).joined(separator: " · "))
                            .font(Typography.caption)
                            .foregroundStyle(Color.textFaint)
                    }
                }

                Spacer()

                if exercise.isTimed {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textFaint)
                }

                if exercise.isEdited && !exercise.isCustom {
                    Text("Edited")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textFaint)
                        .textCase(.uppercase)
                        .tracking(0.4)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }

                if exercise.isCustom {
                    Text("Custom")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(accentColor)
                        .textCase(.uppercase)
                        .tracking(0.4)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Exercise", systemImage: "pencil")
            }
        }
    }
}

// MARK: - Highlighted Text

private struct HighlightedText: View {
    let text: String
    let ranges: [Range<String.Index>]
    let highlightColor: Color

    var body: some View {
        if ranges.isEmpty {
            Text(text).foregroundStyle(Color.textPrimary)
        } else {
            buildAttributed()
        }
    }

    private func buildAttributed() -> some View {
        var result = AttributedString(text)
        result.foregroundColor = UIColor(Color.textPrimary)
        for range in ranges {
            if let attrRange = Range(range, in: result) {
                result[attrRange].foregroundColor = UIColor(highlightColor)
                result[attrRange].font = .systemFont(ofSize: 17, weight: .semibold)
            }
        }
        return Text(result)
    }
}

// MARK: - Editor Target

/// Drives the sheet presented from the picker — new exercise or edit existing.
private enum ExerciseEditorTarget: Identifiable {
    case new
    case edit(ExerciseDefinition)

    var id: String {
        switch self {
        case .new:          return "new"
        case .edit(let ex): return ex.id.uuidString
        }
    }

    var exercise: ExerciseDefinition? {
        switch self {
        case .new:          return nil
        case .edit(let ex): return ex
        }
    }
}

#Preview {
    ExercisePicker { _ in }
        .environment(AppState())
        .modelContainer(PersistenceController.previewContainer)
}
