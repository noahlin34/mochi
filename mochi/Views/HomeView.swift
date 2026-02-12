import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var reactionController: PetReactionController
    @Environment(\.tabBarHeight) private var tabBarHeight
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \InventoryItem.createdAt) private var items: [InventoryItem]

    @Bindable var pet: Pet
    @Bindable var appState: AppState

    @State private var isBouncing = false
    @State private var moodBoostMessageIndex = -1
    @State private var moodBoostEndsAt: Date?
    @State private var moodBoostToken = UUID()
    @State private var isHappyDancing = false
    @State private var showExclamationBadge = false
    @State private var moodBoostResetTask: Task<Void, Never>?
    @State private var danceTask: Task<Void, Never>?
    @State private var danceTilt: Double = 0
    @State private var danceLift: CGFloat = 0
    @State private var launchTipsStartedAt: Date?
    @State private var currentLaunchTip: String?
    @State private var launchTipTask: Task<Void, Never>?

    private let engine = GameEngine()
    private let moodBoostDuration: TimeInterval = 3
    private let launchTipWindowDuration: TimeInterval = 30
    private let moodBoostMessages = [
        "Yay! You are taking great care of me!",
        "I love hanging out with you!",
        "This is so much fun!",
        "My mood is way up now!"
    ]
    private let launchTips = [
        "Tip: The higher your streak, the more coins you earn.",
        "Tip: Change your pet species in Settings.",
        "Tip: Try different habit schedule types.",
        "Tip: Spend coins in the Shop on outfits and rooms.",
        "Tip: Weekly habits are great for bigger goals.",
        "Tip: Keep energy, hunger, and cleanliness balanced for a happier pet."
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusRow
                petCard
                statsRow
                streakRow
                todaySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, tabBarPadding)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .onChange(of: reactionController.pulse) { _ in
            triggerBounce()
        }
        .onChange(of: reactionController.moodBoostPulse) { _ in
            triggerMoodBoostCelebration()
        }
        .onAppear {
            startLaunchTipDisplayIfNeeded()
        }
        .onChange(of: appState.tutorialSeen) { _, newValue in
            guard newValue else { return }
            startLaunchTipDisplayIfNeeded()
        }
        .onDisappear {
            stopLaunchTipDisplayCountdown()
            cancelMoodBoostTasks()
        }
    }

    private var tabBarPadding: CGFloat {
        max(tabBarHeight + 16, 96)
    }

    private var statusRow: some View {
        HStack(spacing: 12) {
            StatCapsule(icon: "heart.fill", value: wellnessScore, tint: AppColors.accentPeach)
                .frame(maxWidth: .infinity)

            CoinsPill(coins: pet.coins)
        }
    }

    private var petCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.cardPurple)
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)

            LandscapeBackgroundView(assetName: equippedRoom?.assetName)
                .padding(16)

            VStack(spacing: 8) {
                SpeechBubble(text: "Hi \(appState.userDisplayName)! \(petChatMessage)")
                    .padding(.top, 10)

                ZStack(alignment: .topTrailing) {
                    PetView(
                        species: pet.species,
                        baseOutfitSymbol: equippedBaseOutfit?.assetName,
                        overlaySymbols: equippedOverlayOutfits.map(\.assetName),
                        isBouncing: isBouncing
                    )
                    if showExclamationBadge {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AppColors.accentPeach)
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                            .offset(x: 20, y: -8)
                            .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }
                }
                .rotationEffect(.degrees(danceTilt))
                .offset(y: danceLift)
                .scaleEffect(isHappyDancing ? 1.04 : 1.0)
                .frame(height: 170)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 280)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatMiniCard(title: "Energy", value: pet.energy, tint: AppColors.accentPeach, icon: "bolt.fill")
            StatMiniCard(title: "Hunger", value: pet.hunger, tint: .orange, icon: "fork.knife")
            StatMiniCard(title: "Cleanliness", value: pet.cleanliness, tint: .blue, icon: "sparkles")
        }
    }

    private var streakRow: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("Streak \(appState.currentStreak) day\(appState.currentStreak == 1 ? "" : "s")")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.cardPeach)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            if habits.isEmpty {
                Text("No habits yet. Add one from the Habits tab.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                    HabitCardRow(
                        habit: habit,
                        cardColor: habitCardColors[index % habitCardColors.count],
                        onComplete: { completeHabit(habit) }
                    )
                }
            }
        }
    }

    private var habitCardColors: [Color] {
        [AppColors.cardGreen, AppColors.cardYellow, AppColors.cardPurple]
    }

    private var equippedBaseOutfit: InventoryItem? {
        let equipped = items.filter {
            $0.type == .outfit
                && $0.equipped
                && $0.equipStyle == .replaceSprite
        }
        if let match = equipped.first(where: { $0.petSpecies == pet.species }) {
            return match
        }
        return equipped.first(where: { $0.petSpecies == nil })
    }

    private var equippedOverlayOutfits: [InventoryItem] {
        items
            .filter {
                $0.type == .outfit
                    && $0.equipped
                    && $0.equipStyle == .overlay
                    && $0.isAvailable(for: pet.species)
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var equippedRoom: InventoryItem? {
        items.first { $0.type == .room && $0.equipped }
    }

    private var petChatMessage: String {
        guard isMoodBoostActive else {
            if isLaunchTipWindowActive(now: Date()), let currentLaunchTip {
                return currentLaunchTip
            }
            return petStatusMessage
        }
        guard !moodBoostMessages.isEmpty else {
            return petStatusMessage
        }
        let safeIndex = max(0, moodBoostMessageIndex) % moodBoostMessages.count
        return moodBoostMessages[safeIndex]
    }

    private var isMoodBoostActive: Bool {
        guard let moodBoostEndsAt else { return false }
        return moodBoostEndsAt > Date()
    }

    private func isLaunchTipWindowActive(now: Date = Date()) -> Bool {
        LaunchTipRotationHelper.isWindowActive(
            startedAt: launchTipsStartedAt,
            now: now,
            windowDuration: launchTipWindowDuration
        )
    }

    private func selectLaunchTip() -> String? {
        LaunchTipRotationHelper.selectRandomTip(tips: launchTips)
    }

    private var petStatusMessage: String {
        let stats = [
            ("hunger", pet.hunger),
            ("cleanliness", pet.cleanliness),
            ("energy", pet.energy)
        ]
        let lowest = stats.min { $0.1 < $1.1 }

        guard let (stat, value) = lowest else {
            return "I feel cozy today."
        }

        switch value {
        case ..<20:
            return urgentMessage(for: stat)
        case 20..<45:
            return lowMessage(for: stat)
        case 45..<75:
            return "I’m doing okay. Keep me cared for!"
        default:
            return "I feel great today!"
        }
    }

    private func lowMessage(for stat: String) -> String {
        switch stat {
        case "hunger":
            return "I’m getting hungry."
        case "cleanliness":
            return "I need a little clean-up."
        case "energy":
            return "I’m feeling a bit tired."
        default:
            return "I’m a bit low."
        }
    }

    private func urgentMessage(for stat: String) -> String {
        switch stat {
        case "hunger":
            return "I’m really hungry!"
        case "cleanliness":
            return "I really need a bath!"
        case "energy":
            return "I’m running out of energy!"
        default:
            return "I need help!"
        }
    }

    private var wellnessScore: Int {
        let total = pet.energy + pet.hunger + pet.cleanliness
        return max(0, min(100, total / 3))
    }

    private func completeHabit(_ habit: Habit) {
        let previousCoins = pet.coins
        let previousEnergy = pet.energy
        let previousHunger = pet.hunger
        let previousCleanliness = pet.cleanliness
        let completed = engine.completeHabit(habit, pet: pet, appState: appState)
        if completed {
            reactionController.trigger()
            let delta = pet.coins - previousCoins
            if delta > 0 {
                reactionController.triggerCoins(amount: delta)
            }
            let energyDelta = pet.energy - previousEnergy
            let hungerDelta = pet.hunger - previousHunger
            let cleanlinessDelta = pet.cleanliness - previousCleanliness
            reactionController.triggerMoodBoostIfNeeded(
                energyDelta: energyDelta,
                hungerDelta: hungerDelta,
                cleanlinessDelta: cleanlinessDelta
            )
            if energyDelta > 0 {
                reactionController.triggerStatBurst(kind: .energy, amount: energyDelta)
            }
            if hungerDelta > 0 {
                reactionController.triggerStatBurst(kind: .hunger, amount: hungerDelta)
            }
            if cleanlinessDelta > 0 {
                reactionController.triggerStatBurst(kind: .cleanliness, amount: cleanlinessDelta)
            }
            HabitWidgetSyncService.sync(context: modelContext)
        }
    }

    private func triggerMoodBoostCelebration() {
        advanceMoodBoostMessage()

        let token = UUID()
        moodBoostToken = token
        moodBoostEndsAt = Date().addingTimeInterval(moodBoostDuration)

        moodBoostResetTask?.cancel()
        moodBoostResetTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(moodBoostDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard moodBoostToken == token else { return }
                moodBoostEndsAt = nil
                showExclamationBadge = false
                isHappyDancing = false
                danceTilt = 0
                danceLift = 0
            }
        }

        startHappyDance(token: token)
    }

    private func advanceMoodBoostMessage() {
        guard !moodBoostMessages.isEmpty else { return }
        if moodBoostMessageIndex < 0 {
            moodBoostMessageIndex = 0
            return
        }
        moodBoostMessageIndex = (moodBoostMessageIndex + 1) % moodBoostMessages.count
    }

    private func startHappyDance(token: UUID) {
        danceTask?.cancel()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.62)) {
            isHappyDancing = true
            showExclamationBadge = true
            danceLift = -9
            danceTilt = -10
        }

        danceTask = Task {
            let danceSteps: [(tilt: Double, lift: CGFloat, delay: UInt64)] = [
                (10, -4, 130_000_000),
                (-9, -8, 130_000_000),
                (8, -3, 130_000_000),
                (0, 0, 160_000_000)
            ]

            for step in danceSteps {
                try? await Task.sleep(nanoseconds: step.delay)
                guard !Task.isCancelled else { return }
                let isCurrentToken = await MainActor.run { moodBoostToken == token }
                guard isCurrentToken else { return }

                await MainActor.run {
                    withAnimation(.spring(response: 0.17, dampingFraction: 0.65)) {
                        danceTilt = step.tilt
                        danceLift = step.lift
                    }
                }
            }

            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !Task.isCancelled else { return }
            let isCurrentToken = await MainActor.run { moodBoostToken == token }
            guard isCurrentToken else { return }

            await MainActor.run {
                withAnimation(.easeIn(duration: 0.18)) {
                    showExclamationBadge = false
                }
                withAnimation(.easeOut(duration: 0.2)) {
                    isHappyDancing = false
                }
            }
        }
    }

    private func cancelMoodBoostTasks() {
        moodBoostResetTask?.cancel()
        moodBoostResetTask = nil
        danceTask?.cancel()
        danceTask = nil
        moodBoostEndsAt = nil
        showExclamationBadge = false
        isHappyDancing = false
        danceTilt = 0
        danceLift = 0
    }

    private func startLaunchTipDisplayIfNeeded() {
        guard appState.tutorialSeen else { return }

        let now = Date()

        if launchTipsStartedAt == nil {
            launchTipsStartedAt = now
            currentLaunchTip = selectLaunchTip()
        }

        guard isLaunchTipWindowActive(now: now) else {
            currentLaunchTip = nil
            stopLaunchTipDisplayCountdown()
            return
        }

        guard currentLaunchTip != nil else { return }
        guard launchTipTask == nil else { return }

        let start = launchTipsStartedAt ?? now
        let elapsed = now.timeIntervalSince(start)
        let remaining = max(0, launchTipWindowDuration - elapsed)
        guard remaining > 0 else {
            currentLaunchTip = nil
            stopLaunchTipDisplayCountdown()
            return
        }

        launchTipTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            guard !Task.isCancelled else { return }
            currentLaunchTip = nil
            launchTipTask = nil
        }
    }

    private func stopLaunchTipDisplayCountdown() {
        launchTipTask?.cancel()
        launchTipTask = nil
    }

    private func triggerBounce() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            isBouncing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isBouncing = false
            }
        }
    }
}

