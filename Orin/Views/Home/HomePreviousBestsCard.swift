// iOS 26+ only. No #available guards.

import SwiftUI

struct HomePreviousBestsCard: View {
    let vm: ActiveWorkoutViewModel
    let onExerciseTap: (_ name: String, _ lineageID: UUID?) -> Void

    private var exercisesWithHistory: [(ActiveWorkoutViewModel.DraftExercise, [ActiveWorkoutViewModel.PreviousSet])] {
        vm.draftExercises.compactMap { ex in
            let sets = ex.previousSets.filter { $0.weight > 0 || $0.reps > 0 }
            guard !sets.isEmpty else { return nil }
            return (ex, sets)
        }
    }

    var body: some View {
        if !exercisesWithHistory.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Last Time")

                VStack(spacing: 0) {
                    let items = exercisesWithHistory
                    ForEach(items.indices, id: \.self) { idx in
                        exerciseRow(exercise: items[idx].0, sets: items[idx].1)
                        if idx < items.count - 1 {
                            Divider()
                                .opacity(0.1)
                                .padding(.leading, Spacing.md)
                        }
                    }
                }
                .cardSurface(border: true)
            }
        }
    }

    @ViewBuilder
    private func exerciseRow(exercise: ActiveWorkoutViewModel.DraftExercise, sets: [ActiveWorkoutViewModel.PreviousSet]) -> some View {
        Button {
            onExerciseTap(exercise.exerciseName, exercise.exerciseLineageID)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.exerciseName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(Array(sets.enumerated()), id: \.offset) { _, set in
                            Text(setLabel(set))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.white.opacity(0.08), in: Capsule())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 2)
    }

    private func setLabel(_ set: ActiveWorkoutViewModel.PreviousSet) -> String {
        let w = set.weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(set.weight))" : String(format: "%.1f", set.weight)
        if set.weight > 0 && set.reps > 0 { return "\(w) × \(set.reps)" }
        if set.reps > 0                   { return "\(set.reps) reps" }
        return "\(w) lbs"
    }
}
