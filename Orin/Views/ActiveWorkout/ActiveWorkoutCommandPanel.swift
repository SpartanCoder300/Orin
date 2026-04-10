// iOS 26+ only. No #available guards.

import SwiftData
import SwiftUI

// MARK: - Command Panel

struct ActiveWorkoutCommandPanel: View {
    let vm: ActiveWorkoutViewModel
    let theme: AccentTheme
    let onComplete: (WorkoutSession) -> Void
    let onDismiss: () -> Void

    private let tuner = SwipeTuningManager.shared

    @AppStorage("hasUsedSwipeControl") private var hasUsedSwipeControl: Bool = false
    /// Counts how many sessions have shown the hint. Stops at 2.
    @AppStorage("Orin.swipeHintSessionCount") private var swipeHintSessionCount: Int = 0
    @State private var isKeyboardVisible = false
    @State private var hintToken: UUID? = nil
    /// Prevents the hint from firing more than once within the same session.
    @State private var didShowHintThisSession: Bool = false
    @State private var hintTask: Task<Void, Never>? = nil
    @State private var isShowingLogSuccess = false
    @State private var logSuccessTrigger = 0
    @State private var logSuccessResetTask: Task<Void, Never>? = nil

    private let horizontalInset: CGFloat = ActiveWorkoutLayout.horizontalInset

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
                    .foregroundStyle(Color.OrinGreen)
                    .padding(.vertical, Spacing.md)
                    .padding(.horizontal, Spacing.xl)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
            .modifier(CommandPanelElevation(cornerRadius: Radius.sheet))
            .padding(.horizontal, horizontalInset)
            .padding(.bottom, Spacing.md)

        } else if let focus = vm.currentFocusContext {
            // ── Set editing card ───────────────────────────────────────────────
            let exercise = focus.exercise

            VStack(spacing: 0) {
                // Drag handle — visible only when keyboard is up, swipe down dismisses
                if isKeyboardVisible {
                    ZStack {
                        Color.clear.frame(height: 24)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 36, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onEnded { value in
                                guard value.translation.height > 20,
                                      abs(value.translation.height) > abs(value.translation.width) else { return }
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil
                                )
                            }
                    )
                }

                // Context label — mirrors the accent bar in SetRow to visually connect panel to row
                HStack(spacing: Spacing.xs) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(theme.accentColor)
                        .frame(width: 3, height: 14)
                    Text("\(exercise.exerciseName)  ·  Set \(focus.setIndex + 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.86))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, 2)
                .contentTransition(.opacity)
                .animation(
                    .easeOut(duration: ActiveWorkoutLayout.focusSyncDuration),
                    value: focus.exerciseIndex
                )
                .animation(
                    .easeOut(duration: ActiveWorkoutLayout.focusSyncDuration),
                    value: focus.setIndex
                )

                // Row 1: Weight | Reps (or Duration for timed exercises)
                HStack(spacing: 0) {
                    if exercise.tracksWeight {
                        SwipeValueControl(
                            text: Binding(
                                get: { vm.currentFocusContext?.set.weightText ?? "" },
                                set: {
                                    vm.draftExercises[focus.exerciseIndex].sets[focus.setIndex].weightText = $0
                                    vm.markSetTouched(exerciseIndex: focus.exerciseIndex, setIndex: focus.setIndex)
                                }
                            ),
                            unit: "lbs",
                            step: exercise.weightIncrement,
                            minValue: 0,
                            maxValue: 999,
                            isInteger: false,
                            firstTapDefault: exercise.startingWeight,
                            pixelsPerStep: Double(tuner.config.weightPointsPerStep),
                            dragActivationThreshold: tuner.config.dragActivationThreshold,
                            activeLiftAmount: tuner.config.activeLiftAmount,
                            milestones: weightMilestones(for: exercise.equipmentType),
                            onInteractionStart: { vm.requestRevealCurrentFocus(); hasUsedSwipeControl = true; cancelHint() },
                            onCommit: { vm.queueDraftPersistence(); vm.refreshActivityState() },
                            hintToken: hintToken,
                            maxMomentumSteps: tuner.config.weightMaxMomentumSteps
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        Divider()
                    }

                    if exercise.isTimed {
                        SwipeValueControl(
                            text: Binding(
                                get: { vm.currentFocusContext?.set.durationText ?? "" },
                                set: {
                                    vm.draftExercises[focus.exerciseIndex].sets[focus.setIndex].durationText = $0
                                    vm.markSetTouched(exerciseIndex: focus.exerciseIndex, setIndex: focus.setIndex)
                                }
                            ),
                            unit: "sec",
                            step: 5,
                            minValue: 5,
                            maxValue: 600,
                            isInteger: true,
                            firstTapDefault: 30,
                            dragActivationThreshold: tuner.config.dragActivationThreshold,
                            activeLiftAmount: tuner.config.activeLiftAmount,
                            onInteractionStart: { vm.requestRevealCurrentFocus(); hasUsedSwipeControl = true; cancelHint() },
                            onCommit: { vm.queueDraftPersistence(); vm.refreshActivityState() },
                            hintToken: hintToken,
                            maxMomentumSteps: tuner.config.repsMaxMomentumSteps
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        SwipeValueControl(
                            text: Binding(
                                get: { vm.currentFocusContext?.set.repsText ?? "" },
                                set: {
                                    vm.draftExercises[focus.exerciseIndex].sets[focus.setIndex].repsText = $0
                                    vm.markSetTouched(exerciseIndex: focus.exerciseIndex, setIndex: focus.setIndex)
                                }
                            ),
                            unit: "reps",
                            step: 1,
                            minValue: 0,
                            maxValue: 50,
                            isInteger: true,
                            firstTapDefault: 5,
                            pixelsPerStep: Double(tuner.config.repsPointsPerStep),
                            dragActivationThreshold: tuner.config.dragActivationThreshold,
                            activeLiftAmount: tuner.config.activeLiftAmount,
                            onInteractionStart: { vm.requestRevealCurrentFocus(); hasUsedSwipeControl = true; cancelHint() },
                            onCommit: { vm.queueDraftPersistence(); vm.refreshActivityState() },
                            hintToken: hintToken,
                            maxMomentumSteps: tuner.config.repsMaxMomentumSteps
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(height: 72)

                if !hasUsedSwipeControl {
                    Text("Swipe to adjust · Tap to type")
                        .font(.caption2)
                        .foregroundStyle(Color.textFaint.opacity(0.55))
                        .padding(.vertical, Spacing.xs)
                        .transition(.opacity)
                }

                Divider()
                    .overlay(Color.white.opacity(0.02))

                Button {
                    cancelHint()
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                    if vm.logFocusedSet() {
                        triggerLogSuccess()
                    }
                } label: {
                    let buttonShape = UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 0,
                            bottomLeading: Radius.large,
                            bottomTrailing: Radius.large,
                            topTrailing: 0
                        ),
                        style: .continuous
                    )

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: isShowingLogSuccess ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .contentTransition(.symbolEffect(.replace))
                        Text(isShowingLogSuccess ? "Logged" : "Log Set")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(isShowingLogSuccess ? Color.OrinGreen : theme.accentColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        let activeColor = isShowingLogSuccess ? Color.OrinGreen : theme.accentColor
                        buttonShape
                            .fill(activeColor.opacity(isShowingLogSuccess ? 0.042 : 0.03))
                            .overlay {
                                buttonShape
                                    .strokeBorder(activeColor.opacity(isShowingLogSuccess ? 0.09 : 0.06), lineWidth: 1)
                            }
                    }
                    .contentShape(Rectangle())
                    .animation(Motion.standardSpring, value: isShowingLogSuccess)
                }
                .buttonStyle(LogSetButtonStyle())
                .frame(height: 60)
            }
            .background {
                // Glass as a background layer so the swipe pill's lift offset
                // isn't clipped — glassEffect clips its own subtree, not the parent.
                Color.clear
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
            }
            .modifier(CommandPanelElevation(cornerRadius: Radius.large))
            .padding(.horizontal, horizontalInset)
            .padding(.bottom, Spacing.md)
            .onAppear { triggerHintIfNeeded() }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.2)) { isKeyboardVisible = true }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.2)) { isKeyboardVisible = false }
            }
            .sensoryFeedback(.success, trigger: logSuccessTrigger)
            .onDisappear {
                logSuccessResetTask?.cancel()
            }

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

    private func triggerHintIfNeeded() {
        guard swipeHintSessionCount < 2, !didShowHintThisSession else { return }
        hintTask?.cancel()
        hintTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1400))
            guard !Task.isCancelled else { return }
            didShowHintThisSession = true
            swipeHintSessionCount += 1
            hintToken = UUID()
        }
    }

    private func cancelHint() {
        hintTask?.cancel()
        hintTask = nil
        hintToken = nil
    }

    private func triggerLogSuccess() {
        logSuccessResetTask?.cancel()
        withAnimation(Motion.standardSpring) {
            isShowingLogSuccess = true
        }
        logSuccessTrigger += 1
        logSuccessResetTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            withAnimation(Motion.standardSpring) {
                isShowingLogSuccess = false
            }
        }
    }

}

