import Foundation
import SwiftData

@Model
final class InventoryItem {
    var id: UUID
    var type: InventoryItemType
    var name: String
    var price: Int
    var owned: Bool
    var equipped: Bool
    var assetName: String
    var petSpeciesRaw: String?
    var equipStyleRaw: String = InventoryEquipStyle.replaceSprite.rawValue
    var createdAt: Date

    init(
        id: UUID = UUID(),
        type: InventoryItemType,
        name: String,
        price: Int,
        owned: Bool = false,
        equipped: Bool = false,
        assetName: String,
        petSpecies: PetSpecies? = nil,
        equipStyle: InventoryEquipStyle = .replaceSprite,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.price = price
        self.owned = owned
        self.equipped = equipped
        self.assetName = assetName
        self.petSpeciesRaw = petSpecies?.rawValue
        self.equipStyleRaw = equipStyle.rawValue
        self.createdAt = createdAt
    }

    var petSpecies: PetSpecies? {
        get {
            guard let petSpeciesRaw else { return nil }
            return PetSpecies(rawValue: petSpeciesRaw)
        }
        set {
            petSpeciesRaw = newValue?.rawValue
        }
    }

    var equipStyle: InventoryEquipStyle {
        get {
            InventoryEquipStyle(rawValue: equipStyleRaw) ?? .replaceSprite
        }
        set {
            equipStyleRaw = newValue.rawValue
        }
    }

    func isAvailable(for species: PetSpecies) -> Bool {
        if type == .room { return true }
        guard let petSpecies else { return true }
        return petSpecies == species
    }
}
