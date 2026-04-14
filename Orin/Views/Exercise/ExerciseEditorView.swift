// iOS 26+ only. No #available guards.

import SwiftUI
import SwiftData

private let editorEquipmentTypes = ["Barbell", "Dumbbell", "Cable", "Machine", "Kettlebell", "Bodyweight", "Band"]
private let editorMuscleGroups   = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Forearms", "Legs", "Core"]

struct ExerciseEditorView: View {
    /// Pass an existing exercise to edit, or nil to create a new custom one.
    let exercise: ExerciseDefinition?
    var allowsLifecycleActions: Bool = true
    var embedsInNavigationStack: Bool = true
    var showsCancelButton: Bool = true
    var onSave: ((ExerciseDefinition) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.OrinTheme) private var theme

    @Query(sort: \ExerciseDefinition.name) private var allExercises: [ExerciseDefinition]

    // MARK: - Draft state

    @State private var name = ""
    @State private var equipmentType = "Barbell"
    @State private var selectedGroups: [String] = []
    @State private var loadTrackingMode: LoadTrackingMode = .externalWeight
    @State private var isTimed = false
    @State private var weightIncrementText = ""
    @State private var startingWeightText = ""

    // MARK: - UI state

    @FocusState private var nameFieldFocused: Bool
    @State private var showAdvanced = false
    @State private var saveErrorMessage: String? = nil
    @State private var showingArchiveConfirmation = false
    @State private var showingPermanentDeleteConfirmation = false

    // MARK: - Smart defaults tracking

    /// Tracks whether the user has manually touched advanced fields.
    /// Equipment changes only apply defaults when these are false.
    @State private var userEditedLoadTracking = false
    @State private var userEditedIncrement = false
    @State private var userEditedStartingWeight = false
    @State private var userEditedTimed = false

    // MARK: - Edit-mode original snapshot

    @State private var originalName = ""
    @State private var originalEquipment = ""
    @State private var originalGroups: [String] = []
    @State private var originalLoadTracking: LoadTrackingMode = .externalWeight
    @State private var originalIsTimed = false
    @State private var originalIncrementText = ""
    @State private var originalStartingWeightText = ""

    // MARK: - Derived

    private var isNew: Bool { exercise == nil }
    private var canEditName: Bool { exercise?.isCustom ?? true }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var nameError: String? {
        guard canEditName else { return nil }
        // Don't report empty-name as an error — the save button is already disabled for that.
        // Only surface errors that need visible inline feedback.
        guard !trimmedName.isEmpty else { return nil }
        guard !hasActiveDuplicateName else { return "An exercise with this name already exists." }
        if !isNew, archivedMatch != nil {
            return "An archived exercise already uses this name. Restore it instead."
        }
        return nil
    }
    private var weightIncrementError: String? {
        guard loadTrackingMode != .none else { return nil }
        guard !weightIncrementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard parsedNumber(from: weightIncrementText) != nil else { return "Enter a valid number." }
        return nil
    }
    private var startingWeightError: String? {
        guard loadTrackingMode != .none else { return nil }
        guard !startingWeightText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard parsedNumber(from: startingWeightText) != nil else { return "Enter a valid number." }
        return nil
    }
    private var formErrorMessage: String? { nameError ?? weightIncrementError ?? startingWeightError }

    private var isSaveEnabled: Bool {
        guard formErrorMessage == nil else { return false }
        guard !trimmedName.isEmpty else { return false }
        if !isNew { return hasChanges }
        return true
    }

    private var hasChanges: Bool {
        trimmedName != originalName ||
        equipmentType != originalEquipment ||
        selectedGroups != originalGroups ||
        loadTrackingMode != originalLoadTracking ||
        isTimed != originalIsTimed ||
        weightIncrementText != originalIncrementText ||
        startingWeightText != originalStartingWeightText
    }

