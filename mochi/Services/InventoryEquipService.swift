import Foundation

@MainActor
enum InventoryEquipService {
    @discardableResult
    static func applyEquip(
        for item: InventoryItem,
        in allItems: [InventoryItem],
        activeSpecies: PetSpecies
    ) -> Bool {
        guard item.owned else { return false }

        migrateLegacyEquippedStatesIfNeeded(in: allItems, activeSpecies: activeSpecies)

        if item.type == .room {
            for other in allItems where
                other.type == .room
                    && other.id != item.id
                    && other.isEquipped(for: activeSpecies) {
                other.setEquipped(false, for: activeSpecies)
            }
        } else if item.type == .outfit {
            for other in allItems where
                other.type == .outfit
                    && other.isEquipped(for: activeSpecies)
                    && other.outfitClass == item.outfitClass
                    && other.id != item.id {
                other.setEquipped(false, for: activeSpecies)
            }
        }

        item.setEquipped(true, for: activeSpecies)
        return true
    }

    static func migrateLegacyEquippedStatesIfNeeded(
        in allItems: [InventoryItem],
        activeSpecies: PetSpecies
    ) {
        for item in allItems {
            item.migrateLegacyEquippedStateIfNeeded(activeSpecies: activeSpecies)
        }
    }
}
