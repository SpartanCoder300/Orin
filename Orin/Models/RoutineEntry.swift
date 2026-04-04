// iOS 26+ only. No #available guards.

import Foundation
import SwiftData

@Model
final class RoutineEntry {
    var id: UUID = UUID()
    var exerciseDefinition: ExerciseDefinition?
    var order: Int = 0
    var targetSets: Int = 3
    var targetRepsMin: Int = 8
    var targetRepsMax: Int = 12
    var restSeconds: Int = 90
    var routineTemplate: RoutineTemplate?

    init(
        id: UUID = UUID(),
        exerciseDefinition: ExerciseDefinition? = nil,
        order: Int,
        targetSets: Int,
        targetRepsMin: Int,
        targetRepsMax: Int,
        restSeconds: Int,
        routineTemplate: RoutineTemplate? = nil
    ) {
        self.id = id
        self.exerciseDefinition = exerciseDefinition
        self.order = order
        self.targetSets = targetSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.restSeconds = restSeconds
        self.routineTemplate = routineTemplate
    }
}
