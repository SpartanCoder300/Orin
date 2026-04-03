// iOS 26+ only. No #available guards.

import SwiftUI

struct LibraryRootView: View {
    @Environment(\.OrinTheme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(theme.accentColor.opacity(0.6))
            VStack(spacing: 4) {
                Text("Library")
                    .font(.headline)
                Text("Routines, exercises, and plans coming soon.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground()
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        LibraryRootView()
    }
    .environment(AppState())
    .preferredColorScheme(.dark)
}
