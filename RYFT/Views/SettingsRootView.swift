// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

struct SettingsRootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.ryftTheme) private var theme
    @Environment(\.ryftCardMaterial) private var cardMaterial
    @State private var isShowingResetExercisesConfirm = false

    var body: some View {
        List {
            // ── Appearance ─────────────────────────────────────────────
            Section {
                ForEach(AccentTheme.allCases) { t in
                    ThemeRow(
                        theme: t,
                        isSelected: appState.accentTheme == t,
                        accentColor: theme.accentColor
                    ) {
                        appState.accentTheme = t
                    }
                    .listRowBackground(Rectangle().fill(cardMaterial))
                }
            } header: {
                Text("Theme")
            }

            // ── Exercise Library ───────────────────────────────────────
            Section {
                Button(role: .destructive) {
                    isShowingResetExercisesConfirm = true
                } label: {
                    LabeledContent("Reset Built-In Exercises") {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .foregroundStyle(Color.ryftRed)
                    }
                }
                .listRowBackground(Rectangle().fill(cardMaterial))
            } footer: {
                Text("Restores all built-in exercises to their default names, equipment, type, increment, and starting weight. Custom exercises are not changed.")
            }

            // ── About ──────────────────────────────────────────────────
            Section {
                LabeledContent("Version", value: "1.0")
                    .listRowBackground(Rectangle().fill(cardMaterial))
            } header: {
                Text("About")
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Settings")
        .themedBackground()
        .alert("Reset Built-In Exercises?", isPresented: $isShowingResetExercisesConfirm) {
            Button("Reset", role: .destructive) {
                ExerciseSeeder.resetBuiltInExercises(in: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This restores all built-in exercises to the app defaults. Custom exercises will stay as they are.")
        }
    }
}

// MARK: - Theme Row

private struct ThemeRow: View {
    let theme: AccentTheme
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(theme.backgroundColor)
                    Circle()
                        .fill(theme.accentColor)
                        .padding(7)
                }
                .frame(width: 32, height: 32)
                .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(Typography.body)
                        .foregroundStyle(Color.textPrimary)
                    if theme.isPro {
                        Text("Pro")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.ryftAmber)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SettingsRootView()
    }
    .environment(AppState())
}
