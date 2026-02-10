import SwiftUI
import SwiftData
import RevenueCat
import RevenueCatUI

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var reactionController: PetReactionController
    @EnvironmentObject private var revenueCat: RevenueCatManager
    @Environment(\.tabBarHeight) private var tabBarHeight
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @Bindable var pet: Pet
    @Bindable var appState: AppState

    @State private var showingForm = false
    @State private var habitToEdit: Habit?
    @State private var isBouncing = false
    @State private var offeringToPresent: Offering?

    private let freeHabitLimit = 3
    private let engine = GameEngine()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    if hasReachedFreeLimit {
                        Text("Free plan supports up to \(freeHabitLimit) habits. Upgrade to Mochi Pro for unlimited habits.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if habits.isEmpty {
                        ContentUnavailableView("No Habits Yet", systemImage: "sparkles", description: Text("Add your first habit to care for your pet."))
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(habits) { habit in
                                HabitListCard(
                                    habit: habit,
                                    onComplete: { complete(habit) },
                                    onEdit: {
                                        habitToEdit = habit
                                        showingForm = true
                                    },
                                    onDelete: {
                                        deleteHabit(habit)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, tabBarPadding)
            }
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await handleAddTapped()
                        }
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                HabitFormView(habit: habitToEdit)
            }
        }
        .onChange(of: reactionController.pulse) { _ in
            triggerBounce()
        }
        .presentPaywall(
            offering: $offeringToPresent,
            presentationMode: .sheet
        )
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
    }

    private var tabBarPadding: CGFloat {
        max(tabBarHeight + 16, 96)
    }

    private var hasReachedFreeLimit: Bool {
        !revenueCat.hasMochiPro && habits.count >= freeHabitLimit
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            PetView(species: pet.species, baseOutfitSymbol: nil, overlaySymbols: [], isBouncing: isBouncing)
                .scaleEffect(0.55)
                .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 6) {
                Text("Care Actions")
                    .font(.headline)
                Text("Complete habits to keep your pet happy.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColors.cardPurple)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func complete(_ habit: Habit) {
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

    private func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        HabitWidgetSyncService.sync(context: modelContext)
    }

    private func handleAddTapped() async {
        habitToEdit = nil

        if hasReachedFreeLimit {
            if revenueCat.currentOffering == nil {
                await revenueCat.loadCurrentOffering()
            }
            offeringToPresent = revenueCat.currentOffering
            return
        }

        showingForm = true
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

private struct HabitListCard: View {
    @Bindable var habit: Habit
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.headline)
                    Text(scheduleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onComplete()
                } label: {
                    Text(buttonTitle)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(buttonBackground)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .disabled(isCompletionLocked)
            }

            HStack {
                Label("Today: \(habit.completedCountToday)", systemImage: "sun.max")
                Spacer()
                Label("This week: \(habit.completedThisWeek)", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var scheduleText: String {
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

    private var isCompletionLocked: Bool {
        switch habit.scheduleType {
        case .daily, .weekly, .xTimesPerDay, .xTimesPerWeek:
            return habit.isGoalMetForSchedule
        }
    }

    private var buttonTitle: String {
        isCompletionLocked ? "Done" : "Complete"
    }

    private var buttonBackground: Color {
        isCompletionLocked ? AppColors.mutedPurple : AppColors.accentPurple
    }
}

#Preview {
    let preview = PreviewData.make()
    return HabitsView(pet: preview.pet, appState: preview.appState)
        .modelContainer(preview.container)
        .environmentObject(PetReactionController())
        .environmentObject(RevenueCatManager())
}
