// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

@MainActor
enum ExerciseEditorPreviewData {
    /// A simple custom exercise for the "new" preview (insert into container yourself).
    static func newCustomExercise() -> ExerciseDefinition {
        ExerciseDefinition(
            name: "",
            muscleGroups: [],
            equipmentType: "Barbell",
            isCustom: true
        )
    }

    /// A seeded exercise with non-default advanced values to test auto-expand.
    static func editableExercise() -> ExerciseDefinition {
        ExerciseDefinition(
            name: "Barbell Bench Press",
            muscleGroups: ["Chest", "Triceps"],
            equipmentType: "Barbell",
            isCustom: false,
            weightIncrement: 2.5,
            startingWeight: 45,
            loadTrackingMode: .externalWeight,
            isTimed: false
        )
    }

    /// A timed bodyweight exercise to test advanced auto-expand with .none load tracking.
    static func timedExercise() -> ExerciseDefinition {
        ExerciseDefinition(
            name: "Plank",
            muscleGroups: ["Core"],
            equipmentType: "Bodyweight",
            isCustom: true,
            loadTrackingMode: .none,
            isTimed: true
        )
    }
}

extension View {
    func exerciseEditorPreviewEnvironments() -> some View {
        self
            .environment(AppState())
            .environment(\.OrinTheme, .midnight)
            .environment(\.OrinCardMaterial, .regularMaterial)
            .modelContainer(PersistenceController.previewContainer)
    }
}
