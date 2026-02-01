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
    var createdAt: Date

    init(
        id: UUID = UUID(),
        type: InventoryItemType,
        name: String,
        price: Int,
        owned: Bool = false,
        equipped: Bool = false,
        assetName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.price = price
        self.owned = owned
        self.equipped = equipped
        self.assetName = assetName
        self.createdAt = createdAt
    }
}
