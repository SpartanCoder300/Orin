// iOS 26+ only. No #available guards.

import Foundation
import SwiftData

/// Computes frecency scores for exercise names based on historical usage.
/// score = (1 / (daysSinceLastUse + 1)) * log(timesUsed + 1)
@ModelActor
actor ExerciseFrecencyActor {

    /// Returns a dictionary mapping exercise name → frecency score.
    /// Only exercises that appear in at least one completed session are scored.
    func scores() throws -> [String: Double] {
        let snapshots = try modelContext.fetch(FetchDescriptor<ExerciseSnapshot>())

        // Group by exercise name, collecting last-used dates and total usage counts.
        struct Usage {
            var count: Int = 0
            var lastUsed: Date = .distantPast
        }

        var usageMap: [String: Usage] = [:]

        for snapshot in snapshots {
            let sessionDate = snapshot.workoutSession?.completedAt
                           ?? snapshot.workoutSession?.startedAt
                           ?? .distantPast
            let name = snapshot.exerciseName
            var u = usageMap[name, default: Usage()]
            u.count += 1
            if sessionDate > u.lastUsed { u.lastUsed = sessionDate }
            usageMap[name] = u
        }

        let now = Date.now
        var result: [String: Double] = [:]
        for (name, usage) in usageMap {
            let days = now.timeIntervalSince(usage.lastUsed) / 86_400
            let recency = 1.0 / (days + 1)
            let frequency = log(Double(usage.count) + 1)
            result[name] = recency * frequency
        }
        return result
    }
}
