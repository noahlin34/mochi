import SwiftUI
import SwiftData

struct TutorialView: View {
    @Bindable var pet: Pet
    @Bindable var appState: AppState

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderHour") private var reminderHour: Int = 9
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0

    @State private var stepIndex = 0
    @State private var nameInput = ""
    @State private var notificationsDenied = false
    @State private var isRequestingNotifications = false

    private var steps: [TutorialStep] {
        [
            TutorialStep(
                title: "Home",
                message: "Check your pet’s energy, hunger, and cleanliness. Tap “Complete” to care for them.",
                icon: "house.fill",
                tint: AppColors.cardPeach,
                tip: "Tip: energy bars show what needs attention."
            ),
            TutorialStep(
                title: "Habits",
                message: "Add daily, weekly, or “x times” habits. Rewards trigger when the goal is met.",
                icon: "checkmark.circle.fill",
                tint: AppColors.cardGreen,
                tip: "Swipe to delete or edit a habit."
            ),
            TutorialStep(
                title: "Shop",
                message: "Spend coins on outfits and rooms. Outfits swap your pet’s look.",
                icon: "bag.fill",
                tint: AppColors.cardYellow,
                tip: "Use the filter to see items for the current pet."
            ),
            TutorialStep(
                title: "Settings",
                message: "Switch pets, adjust eye placement, and manage preferences.",
                icon: "gearshape.fill",
                tint: AppColors.cardPurple,
                tip: "You can revisit this tutorial anytime here."
            ),
            TutorialStep(
                title: "Reminders",
                message: "Turn on notifications so we can nudge you when it’s habit time.",
                icon: "bell.fill",
                tint: AppColors.cardGreen,
                tip: "You can change the reminder time in Settings."
            )
        ]
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                Spacer(minLength: 0)

                if stepIndex > 0 {
                    TutorialScreenPreview {
                        previewView
                    }
                    .padding(.horizontal, 24)
                }

                if stepIndex == 0 {
                    nameStepCard
                        .padding(.horizontal, 24)
                } else if isNotificationsStep {
                    notificationsStepCard
                        .padding(.horizontal, 24)
                } else {
                    TutorialCard(step: steps[stepIndex - 1])
                        .padding(.horizontal, 24)
                }

                progressDots

                navigationButtons
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            if nameInput.isEmpty {
                nameInput = appState.userName
            }
            Task {
                let status = await NotificationManager.authorizationStatus()
                await MainActor.run {
                    switch status {
                    case .authorized, .provisional, .ephemeral:
                        break
                    case .denied:
                        notificationsEnabled = false
                        notificationsDenied = true
                    case .notDetermined:
                        notificationsEnabled = false
                    @unknown default:
                        notificationsEnabled = false
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Quick Tour")
                .font(.title2.bold())
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Button("Skip") {
                finishTutorial()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppColors.accentPurple)
        }
        .padding(.horizontal, 24)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<(steps.count + 1), id: \.self) { index in
                Circle()
                    .fill(index == stepIndex ? AppColors.accentPurple : AppColors.mutedPurple.opacity(0.4))
                    .frame(width: index == stepIndex ? 10 : 8, height: index == stepIndex ? 10 : 8)
                    .animation(.easeInOut(duration: 0.2), value: stepIndex)
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    stepIndex = max(0, stepIndex - 1)
                }
            } label: {
                Text("Back")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.cardYellow.opacity(stepIndex == 0 ? 0.4 : 1))
                    .foregroundStyle(AppColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(stepIndex == 0)

            Button {
                if stepIndex == steps.count {
                    finishTutorial()
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        stepIndex = min(steps.count, stepIndex + 1)
                    }
                }
            } label: {
                Text(stepIndex == steps.count ? "Get Started" : "Next")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.accentPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(stepIndex == 0 && nameInputTrimmed.isEmpty)
        }
        .padding(.horizontal, 24)
    }

    private func finishTutorial() {
        appState.userName = nameInputTrimmed
        appState.tutorialSeen = true
    }

    @ViewBuilder
    private var previewView: some View {
        switch stepIndex {
        case 1:
            TutorialMockScreen(kind: .home)
        case 2:
            TutorialMockScreen(kind: .habits)
        case 3:
            TutorialMockScreen(kind: .shop)
        case 4:
            TutorialMockScreen(kind: .settings)
        case 5:
            TutorialMockScreen(kind: .reminders)
        default:
            EmptyView()
        }
    }

