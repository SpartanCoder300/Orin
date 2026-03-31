// iOS 26+ only. No #available guards.

import Foundation
import SwiftData

@MainActor
enum HomePreviewData {
    static let featured: Scenario = makeScenario(mode: .featured)
    static let routinesOnly: Scenario = makeScenario(mode: .routinesOnly)
    static let empty: Scenario = makeScenario(mode: .empty)

    static var container: ModelContainer { featured.container }
    static var routines: [RoutineTemplate] { featured.routines }
    static var avgMinutes: [UUID: Int] { featured.avgMinutes }
    static var featuredSuggestion: FeaturedRoutineSuggestion? { featured.featuredSuggestion }
    static var recentSessions: [WorkoutSession] { featured.recentSessions }

    static var featuredRootContainer: ModelContainer { featured.container }
    static var routinesOnlyRootContainer: ModelContainer { routinesOnly.container }
    static var emptyRootContainer: ModelContainer { empty.container }

    private enum Mode {
        case featured
        case routinesOnly
        case empty
    }

    struct Scenario {
        let container: ModelContainer
        let routines: [RoutineTemplate]
        let avgMinutes: [UUID: Int]
        let featuredSuggestion: FeaturedRoutineSuggestion?
        let recentSessions: [WorkoutSession]
    }

    private static func makeScenario(mode: Mode) -> Scenario {
        let configuration = ModelConfiguration(
            "HomePreview",
            schema: PersistenceController.schema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )

        let container = try! ModelContainer(for: PersistenceController.schema, configurations: [configuration])
        let context = container.mainContext

        guard mode != .empty else {
            return Scenario(
                container: container,
                routines: [],
                avgMinutes: [:],
                featuredSuggestion: nil,
                recentSessions: []
            )
        }

        let bench = ExerciseDefinition(name: "Bench Press", muscleGroups: ["Chest", "Triceps"], equipmentType: "Barbell", weightIncrement: 2.5, isTimed: false)
        let row = ExerciseDefinition(name: "Cable Row", muscleGroups: ["Back", "Biceps"], equipmentType: "Cable", weightIncrement: 5, isTimed: false)
        let squat = ExerciseDefinition(name: "Back Squat", muscleGroups: ["Legs", "Core"], equipmentType: "Barbell", weightIncrement: 5, isTimed: false)
        let rdl = ExerciseDefinition(name: "Romanian Deadlift", muscleGroups: ["Legs", "Back"], equipmentType: "Barbell", weightIncrement: 5, isTimed: false)
        let exercises = [bench, row, squat, rdl]
        exercises.forEach { context.insert($0) }

        let upper = RoutineTemplate(name: "Upper A")
        let lower = RoutineTemplate(name: "Lower A")

        let upperEntries: [RoutineEntry] = [
            RoutineEntry(exerciseDefinition: bench, order: 0, targetSets: 4, targetRepsMin: 5, targetRepsMax: 8, restSeconds: 120),
            RoutineEntry(exerciseDefinition: row, order: 1, targetSets: 3, targetRepsMin: 8, targetRepsMax: 12, restSeconds: 90)
        ]
        let lowerEntries: [RoutineEntry] = [
            RoutineEntry(exerciseDefinition: squat, order: 0, targetSets: 4, targetRepsMin: 5, targetRepsMax: 8, restSeconds: 150),
            RoutineEntry(exerciseDefinition: rdl, order: 1, targetSets: 3, targetRepsMin: 6, targetRepsMax: 10, restSeconds: 120)
        ]

        upper.entries = upperEntries
        lower.entries = lowerEntries

        context.insert(upper)
        context.insert(lower)
        upperEntries.forEach { context.insert($0) }
        lowerEntries.forEach { context.insert($0) }

        if mode == .featured {
            addSession(
                to: context,
                daysAgo: 4,
                durationMinutes: 50,
                routine: upper,
                exercises: [bench, row],
                setCounts: [4, 3]
            )
            addSession(
                to: context,
                daysAgo: 8,
                durationMinutes: 48,
                routine: upper,
                exercises: [bench, row],
                setCounts: [4, 3]
            )
            addSession(
                to: context,
                daysAgo: 1,
                durationMinutes: 57,
                routine: lower,
                exercises: [squat, rdl],
                setCounts: [4, 3],
                personalRecord: (exerciseIndex: 0, setIndex: 1)
            )
            addSession(
                to: context,
                daysAgo: 3,
                durationMinutes: 53,
                routine: lower,
                exercises: [squat, rdl],
                setCounts: [4, 3]
            )
        }

        let sessions = try! context.fetch(
            FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        )
        let recentSessions = Array(sessions.filter { $0.completedAt != nil }.prefix(3))

        return Scenario(
            container: container,
            routines: [upper, lower],
            avgMinutes: [upper.id: 49, lower.id: 55],
            featuredSuggestion: mode == .featured
                ? FeaturedRoutineSuggestion(
                    routineID: upper.id,
                    routineName: upper.name,
                    exerciseCount: upper.entries.count,
                    daysSinceLast: 4,
                    avgIntervalDays: 4
                )
                : nil,
            recentSessions: recentSessions
        )
    }

    private static func addSession(
        to context: ModelContext,
        daysAgo: Int,
        durationMinutes: Int,
        routine: RoutineTemplate,
        exercises: [ExerciseDefinition],
        setCounts: [Int],
        personalRecord: (exerciseIndex: Int, setIndex: Int)? = nil
    ) {
        let end = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let start = end.addingTimeInterval(TimeInterval(-durationMinutes * 60))
        let session = WorkoutSession(
            startedAt: start,
            completedAt: end,
            routineTemplateId: routine.id
        )
        context.insert(session)

        for (exerciseIndex, exercise) in exercises.enumerated() {
            let snapshot = ExerciseSnapshot(
                exerciseName: exercise.name,
                order: exerciseIndex,
                workoutSession: session
            )
            context.insert(snapshot)
            session.exercises.append(snapshot)

            for setIndex in 0..<(setCounts[safe: exerciseIndex] ?? 0) {
                let set = SetRecord(
                    weight: Double(95 + (exerciseIndex * 40) + (setIndex * 10)),
                    reps: exercise.isTimed ? 0 : max(4, 8 - setIndex),
                    setType: .normal,
                    loggedAt: start.addingTimeInterval(Double((exerciseIndex * 10 + setIndex) * 60)),
                    isPersonalRecord: personalRecord?.exerciseIndex == exerciseIndex && personalRecord?.setIndex == setIndex,
                    duration: exercise.isTimed ? Double(30 + setIndex * 10) : nil,
                    exerciseSnapshot: snapshot
                )
                context.insert(set)
                snapshot.sets.append(set)
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
