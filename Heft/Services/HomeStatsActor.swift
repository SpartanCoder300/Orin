// iOS 26+ only. No #available guards.

import Foundation
import SwiftData

@ModelActor
actor HomeStatsActor {

    /// Number of completed sessions in the current calendar week.
    func sessionCountThisWeek() -> Int {
        let descriptor = FetchDescriptor<WorkoutSession>()
        guard let sessions = try? modelContext.fetch(descriptor) else { return 0 }
        guard let weekStart = Self.currentWeekStart() else { return 0 }
        return sessions.filter { ($0.completedAt ?? .distantPast) >= weekStart }.count
    }

    /// Number of personal records logged this calendar week.
    func prCountThisWeek() -> Int {
        guard let weekStart = Self.currentWeekStart() else { return 0 }
        let descriptor = FetchDescriptor<SetRecord>(
            predicate: #Predicate<SetRecord> { record in
                record.isPersonalRecord && record.loggedAt >= weekStart
            }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Consecutive days ending today on which at least one session was completed.
    func currentStreak() -> Int {
        let descriptor = FetchDescriptor<WorkoutSession>()
        guard let sessions = try? modelContext.fetch(descriptor) else { return 0 }

        let calendar = Calendar.current
        let completedDays = Set(
            sessions
                .compactMap { $0.completedAt }
                .map { calendar.startOfDay(for: $0) }
        )

        var streak = 0
        var day = calendar.startOfDay(for: .now)
        while completedDays.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    private static func currentWeekStart() -> Date? {
        let calendar = Calendar.current
        return calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        )
    }
}
