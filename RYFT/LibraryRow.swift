// iOS 26+ only. No #available guards.

import SwiftUI

struct LibraryRow: View {
    let exercise: ExerciseDefinition
    let matchRanges: [Range<String.Index>]
    let accentColor: Color
    let onTap: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    HighlightedText(
                        text: exercise.name,
                        ranges: matchRanges,
                        highlightColor: accentColor
                    )
                    .font(Typography.body)

                    if !exercise.muscleGroups.isEmpty {
                        Text(exercise.muscleGroups.prefix(2).joined(separator: " · "))
                            .font(Typography.caption)
                            .foregroundStyle(Color.textFaint)
                    }
                }

                Spacer()

                if exercise.isTimed {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textFaint)
                }

                if exercise.isEdited && !exercise.isCustom {
                    Text("Edited")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textFaint)
                        .textCase(.uppercase)
                        .tracking(0.4)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }

                if exercise.isCustom {
                    Text("Custom")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(accentColor)
                        .textCase(.uppercase)
                        .tracking(0.4)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Exercise", systemImage: "pencil")
            }
        }
    }
}
