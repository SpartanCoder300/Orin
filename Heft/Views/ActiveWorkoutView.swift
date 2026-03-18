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
                            EmptyWorkoutPrompt(accentColor: theme.accentColor) {
                                vm.isShowingExercisePicker = true
                            }
                        } else {
                            ActiveExerciseCard(vm: vm, exerciseIndex: vm.activeExerciseIndex, theme: theme)
                                .id("active")

                            if vm.draftExercises.count > 1 {
                                OtherExercisesSection(vm: vm, theme: theme)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.lg)
                    .padding(.bottom, 88)
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
                    RestTimerPlaceholder()
                }
                ToolbarItem(placement: .principal) {
                    TimelineView(.periodic(from: vm.openedAt, by: 1.0)) { ctx in
                        Text(vm.elapsedLabel(at: ctx.date))
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End") { vm.isShowingEndConfirm = true }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.heftRed)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button { vm.isShowingExercisePicker = true } label: {
                    Label("Add Exercise", systemImage: "plus")
                        .font(Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(theme.accentColor.opacity(0.12), in: Capsule())
                        .overlay(Capsule().strokeBorder(theme.accentColor.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(.ultraThinMaterial)
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
                    .font(Typography.heading)
                    .fontWeight(.bold)
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
                        .frame(width: 44, height: 36)
                        .contentShape(Rectangle())
                }
            }

            // ── Previous performance ───────────────────────────────────
            if !exercise.previousSets.isEmpty {
                Text("Last: \(previousLabel)")
                    .font(Typography.caption)
                    .foregroundStyle(Color.textFaint)
                    .padding(.top, 2)
            }

            // ── Column headers ────────────────────────────────────────
            HStack(spacing: Spacing.sm) {
                Text("SET").frame(width: 20, alignment: .center)
                Text("").frame(width: 30)
                Text("WEIGHT").frame(maxWidth: .infinity)
                Text("REPS").frame(maxWidth: .infinity)
                Text("").frame(width: 36)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.textFaint)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xs)

            Divider().overlay(Color.white.opacity(0.08))

            // ── Set rows ──────────────────────────────────────────────
            ForEach(exercise.sets.indices, id: \.self) { sIdx in
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
                    isLogged: exercise.sets[sIdx].isLogged,
                    accentColor: theme.accentColor,
                    onCycleType: { vm.cycleSetType(exerciseIndex: exerciseIndex, setIndex: sIdx) },
                    onLog: { vm.logSet(exerciseIndex: exerciseIndex, setIndex: sIdx) },
                    onAdjustWeight: { vm.adjustWeight(exerciseIndex: exerciseIndex, setIndex: sIdx, increment: $0) },
                    onAdjustReps: { vm.adjustReps(exerciseIndex: exerciseIndex, setIndex: sIdx, increment: $0) }
                )

                if sIdx < exercise.sets.count - 1 {
                    Divider().overlay(Color.white.opacity(0.05))
                }
            }

            // ── Add Set ───────────────────────────────────────────────
            Button { vm.addSet(toExerciseAt: exerciseIndex) } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
    }

    private var previousLabel: String {
        exercise.previousSets
            .map { "\(vm.formatWeight($0.weight))×\($0.reps)" }
            .joined(separator: "  ")
    }
}

// MARK: - Set Row

