import Foundation

@MainActor
enum InventoryEquipService {
    @discardableResult
    static func applyEquip(for item: InventoryItem, in allItems: [InventoryItem]) -> Bool {
        guard item.owned else { return false }

        if item.type == .room {
            for other in allItems where other.type == .room && other.id != item.id {
                other.equipped = false
            }
        } else if item.type == .outfit {
            for other in allItems where
                other.type == .outfit
                    && other.equipped
                    && other.outfitClass == item.outfitClass
                    && other.id != item.id {
                other.equipped = false
            }
        }

        item.equipped = true
        return true
    }
}
