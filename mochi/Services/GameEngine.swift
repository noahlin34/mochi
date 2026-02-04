import Foundation
import SwiftData

@MainActor
final class GameEngine {
    // Centralized rules for rewards and daily/weekly resets.
    struct Reward {
        let coins: Int
        let xp: Int
        let energy: Int
        let hunger: Int
        let cleanliness: Int
    }

    static let habitReward = Reward(coins: 5, xp: 10, energy: 3, hunger: 5, cleanliness: 2)
    private static let dailyEnergyDecay = 20
    private static let dailyHungerDecay = 12
    private static let dailyCleanlinessDecay = 6

    private let calendar: Calendar
    private let dateProvider: () -> Date

    init(calendar: Calendar = .current, dateProvider: @escaping () -> Date = Date.init) {
        self.calendar = calendar
        self.dateProvider = dateProvider
    }

    @discardableResult
    func completeHabit(_ habit: Habit, pet: Pet, appState: AppState? = nil) -> Bool {
        let now = dateProvider()
        let rewardEarned: Bool
        let hungerEarned: Bool
        let cleanlinessEarned: Bool

        switch habit.scheduleType {
        case .daily:
            guard habit.completedCountToday < 1 else { return false }
            habit.completedCountToday += 1
            habit.completedThisWeek += 1
            rewardEarned = true
            hungerEarned = true
            cleanlinessEarned = false

        case .weekly:
            guard habit.completedThisWeek < 1 else { return false }
            habit.completedThisWeek += 1
            habit.completedCountToday += 1
            rewardEarned = true
            hungerEarned = false
            cleanlinessEarned = true

        case .xTimesPerDay:
            guard habit.completedCountToday < habit.targetForSchedule else { return false }
            habit.completedCountToday += 1
            habit.completedThisWeek += 1
            rewardEarned = habit.completedCountToday == habit.targetForSchedule
            hungerEarned = rewardEarned
            cleanlinessEarned = false

        case .xTimesPerWeek:
            guard habit.completedThisWeek < habit.targetForSchedule else { return false }
            habit.completedThisWeek += 1
            habit.completedCountToday += 1
            rewardEarned = habit.completedThisWeek == habit.targetForSchedule
            hungerEarned = false
            cleanlinessEarned = rewardEarned
        }

        habit.lastCompletedDate = now
        applyCompletionEffects(to: pet, hunger: hungerEarned, cleanliness: cleanlinessEarned)
        updateStreakIfNeeded(appState: appState, on: now)
        applyStreakBonusIfNeeded(appState: appState, pet: pet, on: now)

        if rewardEarned {
            applyReward(to: pet)
        }

        return true
    }

    // Applies daily decay and weekly counters based on calendar boundaries.
    func runResetsIfNeeded(appState: AppState, habits: [Habit], pet: Pet) {
        let now = dateProvider()
        let startOfToday = calendar.startOfDay(for: now)
        let lastDailyReset = calendar.startOfDay(for: appState.lastDailyReset)

        if startOfToday > lastDailyReset {
            let dayDiff = calendar.dateComponents([.day], from: lastDailyReset, to: startOfToday).day ?? 0
            let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)
            let hadCompletionYesterday = habits.contains { habit in
                guard let lastCompletedDate = habit.lastCompletedDate, let yesterday else {
                    return false
                }
                return calendar.isDate(lastCompletedDate, inSameDayAs: yesterday)
            }

            if dayDiff == 1 {
                appState.currentStreak = hadCompletionYesterday ? appState.currentStreak + 1 : 0
            } else if dayDiff > 1 {
                appState.currentStreak = 0
            }

            habits.forEach { $0.completedCountToday = 0 }
            pet.hunger = GameLogic.clamp(pet.hunger - Self.dailyHungerDecay)
            pet.cleanliness = GameLogic.clamp(pet.cleanliness - Self.dailyCleanlinessDecay)
            if hadCompletionYesterday {
                pet.energy = GameLogic.clamp(pet.energy - Self.dailyEnergyDecay)
            } else {
                pet.energy = 0
            }
            appState.lastDailyReset = startOfToday
        }

        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfToday
        let lastWeeklyReset = calendar.dateInterval(of: .weekOfYear, for: appState.lastWeeklyReset)?.start ?? startOfWeek

        if startOfWeek > lastWeeklyReset {
            habits.forEach { $0.completedThisWeek = 0 }
            appState.lastWeeklyReset = startOfWeek
        }
    }

    func runResetsIfNeeded(context: ModelContext) {
        let appState = fetchSingle(AppState.self, context: context)
        let pet = fetchSingle(Pet.self, context: context)
        let habits = fetchAll(Habit.self, context: context)

        guard let appState, let pet else { return }
        runResetsIfNeeded(appState: appState, habits: habits, pet: pet)
    }

    private func fetchSingle<T: PersistentModel>(_ type: T.Type, context: ModelContext) -> T? {
        let descriptor = FetchDescriptor<T>()
        return (try? context.fetch(descriptor))?.first
    }

    private func fetchAll<T: PersistentModel>(_ type: T.Type, context: ModelContext) -> [T] {
        let descriptor = FetchDescriptor<T>()
        return (try? context.fetch(descriptor)) ?? []
    }

    private func applyReward(to pet: Pet) {
        let multiplier = coinMultiplier(for: pet)
        let coinsEarned = Int(Double(Self.habitReward.coins) * multiplier)
        pet.coins += max(1, coinsEarned)
        pet.xp += Self.habitReward.xp
        pet.level = GameLogic.levelForXP(pet.xp)
    }

    private func applyCompletionEffects(to pet: Pet, hunger: Bool, cleanliness: Bool) {
        pet.energy = GameLogic.clamp(pet.energy + Self.habitReward.energy)
        if hunger {
            pet.hunger = GameLogic.clamp(pet.hunger + Self.habitReward.hunger)
        }
        if cleanliness {
            pet.cleanliness = GameLogic.clamp(pet.cleanliness + Self.habitReward.cleanliness)
        }
    }

    private func applyStreakBonusIfNeeded(appState: AppState?, pet: Pet, on date: Date) {
        guard let appState else { return }
        if let lastBonus = appState.lastStreakBonusDate,
           calendar.isDate(lastBonus, inSameDayAs: date) {
            return
        }
        let bonus = max(0, appState.currentStreak)
        if bonus > 0 {
            pet.coins += bonus
        }
        appState.lastStreakBonusDate = date
    }

    private func coinMultiplier(for pet: Pet) -> Double {
        let wellness = (pet.energy + pet.hunger + pet.cleanliness) / 3
        switch wellness {
        case 71...:
            return 1.0
        case 51...70:
            return 0.75
        case 31...50:
            return 0.5
        default:
            return 0.25
        }
    }

    private func updateStreakIfNeeded(appState: AppState?, on date: Date) {
        guard let appState else { return }
        let startOfToday = calendar.startOfDay(for: date)
        let lastDailyReset = calendar.startOfDay(for: appState.lastDailyReset)
        if startOfToday == lastDailyReset, appState.currentStreak == 0 {
            appState.currentStreak = 1
        }
    }
}

struct GameLogic {
    static func clamp(_ value: Int, min: Int = 0, max: Int = 100) -> Int {
        Swift.max(min, Swift.min(max, value))
    }

    static func levelForXP(_ xp: Int) -> Int {
        // Simple formula: every 100 XP is a level-up, starting at level 1.
        (xp / 100) + 1
    }
}
