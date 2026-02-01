import Foundation
import SwiftData

@Model
final class AppState {
    var lastDailyReset: Date
    var lastWeeklyReset: Date
    var selectedPetSpecies: PetSpecies
    var tutorialSeen: Bool
    var currentStreak: Int
    var createdAt: Date

    init(
        lastDailyReset: Date = Date(),
        lastWeeklyReset: Date = Date(),
        selectedPetSpecies: PetSpecies = .cat,
        tutorialSeen: Bool = false,
        currentStreak: Int = 0,
        createdAt: Date = Date()
    ) {
        self.lastDailyReset = lastDailyReset
        self.lastWeeklyReset = lastWeeklyReset
        self.selectedPetSpecies = selectedPetSpecies
        self.tutorialSeen = tutorialSeen
        self.currentStreak = currentStreak
        self.createdAt = createdAt
    }
}
