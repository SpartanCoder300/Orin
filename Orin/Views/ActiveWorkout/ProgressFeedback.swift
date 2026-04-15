// iOS 26+ only. No #available guards.

import SwiftUI

// MARK: - Thresholds

/// Tune significance thresholds here. A change must meet or exceed these values
/// to be considered meaningful when classifying progress feedback.
enum ProgressThreshold {
    static let weight: Double = 5.0
    /// 2 reps: a single-rep delta is noise; two or more is a real change.
    static let reps: Int = 2
    static let duration: Double = 5.0
}

// MARK: - State

enum ProgressFeedbackState: Equatable {
    case none
    case positive(primary: String, secondary: String?)
    case negative(primary: String, secondary: String?)
    // No mixed case: opposite-direction changes are ambiguous and show no signal.

    var isVisible: Bool {
        if case .none = self { return false }
        return true
    }

    var displayText: String {
        switch self {
        case .none:                     return ""
        case .positive(let p, let s):  return s.map { "↑ \(p) · \($0)" } ?? "↑ \(p)"
        case .negative(let p, let s):  return s.map { "↓ \(p) · \($0)" } ?? "↓ \(p)"
        }
    }

    var color: Color {
        switch self {
        case .none:     return .clear
        case .positive: return Color.OrinGreen
        case .negative: return Color.red.opacity(0.85)
        }
    }
}

// MARK: - Formatting

func formatWeight(_ w: Double) -> String {
    w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
}

// MARK: - Classification

/// Classifies progress between a newly logged set and its previous reference.
/// Returns `.none` for insignificant changes, invalid inputs, or missing data.
/// Does **not** handle the PR-override check — callers should suppress feedback when `isPR`.
func classifySetProgress(
    loggedWeight: Double, loggedReps: Int,
    prevWeight: Double, prevReps: Int
) -> ProgressFeedbackState {
    // Reject nonsensical values; 0 weight on a weight-tracking exercise is treated as missing data
    guard loggedWeight > 0, prevWeight >= 0, loggedReps > 0, prevReps > 0 else { return .none }

    let weightDiff = loggedWeight - prevWeight
    let repsDiff   = loggedReps  - prevReps

    let weightMeaningful = abs(weightDiff) >= ProgressThreshold.weight
    let repsMeaningful   = abs(repsDiff)   >= ProgressThreshold.reps

    guard weightMeaningful || repsMeaningful else { return .none }

    // Single-axis: only weight meaningful
    if weightMeaningful && !repsMeaningful {
        let label = "\(formatWeight(abs(weightDiff))) lb"
        return weightDiff > 0
            ? .positive(primary: label, secondary: nil)
            : .negative(primary: label, secondary: nil)
    }

    // Single-axis: only reps meaningful
    if repsMeaningful && !weightMeaningful {
        let absReps = abs(repsDiff)
        let label = "\(absReps) \(absReps == 1 ? "rep" : "reps")"
        return repsDiff > 0
            ? .positive(primary: label, secondary: nil)
            : .negative(primary: label, secondary: nil)
    }

    // Both axes meaningful — same direction?
    if (weightDiff > 0) == (repsDiff > 0) {
        let wLabel  = "\(formatWeight(abs(weightDiff))) lb"
        let rAbs    = abs(repsDiff)
        let rLabel  = "\(rAbs) \(rAbs == 1 ? "rep" : "reps")"
        return weightDiff > 0
            ? .positive(primary: wLabel, secondary: rLabel)
            : .negative(primary: wLabel, secondary: rLabel)
    }

    // Both meaningful but opposite directions — ambiguous, show nothing
    return .none
}
