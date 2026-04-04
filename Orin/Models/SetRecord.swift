// iOS 26+ only. No #available guards.

import Foundation
import SwiftData

@Model
final class SetRecord {
    var id: UUID = UUID()
    var weight: Double = 0
    var reps: Int = 0
    var setType: SetType = SetType.normal
    var loggedAt: Date = Date.now
    var isPersonalRecord: Bool = false
    var duration: Double?
    var exerciseSnapshot: ExerciseSnapshot?

    init(
        id: UUID = UUID(),
        weight: Double,
        reps: Int,
        setType: SetType = .normal,
        loggedAt: Date = .now,
        isPersonalRecord: Bool = false,
        duration: Double? = nil,
        exerciseSnapshot: ExerciseSnapshot? = nil
    ) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.setType = setType
        self.loggedAt = loggedAt
        self.isPersonalRecord = isPersonalRecord
        self.duration = duration
        self.exerciseSnapshot = exerciseSnapshot
    }
}
