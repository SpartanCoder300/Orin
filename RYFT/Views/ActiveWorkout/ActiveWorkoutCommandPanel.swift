// iOS 26+ only. No #available guards.

import SwiftData
import SwiftUI

// MARK: - Command Panel

struct ActiveWorkoutCommandPanel: View {
    let vm: ActiveWorkoutViewModel
    let theme: AccentTheme
    let onComplete: (WorkoutSession) -> Void
    let onDismiss: () -> Void

    var body: some View {
        if vm.isAllSetsLogged {
            // ── Complete Workout ───────────────────────────────────────────────
            Button {
                if let session = vm.endWorkout() {
                    onComplete(session)
                } else {
                    onDismiss()
                }
            } label: {
                Label("Complete Workout", systemImage: "checkmark.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.ryftGreen)
                    .padding(.vertical, Spacing.md)
                    .padding(.horizontal, Spacing.xl)
            }
            .buttonStyle(.plain)
            .glassEffect(in: RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
            .padding(.bottom, Spacing.md)

        } else if let focus = vm.currentFocus,
                  vm.draftExercises.indices.contains(focus.exerciseIndex),
                  vm.draftExercises[focus.exerciseIndex].sets.indices.contains(focus.setIndex) {
            // ── Set editing card ───────────────────────────────────────────────
            let exercise = vm.draftExercises[focus.exerciseIndex]

            VStack(spacing: 0) {
                // Row 1: Weight | Reps (or Duration for timed exercises)
                HStack(spacing: 0) {
                    if !exercise.isTimed {
                        CompactStepper(
                            text: Binding(
                                get: {
                                    guard vm.draftExercises.indices.contains(focus.exerciseIndex),
                                          vm.draftExercises[focus.exerciseIndex].sets.indices.contains(focus.setIndex)
                                    else { return "" }
                                    return vm.draftExercises[focus.exerciseIndex].sets[focus.setIndex].weightText
                                },
                                set: {
                                    guard vm.draftExercises.indices.contains(focus.exerciseIndex),
                                          vm.draftExercises[focus.exerciseIndex].sets.indices.contains(focus.setIndex)
                                    else { return }
                                    vm.draftExercises[focus.exerciseIndex].sets[focus.setIndex].weightText = $0
                                }
                            ),
                            unit: "lbs",
                            step: exercise.weightIncrement,
                            minValue: 0,
                            maxValue: 999,
                            isInteger: false,
                            firstTapDefault: weightDefault(for: exercise.equipmentType)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        Divider()
                    }

                    if exercise.isTimed {
                        // Duration stepper — full width for timed exercises
                        CompactStepper(
                            text: Binding(
                                get: {
                                    guard vm.draftExercises.indices.contains(focus.exerciseIndex),
                                          vm.draftExercises[focus.exerciseIndex].sets.indices.contains(focus.setIndex)
                                    else { return "" }
                                    return vm.draftExercises[focus.exerciseIndex].sets[focus.setIndex].durationText
                                },
                                set: {
                                    guard vm.draftExercises.indices.contains(focus.exerciseIndex),
                                          vm.draftExercises[focus.exerciseIndex].sets.indices.contains(focus.setIndex)
                                    else { return }
                                    vm.draftExercises[focus.exerciseIndex].sets[focus.setIndex].durationText = $0
                                }
                            ),
                            unit: "sec",
                            step: 5,
                            minValue: 5,
                            maxValue: 600,
                            isInteger: true,
                            firstTapDefault: 30
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        CompactStepper(
                            text: Binding(
                                get: {
                                    guard vm.draftExercises.indices.contains(focus.exerciseIndex),
                                          vm.draftExercises[focus.exerciseIndex].sets.indices.contains(focus.setIndex)
                                    else { return "" }
                                    return vm.draftExercises[focus.exerciseIndex].sets[focus.setIndex].repsText
                                },
                                set: {
                                    guard vm.draftExercises.indices.contains(focus.exerciseIndex),
                                          vm.draftExercises[focus.exerciseIndex].sets.indices.contains(focus.setIndex)
                                    else { return }
                                    vm.draftExercises[focus.exerciseIndex].sets[focus.setIndex].repsText = $0
                                }
                            ),
                            unit: "reps",
                            step: 1,
                            minValue: 0,
                            maxValue: 50,
                            isInteger: true,
                            firstTapDefault: 5
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(height: 72)

                Divider()

                // Row 2: Set type (left) | Log Set (centered) | mirror spacer (right)
                HStack(spacing: 0) {
                    // Left: set type chip — 44pt to match the mirror spacer
                    SetTypeChip(
                        setType: vm.draftExercises[focus.exerciseIndex].sets[focus.setIndex].setType,
                        onTap: { vm.cycleSetType(exerciseIndex: focus.exerciseIndex, setIndex: focus.setIndex) }
                    )
                    .frame(width: 44)

                    // Centre: Log Set fills remaining space, text naturally centred
                    Button { vm.logFocusedSet() } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                            Text("Log Set")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(theme.accentColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    // Right mirror: same width as chip so the label stays centred
                    Color.clear.frame(width: 44)
                }
                .frame(height: 52)
            }
            .glassEffect(in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)

        } else if !vm.draftExercises.isEmpty {
            // ── No focus — prompt user ─────────────────────────────────────────
            Text("Tap a set to edit")
                .font(.subheadline)
                .foregroundStyle(Color.textFaint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .padding(.bottom, Spacing.md)
        }
    }
}

// MARK: - Helpers

// MARK: - Previews

#Preview("Editing panel") {
    {
        let vm = ActiveWorkoutViewModel(
            modelContext: PersistenceController.previewContainer.mainContext,
            pendingRoutineID: nil
        )
        vm.addExercise(named: "Bench Press")
        vm.draftExercises[0].sets[0].weightText = "185"
        vm.draftExercises[0].sets[0].repsText = "5"
        return ActiveWorkoutCommandPanel(vm: vm, theme: .midnight, onComplete: { _ in }, onDismiss: {})
            .environment(\.ryftTheme, .midnight)
            .preferredColorScheme(.dark)
    }()
}

#Preview("Complete Workout") {
    {
        let vm = ActiveWorkoutViewModel(
            modelContext: PersistenceController.previewContainer.mainContext,
            pendingRoutineID: nil
        )
        vm.addExercise(named: "Bench Press")
        vm.draftExercises[0].sets[0].weightText = "185"
        vm.draftExercises[0].sets[0].repsText = "5"
        vm.draftExercises[0].sets[0].isLogged = true
        return ActiveWorkoutCommandPanel(vm: vm, theme: .midnight, onComplete: { _ in }, onDismiss: {})
            .environment(\.ryftTheme, .midnight)
            .preferredColorScheme(.dark)
    }()
}

#Preview("No focus") {
    {
        let vm = ActiveWorkoutViewModel(
            modelContext: PersistenceController.previewContainer.mainContext,
            pendingRoutineID: nil
        )
        // No exercises added — currentFocus is naturally nil
        return ActiveWorkoutCommandPanel(vm: vm, theme: .midnight, onComplete: { _ in }, onDismiss: {})
            .environment(\.ryftTheme, .midnight)
            .preferredColorScheme(.dark)
    }()
}

private func weightDefault(for equipmentType: String) -> Double? {
    switch equipmentType {
    case "Barbell":    return 45
    case "Dumbbell":   return 10
    case "Cable":      return 20
    case "Machine":    return 45
    case "Kettlebell": return 35
    case "Bodyweight": return nil
    default:           return 45
    }
}
