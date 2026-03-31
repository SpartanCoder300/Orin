// iOS 26+ only. No #available guards.

import SwiftUI

struct SummaryPRBadge: View {
    let estimatedOneRepMax: Double
    let weight: Double
    let reps: Int
    let formatWeight: (Double) -> String

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("PR")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.OrinAmber)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.OrinAmber.opacity(0.15), in: Capsule())
            Text("\(formatWeight(estimatedOneRepMax)) e1RM")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.OrinGold)
            Text("\(formatWeight(weight)) × \(reps)")
                .font(.caption2)
                .foregroundStyle(Color.OrinAmber.opacity(0.72))
        }
    }
}

// MARK: - Preview

#Preview {
    SummaryPRBadge(estimatedOneRepMax: 216, weight: 185, reps: 5, formatWeight: { w in
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    })
    .padding()
    .preferredColorScheme(.dark)
}
