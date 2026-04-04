// iOS 26+ only. No #available guards.

import Foundation
import SwiftData

@Model
final class RoutineTemplate {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .cascade, inverse: \RoutineEntry.routineTemplate) var entries: [RoutineEntry] = []
    var createdAt: Date = Date.now
    var lastUsedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        entries: [RoutineEntry] = [],
        createdAt: Date = .now,
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.entries = entries
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}
