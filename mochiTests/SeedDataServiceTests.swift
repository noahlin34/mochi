import SwiftData
import XCTest
@testable import mochi

final class SeedDataServiceTests: XCTestCase {
    @MainActor
    func testSeedIfNeededRemovesLegacyRoyalCrownFromExistingCatalog() throws {
        let context = try makeInMemoryContext()
        context.insert(AppState())

        let legacyRoyalCrown = InventoryItem(
            type: .outfit,
            name: "Royal Crown",
            price: 60,
            owned: true,
            equipped: true,
            assetName: "crown",
            petSpecies: .cat,
            equipStyle: .replaceSprite
        )
        let overlayCrown = InventoryItem(
            type: .outfit,
            name: "Crown",
            price: 55,
            owned: true,
            equipped: true,
            assetName: "crown_overlay",
            equipStyle: .overlay,
            outfitClass: .hat
        )
        context.insert(legacyRoyalCrown)
        context.insert(overlayCrown)

        SeedDataService.seedIfNeeded(context: context)

        let items = try context.fetch(FetchDescriptor<InventoryItem>())
        XCTAssertFalse(items.contains(where: isLegacyRoyalCrown))
        XCTAssertTrue(
            items.contains(where: { item in
                item.assetName == "crown_overlay"
                    && item.equipStyle == .overlay
            })
        )
    }

    @MainActor
    func testSeedIfNeededDoesNotSeedLegacyRoyalCrownInFreshCatalog() throws {
        let context = try makeInMemoryContext()
        context.insert(AppState())

        SeedDataService.seedIfNeeded(context: context)

        let items = try context.fetch(FetchDescriptor<InventoryItem>())
        XCTAssertFalse(items.contains(where: isLegacyRoyalCrown))
    }

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([
            Habit.self,
            Pet.self,
            InventoryItem.self,
            AppState.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return container.mainContext
    }

    private func isLegacyRoyalCrown(_ item: InventoryItem) -> Bool {
        item.type == .outfit
            && item.assetName == "crown"
            && item.petSpecies == .cat
            && item.equipStyle == .replaceSprite
    }
}
