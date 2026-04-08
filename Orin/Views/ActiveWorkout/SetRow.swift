// iOS 26+ only. No #available guards.

import SwiftUI
import UIKit

// MARK: - Helpers

/// Formats a duration in seconds as "30s" (< 60s) or "1:30" (≥ 60s).
func formatDuration(_ seconds: Int) -> String {
    guard seconds > 0 else { return "—" }
    if seconds < 60 { return "\(seconds)s" }
    let m = seconds / 60
    let s = seconds % 60
    return s == 0 ? "\(m)m" : "\(m):\(String(format: "%02d", s))"
}

private func formatWeight(_ w: Double) -> String {
    w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
}

private enum DeltaDirection {
    case up, down
    var symbol: String { switch self { case .up: "↑"; case .down: "↓" } }
    var color: Color {
        switch self {
        case .up:   Color.OrinGreen
        case .down: Color.red.opacity(0.75)
        }
    }
}

private struct DeltaResult {
    let direction: DeltaDirection
    let label: String
    var displayText: String { "\(direction.symbol) \(label)" }
    var color: Color { direction.color }
}

private enum SetRowSwipeAction: Equatable {
    case copyFromAbove
    case delete
    case undo

    var title: String {
        switch self {
        case .copyFromAbove: "Copy"
        case .delete: "Delete"
        case .undo: "Undo"
        }
    }

    var icon: String {
        switch self {
        case .copyFromAbove: "arrow.up.doc.on.clipboard"
        case .delete: "trash"
        case .undo: "arrow.uturn.backward"
        }
    }

    var tint: Color {
        switch self {
        case .copyFromAbove: Color.OrinBlue
        case .delete: Color.OrinRed
        case .undo: .orange
        }
    }
}

private enum SetRowDragIntent {
    case undetermined
    case horizontal
    case vertical
}

// MARK: - Set Row

/// Compact set row — values display only, editing via bottom command bar.
/// Tap row to focus, tap circle to log directly.
struct SetRow: View {
    let setNumber: Int
    let weightText: String
    let repsText: String
    let durationText: String
    let isTimed: Bool
    let tracksWeight: Bool
    let setType: SetType
    let isLogged: Bool
    let isFocused: Bool
    let isFirstInCard: Bool
    let isLastInCard: Bool
    let isPR: Bool
    let justGotPR: Bool
    let accentColor: Color
    /// When non-nil and the set has no user-entered values, this text is shown greyed
    /// out to signal that the app will pre-fill from set 1.
    let placeholderDisplayText: String?
    /// Animation delay for the placeholder fade-in (stagger effect across sets).
    let placeholderDelay: Double
    let previousSet: ActiveWorkoutViewModel.PreviousSet?
    /// True only for the single most-recently-logged set — drives the delta fade timer.
    let justLogged: Bool
    let onCycleType: () -> Void
    let onFocus: () -> Void
    let onLog: () -> Void
    let onDelete: () -> Void
    let onUndo: () -> Void
    let onCopyFromAbove: (() -> Void)?
    let onAdoptPlaceholder: (() -> Void)?

    @State private var rowScale: CGFloat = 1.0
    @State private var badgeScale: CGFloat = 0
    @State private var showDelta = false
    @State private var deltaFadeTask: Task<Void, Never>? = nil
    @State private var logHighlightOpacity: Double = 0
    @State private var checkScale: CGFloat = 1.0
    @State private var swipeOffset: CGFloat = 0
    @State private var dragIntent: SetRowDragIntent = .undetermined
    @State private var didTriggerSwipeHaptic = false
    @State private var swipeResetTask: Task<Void, Never>? = nil
    private let triggerThreshold: CGFloat = 60
    private let revealWidth: CGFloat = 72
    private let swipeElasticity: CGFloat = 0.2
    private let horizontalLockThreshold: CGFloat = 10
    private let verticalIntentThreshold: CGFloat = 10

    private var canSwipeRight: Bool { !isLogged && onCopyFromAbove != nil }
    private var trailingSwipeAction: SetRowSwipeAction { isLogged ? .undo : .delete }

    private var isShowingPlaceholder: Bool {
        guard let _ = placeholderDisplayText else { return false }
        return !isLogged && weightText.isEmpty && repsText.isEmpty && durationText.isEmpty
    }

