// iOS 26+ only. No #available guards.

import SwiftUI

struct SummaryPRBadge: View {
    let weight: Double
    let reps: Int
    let formatWeight: (Double) -> String

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("PR")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.ryftAmber)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.ryftAmber.opacity(0.15), in: Capsule())
            Text("\(formatWeight(weight)) × \(reps)")
                .font(.caption2)
                .foregroundStyle(Color.ryftAmber.opacity(0.7))
        }
    }
}

// MARK: - Preview

#Preview {
    SummaryPRBadge(weight: 185, reps: 5, formatWeight: { w in
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    })
    .padding()
    .preferredColorScheme(.dark)
}
