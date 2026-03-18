// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @State private var vm: ActiveWorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.heftTheme) private var theme

    init(modelContext: ModelContext, pendingRoutineID: UUID?) {
        _vm = State(initialValue: ActiveWorkoutViewModel(
            modelContext: modelContext,
            pendingRoutineID: pendingRoutineID
        ))
    }

    var body: some View {
        @Bindable var vm = vm

        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        if vm.draftExercises.isEmpty {
                            EmptyWorkoutPrompt(accentColor: theme.accentColor)
                        } else {
                            ActiveExerciseCard(
                                vm: vm,
                                exerciseIndex: vm.activeExerciseIndex,
                                theme: theme
                            )
                            .id("active")

                            if vm.draftExercises.count > 1 {
                                OtherExercisesSection(vm: vm)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.lg)
                }
                .onChange(of: vm.activeExerciseIndex) { _, _ in
                    withAnimation(Motion.standardSpring) {
                        proxy.scrollTo("active", anchor: .top)
                    }
                }
            }
            .themedBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("End") { vm.isShowingEndConfirm = true }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.heftRed)
                }
                ToolbarItem(placement: .principal) {
                    TimelineView(.periodic(from: vm.openedAt, by: 1.0)) { ctx in
                        Text(vm.elapsedLabel(at: ctx.date))
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.isShowingExercisePicker = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .confirmationDialog(
                "End Workout?",
                isPresented: $vm.isShowingEndConfirm,
                titleVisibility: .visible
            ) {
                Button("End Workout", role: .destructive) {
                    vm.endWorkout()
                    dismiss()
                }
            } message: {
                Text(vm.isSessionStarted
                     ? "Your logged sets have been saved."
                     : "No sets logged — this session won't be saved.")
            }
            .sheet(isPresented: $vm.isShowingExercisePicker) {
                ExercisePicker { exercise in
                    vm.addExercise(named: exercise.name)
                }
            }
            .sheet(isPresented: $vm.isShowingRestTimer) {
                RestTimerSheet(restTimer: vm.restTimer, vm: vm)
                    .presentationDetents([.fraction(0.92)])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(Radius.large)
                    .presentationBackground(.clear)
            }
            .onChange(of: vm.restTimer.isActive) { _, isActive in
                vm.isShowingRestTimer = isActive
            }
        }
        .task { vm.setup() }
    }
}

// MARK: - Active Exercise Card

private struct ActiveExerciseCard: View {
    let vm: ActiveWorkoutViewModel
    let exerciseIndex: Int
    let theme: AccentTheme

