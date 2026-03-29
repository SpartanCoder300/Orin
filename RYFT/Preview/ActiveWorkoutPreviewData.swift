// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

@MainActor
enum ActiveWorkoutPreviewData {
    static func makeViewModel(
        allLogged: Bool = false,
        restTimer: (duration: TimeInterval, elapsed: TimeInterval)? = nil
    ) -> ActiveWorkoutViewModel {
        let vm = ActiveWorkoutViewModel(
            modelContext: PersistenceController.previewContainer.mainContext,
            pendingRoutineID: nil
        )

        let sets: (String, String) -> [ActiveWorkoutViewModel.DraftSet] = { weight, reps in
            (0..<3).map { _ in
                var set = ActiveWorkoutViewModel.DraftSet()
                set.weightText = weight
                set.repsText = reps
                set.isLogged = allLogged
                return set
            }
        }

        vm.draftExercises = [
            ActiveWorkoutViewModel.DraftExercise(
                exerciseName: "Bench Press",
                equipmentType: "Barbell",
                weightIncrement: 5,
                sets: sets("135", "8")
            ),
            ActiveWorkoutViewModel.DraftExercise(
                exerciseName: "Squat",
                equipmentType: "Barbell",
                weightIncrement: 5,
                sets: sets("225", "5")
            ),
            ActiveWorkoutViewModel.DraftExercise(
                exerciseName: "Bench Press",
                equipmentType: "Barbell",
                weightIncrement: 5,
                sets: sets("135", "8")
            ),
            ActiveWorkoutViewModel.DraftExercise(
                exerciseName: "Squat",
                equipmentType: "Barbell",
                weightIncrement: 5,
                sets: sets("225", "5")
            ),
        ]

        if let restTimer {
            vm.restTimer.simulateInProgress(
                totalDuration: restTimer.duration,
                elapsed: restTimer.elapsed
            )
        }

        return vm
    }

    static var emptyViewModel: ActiveWorkoutViewModel {
        ActiveWorkoutViewModel(
            modelContext: PersistenceController.previewContainer.mainContext,
            pendingRoutineID: nil
        )
    }
}

extension View {
    func activeWorkoutPreviewEnvironments() -> some View {
        self
            .environment(AppState())
            .environment(MeshEngine())
            .environment(\.ryftTheme, .midnight)
            .environment(\.ryftCardMaterial, .regularMaterial)
            .modelContainer(PersistenceController.previewContainer)
    }
}
