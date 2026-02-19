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
    var equippedSpeciesRaw: String?
    var assetName: String
    var petSpeciesRaw: String?
    var equipStyleRaw: String = InventoryEquipStyle.replaceSprite.rawValue
    var outfitClassRaw: String = InventoryOutfitClass.body.rawValue
    var createdAt: Date

    init(
        id: UUID = UUID(),
        type: InventoryItemType,
        name: String,
        price: Int,
        owned: Bool = false,
        equipped: Bool = false,
        equippedSpeciesRaw: String? = nil,
        assetName: String,
        petSpecies: PetSpecies? = nil,
        equipStyle: InventoryEquipStyle = .replaceSprite,
        outfitClass: InventoryOutfitClass = .body,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.price = price
        self.owned = owned
        self.equipped = equipped
        self.equippedSpeciesRaw = equippedSpeciesRaw
        self.assetName = assetName
        self.petSpeciesRaw = petSpecies?.rawValue
        self.equipStyleRaw = equipStyle.rawValue
        self.outfitClassRaw = outfitClass.rawValue
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

    var outfitClass: InventoryOutfitClass {
        get {
            InventoryOutfitClass(rawValue: outfitClassRaw) ?? .body
        }
        set {
            outfitClassRaw = newValue.rawValue
        }
    }

    func isAvailable(for species: PetSpecies) -> Bool {
        if type == .room { return true }
        guard let petSpecies else { return true }
        return petSpecies == species
    }

    func isEquipped(for species: PetSpecies) -> Bool {
        let equippedSpeciesSet = self.equippedSpeciesSet
        if !equippedSpeciesSet.isEmpty {
            return equippedSpeciesSet.contains(species.rawValue)
        }

        guard equipped else { return false }
        if let petSpecies {
            return petSpecies == species
        }
        return true
    }

    func setEquipped(_ isEquipped: Bool, for species: PetSpecies) {
        var equippedSpeciesSet = self.equippedSpeciesSet
        if isEquipped {
            equippedSpeciesSet.insert(species.rawValue)
        } else {
            equippedSpeciesSet.remove(species.rawValue)
        }

        equippedSpeciesRaw = equippedSpeciesSet.isEmpty
            ? nil
            : equippedSpeciesSet.sorted().joined(separator: ",")
        equipped = !equippedSpeciesSet.isEmpty
    }

    func migrateLegacyEquippedStateIfNeeded(activeSpecies: PetSpecies) {
        guard equipped else { return }
        guard equippedSpeciesSet.isEmpty else { return }

        let targetSpecies = petSpecies ?? activeSpecies
        setEquipped(true, for: targetSpecies)
    }

    private var equippedSpeciesSet: Set<String> {
        guard let equippedSpeciesRaw, !equippedSpeciesRaw.isEmpty else {
            return []
        }

        let rawValues = equippedSpeciesRaw.split(separator: ",")
        let validValues = rawValues.compactMap { rawValue -> String? in
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            guard PetSpecies(rawValue: trimmed) != nil else { return nil }
            return trimmed
        }

        return Set(validValues)
    }
}
