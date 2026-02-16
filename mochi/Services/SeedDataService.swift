import Foundation
import SwiftData

@MainActor
enum SeedDataService {
    // Seeds demo data and the store catalog on first launch.
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<AppState>()
        let existingState = (try? context.fetch(descriptor))?.first
        if existingState == nil {
            seedInitialData(context: context)
        }
        upsertCatalog(context: context)
    }

    private static func seedInitialData(context: ModelContext) {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfToday

        context.insert(
            AppState(
                lastDailyReset: startOfToday,
                lastWeeklyReset: startOfWeek,
                selectedPetSpecies: .dog,
                tutorialSeen: false,
                userName: "",
                lastStreakBonusDate: nil,
                currentStreak: 0
            )
        )

        context.insert(
            Pet(
                name: "Mochi",
                species: .dog,
                energy: 85,
                hunger: 80,
                cleanliness: 78,
                level: 1,
                xp: 0,
                coins: 20
            )
        )

        [
            Habit(title: "Walk 10 min", scheduleType: .xTimesPerWeek, targetPerWeek: 3),
            Habit(title: "Read 5 pages", scheduleType: .daily)
        ].forEach { context.insert($0) }
    }

    private static func upsertCatalog(context: ModelContext) {
        var existingItems = (try? context.fetch(FetchDescriptor<InventoryItem>())) ?? []
        removeDeprecatedCatalogItems(from: &existingItems, context: context)

        for seed in catalogSeeds {
            if let existing = existingItems.first(where: { item in
                item.type == seed.type
                    && item.assetName == seed.assetName
                    && item.petSpecies == seed.petSpecies
                    && item.equipStyle == seed.equipStyle
            }) {
                existing.name = seed.name
                existing.price = seed.price
                existing.outfitClass = seed.outfitClass
                continue
            }

            context.insert(
                InventoryItem(
                    type: seed.type,
                    name: seed.name,
                    price: seed.price,
                    owned: false,
                    equipped: false,
                    assetName: seed.assetName,
                    petSpecies: seed.petSpecies,
                    equipStyle: seed.equipStyle,
                    outfitClass: seed.outfitClass
                )
            )
        }
    }

    private static func removeDeprecatedCatalogItems(
        from existingItems: inout [InventoryItem],
        context: ModelContext
    ) {
        let deprecatedItems = existingItems.filter { item in
            isDeprecatedRoyalCrownItem(item)
        }
        for item in deprecatedItems {
            context.delete(item)
        }
        existingItems.removeAll { item in
            isDeprecatedRoyalCrownItem(item)
        }
    }

    private static func isDeprecatedRoyalCrownItem(_ item: InventoryItem) -> Bool {
        item.type == .outfit
            && item.assetName == "crown"
            && item.petSpecies == .cat
            && item.equipStyle == .replaceSprite
    }

    private static let catalogSeeds: [CatalogSeed] = [
        CatalogSeed(type: .outfit, name: "Bandana", price: 30, assetName: "bandana", petSpecies: .dog),
        CatalogSeed(type: .outfit, name: "Sparkle Charm", price: 45, assetName: "sparkles", petSpecies: .bunny),
        CatalogSeed(type: .outfit, name: "Snow Scarf", price: 35, assetName: "scarf", petSpecies: .penguin),
        CatalogSeed(type: .outfit, name: "Top Hat", price: 50, assetName: "top_hat", petSpecies: nil, equipStyle: .overlay, outfitClass: .hat),
        CatalogSeed(type: .outfit, name: "Baseball Hat", price: 50, assetName: "baseball_hat", petSpecies: nil, equipStyle: .overlay, outfitClass: .hat),
        CatalogSeed(type: .outfit, name: "Crown", price: 55, assetName: "crown_overlay", petSpecies: nil, equipStyle: .overlay, outfitClass: .hat),
        CatalogSeed(type: .room, name: "Cozy Home", price: 40, assetName: "house"),
        CatalogSeed(type: .room, name: "Beach Resort", price: 55, assetName: "beach"),
        CatalogSeed(type: .room, name: "Dreamy Bed", price: 70, assetName: "bed.double"),
        CatalogSeed(type: .room, name: "Igloo Village", price: 65, assetName: "igloo")
    ]

    private struct CatalogSeed {
        let type: InventoryItemType
        let name: String
        let price: Int
        let assetName: String
        let petSpecies: PetSpecies?
        let equipStyle: InventoryEquipStyle
        let outfitClass: InventoryOutfitClass

        init(
            type: InventoryItemType,
            name: String,
            price: Int,
            assetName: String,
            petSpecies: PetSpecies? = nil,
            equipStyle: InventoryEquipStyle = .replaceSprite,
            outfitClass: InventoryOutfitClass = .body
        ) {
            self.type = type
            self.name = name
            self.price = price
            self.assetName = assetName
            self.petSpecies = petSpecies
            self.equipStyle = equipStyle
            self.outfitClass = outfitClass
        }
    }
}