    private var exercise: ActiveWorkoutViewModel.DraftExercise {
        vm.draftExercises[exerciseIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ────────────────────────────────────────────────
            HStack(alignment: .center) {
                Text(exercise.exerciseName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Menu {
                    Button("Remove Exercise", role: .destructive) {
                        vm.removeExercise(at: exerciseIndex)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.textMuted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            // ── Previous session ──────────────────────────────────────
            if !exercise.previousSets.isEmpty {
                Text("Last  \(previousLabel)")
                    .font(.caption)
                    .foregroundStyle(Color.textFaint)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.sm)
            } else {
                Color.clear.frame(height: Spacing.sm)
            }

            Divider().overlay(Color.white.opacity(0.07))

            // ── Set rows ──────────────────────────────────────────────
            ForEach(exercise.sets.indices, id: \.self) { sIdx in
                let isDropset = exercise.sets[sIdx].setType == .dropset
                let nextIsDropset = sIdx + 1 < exercise.sets.count
                    && exercise.sets[sIdx + 1].setType == .dropset

                SetRow(
                    setNumber: sIdx + 1,
                    weightText: Binding(
                        get: { vm.draftExercises[exerciseIndex].sets[sIdx].weightText },
                        set: { vm.draftExercises[exerciseIndex].sets[sIdx].weightText = $0 }
                    ),
                    repsText: Binding(
                        get: { vm.draftExercises[exerciseIndex].sets[sIdx].repsText },
                        set: { vm.draftExercises[exerciseIndex].sets[sIdx].repsText = $0 }
                    ),
                    setType: exercise.sets[sIdx].setType,
                    isDropset: isDropset,
                    isLogged: exercise.sets[sIdx].isLogged,
                    onCycleType: { vm.cycleSetType(exerciseIndex: exerciseIndex, setIndex: sIdx) },
                    onLog: { vm.logSet(exerciseIndex: exerciseIndex, setIndex: sIdx) }
                )

                if sIdx < exercise.sets.count - 1 && !nextIsDropset {
                    Divider()
                        .overlay(Color.white.opacity(0.05))
                        .padding(.horizontal, Spacing.md)
                }
            }

            Divider().overlay(Color.white.opacity(0.07))

            // ── Add Set ───────────────────────────────────────────────
            Button { vm.addSet(toExerciseAt: exerciseIndex) } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
    }

    private var previousLabel: String {
        exercise.previousSets
            .map { "\(vm.formatWeight($0.weight)) × \($0.reps)" }
            .joined(separator: "   ")
    }
}

// MARK: - Set Row

private struct SetRow: View {
    let setNumber: Int
    @Binding var weightText: String
    @Binding var repsText: String
    let setType: SetType
    let isDropset: Bool
    let isLogged: Bool
    let onCycleType: () -> Void
    let onLog: () -> Void

    var body: some View {
        HStack(spacing: 0) {

            // Set number + type chip
            HStack(spacing: 5) {
                Text(isDropset ? "↳" : "\(setNumber)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(isDropset ? Color.heftAccentAbyss.opacity(0.7) : Color.textFaint)
                    .frame(width: 18, alignment: .center)

                SetTypeChip(setType: setType, onTap: isLogged ? nil : onCycleType)
            }
            .padding(.leading, isDropset ? Spacing.xl : Spacing.md)
            .frame(width: 72, alignment: .leading)

            // Weight stepper
            CompactStepper(
                text: $weightText,
                unit: "lbs",
                step: 2.5,
                minValue: 0,
                maxValue: 999,
                isInteger: false,
                isLogged: isLogged
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.xs)

            // Reps stepper
            CompactStepper(
                text: $repsText,
                unit: "reps",
                step: 1,
                minValue: 0,
                maxValue: 50,
                isInteger: true,
                isLogged: isLogged
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.xs)

            // Log button
            Button(action: onLog) {
                Image(systemName: isLogged ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isLogged ? Color.heftGreen : Color.textFaint.opacity(0.5))
                    .frame(width: 52, height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isLogged)
        }
        .padding(.vertical, 4)
        .opacity(isLogged ? 0.5 : 1.0)
        .animation(Motion.standardSpring, value: isLogged)
    }
}

// MARK: - Compact Stepper  [−] value [+]

private struct CompactStepper: View {
    @Binding var text: String
    let unit: String
    let step: Double
    let minValue: Double
    let maxValue: Double
    let isInteger: Bool
    var isLogged: Bool = false

    @State private var showingWheel = false
    @State private var wheelValue: Double = 0

    private var current: Double { Double(text) ?? minValue }

    // Wheel always uses 1-unit increments for fine control
    private var wheelValues: [Double] {
        stride(from: minValue, through: maxValue, by: 1).map { $0 }
    }

    private func snapped(_ v: Double) -> Double {
        let steps = ((v - minValue) / step).rounded()
        return Swift.min(maxValue, Swift.max(minValue, minValue + steps * step))
    }

    private func formatted(_ v: Double) -> String {
        if isInteger { return "\(Int(v.rounded()))" }
        let r = (v * 10).rounded() / 10
        return r.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(r))" : String(format: "%.1f", r)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Minus
            Button {
                let next = snapped(current - step)
                text = formatted(next)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.textMuted)
                    .frame(width: 38, height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isLogged)

            // Value — tap to open wheel
            Button {
                wheelValue = snapped(current)
                showingWheel = true
            } label: {
                VStack(spacing: 2) {
                    Text(text.isEmpty ? "—" : formatted(current))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(Motion.standardSpring, value: text)
                    Text(unit)
                        .font(.system(size: 9, weight: .medium))
                        .textCase(.uppercase)
                        .tracking(0.4)
                        .opacity(0.5)
                }
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.plain)
            .disabled(isLogged)

            // Plus
            Button {
                let next = snapped(current + step)
                text = formatted(next)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.textMuted)
                    .frame(width: 38, height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isLogged)
        }
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .sheet(isPresented: $showingWheel) {
            WheelPickerSheet(
                value: $wheelValue,
                values: wheelValues,
                format: formatted,
                onDone: {
                    text = formatted(wheelValue)
                    showingWheel = false
                    UISelectionFeedbackGenerator().selectionChanged()
                },
                onCancel: { showingWheel = false }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Radius.large)
        }
    }
}

// MARK: - Wheel Picker Sheet

private struct WheelPickerSheet: View {
    @Binding var value: Double
    let values: [Double]
    let format: (Double) -> String
    let onDone: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundStyle(Color.textMuted)
                Spacer()
                Button("Done", action: onDone)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xs)

            Picker("", selection: $value) {
                ForEach(values, id: \.self) { v in
                    Text(format(v)).tag(v)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 180)
        }
    }
}

// MARK: - Set Type Chip

private struct SetTypeChip: View {
    let setType: SetType
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(chipColor)
                .frame(width: 26, height: 22)
                .background(chipColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .sensoryFeedback(.selection, trigger: setType)
    }

    private var label: String {
        switch setType {
        case .normal:  "N"
        case .warmup:  "W"
        case .dropset: "D"
        }
    }

    private var chipColor: Color {
        switch setType {
        case .normal:  Color.textFaint
        case .warmup:  Color.heftAmber
        case .dropset: Color.heftAccentAbyss
        }
    }
}

// MARK: - Other Exercises

private struct OtherExercisesSection: View {
    let vm: ActiveWorkoutViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Also in this workout")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textFaint)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, 2)

            ForEach(vm.draftExercises.indices, id: \.self) { idx in
                if idx != vm.activeExerciseIndex {
                    let exercise = vm.draftExercises[idx]
                    let logged = exercise.sets.filter { $0.isLogged }.count

                    Button { vm.activeExerciseIndex = idx } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(exercise.exerciseName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.textPrimary)
                                Text("\(exercise.sets.count) sets  ·  \(logged) logged")
                                    .font(.caption)
                                    .foregroundStyle(Color.textFaint)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.textFaint)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Empty Workout Prompt

private struct EmptyWorkoutPrompt: View {
    let accentColor: Color

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: DesignTokens.Icon.placeholder))
                .foregroundStyle(accentColor)
            VStack(spacing: Spacing.xs) {
                Text("Ready when you are")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Tap + to add your first exercise.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .padding(.top, Spacing.xxl)
    }
}

#Preview("Empty workout") {
    ActiveWorkoutView(
        modelContext: PersistenceController.previewContainer.mainContext,
        pendingRoutineID: nil
    )
    .environment(AppState())
    .modelContainer(PersistenceController.previewContainer)
}
