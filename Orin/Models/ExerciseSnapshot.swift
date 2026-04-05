// iOS 26+ only. No #available guards.

import Foundation
import SwiftData

@Model
final class ExerciseSnapshot {
    var id: UUID = UUID()
    var exerciseName: String = ""
    var exerciseLineageID: UUID?
    var equipmentType: String?
    var weightIncrement: Double?
    var startingWeight: Double?
    var loadTrackingModeRaw: String?
    var isTimed: Bool = false
    var restSeconds: Int?
    var draftStateJSON: String?
    var order: Int = 0
    // CloudKit requires to-many relationships to be optional at the CoreData layer.
    // Public `sets` computed wrapper preserves the non-optional API so no call sites change.
    @Relationship(deleteRule: .cascade, inverse: \SetRecord.exerciseSnapshot) var _sets: [SetRecord]?
    var sets: [SetRecord] {
        get { _sets ?? [] }
        set { _sets = newValue }
    }
    var workoutSession: WorkoutSession?

    var loadTrackingMode: LoadTrackingMode {
        get { LoadTrackingMode(rawValue: loadTrackingModeRaw ?? "") ?? .externalWeight }
        set { loadTrackingModeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        exerciseName: String,
        exerciseLineageID: UUID? = nil,
        equipmentType: String? = nil,
        weightIncrement: Double? = nil,
        startingWeight: Double? = nil,
        loadTrackingModeRaw: String? = nil,
        isTimed: Bool = false,
        restSeconds: Int? = nil,
        draftStateJSON: String? = nil,
        order: Int,
        sets: [SetRecord] = [],
        workoutSession: WorkoutSession? = nil
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.exerciseLineageID = exerciseLineageID
        self.equipmentType = equipmentType
        self.weightIncrement = weightIncrement
        self.startingWeight = startingWeight
        self.loadTrackingModeRaw = loadTrackingModeRaw
        self.isTimed = isTimed
        self.restSeconds = restSeconds
        self.draftStateJSON = draftStateJSON
        self.order = order
        self._sets = sets
        self.workoutSession = workoutSession
    }
}