    private var nameInputTrimmed: String {
        nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isNotificationsStep: Bool {
        stepIndex > 0 && steps[stepIndex - 1].title == "Reminders"
    }

    private var nameStepCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppColors.cardPurple.opacity(0.6))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColors.accentPurple)
                    )

                Text("Welcome to mochi")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }

            Text("Care for \(pet.name) by finishing habits. Each completion earns coins and XP.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("What should I call you?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                TextField("Your name", text: $nameInput)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .padding(12)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    private var notificationsStepCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppColors.cardGreen.opacity(0.6))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "bell.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColors.accentPurple)
                    )

                Text("Reminders")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }

            Text("Allow notifications to get a gentle daily reminder at \(reminderTimeString).")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if notificationsDenied {
                Text("Notifications are off. Enable them in iOS Settings to receive reminders.")
                    .font(.caption)
                    .foregroundStyle(AppColors.accentPeach)
            }

            Button {
                enableNotificationsFromTutorial()
            } label: {
                HStack(spacing: 8) {
                    if isRequestingNotifications {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(notificationsEnabled ? "Notifications Enabled" : "Enable Reminders")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(notificationsEnabled ? AppColors.mutedPurple.opacity(0.4) : AppColors.accentPurple)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(notificationsEnabled || isRequestingNotifications)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    private var reminderTimeString: String {
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func enableNotificationsFromTutorial() {
        isRequestingNotifications = true
        Task {
            let granted = await NotificationManager.requestAuthorizationIfNeeded()
            await MainActor.run {
                notificationsEnabled = granted
                notificationsDenied = !granted
                isRequestingNotifications = false
            }
            if granted {
                await NotificationManager.updateDailyReminder(
                    enabled: true,
                    hour: reminderHour,
                    minute: reminderMinute
                )
            }
        }
    }
}

private struct TutorialStep: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let tint: Color
    let tip: String?

    init(
        title: String,
        message: String,
        icon: String,
        tint: Color,
        tip: String? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.tint = tint
        self.tip = tip
    }
}

private struct TutorialCard: View {
    let step: TutorialStep

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Circle()
                    .fill(step.tint.opacity(0.6))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: step.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColors.accentPurple)
                    )

                Text(step.title)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }

            Text(step.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let tip = step.tip {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(AppColors.accentPeach)
                    Text(tip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

private struct TutorialScreenPreview<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environment(\.tabBarHeight, 0)
            .allowsHitTesting(false)
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
            .scaleEffect(0.95)
            .padding(.bottom, 4)
    }
}

private struct TutorialMockScreen: View {
    let kind: Kind

    var body: some View {
        ZStack {
            Color.appBackground

            VStack(spacing: 12) {
                HStack {
                    Text(kind.title)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: kind.icon)
                        .foregroundStyle(AppColors.accentPurple)
                }

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(kind.accent.opacity(0.55))
                    .frame(height: 94)
                    .overlay(
                        HStack(spacing: 10) {
                            Circle()
                                .fill(.white.opacity(0.85))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Image(systemName: kind.icon)
                                        .foregroundStyle(AppColors.accentPurple)
                                )

                            VStack(alignment: .leading, spacing: 6) {
                                Capsule().fill(.white.opacity(0.9)).frame(width: 86, height: 10)
                                Capsule().fill(.white.opacity(0.75)).frame(width: 120, height: 8)
                                Capsule().fill(.white.opacity(0.75)).frame(width: 66, height: 8)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                    )

                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white)
                        .frame(height: 58)
                        .overlay(Capsule().fill(kind.accent.opacity(0.55)).frame(width: 62, height: 8))

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white)
                        .frame(height: 58)
                        .overlay(Capsule().fill(kind.accent.opacity(0.55)).frame(width: 44, height: 8))
                }
            }
            .padding(14)
        }
    }

    enum Kind {
        case home
        case habits
        case shop
        case settings
        case reminders

        var title: String {
            switch self {
            case .home:
                return "Home"
            case .habits:
                return "Habits"
            case .shop:
                return "Shop"
            case .settings:
                return "Settings"
            case .reminders:
                return "Reminders"
            }
        }

        var icon: String {
            switch self {
            case .home:
                return "house.fill"
            case .habits:
                return "checkmark.circle.fill"
            case .shop:
                return "bag.fill"
            case .settings:
                return "gearshape.fill"
            case .reminders:
                return "bell.fill"
            }
        }

        var accent: Color {
            switch self {
            case .home:
                return AppColors.cardPeach
            case .habits:
                return AppColors.cardGreen
            case .shop:
                return AppColors.cardYellow
            case .settings:
                return AppColors.cardPurple
            case .reminders:
                return AppColors.cardGreen
            }
        }
    }
}

#Preview {
    let preview = PreviewData.make()
    return TutorialView(pet: preview.pet, appState: preview.appState)
        .modelContainer(preview.container)
}
