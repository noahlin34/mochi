import Foundation
import SwiftData

@Model
final class AppState {
    var lastDailyReset: Date
    var lastWeeklyReset: Date
    var selectedPetSpecies: PetSpecies
    var tutorialSeen: Bool
    var userName: String
    var lastStreakBonusDate: Date?
    var currentStreak: Int
    var createdAt: Date

    init(
        lastDailyReset: Date = Date(),
        lastWeeklyReset: Date = Date(),
        selectedPetSpecies: PetSpecies = .cat,
        tutorialSeen: Bool = false,
        userName: String = "",
        lastStreakBonusDate: Date? = nil,
        currentStreak: Int = 0,
        createdAt: Date = Date()
    ) {
        self.lastDailyReset = lastDailyReset
        self.lastWeeklyReset = lastWeeklyReset
        self.selectedPetSpecies = selectedPetSpecies
        self.tutorialSeen = tutorialSeen
        self.userName = userName
        self.lastStreakBonusDate = lastStreakBonusDate
        self.currentStreak = currentStreak
        self.createdAt = createdAt
    }
}

extension AppState {
    var userDisplayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "there" : trimmed
    }
}