private struct SetRow: View {
    let setNumber: Int
    @Binding var weightText: String
    @Binding var repsText: String
    let setType: SetType
    let isLogged: Bool
    let accentColor: Color
    let onCycleType: () -> Void
    let onLog: () -> Void
    let onAdjustWeight: (Bool) -> Void
    let onAdjustReps: (Bool) -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Set number
            Text("\(setNumber)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.textFaint)
                .frame(width: 20, alignment: .center)

            // Set type chip
            SetTypeChip(setType: setType, onTap: isLogged ? nil : onCycleType)
                .frame(width: 30)

            // Weight field
            SwipeAdjustField(
                text: $weightText,
                keyboardType: .decimalPad,
                placeholder: "—",
                isLogged: isLogged,
                onIncrement: { onAdjustWeight(true) },
                onDecrement: { onAdjustWeight(false) }
            )
            .frame(maxWidth: .infinity)

            // Reps field
            SwipeAdjustField(
                text: $repsText,
                keyboardType: .numberPad,
                placeholder: "—",
                isLogged: isLogged,
                onIncrement: { onAdjustReps(true) },
                onDecrement: { onAdjustReps(false) }
            )
            .frame(maxWidth: .infinity)

            // Log checkmark
            Button(action: onLog) {
                Image(systemName: isLogged ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isLogged ? Color.heftGreen : Color.textFaint)
            }
            .buttonStyle(.plain)
            .frame(width: 36)
            .disabled(isLogged)
        }
        .padding(.vertical, 10)
        .opacity(isLogged ? 0.55 : 1.0)
        .animation(Motion.standardSpring, value: isLogged)
    }
}

// MARK: - Swipe Adjust Field

private struct SwipeAdjustField: View {
    @Binding var text: String
    var keyboardType: UIKeyboardType = .numberPad
    var placeholder: String = "0"
    var isLogged: Bool = false
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    @State private var lastDragY: CGFloat = 0
    @State private var dragging: Bool = false

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .multilineTextAlignment(.center)
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .foregroundStyle(Color.textPrimary)
            .disabled(isLogged)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    .fill(Color.white.opacity(isLogged ? 0 : 0.07))
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .global)
                    .onChanged { value in
                        if !dragging {
                            dragging = true
                            lastDragY = value.startLocation.y
                        }
                        let delta = lastDragY - value.location.y
                        if delta >= 10 {
                            onIncrement()
                            lastDragY = value.location.y
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } else if delta <= -10 {
                            onDecrement()
                            lastDragY = value.location.y
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .onEnded { _ in
                        dragging = false
                        lastDragY = 0
                    }
            )
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

// MARK: - Other Exercises Section

private struct OtherExercisesSection: View {
    let vm: ActiveWorkoutViewModel
    let theme: AccentTheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Exercises")
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textFaint)
                .textCase(.uppercase)
                .tracking(0.8)

            ForEach(vm.draftExercises.indices, id: \.self) { idx in
                if idx != vm.activeExerciseIndex {
                    ExerciseListRow(
                        exercise: vm.draftExercises[idx],
                        accentColor: theme.accentColor,
                        onTap: { vm.activeExerciseIndex = idx }
                    )
                }
            }
        }
    }
}

// MARK: - Exercise List Row

private struct ExerciseListRow: View {
    let exercise: ActiveWorkoutViewModel.DraftExercise
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.exerciseName)
                        .font(Typography.body)
                        .foregroundStyle(Color.textPrimary)
                    Text(setsSummary)
                        .font(Typography.caption)
                        .foregroundStyle(Color.textFaint)
                }
                Spacer()
                // §11 exercise context menu — placeholder
                Menu {
                    Text("§11 — coming next")
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textMuted)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var setsSummary: String {
        let total = exercise.sets.count
        let logged = exercise.sets.filter { $0.isLogged }.count
        return "\(total) sets · \(logged) logged"
    }
}

// MARK: - Rest Timer Placeholder

private struct RestTimerPlaceholder: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 2)
            Circle()
                .trim(from: 0, to: 0.0) // §9 — arc driven by rest countdown
                .stroke(Color.heftGreen, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 30, height: 30)
    }
}

// MARK: - Empty Workout Prompt

private struct EmptyWorkoutPrompt: View {
    let accentColor: Color
    let onAddExercise: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: DesignTokens.Icon.placeholder))
                .foregroundStyle(accentColor)
            VStack(spacing: Spacing.xs) {
                Text("Ready when you are")
                    .font(Typography.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text("Add your first exercise to start logging.")
                    .font(Typography.caption)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
            }
            Button(action: onAddExercise) {
                Label("Add Exercise", systemImage: "plus")
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(accentColor.opacity(0.12), in: Capsule())
                    .overlay(Capsule().strokeBorder(accentColor.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
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
