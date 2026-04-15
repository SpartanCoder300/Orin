// iOS 26+ only. No #available guards.

import SwiftUI
import UIKit

struct SwipeSetAction: Identifiable {
    let id = UUID()
    let systemImage: String
    let tint: Color
    let accessibilityLabel: String
    let action: () -> Void
}

struct SwipeableSetRow<Content: View>: View {
    let rowID: UUID
    let actions: [SwipeSetAction]           // trailing — revealed by left swipe
    let leadingAction: SwipeSetAction?      // leading — revealed by right swipe
    @Binding var openRowID: UUID?
    let content: (_ isInteracting: Bool, _ swipeProgress: CGFloat) -> Content

    @State private var offsetX: CGFloat = 0
    @State private var panStartOffsetX: CGFloat = 0
    @State private var isPastCommitThreshold = false
    @State private var lockedDirection: SwipeDirection = .none

    private enum SwipeDirection { case none, leading, trailing }

    private let actionWidth: CGFloat = 68
    private let actionVisibleHeight: CGFloat = 46
    private let actionCornerRadius: CGFloat = 8
    private let actionHorizontalInset: CGFloat = 4
    private let maxOverswipe: CGFloat = 88
    private let commitOverswipeThreshold: CGFloat = 56

    init(
        rowID: UUID,
        actions: [SwipeSetAction],
        leadingAction: SwipeSetAction? = nil,
        openRowID: Binding<UUID?>,
        @ViewBuilder content: @escaping (_ isInteracting: Bool, _ swipeProgress: CGFloat) -> Content
    ) {
        self.rowID = rowID
        self.actions = actions
        self.leadingAction = leadingAction
        self._openRowID = openRowID
        self.content = content
    }

