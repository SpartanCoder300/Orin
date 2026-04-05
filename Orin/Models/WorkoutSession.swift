// iOS 26+ only. No #available guards.

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var startedAt: Date?
    var completedAt: Date?
    var routineTemplateId: UUID?
    var notes: String?
    // CloudKit requires to-many relationships to be optional at the CoreData layer.
    // Public `exercises` computed wrapper preserves the non-optional API so no call sites change.
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSnapshot.workoutSession) var _exercises: [ExerciseSnapshot]?
    var exercises: [ExerciseSnapshot] {
        get { _exercises ?? [] }
        set { _exercises = newValue }
    }

    init(
        id: UUID = UUID(),
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        routineTemplateId: UUID? = nil,
        notes: String? = nil,
        exercises: [ExerciseSnapshot] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.routineTemplateId = routineTemplateId
        self.notes = notes
        self._exercises = exercises
    }
}
