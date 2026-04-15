//
//  OrinTests.swift
//  OrinTests
//
//  Created by Garrett Spencer on 3/17/26.
//

import Testing
@testable import Orin

struct OrinTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

// MARK: - Progress Feedback Classification Tests

struct ProgressFeedbackTests {

    // MARK: Invalid / missing reference

    @Test func invalidLoggedReps_returnsNone() {
        #expect(classifySetProgress(loggedWeight: 100, loggedReps: 0, prevWeight: 100, prevReps: 8) == .none)
    }

    @Test func invalidPrevReps_returnsNone() {
        #expect(classifySetProgress(loggedWeight: 100, loggedReps: 8, prevWeight: 100, prevReps: 0) == .none)
    }

    @Test func zeroLoggedWeight_returnsNone() {
        // 0 weight on a tracksWeight exercise is treated as missing data
        #expect(classifySetProgress(loggedWeight: 0, loggedReps: 8, prevWeight: 100, prevReps: 8) == .none)
    }

    @Test func negativeWeight_returnsNone() {
        #expect(classifySetProgress(loggedWeight: -10, loggedReps: 8, prevWeight: 100, prevReps: 8) == .none)
    }

    // MARK: No meaningful change

    @Test func noChange_returnsNone() {
        #expect(classifySetProgress(loggedWeight: 100, loggedReps: 8, prevWeight: 100, prevReps: 8) == .none)
    }

    @Test func tinyWeightChange_belowThreshold_returnsNone() {
        // +2.5 lb is below the 5 lb threshold
        #expect(classifySetProgress(loggedWeight: 102.5, loggedReps: 8, prevWeight: 100, prevReps: 8) == .none)
    }

    @Test func singleRepChange_belowThreshold_returnsNone() {
        // +1 rep is below the 2-rep threshold — treated as noise
        #expect(classifySetProgress(loggedWeight: 100, loggedReps: 9, prevWeight: 100, prevReps: 8) == .none)
    }

    // MARK: Single-axis: weight only

    @Test func weightOnlyIncrease_returnsPositive() {
        #expect(classifySetProgress(loggedWeight: 110, loggedReps: 8, prevWeight: 100, prevReps: 8)
            == .positive(primary: "10 lb", secondary: nil))
    }

    @Test func weightOnlyDecrease_returnsNegative() {
        #expect(classifySetProgress(loggedWeight: 90, loggedReps: 8, prevWeight: 100, prevReps: 8)
            == .negative(primary: "10 lb", secondary: nil))
    }

    // MARK: Single-axis: reps only

    @Test func repsOnlyIncrease_returnsPositive() {
        // +2 reps meets the threshold
        #expect(classifySetProgress(loggedWeight: 100, loggedReps: 10, prevWeight: 100, prevReps: 8)
            == .positive(primary: "2 reps", secondary: nil))
    }

    @Test func repsOnlyDecrease_returnsNegative() {
        #expect(classifySetProgress(loggedWeight: 100, loggedReps: 6, prevWeight: 100, prevReps: 8)
            == .negative(primary: "2 reps", secondary: nil))
    }

    // MARK: Same-direction changes

    @Test func bothIncrease_returnsPositive_withSecondary() {
        let result = classifySetProgress(loggedWeight: 110, loggedReps: 10, prevWeight: 100, prevReps: 8)
        #expect(result == .positive(primary: "10 lb", secondary: "2 reps"))
    }

    @Test func bothDecrease_returnsNegative_withSecondary() {
        let result = classifySetProgress(loggedWeight: 90, loggedReps: 6, prevWeight: 100, prevReps: 8)
        #expect(result == .negative(primary: "10 lb", secondary: "2 reps"))
    }

    // MARK: Secondary shown in displayText

    @Test func positiveWithSecondary_displayTextIncludesSecondary() {
        let state = ProgressFeedbackState.positive(primary: "10 lb", secondary: "2 reps")
        #expect(state.displayText == "↑ 10 lb · 2 reps")
    }

    @Test func negativeWithSecondary_displayTextIncludesSecondary() {
        let state = ProgressFeedbackState.negative(primary: "10 lb", secondary: "2 reps")
        #expect(state.displayText == "↓ 10 lb · 2 reps")
    }

    @Test func positiveNoSecondary_displayTextArrowOnly() {
        let state = ProgressFeedbackState.positive(primary: "5 lb", secondary: nil)
        #expect(state.displayText == "↑ 5 lb")
    }

    // MARK: Opposite-direction changes → no signal (ambiguous, suppress)

    @Test func heavyWeightDrop_bigRepIncrease_returnsNone() {
        // 90 x 6 -> 45 x 15: can't judge improvement, show nothing
        #expect(classifySetProgress(loggedWeight: 45, loggedReps: 15, prevWeight: 90, prevReps: 6) == .none)
    }

    @Test func weightIncrease_repsDrop_returnsNone() {
        // 135 x 8 -> 155 x 6: can't judge improvement, show nothing
        #expect(classifySetProgress(loggedWeight: 155, loggedReps: 6, prevWeight: 135, prevReps: 8) == .none)
    }

    // MARK: One meaningful axis + insignificant opposite (threshold = 2 reps)

    @Test func meaningfulWeightDrop_insignificantRepGain_returnsNegative() {
        // 100 x 8 -> 80 x 9: -20 lb meaningful, +1 rep below threshold → weight-driven negative
        let result = classifySetProgress(loggedWeight: 80, loggedReps: 9, prevWeight: 100, prevReps: 8)
        #expect(result == .negative(primary: "20 lb", secondary: nil))
    }

    @Test func insignificantWeightIncrease_meaningfulRepsGain_returnsPositive() {
        // 100 x 8 -> 102.5 x 12: +2.5 lb below threshold, +4 reps meaningful
        let result = classifySetProgress(loggedWeight: 102.5, loggedReps: 12, prevWeight: 100, prevReps: 8)
        #expect(result == .positive(primary: "4 reps", secondary: nil))
    }

    @Test func meaningfulWeightIncrease_singleRepDrop_returnsPositive() {
        // 135 x 8 -> 155 x 7: +20 lb meaningful, -1 rep below threshold → weight-driven positive (not mixed)
        let result = classifySetProgress(loggedWeight: 155, loggedReps: 7, prevWeight: 135, prevReps: 8)
        #expect(result == .positive(primary: "20 lb", secondary: nil))
    }

}
