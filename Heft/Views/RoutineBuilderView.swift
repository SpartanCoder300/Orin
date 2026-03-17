// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

struct RoutineBuilderView: View {
    @State private var vm: RoutineBuilderViewModel
    @State private var isShowingExercisePicker = false
    @State private var configEntryID: UUID? = nil
    @State private var isShowingDeleteConfirm = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.heftTheme) private var theme

    init(existingRoutine: RoutineTemplate? = nil) {
        _vm = State(initialValue: RoutineBuilderViewModel(existingRoutine: existingRoutine))
    }

    private var configSheetIsPresented: Binding<Bool> {
        Binding(
            get: { configEntryID != nil },
            set: { if !$0 { configEntryID = nil } }
        )
    }

    var body: some View {
        @Bindable var vm = vm

        NavigationStack {
            List {
                // ── Routine Name ────────────────────────────────────────
                Section {
                    TextField("Routine Name", text: $vm.routineName)
                        .font(Typography.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)
                        .autocorrectionDisabled()
                }
                .listRowBackground(Color.clear)

                // ── Exercise List ────────────────────────────────────────
                if !vm.entries.isEmpty {
                    Section {
                        ForEach(vm.entries) { entry in
                            ExerciseEntryRow(
                                entry: entry,
                                accentColor: theme.accentColor,
                                onConfig: { configEntryID = entry.id }
                            )
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        }
                        .onMove { vm.move(from: $0, to: $1) }
                    } header: {
                        Text("Exercises")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textFaint)
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }
                    .listSectionSpacing(Spacing.xs)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .themedBackground()
            .environment(\.editMode, .constant(.active))
            .navigationTitle(vm.isEditingExisting ? "Edit Routine" : "New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if vm.isEditingExisting {
                        Menu {
                            Button("Delete Routine", role: .destructive) {
                                isShowingDeleteConfirm = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    Button("Save") {
                        vm.save(in: modelContext)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!vm.canSave)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    isShowingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(theme.accentColor.opacity(0.10), in: Capsule())
                        .overlay(Capsule().strokeBorder(theme.accentColor.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $isShowingExercisePicker) {
                ExercisePicker { exercise in
                    vm.addExercise(exercise)
                }
            }
            .sheet(isPresented: configSheetIsPresented) {
                if let id = configEntryID, let idx = vm.entries.firstIndex(where: { $0.id == id }) {
                    ExerciseConfigSheet(
                        entry: Binding(
                            get: { vm.entries[idx] },
                            set: { vm.entries[idx] = $0 }
                        ),
                        onRemove: {
                            vm.removeEntry(withID: id)
                            configEntryID = nil
                        }
                    )
                }
            }
            .confirmationDialog(
                "Delete \"\(vm.routineName)\"?",
                isPresented: $isShowingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Routine", role: .destructive) {
                    vm.deleteRoutine(from: modelContext)
                    dismiss()
                }
            } message: {
                Text("Your workout history won't be affected.")
            }
        }
    }
}

// MARK: - Exercise Entry Row

private struct ExerciseEntryRow: View {
    let entry: RoutineBuilderViewModel.DraftEntry
    let accentColor: Color
    let onConfig: () -> Void

    private let equipmentIcons: [String: String] = [
        "Barbell":    "dumbbell.fill",
        "Dumbbell":   "dumbbell.fill",
        "Cable":      "cable.connector",
        "Machine":    "gearshape.fill",
        "Bodyweight": "figure.strengthtraining.functional",
        "Kettlebell": "dumbbell.fill",
        "Band":       "link",
        "Cardio":     "figure.run",
    ]

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: equipmentIcons[entry.exercise.equipmentType] ?? "dumbbell.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.exercise.name)
                    .font(Typography.body)
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: Spacing.sm) {
                    Text("\(entry.targetSets) × \(entry.targetRepsMin)–\(entry.targetRepsMax)")
                        .font(Typography.caption)
                        .foregroundStyle(Color.textMuted)
                    if !entry.exercise.muscleGroups.isEmpty {
                        Text("·")
                            .font(Typography.caption)
                            .foregroundStyle(Color.textFaint)
                        Text(entry.exercise.muscleGroups.prefix(2).joined(separator: ", "))
                            .font(Typography.caption)
                            .foregroundStyle(Color.textFaint)
                    }
                }
            }

            Spacer()

            Button(action: onConfig) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.textMuted)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
    }
}

// MARK: - Exercise Config Sheet

private struct ExerciseConfigSheet: View {
    @Binding var entry: RoutineBuilderViewModel.DraftEntry
    let onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.heftTheme) private var theme

    private let restOptions = [30, 60, 90, 120, 180]

    var body: some View {
        NavigationStack {
            Form {
                // ── Sets ───────────────────────────────────────────────
                Section("Sets") {
                    Stepper(
                        "\(entry.targetSets) set\(entry.targetSets == 1 ? "" : "s")",
                        value: $entry.targetSets,
                        in: 1...10
                    )
                    .foregroundStyle(Color.textPrimary)
                }

                // ── Reps ───────────────────────────────────────────────
                Section("Reps") {
                    Stepper("Min: \(entry.targetRepsMin)", value: $entry.targetRepsMin, in: 1...99)
                        .foregroundStyle(Color.textPrimary)
                        .onChange(of: entry.targetRepsMin) { _, newVal in
                            if newVal > entry.targetRepsMax { entry.targetRepsMax = newVal }
                        }
                    Stepper("Max: \(entry.targetRepsMax)", value: $entry.targetRepsMax, in: 1...99)
                        .foregroundStyle(Color.textPrimary)
                        .onChange(of: entry.targetRepsMax) { _, newVal in
                            if newVal < entry.targetRepsMin { entry.targetRepsMin = newVal }
                        }
                }

                // ── Rest Time ──────────────────────────────────────────
                Section("Rest Time") {
                    HStack(spacing: Spacing.sm) {
                        ForEach(restOptions, id: \.self) { seconds in
                            RestChip(
                                label: restLabel(seconds),
                                isSelected: entry.restSeconds == seconds,
                                accentColor: theme.accentColor
                            ) {
                                entry.restSeconds = seconds
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }

                // ── Remove ─────────────────────────────────────────────
                Section {
                    Button("Remove from Routine", role: .destructive) {
                        onRemove()
                        dismiss()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .themedBackground()
            .navigationTitle(entry.exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func restLabel(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m):00" : "\(m):\(String(format: "%02d", s))"
    }
}

// MARK: - Rest Chip

private struct RestChip: View {
    let label: String
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? accentColor : Color.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
                .background(
                    isSelected
                        ? accentColor.opacity(0.15)
                        : Color.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                        .strokeBorder(
                            isSelected ? accentColor.opacity(0.4) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview("New Routine") {
    RoutineBuilderView()
        .environment(AppState())
        .modelContainer(PersistenceController.previewContainer)
}
