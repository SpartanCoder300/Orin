// iOS 26+ only. No #available guards.

import Charts
import SwiftUI
import SwiftData

struct ExerciseHistoryChart: View {
    /// Snapshots sorted newest-first. The chart shows the oldest 12 in chronological order.
    let snapshots: [ExerciseSnapshot]

    private struct DataPoint: Identifiable {
        let id: UUID
        let date: Date
        let maxWeight: Double
        let hasPR: Bool
    }

    private var points: [DataPoint] {
        Array(snapshots.prefix(12))
            .reversed()
            .compactMap { snap in
                guard let date = snap.workoutSession?.completedAt else { return nil }
                let working = snap.sets.filter { $0.setType != .warmup && $0.weight > 0 && $0.reps > 0 }
                guard let best = working.max(by: {
                    ExerciseDefinition.estimatedOneRepMax(weight: $0.weight, reps: $0.reps) <
                    ExerciseDefinition.estimatedOneRepMax(weight: $1.weight, reps: $1.reps)
                }) else { return nil }
                let e1rm = ExerciseDefinition.estimatedOneRepMax(weight: best.weight, reps: best.reps)
                guard e1rm > 0 else { return nil }
                return DataPoint(
                    id: snap.id,
                    date: date,
                    maxWeight: e1rm,
                    hasPR: snap.sets.contains { $0.isPersonalRecord }
                )
            }
    }

    @State private var selectedDate: Date?

    private var yDomain: ClosedRange<Double> {
        let values = points.map(\.maxWeight)
        guard let lo = values.min(), let hi = values.max(), lo < hi else { return 0...100 }
        return (lo * 0.92)...(hi * 1.08)
    }

    private var selectedPoint: DataPoint? {
        guard let date = selectedDate else { return nil }
        return points.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    var body: some View {
        if points.count >= 2 {
            Chart(points) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("e1RM", point.maxWeight)
                )
                .foregroundStyle(Color.accentColor.opacity(0.5))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("e1RM", point.maxWeight)
                )
                .foregroundStyle(point.hasPR ? Color.accentColor : .secondary)
                .symbolSize(point.hasPR ? 72 : 36)
                .annotation(position: .top, spacing: 4) {
                    if point.hasPR || point.id == points.last?.id {
                        Text(formatWeight(point.maxWeight))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(point.hasPR ? Color.accentColor : .secondary)
                    }
                }

                if let sel = selectedPoint, sel.id == point.id {
                    RuleMark(x: .value("Selected", sel.date, unit: .day))
                        .foregroundStyle(.secondary.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .annotation(
                            position: .top,
                            spacing: 6,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                        ) {
                            selectionTooltip(sel)
                        }
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartYScale(domain: yDomain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine()
                        .foregroundStyle(.quaternary)
                    AxisValueLabel {
                        if let w = value.as(Double.self) {
                            Text(w.truncatingRemainder(dividingBy: 1) == 0
                                 ? "\(Int(w))" : String(format: "%.1f", w))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 150)
        }
    }

    @ViewBuilder
    private func selectionTooltip(_ point: DataPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(point.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(formatWeight(point.maxWeight))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
            if point.hasPR {
                Text("PR")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func formatWeight(_ value: Double) -> String {
        let v = value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))" : String(format: "%.1f", value)
        return "\(v) lbs"
    }
}

// MARK: - Preview

#Preview {
    ExerciseHistoryChart(snapshots: HistoryRootPreviewData.exerciseHistorySnapshots)
        .padding()
        .modelContainer(HistoryRootPreviewData.exerciseHistoryContainer)
        .preferredColorScheme(.dark)
}
