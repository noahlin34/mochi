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
            VStack(spacing: 20) {
                headerSection
                petSection
                statsSection
                todaySection
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .onChange(of: reactionController.pulse) { _ in
            triggerBounce()
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(pet.name)!")
                    .font(.title2.bold())
                Text("Streak: \(appState.currentStreak) day\(appState.currentStreak == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Coins: \(pet.coins)")
                    .font(.headline)
                Text("Level \(pet.level)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    private var petSection: some View {
        ZStack {
            RoomBackgroundView(assetName: equippedRoom?.assetName)
            PetView(species: pet.species, outfitSymbol: equippedOutfit?.assetName, isBouncing: isBouncing)
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            StatBarView(title: "Mood", value: pet.mood, tint: .pink)
            StatBarView(title: "Hunger", value: pet.hunger, tint: .orange)
            StatBarView(title: "Cleanliness", value: pet.cleanliness, tint: .blue)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today\'s Habits")
                .font(.headline)

            if habits.isEmpty {
                Text("No habits yet. Add one from the Habits tab.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(habits) { habit in
                    HabitQuickRow(habit: habit) {
                        completeHabit(habit)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var equippedOutfit: InventoryItem? {
        items.first { $0.type == .outfit && $0.equipped }
    }

    private var equippedRoom: InventoryItem? {
        items.first { $0.type == .room && $0.equipped }
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

private struct HabitQuickRow: View {
    @Bindable var habit: Habit
    let onComplete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.subheadline.bold())
                Text(progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Complete") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var progressText: String {
        if habit.scheduleType == .daily {
            return "Today: \(habit.completedCountToday)"
        }
        let target = habit.targetPerWeek ?? 0
        return "This week: \(habit.completedThisWeek)/\(target)"
    }
}

private struct StatBarView: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.bold())
                Spacer()
                Text("\(value)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(value), total: 100)
                .tint(tint)
        }
    }
}
