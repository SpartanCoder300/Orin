// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

struct ProgressRootView: View {
    var body: some View {
        // ── Future: analytics + insights sections slot in above history ───────
        HistoryRootView()
    }
}

#Preview {
    NavigationStack {
        ProgressRootView()
    }
    .environment(AppState())
    .modelContainer(HistoryRootPreviewData.populatedContainer)
}
