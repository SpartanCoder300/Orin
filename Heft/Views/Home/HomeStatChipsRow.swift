// iOS 26+ only. No #available guards.

import SwiftUI

struct HomeStatChipsRow: View {
    let stats: HomeStatsViewModel
    @Environment(\.heftTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.sm) {
            StatChip(label: "Day Streak", value: stats.streakLabel,
                     icon: "flame.fill", iconColor: theme.accentColor)
            StatChip(label: "This Week", value: stats.thisWeekLabel,
                     icon: "figure.strengthtraining.traditional", iconColor: theme.accentColor)
            StatChip(label: "PRs", value: stats.prCountLabel,
                     icon: "trophy.fill", iconColor: Color.heftAmber, valueColor: Color.heftAmber)
        }
    }
}

// MARK: - Stat Chip

struct StatChip: View {
    let label: String
    let value: String
    let icon: String
    var iconColor: Color = Color.textPrimary
    var valueColor: Color = Color.textPrimary

    var body: some View {
        ZStack(alignment: .leading) {
            // ── Watermark ────────────────────────────────────────────
            Image(systemName: icon)
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(iconColor.opacity(0.09))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 10, y: 10)

            // ── Content ──────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                    .monospacedDigit()
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textFaint)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                        .fill(iconColor.opacity(0.06))
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
    }
}

#Preview {
    @Previewable @State var stats = HomeStatsViewModel()
    HomeStatChipsRow(stats: stats)
        .padding()
        .preferredColorScheme(.dark)
}