    private var activeMatch: ExerciseDefinition? {
        guard canEditName else { return nil }
        return allExercises.first { existing in
            guard existing.persistentModelID != exercise?.persistentModelID else { return false }
            guard !existing.isArchived else { return false }
            return existing.name.compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }
    private var archivedMatch: ExerciseDefinition? {
        guard canEditName else { return nil }
        return allExercises.first { existing in
            guard existing.persistentModelID != exercise?.persistentModelID else { return false }
            guard existing.isArchived else { return false }
            return existing.name.compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }
    private var hasActiveDuplicateName: Bool { activeMatch != nil }
    private var canManageLifecycle: Bool { allowsLifecycleActions && (exercise?.isCustom ?? false) }

    // MARK: - Body

    var body: some View {
        navigationContainer {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    nameSection
                    equipmentSection
                    muscleGroupSection
                    advancedSection

                    if let ex = exercise, ex.isEdited, !ex.isCustom {
                        resetSection(ex)
                    }

                    if canManageLifecycle {
                        lifecycleSection
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .workflowContentBackground()
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsCancelButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isSaveEnabled)
                }
            }
        }
        .workflowSheetBackground(enabled: embedsInNavigationStack)
        .onAppear { populateDraft() }
        .task {
            guard isNew else { return }
            try? await Task.sleep(for: .milliseconds(100))
            nameFieldFocused = true
        }
        .alert("Couldn't Save Exercise", isPresented: saveErrorIsPresented) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "Please review your changes and try again.")
        }
        .alert("Archive Exercise?", isPresented: $showingArchiveConfirmation) {
            Button("Archive", role: .destructive) { archiveExercise() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the exercise from your library without deleting any workout history.")
        }
        .alert("Delete Exercise and History?", isPresented: $showingPermanentDeleteConfirmation) {
            Button("Delete", role: .destructive) { permanentlyDeleteExercise() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the exercise definition, its workout history, and any routine references.")
        }
    }

    private var navigationTitle: String {
        if isNew { return "New Exercise" }
        if let ex = exercise, !ex.name.isEmpty { return ex.name }
        return "Edit Exercise"
    }

    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if embedsInNavigationStack {
            NavigationStack { content() }
        } else {
            content()
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TextField("Exercise name", text: $name)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .focused($nameFieldFocused)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { nameFieldFocused = false }
                .disabled(!canEditName)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                        .strokeBorder(nameError != nil ? Color.OrinRed.opacity(0.5) : .white.opacity(0.08), lineWidth: 1)
                }

            if let error = nameError, canEditName {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.OrinRed)
                    .padding(.horizontal, Spacing.xs)
            } else if isNew, archivedMatch != nil {
                Text("Saving will restore the archived exercise and keep its history.")
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)
                    .padding(.horizontal, Spacing.xs)
            } else if let ex = exercise, !ex.isCustom {
                Text("Name cannot be changed for built-in exercises.")
                    .font(.caption)
                    .foregroundStyle(Color.textMuted)
                    .padding(.horizontal, Spacing.xs)
            }
        }
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Equipment")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textMuted)

            FlowLayout(spacing: Spacing.sm) {
                ForEach(editorEquipmentTypes, id: \.self) { item in
                    EquipmentChip(
                        label: item,
                        isSelected: equipmentType == item,
                        accentColor: theme.accentColor
                    ) {
                        withAnimation(.easeInOut(duration: Motion.fast)) {
                            applyEquipmentSelection(item)
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: equipmentType)
        }
    }

    // MARK: - Muscle Group Section

    private var muscleGroupSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Text("Muscle Groups")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textMuted)

                if !selectedGroups.isEmpty {
                    Text("First = primary")
                        .font(.caption2)
                        .foregroundStyle(Color.textFaint)
                }
            }

            FlowLayout(spacing: Spacing.sm) {
                ForEach(editorMuscleGroups, id: \.self) { group in
                    let idx = selectedGroups.firstIndex(of: group)
                    MuscleGroupChip(
                        label: group,
                        isPrimary: idx == 0,
                        isSelected: idx != nil,
                        accentColor: theme.accentColor
                    ) {
                        withAnimation(.easeInOut(duration: Motion.fast)) {
                            toggleMuscleGroup(group)
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: selectedGroups)
        }
    }

    // MARK: - Advanced Options Section

    private var advancedSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: Motion.standard)) {
                    showAdvanced.toggle()
                }
            } label: {
                HStack {
                    Text("Advanced Options")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textMuted)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textFaint)
                        .rotationEffect(.degrees(showAdvanced ? 90 : 0))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showAdvanced {
                advancedContent
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.md)
                    .transition(.asymmetric(
                        insertion: .opacity.animation(.easeIn(duration: 0.18).delay(0.12)),
                        removal: .opacity.animation(.easeOut(duration: Motion.fast))
                    ))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
        .sensoryFeedback(.selection, trigger: showAdvanced)
    }

    @ViewBuilder
    private var advancedContent: some View {
        VStack(spacing: Spacing.md) {
            // Load Tracking
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Load Type")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.textFaint)

                Picker("Load Tracking", selection: Binding(
                    get: { loadTrackingMode },
                    set: { newValue in
                        loadTrackingMode = newValue
                        userEditedLoadTracking = true
                    }
                )) {
                    Text("None").tag(LoadTrackingMode.none)
                    Text("External").tag(LoadTrackingMode.externalWeight)
                    Text("BW + Load").tag(LoadTrackingMode.bodyweightPlusLoad)
                }
                .pickerStyle(.segmented)
            }

            // Weight fields — hidden when load tracking is none
            if loadTrackingMode != .none {
                let defaultIncrement = ExerciseDefinition.defaultIncrement(for: equipmentType)
                let defaultStarting = ExerciseDefinition.defaultStartingWeight(for: equipmentType)

                HStack(spacing: Spacing.sm) {
                    // Increment
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Increment (lbs)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.textFaint)

                        TextField(
                            "\(formatIncrement(defaultIncrement))",
                            text: Binding(
                                get: { weightIncrementText },
                                set: { newValue in
                                    weightIncrementText = newValue
                                    userEditedIncrement = true
                                }
                            )
                        )
                        .keyboardType(.decimalPad)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                                .strokeBorder(weightIncrementError != nil ? Color.OrinRed.opacity(0.5) : .white.opacity(0.08), lineWidth: 1)
                        }
                    }

                    // Starting Weight
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Starting Weight (lbs)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.textFaint)

                        TextField(
                            "\(formatIncrement(defaultStarting))",
                            text: Binding(
                                get: { startingWeightText },
                                set: { newValue in
                                    startingWeightText = newValue
                                    userEditedStartingWeight = true
                                }
                            )
                        )
                        .keyboardType(.decimalPad)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                                .strokeBorder(startingWeightError != nil ? Color.OrinRed.opacity(0.5) : .white.opacity(0.08), lineWidth: 1)
                        }
                    }
                }

                if weightIncrementError != nil || startingWeightError != nil {
                    Text(weightIncrementError ?? startingWeightError ?? "")
                        .font(.caption)
                        .foregroundStyle(Color.OrinRed)
                }
            }

            // Timed toggle
            Toggle(isOn: Binding(
                get: { isTimed },
                set: { newValue in
                    isTimed = newValue
                    userEditedTimed = true
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Timed Exercise")
                        .font(.subheadline)
                        .foregroundStyle(Color.textPrimary)
                    Text("For holds and isometric movements")
                        .font(.caption)
                        .foregroundStyle(Color.textFaint)
                }
            }
            .tint(theme.accentColor)
        }
    }

    // MARK: - Reset Section

    private func resetSection(_ ex: ExerciseDefinition) -> some View {
        Button(role: .destructive) {
            resetToDefault(ex)
        } label: {
            HStack {
                Label("Reset to Default", systemImage: "arrow.uturn.backward")
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.OrinRed)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
    }

    // MARK: - Lifecycle Section

    private var lifecycleSection: some View {
        VStack(spacing: Spacing.sm) {
            Button(role: .destructive) {
                showingArchiveConfirmation = true
            } label: {
                HStack {
                    Label("Archive Exercise", systemImage: "archivebox")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.OrinRed.opacity(0.8))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }

            Button(role: .destructive) {
                showingPermanentDeleteConfirmation = true
            } label: {
                HStack {
                    Label("Delete Exercise and History", systemImage: "trash")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.OrinRed)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    // MARK: - Equipment Smart Defaults

    private func applyEquipmentSelection(_ newEquipment: String) {
        equipmentType = newEquipment

        // Apply smart defaults only for fields the user hasn't manually edited.
        // defaultLoadTracking already handles Bodyweight/Band → .none correctly.
        if !userEditedLoadTracking {
            loadTrackingMode = defaultLoadTracking(for: newEquipment)
        }
        if !userEditedIncrement {
            weightIncrementText = ""
        }
        if !userEditedStartingWeight {
            startingWeightText = ""
        }
    }

    private func defaultLoadTracking(for equipment: String) -> LoadTrackingMode {
        switch equipment {
        case "Bodyweight": return .none
        case "Band": return .none
        default: return .externalWeight
        }
    }

    // MARK: - Muscle Group Toggle

    private func toggleMuscleGroup(_ group: String) {
        if let index = selectedGroups.firstIndex(of: group) {
            selectedGroups.remove(at: index)
        } else {
            selectedGroups.append(group)
        }
    }

    // MARK: - Populate Draft

    private func populateDraft() {
        guard let ex = exercise else { return }
        name = ex.name
        equipmentType = ex.equipmentType.isEmpty ? "Barbell" : ex.equipmentType
        // Preserve muscle group order from the model
        selectedGroups = ex.muscleGroups
        loadTrackingMode = ex.loadTrackingMode
        isTimed = ex.isTimed
        weightIncrementText = ex.weightIncrement.map { formatIncrement($0) } ?? ""
        startingWeightText = ex.startingWeight.map { formatIncrement($0) } ?? ""

        // Snapshot originals for change detection
        originalName = ex.name
        originalEquipment = ex.equipmentType.isEmpty ? "Barbell" : ex.equipmentType
        originalGroups = ex.muscleGroups
        originalLoadTracking = ex.loadTrackingMode
        originalIsTimed = ex.isTimed
        originalIncrementText = weightIncrementText
        originalStartingWeightText = startingWeightText

        // In edit mode, treat all fields as user-edited to prevent equipment changes from overwriting
        userEditedLoadTracking = true
        userEditedIncrement = ex.weightIncrement != nil
        userEditedStartingWeight = ex.startingWeight != nil
        userEditedTimed = true

        // Auto-expand advanced if the exercise has non-default advanced values
        let defaultLoad = defaultLoadTracking(for: equipmentType)
        if ex.loadTrackingMode != defaultLoad
            || ex.weightIncrement != nil
            || ex.startingWeight != nil
            || ex.isTimed {
            showAdvanced = true
        }
    }

    // MARK: - Save

    private func save() {
        guard nameError == nil else {
            saveErrorMessage = nameError
            return
        }
        let increment = validatedOptionalNumber(from: weightIncrementText, fieldName: "Weight Increment")
        let startingWeight = validatedOptionalNumber(from: startingWeightText, fieldName: "Starting Weight")
        guard increment.isValid, startingWeight.isValid else { return }
        let orderedGroups = selectedGroups

        if let ex = exercise {
            let previousName = ex.name
            if ex.isCustom {
                ex.name = trimmedName
                attachHistory(to: ex, matchingLegacyName: previousName)
            }
            ex.equipmentType = equipmentType
            ex.muscleGroups = orderedGroups
            ex.loadTrackingMode = loadTrackingMode
            ex.isTimed = isTimed
            ex.weightIncrement = increment.value
            ex.startingWeight = startingWeight.value
            ex.archivedAt = nil
            if !ex.isCustom {
                let original = ExerciseSeeder.defaultDefinition(named: ex.name)
                let matchesDefault = original.map {
                    $0.equipmentType == equipmentType &&
                    Set($0.muscleGroups) == Set(selectedGroups) &&
                    $0.loadTrackingMode == loadTrackingMode &&
                    $0.isTimed == isTimed &&
                    increment.value == $0.weightIncrement &&
                    startingWeight.value == $0.startingWeight
                } ?? false
                ex.isEdited = !matchesDefault
            }
        } else {
            if let archived = archivedMatch {
                archived.name = trimmedName
                archived.archivedAt = nil
                archived.equipmentType = equipmentType
                archived.muscleGroups = orderedGroups
                archived.loadTrackingMode = loadTrackingMode
                archived.isTimed = isTimed
                archived.weightIncrement = increment.value
                archived.startingWeight = startingWeight.value
                attachHistory(to: archived, matchingLegacyName: trimmedName)
                onSave?(archived)
            } else {
                let newEx = ExerciseDefinition(
                    name: trimmedName,
                    muscleGroups: orderedGroups,
                    equipmentType: equipmentType,
                    isCustom: true,
                    weightIncrement: increment.value,
                    startingWeight: startingWeight.value,
                    loadTrackingMode: loadTrackingMode,
                    isTimed: isTimed
                )
                modelContext.insert(newEx)
                onSave?(newEx)
            }
        }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = "Your changes couldn't be saved. Please try again."
        }
    }

    private func resetToDefault(_ ex: ExerciseDefinition) {
        guard let original = ExerciseSeeder.defaultDefinition(named: ex.name) else { return }
        if !ex.isCustom { ex.name = original.name }
        ex.equipmentType = original.equipmentType
        ex.muscleGroups = original.muscleGroups
        ex.loadTrackingMode = original.loadTrackingMode
        ex.isTimed = original.isTimed
        ex.weightIncrement = original.weightIncrement
        ex.startingWeight = original.startingWeight
        ex.isEdited = false
        try? modelContext.save()

        equipmentType = original.equipmentType
        selectedGroups = original.muscleGroups
        loadTrackingMode = original.loadTrackingMode
        isTimed = original.isTimed
        weightIncrementText = original.weightIncrement.map { formatIncrement($0) } ?? ""
        startingWeightText = original.startingWeight.map { formatIncrement($0) } ?? ""
    }

    // MARK: - Helpers

    private func formatIncrement(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v)
    }

    private func attachHistory(to exercise: ExerciseDefinition, matchingLegacyName legacyName: String? = nil) {
        let snapshots = (try? modelContext.fetch(FetchDescriptor<ExerciseSnapshot>())) ?? []
        let names = Set([exercise.name, legacyName].compactMap { $0 })
        for snapshot in snapshots {
            if snapshot.exerciseLineageID == exercise.id || (snapshot.exerciseLineageID == nil && names.contains(snapshot.exerciseName)) {
                snapshot.exerciseLineageID = exercise.id
            }
        }
    }

    private func archiveExercise() {
        guard let exercise, canManageLifecycle else { return }
        exercise.archivedAt = .now
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = "This exercise couldn't be archived. Please try again."
        }
    }

    private func permanentlyDeleteExercise() {
        guard let exercise, canManageLifecycle else { return }
        let snapshots = (try? modelContext.fetch(FetchDescriptor<ExerciseSnapshot>())) ?? []
        for snapshot in snapshots where snapshot.exerciseLineageID == exercise.id
            || (snapshot.exerciseLineageID == nil && snapshot.exerciseName == exercise.name) {
            modelContext.delete(snapshot)
        }
        let routineEntries = (try? modelContext.fetch(FetchDescriptor<RoutineEntry>())) ?? []
        for entry in routineEntries where entry.exerciseDefinition?.id == exercise.id {
            modelContext.delete(entry)
        }
        modelContext.delete(exercise)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = "This exercise couldn't be deleted. Please try again."
        }
    }

    private func parsedNumber(from text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let decimal = Decimal(string: trimmed, locale: .current) else { return nil }
        return NSDecimalNumber(decimal: decimal).doubleValue
    }

    private func validatedOptionalNumber(from text: String, fieldName: String) -> (isValid: Bool, value: Double?) {
        guard loadTrackingMode != .none else { return (true, nil) }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (true, nil) }
        guard let value = parsedNumber(from: trimmed) else {
            saveErrorMessage = "\(fieldName) must be a valid number."
            return (false, nil)
        }
        return (true, value)
    }

    private var saveErrorIsPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }
}

