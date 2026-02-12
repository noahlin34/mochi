import SwiftUI
import SwiftData
import RevenueCat
import RevenueCatUI

struct SettingsView: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @EnvironmentObject private var revenueCat: RevenueCatManager
    @Environment(\.tabBarHeight) private var tabBarHeight
    @Environment(\.openURL) private var openURL

    @Bindable var pet: Pet
    @Bindable var appState: AppState

    @State private var showEditSheet = false
    @State private var showAppearanceAlert = false
    @State private var showSupportAlert = false
    @State private var showNotificationsAlert = false
    @State private var showingCustomerCenter = false
    @State private var offeringToPresent: Offering?
    @State private var footerToastMessage: String?
    @State private var footerToastDismissTask: Task<Void, Never>?

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderHour") private var reminderHour: Int = 9
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0
    @AppStorage("developerPanelEnabled") private var developerPanelEnabled = false
    @AppStorage("dogEyeTunerEnabled") private var dogEyeTunerEnabled = false
    @AppStorage("dogEyeCenterX") private var dogEyeCenterX: Double = 0
    @AppStorage("dogEyeCenterY") private var dogEyeCenterY: Double = -21
    @AppStorage("dogEyeSeparation") private var dogEyeSeparation: Double = 26
    @AppStorage("dogEyeSize") private var dogEyeSize: Double = 10
    @AppStorage("penguinEyeTunerEnabled") private var penguinEyeTunerEnabled = false
    @AppStorage("penguinEyeCenterX") private var penguinEyeCenterX: Double = 0
    @AppStorage("penguinEyeCenterY") private var penguinEyeCenterY: Double = -20
    @AppStorage("penguinEyeSeparation") private var penguinEyeSeparation: Double = 20
    @AppStorage("penguinEyeSize") private var penguinEyeSize: Double = 8
    @AppStorage("lionEyeTunerEnabled") private var lionEyeTunerEnabled = false
    @AppStorage("lionEyeCenterX") private var lionEyeCenterX: Double = -6
    @AppStorage("lionEyeCenterY") private var lionEyeCenterY: Double = -20
    @AppStorage("lionEyeSeparation") private var lionEyeSeparation: Double = 24
    @AppStorage("lionEyeSize") private var lionEyeSize: Double = 8

    private let progressColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    private let speciesColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 12),
    ]
    private let privacyPolicyURL = "https://noahlin.ca/privacy"
    private let termsOfServiceURL = "https://noahlin.ca/terms"
    private let aboutTagline = "Build better habits with your cozy pet friend."

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    profileCard
                    petSpeciesSection
                    progressSection
                    subscriptionSection
                    preferencesSection
                    developerSection
                    footerCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, tabBarPadding)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(AppColors.accentPurple)
                }
            }
            .sheet(isPresented: $showEditSheet) {
                SettingsEditSheet(pet: pet, appState: appState)
            }
            .alert("Notifications Disabled", isPresented: $showNotificationsAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Enable notifications in Settings to receive daily habit reminders.")
            }
            .alert("Coming Soon", isPresented: $showAppearanceAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Appearance customization will be available in a future update.")
            }
            .alert("Need Help?", isPresented: $showSupportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Support is coming soon. For now, reach out in the repo issues.")
            }
            .alert(
                "Subscription Error",
                isPresented: Binding(
                    get: { revenueCat.lastErrorMessage != nil },
                    set: { newValue in
                        if !newValue {
                            revenueCat.lastErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(revenueCat.lastErrorMessage ?? "")
            }
            .overlay(alignment: .bottom) {
                if let footerToastMessage {
                    SettingsFooterToast(message: footerToastMessage)
                        .padding(.horizontal, 20)
                        .padding(.bottom, max(tabBarPadding - 20, 76))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: footerToastMessage != nil)
            .onAppear {
                if appState.selectedPetSpecies != pet.species {
                    appState.selectedPetSpecies = pet.species
                }
            }
        }
        .onDisappear {
            footerToastDismissTask?.cancel()
        }
        .presentPaywall(offering: $offeringToPresent, presentationMode: .sheet)
        .presentCustomerCenter(isPresented: $showingCustomerCenter, presentationMode: .sheet)
    }

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Settings")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.textPrimary)
                Text("Manage your mochi experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(AppColors.accentPeach)
        }
        .padding(16)
        .background(AppColors.cardGreen)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.cardPurple)
                    .frame(width: 56, height: 56)
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(appState.userDisplayName)
                    .font(.headline)
                Text("Caretaker of \(pet.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Edit") {
                showEditSheet = true
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColors.accentPurple)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            LazyVGrid(columns: progressColumns, spacing: 12) {
                ProgressCard(
                    icon: "calendar",
                    iconTint: AppColors.cardGreen,
                    title: "Days Active",
                    value: "\(daysActive)"
                )
                ProgressCard(
                    icon: "checkmark.circle",
                    iconTint: AppColors.cardPurple,
                    title: "Total Habits",
                    value: "\(habits.count)"
                )
                ProgressCard(
                    icon: "trophy",
                    iconTint: AppColors.cardPeach,
                    title: "Achievements",
                    value: "\(max(1, pet.level))"
                )
                ProgressCard(
                    icon: "heart.fill",
                    iconTint: AppColors.cardYellow,
                    title: "Love Earned",
                    value: "\(pet.xp)"
                )
            }
        }
    }

    private var petSpeciesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pet Species")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text("Current: \(pet.species.displayName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: speciesColumns, spacing: 10) {
                ForEach(PetSpecies.allCases) { species in
                    SpeciesSelectionCard(
                        species: species,
                        isSelected: pet.species == species,
                        action: { setSpecies(species) }
                    )
                }
            }
        }
    }

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subscription")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            SettingsLinkRow(
                icon: "star.circle.fill",
                iconTint: AppColors.cardYellow,
                title: revenueCat.hasMochiPro ? "Mochi Pro Active" : "Upgrade to Mochi Pro",
                actionTitle: "Open →",
                action: {
                    Task {
                        if revenueCat.currentOffering == nil {
                            await revenueCat.loadCurrentOffering()
                        }
                        offeringToPresent = revenueCat.currentOffering
                    }
                }
            )

            SettingsLinkRow(
                icon: "creditcard.fill",
                iconTint: AppColors.cardGreen,
                title: "Manage Subscription",
                actionTitle: "Open →",
                action: {
                    showingCustomerCenter = true
                }
            )

            SettingsLinkRow(
                icon: "arrow.clockwise.circle.fill",
                iconTint: AppColors.cardPurple,
                title: "Restore Purchases",
                actionTitle: "Run →",
                action: {
                    Task {
                        await revenueCat.restorePurchases()
                    }
                }
            )
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            SettingsToggleRow(
                icon: "bell.fill",
                iconTint: AppColors.cardPeach,
                title: "Notifications",
                isOn: $notificationsEnabled
            )
            .onChange(of: notificationsEnabled) { _, isOn in
                Task {
                    if isOn {
                        let granted = await NotificationManager.requestAuthorizationIfNeeded()
                        if !granted {
                            await MainActor.run {
                                notificationsEnabled = false
                                showNotificationsAlert = true
                            }
                            await NotificationManager.cancelDailyReminder()
                            return
                        }
                    }

                    await NotificationManager.updateDailyReminder(
                        enabled: isOn,
                        hour: reminderHour,
                        minute: reminderMinute
                    )
                }
            }

            if notificationsEnabled {
                SettingsTimeRow(title: "Reminder Time", selection: reminderDateBinding)
            }

            SettingsToggleRow(
                icon: "eye.fill",
                iconTint: AppColors.cardPurple,
                title: "Dog Eye Tuner",
                isOn: $dogEyeTunerEnabled
            )

            if dogEyeTunerEnabled {
                VStack(spacing: 12) {
                    SettingsSliderRow(title: "Eye Center X", value: $dogEyeCenterX, range: -40...40)
                    SettingsSliderRow(title: "Eye Center Y", value: $dogEyeCenterY, range: -40...40)
                    SettingsSliderRow(title: "Eye Separation", value: $dogEyeSeparation, range: 10...60)
                    SettingsSliderRow(title: "Eye Size", value: $dogEyeSize, range: 4...24)
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            }

            SettingsToggleRow(
                icon: "eye.fill",
                iconTint: AppColors.cardGreen,
                title: "Penguin Eye Tuner",
                isOn: $penguinEyeTunerEnabled
            )

            if penguinEyeTunerEnabled {
                VStack(spacing: 12) {
                    SettingsSliderRow(title: "Eye Center X", value: $penguinEyeCenterX, range: -40...40)
                    SettingsSliderRow(title: "Eye Center Y", value: $penguinEyeCenterY, range: -40...40)
                    SettingsSliderRow(title: "Eye Separation", value: $penguinEyeSeparation, range: 10...60)
                    SettingsSliderRow(title: "Eye Size", value: $penguinEyeSize, range: 4...24)
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            }

            SettingsToggleRow(
                icon: "eye.fill",
                iconTint: AppColors.cardYellow,
                title: "Lion Eye Tuner",
                isOn: $lionEyeTunerEnabled
            )

            if lionEyeTunerEnabled {
                VStack(spacing: 12) {
                    SettingsSliderRow(title: "Eye Center X", value: $lionEyeCenterX, range: -40...40)
                    SettingsSliderRow(title: "Eye Center Y", value: $lionEyeCenterY, range: -40...40)
                    SettingsSliderRow(title: "Eye Separation", value: $lionEyeSeparation, range: 10...60)
                    SettingsSliderRow(title: "Eye Size", value: $lionEyeSize, range: 4...24)
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            }

            SettingsLinkRow(
                icon: "paintpalette.fill",
                iconTint: AppColors.cardGreen,
                title: "Appearance",
                actionTitle: "Open →",
                action: { showAppearanceAlert = true }
            )

            SettingsLinkRow(
                icon: "questionmark.circle.fill",
                iconTint: AppColors.cardYellow,
                title: "Help & Support",
                actionTitle: "Open →",
                action: { showSupportAlert = true }
            )
        }
    }

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Developer")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            SettingsToggleRow(
                icon: "wrench.fill",
                iconTint: AppColors.cardPurple,
                title: "Developer Panel",
                isOn: $developerPanelEnabled
            )

            if developerPanelEnabled {
                VStack(spacing: 12) {
                    DeveloperSliderRow(title: "Energy", value: intBinding(\.energy), range: 0...100)
                    DeveloperSliderRow(title: "Hunger", value: intBinding(\.hunger), range: 0...100)
                    DeveloperSliderRow(title: "Cleanliness", value: intBinding(\.cleanliness), range: 0...100)
                    DeveloperSliderRow(title: "Coins", value: intBinding(\.coins), range: 0...5000)
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
        }
    }

    private var footerCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf.fill")
                .font(.title2)
                .foregroundStyle(AppColors.accentPeach)

            Text("mochi v1.0")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text("Build better habits with your cozy pet friend.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                footerActionButton(title: "Privacy") {
                    openLegalURL(privacyPolicyURL, label: "Privacy Policy")
                }

                Text("•")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                footerActionButton(title: "Terms") {
                    openLegalURL(termsOfServiceURL, label: "Terms of Service")
                }

                Text("•")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                footerActionButton(title: "About") {
                    showAboutToast()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppColors.cardYellow)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var daysActive: Int {
        let start = Calendar.current.startOfDay(for: pet.createdAt)
        let today = Calendar.current.startOfDay(for: Date())
        let components = Calendar.current.dateComponents([.day], from: start, to: today)
        return max(1, (components.day ?? 0) + 1)
    }

    private var tabBarPadding: CGFloat {
        max(tabBarHeight + 16, 96)
    }

    private var reminderDateBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = components.hour ?? 9
                reminderMinute = components.minute ?? 0
                Task {
                    await NotificationManager.updateDailyReminder(
                        enabled: notificationsEnabled,
                        hour: reminderHour,
                        minute: reminderMinute
                    )
                }
            }
        )
    }

    private func intBinding(_ keyPath: ReferenceWritableKeyPath<Pet, Int>) -> Binding<Double> {
        Binding<Double>(
            get: { Double(pet[keyPath: keyPath]) },
            set: { newValue in
                pet[keyPath: keyPath] = Int(newValue.rounded())
            }
        )
    }

    private func setSpecies(_ species: PetSpecies) {
        guard pet.species != species || appState.selectedPetSpecies != species else { return }
        pet.species = species
        appState.selectedPetSpecies = species
        Haptics.light()
    }

    private func footerActionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private var aboutToastMessage: String {
        "\(appVersionText) • \(aboutTagline)"
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "mochi v\(version) (build \(build))"
    }

    private func openLegalURL(_ urlString: String, label: String) {
        guard let url = URL(string: urlString), let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
            showFooterToast("Could not open \(label) right now.")
            return
        }

        openURL(url) { accepted in
            guard !accepted else { return }
            Task { @MainActor in
                showFooterToast("Could not open \(label) right now.")
            }
        }
    }

    private func showAboutToast() {
        showFooterToast(aboutToastMessage)
    }

    private func showFooterToast(_ message: String) {
        footerToastDismissTask?.cancel()
        footerToastMessage = message

        footerToastDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            footerToastMessage = nil
            footerToastDismissTask = nil
        }
    }
}