    var body: some View {
        ZStack {
            // Leading background — only shown when actually swiping leading, not rubber-banding
            if offsetX > 0, lockedDirection != .trailing {
                leadingActionBackground
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Trailing background — only shown when actually swiping trailing, not rubber-banding
            if offsetX < 0, lockedDirection != .leading {
                trailingActionBackground
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            content(isInteracting, trailingSwipeProgress)
                .contentShape(Rectangle())
                .offset(x: offsetX)
                .allowsHitTesting(offsetX == 0)
        }
        .gesture(
            HorizontalSwipePanGesture(
                isEnabled: !actions.isEmpty || leadingAction != nil,
                allowsRightSwipeToClose: isOpen && offsetX < 0,
                hasLeadingAction: leadingAction != nil && offsetX >= 0,
                onBegan: handlePanBegan,
                onChanged: handlePanChanged(_:),
                onEnded: handlePanEnded(translationX:velocityX:),
                onCancelled: resetPanState
            )
        )
        .onChange(of: openRowID) { _, newValue in
            guard newValue != rowID, offsetX != 0 else { return }
            closeRow()
        }
    }

    // MARK: - Computed

    private var trailingRevealWidth: CGFloat {
        CGFloat(actions.count) * actionWidth
    }

    private var leadingRevealWidth: CGFloat {
        leadingAction != nil ? actionWidth : 0
    }

    private var isOpen: Bool { openRowID == rowID }
    private var isInteracting: Bool { offsetX != 0 }

    /// 0→1 as the row is swiped left (for content dimming / scale effects).
    private var trailingSwipeProgress: CGFloat {
        min(1, max(0, -offsetX / max(trailingRevealWidth, 1)))
    }

    // MARK: - Trailing action background (left swipe)

    private var trailingActionBackground: some View {
        let exposedWidth = max(0, -offsetX)
        let commitProgress = trailingFullSwipeCommitProgress(exposedWidth: exposedWidth)

        return HStack(spacing: 0) {
            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                let isPrimary = index == actions.count - 1
                let zoneWidth = isPrimary
                    ? actionWidth + ((exposedWidth - trailingRevealWidth) * commitProgress)
                    : actionWidth
                let bgOpacity = 0.18 + (0.54 * commitProgress)
                let fgColor: Color = commitProgress > 0.72 ? .white : action.tint

                Button {
                    closeRow()
                    action.action()
                } label: {
                    let actionZoneWidth = max(actionWidth, zoneWidth)
                    ZStack {
                        RoundedRectangle(cornerRadius: actionCornerRadius, style: .continuous)
                            .fill(action.tint.opacity(bgOpacity))
                            .frame(
                                width: max(0, actionZoneWidth - actionHorizontalInset * 2),
                                height: actionVisibleHeight
                            )

                        Image(systemName: action.systemImage)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(fgColor)
                    }
                    .frame(width: actionZoneWidth)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.accessibilityLabel)
            }
        }
        .frame(width: exposedWidth, alignment: .trailing)
        .clipped()
    }

    // MARK: - Leading action background (right swipe)

    @ViewBuilder
    private var leadingActionBackground: some View {
        if let action = leadingAction {
            let exposedWidth = max(0, offsetX)
            let commitProgress = leadingFullSwipeCommitProgress(exposedWidth: exposedWidth)
            let zoneWidth = actionWidth + ((exposedWidth - leadingRevealWidth) * commitProgress)
            let bgOpacity = 0.18 + (0.54 * commitProgress)
            let fgColor: Color = commitProgress > 0.72 ? .white : action.tint

            Button {
                closeRow()
                action.action()
            } label: {
                let actionZoneWidth = max(actionWidth, zoneWidth)
                ZStack {
                    RoundedRectangle(cornerRadius: actionCornerRadius, style: .continuous)
                        .fill(action.tint.opacity(bgOpacity))
                        .frame(
                            width: max(0, actionZoneWidth - actionHorizontalInset * 2),
                            height: actionVisibleHeight
                        )

                    Image(systemName: action.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(fgColor)
                }
                .frame(width: actionZoneWidth)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(action.accessibilityLabel)
            .frame(width: exposedWidth, alignment: .leading)
            .clipped()
        }
    }

    // MARK: - Gesture handlers

    private func handlePanBegan() {
        // Lock direction based on current open state so the gesture can't cross sides.
        if offsetX < 0 {
            panStartOffsetX = offsetX
            lockedDirection = .trailing
        } else if offsetX > 0 {
            panStartOffsetX = offsetX
            lockedDirection = .leading
        } else {
            panStartOffsetX = 0
            lockedDirection = .none
        }
        isPastCommitThreshold = false
    }

    private func handlePanChanged(_ translationX: CGFloat) {
        let proposed = panStartOffsetX + translationX

        // Lock direction on first meaningful movement.
        if lockedDirection == .none {
            if proposed < -4 { lockedDirection = .trailing }
            else if proposed > 4 { lockedDirection = .leading }
            else { return }
        }

        switch lockedDirection {
        case .trailing:
            if proposed <= 0 {
                offsetX = max(-(trailingRevealWidth + maxOverswipe), proposed)
                if offsetX != 0 { openRowID = rowID }
                let exposed = -offsetX
                let isNowPast = exposed > trailingRevealWidth + commitOverswipeThreshold
                if isNowPast != isPastCommitThreshold {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
                    isPastCommitThreshold = isNowPast
                }
            } else {
                // Wrong direction — rubber band resistance, no action
                offsetX = rubberBand(proposed)
            }

        case .leading:
            if proposed >= 0 {
                offsetX = min(leadingRevealWidth + maxOverswipe, proposed)
                if offsetX != 0 { openRowID = rowID }
                let exposed = offsetX
                let isNowPast = exposed > leadingRevealWidth + commitOverswipeThreshold
                if isNowPast != isPastCommitThreshold {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
                    isPastCommitThreshold = isNowPast
                }
            } else {
                // Wrong direction — rubber band resistance, no action
                offsetX = -rubberBand(-proposed)
            }

        case .none:
            break
        }
    }

    private func handlePanEnded(translationX: CGFloat, velocityX: CGFloat) {
        // Rubber-banded into wrong direction — spring back with finger velocity.
        let isRubberBanded = (lockedDirection == .trailing && offsetX > 0)
                          || (lockedDirection == .leading && offsetX < 0)
        if isRubberBanded {
            withAnimation(springBack(velocity: velocityX, from: offsetX, to: panStartOffsetX)) {
                offsetX = panStartOffsetX
                if offsetX == 0, openRowID == rowID { openRowID = nil }
            }
            return
        }

        // Velocity threshold Apple uses: low enough that any deliberate flick works.
        let flickThreshold: CGFloat = 150

        // Leading (right swipe)
        if lockedDirection == .leading, let leadingAction {
            if offsetX > leadingRevealWidth + commitOverswipeThreshold
                || velocityX > flickThreshold * 5 {
                commit(leadingAction, velocityX: velocityX); return
            }
            // Flick right → stay open. Flick left OR slow drag past midpoint → close.
            let shouldOpen: Bool
            if velocityX < -flickThreshold {
                shouldOpen = false
            } else if velocityX > flickThreshold {
                shouldOpen = true
            } else {
                shouldOpen = offsetX > leadingRevealWidth * 0.5
            }
            let target: CGFloat = shouldOpen ? leadingRevealWidth : 0
            withAnimation(springBack(velocity: velocityX, from: offsetX, to: target)) {
                offsetX = target
                if !shouldOpen, openRowID == rowID { openRowID = nil }
                else if shouldOpen { openRowID = rowID }
            }
            return
        }

        // Trailing (left swipe)
        if -offsetX > trailingRevealWidth + commitOverswipeThreshold
            || velocityX < -flickThreshold * 5 {
            if let action = actions.last { commit(action, velocityX: velocityX) }
            return
        }
        // Flick right → close. Flick left → stay open. Slow drag: use position midpoint,
        // but also close if the user clearly dragged away from the open position.
        let movedTowardClose = panStartOffsetX < 0 && offsetX > panStartOffsetX + trailingRevealWidth * 0.4
        let shouldOpen: Bool
        if velocityX > flickThreshold || movedTowardClose {
            shouldOpen = false
        } else if velocityX < -flickThreshold {
            shouldOpen = true
        } else {
            shouldOpen = -offsetX > trailingRevealWidth * 0.5
        }
        let target: CGFloat = shouldOpen ? -trailingRevealWidth : 0
        withAnimation(springBack(velocity: velocityX, from: offsetX, to: target)) {
            offsetX = target
            if !shouldOpen, openRowID == rowID { openRowID = nil }
            else if shouldOpen { openRowID = rowID }
        }
    }

    /// Creates an interpolating spring seeded with the gesture's actual finger velocity,
    /// so the settle feels like a physical continuation rather than a fresh animation.
    private func springBack(velocity: CGFloat, from: CGFloat, to: CGFloat) -> Animation {
        let distance = to - from
        guard abs(distance) > 0.1 else { return .spring(response: 0.3, dampingFraction: 0.8) }
        let normalizedVelocity = velocity / distance
        return .interpolatingSpring(stiffness: 400, damping: 40, initialVelocity: normalizedVelocity)
    }

    private func rubberBand(_ delta: CGFloat, limit: CGFloat = 60) -> CGFloat {
        limit * (1 - 1 / (delta / limit + 1))
    }

    private func resetPanState() {
        panStartOffsetX = 0
        isPastCommitThreshold = false
        lockedDirection = .none
        if offsetX == 0 { openRowID = nil }
    }

    private func commit(_ action: SwipeSetAction, velocityX: CGFloat = 0) {
        let target: CGFloat = offsetX > 0 ? leadingRevealWidth : -trailingRevealWidth
        withAnimation(springBack(velocity: velocityX, from: offsetX, to: target)) {
            offsetX = target
            openRowID = rowID
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                offsetX = 0
                if openRowID == rowID { openRowID = nil }
            }
            action.action()
        }
    }

    private func closeRow() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            offsetX = 0
            if openRowID == rowID { openRowID = nil }
        }
    }