// MARK: - Helpers

private struct LogSetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.14, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private struct CommandPanelElevation: ViewModifier {
    let cornerRadius: CGFloat

    private enum DepthStyle {
        static let topScrimHeight: CGFloat = 20
        static let topScrimOpacity = 0.12
        // White surface fill — makes the glass panel read as elevated on dark backgrounds
        static let surfaceTintOpacity = 0.07
        // Specular highlight — brighter on top edge, fades out toward bottom
        static let borderTopOpacity = 0.18
        static let borderBottomOpacity = 0.05
        // Ambient shadow — large, soft, spreads depth far
        static let primaryShadowOpacity = 0.30
        static let primaryShadowRadius: CGFloat = 24
        static let primaryShadowYOffset: CGFloat = 12
        // Directional shadow — medium, main cast
        static let secondaryShadowOpacity = 0.18
        static let secondaryShadowRadius: CGFloat = 8
        static let secondaryShadowYOffset: CGFloat = 4
        // Contact shadow — tight, reads as "lifted off surface"
        static let contactShadowOpacity = 0.22
        static let contactShadowRadius: CGFloat = 1
        static let contactShadowYOffset: CGFloat = 1
        static let recessionOpacity = 0.08
        static let recessionInset: CGFloat = 3
        static let recessionBlur: CGFloat = 18
    }