private struct ProgressCard: View {
    let icon: String
    let iconTint: Color
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(iconTint.opacity(0.5))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.accentPurple)
                )

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppColors.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let iconTint: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconTint.opacity(0.5))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.accentPurple)
                )

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct SettingsTimeRow: View {
    let title: String
    @Binding var selection: Date

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppColors.cardYellow.opacity(0.5))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.accentPurple)
                )

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

private struct SettingsLinkRow: View {
    let icon: String
    let iconTint: Color
    let title: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(iconTint.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.accentPurple)
                    )

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text(actionTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.accentPurple)
            }
            .padding(12)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(String(format: "%.0f", value))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: 1)
        }
    }
}

private struct DeveloperSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(String(format: "%.0f", value))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: 1)
        }
    }
}

private struct SettingsEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var pet: Pet
    @Bindable var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("User") {
                    TextField("Your name", text: $appState.userName)
                }

                Section("Pet") {
                    TextField("Name", text: $pet.name)
                    Text("Species is managed from the main Settings screen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Tutorial") {
                    Toggle("Tutorial seen", isOn: $appState.tutorialSeen)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SpeciesSelectionCard: View {
    let species: PetSpecies
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(isSelected ? 0.95 : 0.25))
                        .frame(width: 34, height: 34)

                    Text(speciesEmoji)
                        .font(.system(size: 18))
                }

                Text(species.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColors.accentPurple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.85))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(height: 92)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? accentColor.opacity(0.22) : .white)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? accentColor : Color.black.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var speciesEmoji: String {
        switch species {
        case .cat:
            return "🐱"
        case .dog:
            return "🐶"
        case .bunny:
            return "🐰"
        case .penguin:
            return "🐧"
        case .lion:
            return "🦁"
        }
    }

    private var accentColor: Color {
        switch species {
        case .cat:
            return AppColors.cardPurple
        case .dog:
            return AppColors.cardPeach
        case .bunny:
            return AppColors.cardGreen
        case .penguin:
            return AppColors.cardYellow
        case .lion:
            return AppColors.mutedPurple
        }
    }
}

private struct SettingsFooterToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.accentPurple)

            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.cardPurple.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    let preview = PreviewData.make()
    return SettingsView(pet: preview.pet, appState: preview.appState)
        .modelContainer(preview.container)
        .environmentObject(PetReactionController())
        .environmentObject(RevenueCatManager())
}
