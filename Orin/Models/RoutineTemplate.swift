// iOS 26+ only. No #available guards.

import Foundation
import SwiftData

@Model
final class RoutineTemplate {
    var id: UUID = UUID()
    var name: String = ""
    // CloudKit requires to-many relationships to be optional at the CoreData layer.
    // Public `entries` computed wrapper preserves the non-optional API so no call sites change.
    @Relationship(deleteRule: .cascade, inverse: \RoutineEntry.routineTemplate) var _entries: [RoutineEntry]?
    var entries: [RoutineEntry] {
        get { _entries ?? [] }
        set { _entries = newValue }
    }
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
        self._entries = entries
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}
