// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

// MARK: - Active Exercise Card

struct ActiveExerciseCard: View {
    let vm: ActiveWorkoutViewModel
    let exercise: ActiveWorkoutViewModel.DraftExercise
    let theme: AccentTheme
    @Binding var openSwipeSetID: UUID?

    @Environment(\.modelContext) private var modelContext
    @State private var showingRemoveConfirm = false
    @State private var editingDefinition: ExerciseDefinition? = nil
    @State private var isShowingHistory = false

    private let cardShape = RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)

    private var exerciseIndex: Int {
        vm.draftExercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
    }

    var body: some View {
        cardBody(exercise: exercise)
            .contentShape(cardShape)
            .contextMenu {
                Button { isShowingHistory = true } label: {
                    Label("View History", systemImage: "chart.line.uptrend.xyaxis")
                }
                Button { editingDefinition = resolveDefinition(for: exercise) } label: {
                    Label("Edit Exercise", systemImage: "pencil")
                }
                Button { vm.beginSwap(exerciseIndex: exerciseIndex) } label: {
                    Label("Swap Exercise", systemImage: "arrow.left.arrow.right")
                }
                Button { vm.isShowingExercisePicker = true } label: {
                    Label("Add Superset", systemImage: "arrow.2.squarepath")
                }
                Divider()
                Button { vm.addDropset(toExerciseAt: exerciseIndex) } label: {
                    Label("Add Dropset", systemImage: "arrow.turn.down.right")
                }
                Button { vm.moveExercise(at: exerciseIndex, direction: .up) } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }
                .disabled(exerciseIndex == 0)
                Button { vm.moveExercise(at: exerciseIndex, direction: .down) } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }
                .disabled(exerciseIndex == vm.draftExercises.count - 1)
                Divider()
                Button(role: .destructive) { showingRemoveConfirm = true } label: {
                    Label("Remove from Workout", systemImage: "trash")
                }
            }
    }

    @ViewBuilder
    private func cardBody(exercise: ActiveWorkoutViewModel.DraftExercise) -> some View {
        let eIdx = exerciseIndex
        VStack(alignment: .leading, spacing: 0) {
            Text(exercise.exerciseName)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.sm)

            ForEach(exercise.sets) { set in
                let sIdx = exercise.sets.firstIndex(where: { $0.id == set.id }) ?? 0
                setRow(exercise: exercise, set: set, setIndex: sIdx, cachedExerciseIndex: eIdx)

                if sIdx < exercise.sets.count - 1 {
                    cardDivider
                        .padding(.leading, Spacing.md)
                }
            }
            .animation(Motion.standardSpring, value: exercise.sets.count)

            cardDivider

            Button {
                vm.addSet(toExerciseAt: exerciseIndex)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.textFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .cardSurface(border: true)
        .clipShape(cardShape)
        .alert("Remove \(exercise.exerciseName)?", isPresented: $showingRemoveConfirm) {
            Button("Remove", role: .destructive) {
                vm.removeExercise(at: exerciseIndex)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the exercise and all its logged sets from this session.")
        }
        .sheet(item: $editingDefinition, onDismiss: {
            vm.syncDefinition(at: exerciseIndex)
        }) { definition in
            ExerciseEditorView(exercise: definition, allowsLifecycleActions: false)
        }
        .sheet(isPresented: $isShowingHistory) {
            ExerciseHistoryView(exerciseName: exercise.exerciseName, exerciseLineageID: exercise.exerciseLineageID)
                .environment(\.OrinCardMaterial, .regularMaterial)
        }
    }

    @ViewBuilder
    private func setRow(
        exercise: ActiveWorkoutViewModel.DraftExercise,
        set: ActiveWorkoutViewModel.DraftSet,
        setIndex: Int,
        cachedExerciseIndex eIdx: Int
    ) -> some View {
        SwipeableSetRow(
            rowID: set.id,
            actions: swipeActions(for: set, setIndex: setIndex, exerciseIndex: eIdx),
            openRowID: $openSwipeSetID
        ) { isSwiping, swipeProgress in
            SetRow(
                setNumber: setIndex + 1,
                weightText: set.weightText,
                repsText: set.repsText,
                durationText: set.durationText,
                isTimed: exercise.isTimed,
                tracksWeight: exercise.tracksWeight,
                setType: set.setType,
                isLogged: set.isLogged,
                isFocused: vm.currentFocus == vm.focus(forExerciseID: exercise.id, setID: set.id),
                hasActiveSelection: vm.currentFocus != nil,
                isSwiping: isSwiping,
                isFirstInCard: setIndex == 0,
                isLastInCard: setIndex == exercise.sets.count - 1,
                isPR: set.isPR,
                justGotPR: vm.lastPRSetID != nil && vm.lastPRSetID == set.loggedRecord?.id,
                accentColor: theme.accentColor,
                placeholderDisplayText: placeholderText(for: exercise, setIndex: setIndex),
                placeholderDelay: Double(max(0, setIndex - 1)) * 0.05,
                previousSet: setIndex < exercise.previousSets.count ? exercise.previousSets[setIndex] : exercise.previousSets.last,
                justLogged: vm.lastLoggedFocus == vm.focus(forExerciseID: exercise.id, setID: set.id),
                onCycleType: { vm.cycleSetType(exerciseIndex: eIdx, setIndex: setIndex) },
                onFocus: {
                    openSwipeSetID = nil
                    vm.setManualFocus(exerciseIndex: eIdx, setIndex: setIndex)
                },
                onLog: {
                    openSwipeSetID = nil
                    vm.logSet(exerciseIndex: eIdx, setIndex: setIndex)
                },
                onDelete: {
                    openSwipeSetID = nil
                    vm.removeSet(exerciseIndex: eIdx, setIndex: setIndex)
                },
                onUndo: {
                    openSwipeSetID = nil
                    vm.unlogSet(exerciseIndex: eIdx, setIndex: setIndex)
                },
                onCopyFromAbove: setIndex > 0 ? {
                    openSwipeSetID = nil
                    vm.copySetFromAbove(exerciseIndex: eIdx, setIndex: setIndex)
                } : nil,
                onAdoptPlaceholder: setIndex > 0 ? {
                    openSwipeSetID = nil
                    vm.adoptPlaceholderValues(exerciseIndex: eIdx, setIndex: setIndex)
                } : nil,
                swipeProgress: swipeProgress
            )
            .padding(.horizontal, Spacing.md)
        }
    }

    private var cardDivider: some View {
        Divider()
            .overlay(Color.white.opacity(0.08))
    }

    private func swipeActions(
        for set: ActiveWorkoutViewModel.DraftSet,
        setIndex: Int,
        exerciseIndex eIdx: Int
    ) -> [SwipeSetAction] {
        var actions: [SwipeSetAction] = []

        if setIndex > 0 && !set.isLogged {
            actions.append(
                SwipeSetAction(
                    systemImage: "arrow.up.doc.on.clipboard",
                    tint: Color.white.opacity(0.72),
                    accessibilityLabel: "Copy from above"
                ) {
                    vm.copySetFromAbove(exerciseIndex: eIdx, setIndex: setIndex)
                }
            )
        }

        if set.isLogged {
            actions.append(
                SwipeSetAction(
                    systemImage: "arrow.uturn.backward",
                    tint: .orange,
                    accessibilityLabel: "Undo set"
                ) {
                    vm.unlogSet(exerciseIndex: eIdx, setIndex: setIndex)
                }
            )
        } else {
            actions.append(
                SwipeSetAction(
                    systemImage: "trash",
                    tint: .red,
                    accessibilityLabel: "Delete set"
                ) {
                    vm.removeSet(exerciseIndex: eIdx, setIndex: setIndex)
                }
            )
        }

        return actions
    }

    private func resolveDefinition(for exercise: ActiveWorkoutViewModel.DraftExercise) -> ExerciseDefinition? {
        if let definitionID = exercise.exerciseDefinitionID {
            let descriptor = FetchDescriptor<ExerciseDefinition>(predicate: #Predicate { $0.id == definitionID })
            if let match = (try? modelContext.fetch(descriptor))?.first {
                return match
            }
        }

        if let lineageID = exercise.exerciseLineageID {
            let descriptor = FetchDescriptor<ExerciseDefinition>(predicate: #Predicate { $0.id == lineageID })
            if let match = (try? modelContext.fetch(descriptor))?.first {
                return match
            }
        }

        let name = exercise.exerciseName
        let descriptor = FetchDescriptor<ExerciseDefinition>(predicate: #Predicate { $0.name == name })
        return (try? modelContext.fetch(descriptor))?.first
    }

    /// Returns the placeholder display string for a set that has no user-entered values,
    /// derived reactively from set 0. Returns nil if set 0 is also empty or this is set 0.
    private func placeholderText(for exercise: ActiveWorkoutViewModel.DraftExercise, setIndex: Int) -> String? {
        guard setIndex > 0 else { return nil }
        let set = exercise.sets[setIndex]
        guard !set.isLogged,
              set.weightText.isEmpty, set.repsText.isEmpty, set.durationText.isEmpty else { return nil }
        let first = exercise.sets[0]
        guard !first.weightText.isEmpty || !first.repsText.isEmpty || !first.durationText.isEmpty else { return nil }

        if exercise.isTimed {
            let secs = Int(first.durationText) ?? 0
            let durationLabel = first.durationText.isEmpty ? "—" : formatDuration(secs)
            guard exercise.tracksWeight else { return durationLabel }
            let w = first.weightText.isEmpty ? "—" : first.weightText
            return "\(w) lb · \(durationLabel)"
        }
        guard exercise.tracksWeight else {
            let r = first.repsText.isEmpty ? "—" : first.repsText
            return "\(r) reps"
        }
        let w = first.weightText.isEmpty ? "—" : first.weightText
        let r = first.repsText.isEmpty ? "—" : first.repsText
        return "\(w) × \(r)"
    }

}


// MARK: - Previews

#Preview("With sets") {
    {
        let vm = ActiveWorkoutViewModel(
            modelContext: PersistenceController.previewContainer.mainContext,
            pendingRoutineID: nil
        )
        vm.addExercise(named: "Bench Press")
        vm.addSet(toExerciseAt: 0)
        vm.addSet(toExerciseAt: 0)
        vm.draftExercises[0].sets[0].weightText = "135"
        vm.draftExercises[0].sets[0].repsText = "8"
        vm.draftExercises[0].sets[1].weightText = "135"
        vm.draftExercises[0].sets[1].repsText = "8"
        return NavigationStack {
            ScrollView {
                ActiveExerciseCard(
                    vm: vm,
                    exercise: vm.draftExercises[0],
                    theme: AccentTheme.midnight,
                    openSwipeSetID: .constant(nil)
                )
                    .padding(.horizontal, ActiveWorkoutLayout.horizontalInset)
                    .padding(.top, Spacing.sm)
            }
            .themedBackground()
        }
    }()
    .activeWorkoutPreviewEnvironments()
}

#Preview("With previous performance") {
    {
        let vm = ActiveWorkoutViewModel(
            modelContext: PersistenceController.previewContainer.mainContext,
            pendingRoutineID: nil
        )
        vm.addExercise(named: "Squat")
        vm.draftExercises[0].sets[0].weightText = "225"
        vm.draftExercises[0].sets[0].repsText = "5"
        vm.draftExercises[0].previousSets = [
            .init(weight: 225, reps: 5),
            .init(weight: 225, reps: 5),
            .init(weight: 215, reps: 6),
        ]
        return NavigationStack {
            ScrollView {
                ActiveExerciseCard(
                    vm: vm,
                    exercise: vm.draftExercises[0],
                    theme: AccentTheme.midnight,
                    openSwipeSetID: .constant(nil)
                )
                    .padding(.horizontal, ActiveWorkoutLayout.horizontalInset)
                    .padding(.top, Spacing.sm)
            }
            .themedBackground()
        }
    }()
    .activeWorkoutPreviewEnvironments()
}