    // MARK: - Trailing math helpers

    private func trailingFullSwipeCommitProgress(exposedWidth: CGFloat) -> CGFloat {
        let start = trailingRevealWidth
        let end = trailingRevealWidth + maxOverswipe * 0.55
        guard end > start else { return 0 }
        return max(0, min(1, (exposedWidth - start) / (end - start)))
    }

    // MARK: - Leading math helpers

    private func leadingFullSwipeCommitProgress(exposedWidth: CGFloat) -> CGFloat {
        let start = leadingRevealWidth
        let end = leadingRevealWidth + maxOverswipe * 0.55
        guard end > start else { return 0 }
        return max(0, min(1, (exposedWidth - start) / (end - start)))
    }
}

// MARK: - Gesture Recognizer

private struct HorizontalSwipePanGesture: UIGestureRecognizerRepresentable {
    let isEnabled: Bool
    let allowsRightSwipeToClose: Bool
    let hasLeadingAction: Bool
    let onBegan: () -> Void
    let onChanged: (CGFloat) -> Void
    let onEnded: (_ translationX: CGFloat, _ velocityX: CGFloat) -> Void
    let onCancelled: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.maximumNumberOfTouches = 1
        recognizer.delegate = context.coordinator
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        context.coordinator.isEnabled = isEnabled
        context.coordinator.allowsRightSwipeToClose = allowsRightSwipeToClose
        context.coordinator.hasLeadingAction = hasLeadingAction
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        context.coordinator.isEnabled = isEnabled
        context.coordinator.allowsRightSwipeToClose = allowsRightSwipeToClose
        context.coordinator.hasLeadingAction = hasLeadingAction
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translationX = recognizer.translation(in: recognizer.view).x
        let velocityX = recognizer.velocity(in: recognizer.view).x

        switch recognizer.state {
        case .began:
            onBegan()
            onChanged(translationX)
        case .changed:
            onChanged(translationX)
        case .ended:
            onEnded(translationX, velocityX)
        case .cancelled, .failed:
            onCancelled()
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var isEnabled = true
        var allowsRightSwipeToClose = false
        var hasLeadingAction = false

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard isEnabled, let pan = gestureRecognizer as? UIPanGestureRecognizer else {
                return false
            }
            let velocity = pan.velocity(in: pan.view)
            let isRightSwipe = velocity.x > 0

            // When closing an already-open row, be very lenient — accept any rightward gesture
            // that isn't nearly vertical. The direction lock handles drift in handlePanChanged.
            if allowsRightSwipeToClose && isRightSwipe {
                return abs(velocity.x) > abs(velocity.y) * 0.25
            }

            // For opening, require a clearly horizontal gesture to avoid competing with ScrollView.
            guard abs(velocity.x) > abs(velocity.y) * 1.5 else { return false }
            if !isRightSwipe { return true }
            return hasLeadingAction
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            false
        }
    }
}