    var body: some View {
        ZStack {
            if canSwipeRight { leadingActionView }
            trailingActionView
            rowContentView
        }
        .clipped()
        .contentShape(Rectangle())
        .onAppear {
            if isPR { badgeScale = 1.0 }
        }
        .onDisappear {
            deltaFadeTask?.cancel()
            swipeResetTask?.cancel()
            resetSwipeState(animated: false)
        }
        .onChange(of: justLogged) { _, isJust in
            deltaFadeTask?.cancel()
            if isJust {
                showDelta = true
                deltaFadeTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(2500))
                    guard !Task.isCancelled else { return }
                    withAnimation(Motion.standardSpring) { showDelta = false }
                }
                // Immediate ack: accent-tinted highlight with a restrained settle.
                withAnimation(.easeOut(duration: 0.08)) {
                    logHighlightOpacity = 1.0
                    rowScale = 0.992
                    checkScale = 1.08
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(110))
                    withAnimation(.easeOut(duration: 0.16)) {
                        logHighlightOpacity = 0.0
                    }
                    withAnimation(Motion.standardSpring) {
                        rowScale = 1.0
                        checkScale = 1.0
                    }
                }
            } else {
                withAnimation(Motion.standardSpring) { showDelta = false }
                logHighlightOpacity = 0
                checkScale = 1.0
            }
        }
        .onChange(of: justGotPR) { _, newVal in
            guard newVal else { return }
            // Badge: scale from zero with bouncy spring
            badgeScale = 0
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                badgeScale = 1.0
            }
            // Row: pulse scale 1.0 → 1.05 → 1.0
            withAnimation(.spring(response: 0.18, dampingFraction: 0.4)) {
                rowScale = 1.05
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(Motion.standardSpring) {
                    rowScale = 1.0
                }
            }
        }
        .simultaneousGesture(swipeGesture)
    }

    private var rowContentView: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isFocused ? accentColor.opacity(1.0) : .clear)
                .frame(width: 4, height: isFocused ? 34 : 26)

            Text("\(setNumber)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    isLogged
                        ? Color.white.opacity(0.16)
                        : isFocused
                            ? accentColor.opacity(0.70)
                            : Color.textFaint
                )
                .frame(width: 20, alignment: .center)

            if setType != .normal {
                Button(action: onCycleType) {
                    SetTypeLabel(setType: setType)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(!isLogged)
            }

            VStack(alignment: .leading, spacing: 1) {
                if isFocused, let prev = previousDisplayText {
                    Text(prev)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.48))
                        .transition(.opacity)
                }

                Text(isShowingPlaceholder ? placeholderDisplayText ?? displayText : displayText)
                    .font(.system(
                        size: isLogged ? 15 : isFocused ? 17 : 16,
                        weight: isLogged ? .regular : isFocused ? .semibold : .medium,
                        design: .rounded
                    ))
                    .monospacedDigit()
                    .foregroundStyle(valueForegroundStyle)
                    .contentTransition(.numericText())
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.85)
                            .delay(isShowingPlaceholder ? placeholderDelay : 0),
                        value: isShowingPlaceholder
                    )
            }

            if showDelta, let delta = deltaResult {
                Text(delta.displayText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(delta.color)
                    .transition(.opacity)
            }

            if isPR {
                PRBadge()
                    .scaleEffect(badgeScale)
            }

            Spacer(minLength: Spacing.sm)

            Button(action: isLogged ? onUndo : onLog) {
                Image(systemName: isLogged ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isLogged
                            ? Color.OrinGreen.opacity(0.82)
                            : isFocused
                                ? accentColor.opacity(0.90)
                                : Color.white.opacity(0.34)
                    )
                    .background {
                        if isLogged {
                            Circle()
                                .fill(Color.OrinGreen.opacity(0.08))
                                .frame(width: 28, height: 28)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(checkScale)
            }
            .buttonStyle(.plain)
        }
        .scaleEffect(rowScale)
        .padding(.vertical, isLogged ? 3 : isFocused ? 7 : 4)
        .padding(.leading, Spacing.xs)
        .padding(.trailing, Spacing.sm)
        .background(rowBackground)
        .overlay {
            rowShape
                .fill(accentColor.opacity(0.16))
                .opacity(logHighlightOpacity)
                .allowsHitTesting(false)
        }
        .overlay {
            if isLogged || isFocused {
                rowShape
                    .strokeBorder(
                        isLogged
                            ? Color.white.opacity(0.025)
                            : accentColor.opacity(0.50),
                        lineWidth: 1
                    )
            }
        }
        .offset(x: swipeOffset)
        .onTapGesture {
            guard abs(swipeOffset) < 4, !isLogged else { return }
            if isShowingPlaceholder {
                onAdoptPlaceholder?()
            } else {
                onFocus()
            }
        }
        .accessibilityAction(named: isLogged ? "Undo Set" : "Log Set") {
            if isLogged {
                onUndo()
            } else {
                onLog()
            }
        }
    }

    private var leadingActionView: some View {
        swipeActionContainer(
            alignment: .leading,
            action: .copyFromAbove,
            progress: leadingRevealProgress
        )
    }

    private var trailingActionView: some View {
        swipeActionContainer(
            alignment: .trailing,
            action: trailingSwipeAction,
            progress: trailingRevealProgress
        )
    }

    private func swipeActionContainer(
        alignment: Alignment,
        action: SetRowSwipeAction,
        progress: CGFloat
    ) -> some View {
        rowShape
            .fill(actionBackground(for: action, progress: progress))
            .overlay(alignment: alignment) {
                swipeActionLabel(for: action, progress: progress)
                    .padding(.horizontal, Spacing.md)
            }
            .opacity(progress > 0.01 ? 1 : 0)
            .allowsHitTesting(false)
    }

    private func swipeActionLabel(for action: SetRowSwipeAction, progress: CGFloat) -> some View {
        VStack(spacing: 3) {
            Image(systemName: action.icon)
                .font(.system(size: 17, weight: .semibold))
            Text(action.title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.96))
        .scaleEffect(0.86 + (0.14 * progress))
        .opacity(0.45 + (0.55 * progress))
        .offset(x: swipeLabelOffset(for: action, progress: progress))
    }

    private func actionBackground(for action: SetRowSwipeAction, progress: CGFloat) -> some ShapeStyle {
        LinearGradient(
            colors: [
                action.tint.opacity(0.55 + (0.18 * progress)),
                action.tint.opacity(0.82 + (0.10 * progress))
            ],
            startPoint: action == .copyFromAbove ? .leading : .trailing,
            endPoint: action == .copyFromAbove ? .trailing : .leading
        )
    }

    private var valueForegroundStyle: AnyShapeStyle {
        if isLogged {
            return AnyShapeStyle(Color.white.opacity(0.16))
        }
        if isShowingPlaceholder {
            return AnyShapeStyle(Color.white.opacity(0.36))
        }
        if isFocused {
            return AnyShapeStyle(Color.white.opacity(0.98))
        }
        return AnyShapeStyle(Color.white.opacity(0.54))
    }

    private var leadingRevealProgress: CGFloat {
        normalizedProgress(for: max(0, swipeOffset))
    }

    private var trailingRevealProgress: CGFloat {
        normalizedProgress(for: max(0, -swipeOffset))
    }

    private func normalizedProgress(for distance: CGFloat) -> CGFloat {
        max(0, min(1, distance / revealWidth))
    }

    private func swipeLabelOffset(for action: SetRowSwipeAction, progress: CGFloat) -> CGFloat {
        let base = (1 - progress) * 12
        return action == .copyFromAbove ? -base : base
    }

    private var displayText: String {
        if isTimed {
            let secs = Int(durationText) ?? 0
            let durationLabel = durationText.isEmpty ? "—" : formatDuration(secs)
            guard tracksWeight else { return durationLabel }
            let w = weightText.isEmpty ? "—" : weightText
            return "\(w) lb · \(durationLabel)"
        }
        guard tracksWeight else {
            let r = repsText.isEmpty ? "—" : repsText
            return "\(r) reps"
        }
        let w = weightText.isEmpty ? "—" : weightText
        let r = repsText.isEmpty ? "—" : repsText
        return "\(w) × \(r)"
    }

    /// "Last  X" string for the focused row — shows the matching previous set's value.
    private var previousDisplayText: String? {
        guard let prev = previousSet else { return nil }
        if isTimed {
            let dur = prev.duration.map { formatDuration(Int($0)) } ?? "—"
            if tracksWeight {
                return "Last  \(formatWeight(prev.weight)) × \(dur)"
            }
            return "Last  \(dur)"
        }
        if tracksWeight {
            return "Last  \(formatWeight(prev.weight)) × \(prev.reps)"
        }
        return "Last  \(prev.reps) reps"
    }

    /// Progress vs previous session — direction + magnitude label for logged rows.
    private var deltaResult: DeltaResult? {
        guard isLogged, let prev = previousSet else { return nil }

        if isTimed {
            guard let prevDur = prev.duration, let loggedDur = Double(durationText) else { return nil }
            let diff = loggedDur - prevDur
            guard diff != 0 else { return nil }
            let dir: DeltaDirection = diff > 0 ? .up : .down
            let label = (diff > 0 ? "+" : "") + formatDuration(Int(abs(diff)))
            return DeltaResult(direction: dir, label: label)
        }

        let loggedWeight = Double(weightText) ?? 0
        let loggedReps   = Int(repsText) ?? 0

        if tracksWeight {
            let weightDiff = loggedWeight - prev.weight
            let repsDiff   = loggedReps - prev.reps
            guard weightDiff != 0 || repsDiff != 0 else { return nil }

            let loggedVol = loggedWeight * Double(loggedReps)
            let prevVol   = prev.weight  * Double(prev.reps)
            guard loggedVol != prevVol else { return nil }

            let dir: DeltaDirection = loggedVol > prevVol ? .up : .down

            // Weight changed → label shows weight delta; otherwise show reps delta
            if weightDiff != 0 {
                let abs = formatWeight(Swift.abs(weightDiff))
                let prefix = weightDiff > 0 ? "+" : "-"
                return DeltaResult(direction: dir, label: "\(prefix)\(abs) lb")
            } else {
                let abs = Swift.abs(repsDiff)
                let prefix = repsDiff > 0 ? "+" : "-"
                return DeltaResult(direction: dir, label: "\(prefix)\(abs) \(abs == 1 ? "rep" : "reps")")
            }
        }

        // Reps only
        let repsDiff = loggedReps - prev.reps
        guard repsDiff != 0 else { return nil }
        let dir: DeltaDirection = repsDiff > 0 ? .up : .down
        let abs = Swift.abs(repsDiff)
        let prefix = repsDiff > 0 ? "+" : "-"
        return DeltaResult(direction: dir, label: "\(prefix)\(abs) \(abs == 1 ? "rep" : "reps")")
    }

    private var rowShape: some InsettableShape {
        Rectangle()
    }

    private var rowBackground: some View {
        rowShape
            .fill(
                isLogged
                ? Color.white.opacity(0.04)
                : isFocused
                    ? accentColor.opacity(0.40)
                    : .clear
            )
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .local)
            .onChanged { value in
                swipeResetTask?.cancel()

                switch dragIntent {
                case .vertical:
                    return
                case .undetermined:
                    let horizontalTravel = abs(value.translation.width)
                    let verticalTravel = abs(value.translation.height)

                    if verticalTravel > verticalIntentThreshold && verticalTravel > horizontalTravel * 1.05 {
                        dragIntent = .vertical
                        resetSwipeState(animated: false)
                        return
                    }

                    guard horizontalTravel > horizontalLockThreshold,
                          horizontalTravel > verticalTravel * 1.1 else { return }

                    dragIntent = .horizontal
                case .horizontal:
                    break
                }

                let raw = value.translation.width
                if raw > 0 {
                    guard canSwipeRight else { return }
                    let excess = max(0, raw - revealWidth)
                    swipeOffset = min(raw, revealWidth) + excess * swipeElasticity
                } else if raw < 0 {
                    let excess = min(0, raw + revealWidth)
                    swipeOffset = max(raw, -revealWidth) + excess * swipeElasticity
                } else {
                    swipeOffset = 0
                }
                let absOffset = abs(swipeOffset)
                if absOffset >= triggerThreshold && !didTriggerSwipeHaptic {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    didTriggerSwipeHaptic = true
                } else if absOffset < triggerThreshold {
                    didTriggerSwipeHaptic = false
                }
            }
            .onEnded { value in
                let intent = dragIntent
                dragIntent = .undetermined

                guard intent == .horizontal else {
                    resetSwipeState(animated: false)
                    return
                }

                let velocityX = value.predictedEndTranslation.width - value.translation.width
                let triggerRight = swipeOffset > triggerThreshold || (swipeOffset > 20 && velocityX > 400)
                let triggerLeft  = swipeOffset < -triggerThreshold || (swipeOffset < -20 && velocityX < -400)
                let triggeredAction = triggerRight ? SetRowSwipeAction.copyFromAbove : (triggerLeft ? trailingSwipeAction : nil)
                if let triggeredAction {
                    let commitOffset = triggeredAction == .copyFromAbove ? revealWidth + 8 : -(revealWidth + 8)
                    withAnimation(.spring(response: 0.20, dampingFraction: 0.82)) {
                        swipeOffset = commitOffset
                    }
                    swipeResetTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(70))
                        guard !Task.isCancelled else { return }
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                            swipeOffset = 0
                        }
                        didTriggerSwipeHaptic = false
                    }
                } else {
                    resetSwipeState(animated: true)
                }
                if triggerRight { onCopyFromAbove?() }
                else if triggerLeft { isLogged ? onUndo() : onDelete() }
            }
    }

    private func resetSwipeState(animated: Bool) {
        swipeResetTask?.cancel()
        didTriggerSwipeHaptic = false

        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                swipeOffset = 0
            }
        } else {
            swipeOffset = 0
        }
    }
}