private struct StatCapsule: View {
    let icon: String
    let value: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            CapsuleProgressBar(value: value, tint: tint)
            Text("\(value)%")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

private struct CapsuleProgressBar: View {
    let value: Int
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let progress = max(0, min(1, CGFloat(value) / 100))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.progressTrack)
                Capsule()
                    .fill(tint)
                    .frame(width: max(8, width * progress))
            }
        }
        .frame(height: 8)
    }
}

private struct CoinsPill: View {
    let coins: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.accentPeach)
            Text("\(coins)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColors.coinPill)
        .clipShape(Capsule())
    }
}

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.9))
                )

            Triangle()
                .fill(.white.opacity(0.9))
                .frame(width: 16, height: 10)
                .rotationEffect(.degrees(180))
                .offset(y: 1)
        }
    }
}

private struct StatMiniCard: View {
    let title: String
    let value: Int
    let tint: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            CapsuleProgressBar(value: value, tint: tint)
                .frame(height: 6)
            Text("\(value)%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct HabitCardRow: View {
    @Bindable var habit: Habit
    let cardColor: Color
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.7))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.accentPurple)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onComplete()
            } label: {
                Image(systemName: isGoalMet ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isGoalMet ? AppColors.accentPurple : .white)
            }
            .buttonStyle(.plain)
            .disabled(isCompletionLocked)
        }
        .padding(14)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var isGoalMet: Bool {
        habit.isGoalMetForSchedule
    }

    private var isCompletionLocked: Bool {
        switch habit.scheduleType {
        case .daily, .weekly, .xTimesPerDay, .xTimesPerWeek:
            return habit.isGoalMetForSchedule
        }
    }

    private var subtitleText: String {
        switch habit.scheduleType {
        case .daily:
            return "Daily · \(habit.completedCountToday)/1"
        case .weekly:
            return "Weekly · \(habit.completedThisWeek)/1"
        case .xTimesPerDay:
            let target = habit.targetForSchedule
            return "\(target)x per day · \(habit.completedCountToday)/\(target)"
        case .xTimesPerWeek:
            let target = habit.targetForSchedule
            return "\(target)x per week · \(habit.completedThisWeek)/\(target)"
        }
    }

    private var iconName: String {
        switch habit.scheduleType {
        case .daily:
            return "sun.max.fill"
        case .weekly:
            return "calendar"
        case .xTimesPerDay:
            return "repeat"
        case .xTimesPerWeek:
            return "calendar"
        }
    }
}

#Preview {
    let preview = PreviewData.make()
    return HomeView(pet: preview.pet, appState: preview.appState)
        .modelContainer(preview.container)
        .environmentObject(PetReactionController())
}
