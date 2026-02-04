import Foundation
import SwiftData

@Model
final class Pet {
    var id: UUID
    var name: String
    var species: PetSpecies
    var energy: Int
    var hunger: Int
    var cleanliness: Int
    var level: Int
    var xp: Int
    var coins: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        species: PetSpecies,
        energy: Int = 80,
        hunger: Int = 80,
        cleanliness: Int = 80,
        level: Int = 1,
        xp: Int = 0,
        coins: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.energy = energy
        self.hunger = hunger
        self.cleanliness = cleanliness
        self.level = level
        self.xp = xp
        self.coins = coins
        self.createdAt = createdAt
    }
}