// MARK: - Previews

#Preview("Unlogged – focused") {
    SetRow(
        setNumber: 1,
        weightText: "185",
        repsText: "5",
        durationText: "",
        isTimed: false,
        tracksWeight: true,
        setType: .normal,
        isLogged: false,
        isFocused: true,
        isFirstInCard: true,
        isLastInCard: false,
        isPR: false,
        justGotPR: false,
        accentColor: AccentTheme.midnight.accentColor,
        placeholderDisplayText: nil,
        placeholderDelay: 0,
        previousSet: nil, justLogged: false,
        onCycleType: {}, onFocus: {}, onLog: {}, onDelete: {}, onUndo: {}, onCopyFromAbove: nil, onAdoptPlaceholder: nil
    )
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Placeholder") {
    SetRow(
        setNumber: 2,
        weightText: "",
        repsText: "",
        durationText: "",
        isTimed: false,
        tracksWeight: true,
        setType: .normal,
        isLogged: false,
        isFocused: false,
        isFirstInCard: false,
        isLastInCard: false,
        isPR: false,
        justGotPR: false,
        accentColor: AccentTheme.midnight.accentColor,
        placeholderDisplayText: "185 × 5",
        placeholderDelay: 0.05,
        previousSet: nil, justLogged: false,
        onCycleType: {}, onFocus: {}, onLog: {}, onDelete: {}, onUndo: {}, onCopyFromAbove: {}, onAdoptPlaceholder: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Logged – PR") {
    SetRow(
        setNumber: 2,
        weightText: "200",
        repsText: "3",
        durationText: "",
        isTimed: false,
        tracksWeight: true,
        setType: .normal,
        isLogged: true,
        isFocused: false,
        isFirstInCard: false,
        isLastInCard: false,
        isPR: true,
        justGotPR: false,
        accentColor: AccentTheme.midnight.accentColor,
        placeholderDisplayText: nil,
        placeholderDelay: 0,
        previousSet: nil, justLogged: false,
        onCycleType: {}, onFocus: {}, onLog: {}, onDelete: {}, onUndo: {}, onCopyFromAbove: {}, onAdoptPlaceholder: nil
    )
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Warmup") {
    SetRow(
        setNumber: 1,
        weightText: "135",
        repsText: "8",
        durationText: "",
        isTimed: false,
        tracksWeight: true,
        setType: .warmup,
        isLogged: false,
        isFocused: false,
        isFirstInCard: false,
        isLastInCard: true,
        isPR: false,
        justGotPR: false,
        accentColor: AccentTheme.midnight.accentColor,
        placeholderDisplayText: nil,
        placeholderDelay: 0,
        previousSet: nil, justLogged: false,
        onCycleType: {}, onFocus: {}, onLog: {}, onDelete: {}, onUndo: {}, onCopyFromAbove: {}, onAdoptPlaceholder: nil
    )
    .padding()
    .preferredColorScheme(.dark)
}