// MARK: - Chip Views

private struct EquipmentChip: View {
    let label: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                Capsule(style: .continuous).fill(accentColor.opacity(0.35))
            }
        }
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(isSelected ? accentColor.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
        }
        .contentShape(Capsule())
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct MuscleGroupChip: View {
    let label: String
    let isPrimary: Bool
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .background(chipFill)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay(chipBorder)
        .contentShape(Capsule())
        .accessibilityLabel(label)
        .accessibilityValue(isPrimary ? "Primary" : isSelected ? "Secondary" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder private var chipFill: some View {
        if isPrimary {
            Capsule(style: .continuous).fill(accentColor.opacity(0.4))
        } else if isSelected {
            Capsule(style: .continuous).fill(accentColor.opacity(0.2))
        }
    }

    private var chipBorder: some View {
        let color: Color = isPrimary ? accentColor.opacity(0.6) :
                           isSelected ? accentColor.opacity(0.35) :
                           Color.white.opacity(0.08)
        return Capsule(style: .continuous).strokeBorder(color, lineWidth: 1)
    }
}

// MARK: - Flow Layout

/// A simple wrapping horizontal layout for pill chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let available = proposal.width ?? 0
        let result = layout(in: available, subviews: subviews)
        return CGSize(width: available, height: result.size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

// MARK: - Previews

#Preview("New exercise") {
    ExerciseEditorView(exercise: nil)
        .exerciseEditorPreviewEnvironments()
}

#Preview("Edit — advanced visible") {
    ExerciseEditorView(exercise: ExerciseEditorPreviewData.editableExercise())
        .exerciseEditorPreviewEnvironments()
}

#Preview("Edit — timed bodyweight") {
    ExerciseEditorView(exercise: ExerciseEditorPreviewData.timedExercise())
        .exerciseEditorPreviewEnvironments()
}