    func body(content: Content) -> some View {
        content
            .padding(.top, Spacing.sm)
            .background {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(DepthStyle.topScrimOpacity)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: DepthStyle.topScrimHeight)
                    .mask {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    }
                    .allowsHitTesting(false)

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(DepthStyle.surfaceTintOpacity))
                        .background {
                            RoundedRectangle(cornerRadius: cornerRadius + DepthStyle.recessionInset, style: .continuous)
                                .fill(Color.black.opacity(DepthStyle.recessionOpacity))
                                .padding(.horizontal, -DepthStyle.recessionInset)
                                .padding(.vertical, -DepthStyle.recessionInset)
                                .blur(radius: DepthStyle.recessionBlur)
                        }
                }
            }
            // Specular highlight: bright top edge fades to subtle bottom — simulates light hitting a raised surface
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(DepthStyle.borderTopOpacity),
                                Color.white.opacity(DepthStyle.borderBottomOpacity)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
            .shadow(
                color: Color.black.opacity(DepthStyle.contactShadowOpacity),
                radius: DepthStyle.contactShadowRadius,
                y: DepthStyle.contactShadowYOffset
            )
            .shadow(
                color: Color.black.opacity(DepthStyle.secondaryShadowOpacity),
                radius: DepthStyle.secondaryShadowRadius,
                y: DepthStyle.secondaryShadowYOffset
            )
            .shadow(
                color: Color.black.opacity(DepthStyle.primaryShadowOpacity),
                radius: DepthStyle.primaryShadowRadius,
                y: DepthStyle.primaryShadowYOffset
            )
    }
}

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
            .environment(\.OrinTheme, .midnight)
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
            .environment(\.OrinTheme, .midnight)
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
            .environment(\.OrinTheme, .midnight)
            .preferredColorScheme(.dark)
    }()
}

private func weightMilestones(for equipmentType: String) -> Set<Double>? {
    switch equipmentType {
    case "Barbell":
        // Standard plate combinations on a 45 lb bar
        return [45, 95, 135, 185, 225, 275, 315, 365, 405]
    case "Dumbbell":
        // Common dumbbell rack weights every 10 lbs
        return Set(stride(from: 10.0, through: 150.0, by: 10.0))
    case "Cable":
        // Cable stack landmarks every 20 lbs
        return Set(stride(from: 20.0, through: 300.0, by: 20.0))
    case "Machine":
        // Machine stack landmarks every 25 lbs
        return Set(stride(from: 25.0, through: 400.0, by: 25.0))
    case "Kettlebell":
        // Nearest multiples of 4 (the step size) to standard bell weights
        return [16, 28, 36, 44, 52, 60, 72, 88]
    default:
        return nil
    }
}
