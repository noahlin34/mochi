import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var reactionController: PetReactionController
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \InventoryItem.createdAt) private var items: [InventoryItem]

    @Bindable var pet: Pet
    @Bindable var appState: AppState

    @State private var isBouncing = false

    private let engine = GameEngine()

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
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .onChange(of: reactionController.pulse) { _ in
            triggerBounce()
        }
    }

    private var statusRow: some View {
        HStack(spacing: 12) {
            StatCapsule(icon: "heart.fill", value: pet.mood, tint: AppColors.accentPeach)
                .frame(maxWidth: .infinity)

            CoinsPill(coins: pet.coins)
        }
    }

    private var petCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.cardPurple)
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)

            RoomBackgroundView(assetName: equippedRoom?.assetName)
                .padding(16)

            VStack(spacing: 8) {
                SpeechBubble(text: "Hi \(pet.name)! \(petStatusMessage)")
                    .padding(.top, 10)

                PetView(species: pet.species, outfitSymbol: equippedOutfit?.assetName, isBouncing: isBouncing)
                    .frame(height: 170)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 280)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatMiniCard(title: "Mood", value: pet.mood, tint: AppColors.accentPeach, icon: "face.smiling")
            StatMiniCard(title: "Hunger", value: pet.hunger, tint: .orange, icon: "fork.knife")
            StatMiniCard(title: "Clean", value: pet.cleanliness, tint: .blue, icon: "sparkles")
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

    private var equippedOutfit: InventoryItem? {
        items.first { $0.type == .outfit && $0.equipped }
    }

    private var equippedRoom: InventoryItem? {
        items.first { $0.type == .room && $0.equipped }
    }

    private var petStatusMessage: String {
        let lowest = min(pet.hunger, pet.cleanliness, pet.mood)
        if lowest < 35 {
            if pet.hunger == lowest { return "I\'m a bit hungry." }
            if pet.cleanliness == lowest { return "I need a bath." }
            return "I could use a cuddle."
        }
        return "I feel cozy today."
    }

    private func completeHabit(_ habit: Habit) {
        engine.completeHabit(habit, pet: pet, appState: appState)
        reactionController.trigger()
        Haptics.success()
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
                Image(systemName: completedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(completedToday ? AppColors.accentPurple : .white)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var completedToday: Bool {
        habit.completedCountToday > 0
    }

    private var subtitleText: String {
        switch habit.scheduleType {
        case .daily:
            return "Daily · Today \(habit.completedCountToday)"
        case .xTimesPerWeek:
            let target = habit.targetPerWeek ?? 0
            return "\(target)x per week · \(habit.completedThisWeek) done"
        }
    }

    private var iconName: String {
        switch habit.scheduleType {
        case .daily:
            return "sun.max.fill"
        case .xTimesPerWeek:
            return "calendar"
        }
    }
}
