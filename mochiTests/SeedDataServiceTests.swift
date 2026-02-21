import SwiftData
import XCTest
@testable import mochi

final class SeedDataServiceTests: XCTestCase {
    @MainActor
    func testSeedIfNeededCreatesInitialDataOnFreshContext() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()

        SeedDataService.seedIfNeeded(context: context)

        let appStates = try context.fetch(FetchDescriptor<AppState>())
        let pets = try context.fetch(FetchDescriptor<Pet>())
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let items = try context.fetch(FetchDescriptor<InventoryItem>())

        XCTAssertEqual(appStates.count, 1)
        XCTAssertEqual(pets.count, 1)
        XCTAssertEqual(habits.count, 2)
        XCTAssertGreaterThanOrEqual(items.count, 10)

        let appState = try XCTUnwrap(appStates.first)
        XCTAssertEqual(appState.selectedPetSpecies, .dog)
        XCTAssertFalse(appState.tutorialSeen)
        XCTAssertEqual(appState.currentStreak, 0)

        let pet = try XCTUnwrap(pets.first)
        XCTAssertEqual(pet.name, "Mochi")
        XCTAssertEqual(pet.species, .dog)
        XCTAssertEqual(pet.coins, 20)

        XCTAssertTrue(items.contains(where: { $0.assetName == "top_hat" && $0.equipStyle == .overlay }))
        XCTAssertTrue(items.contains(where: { $0.assetName == "crown_overlay" && $0.equipStyle == .overlay }))
        XCTAssertFalse(items.contains(where: isLegacyRoyalCrown))
    }

    @MainActor
    func testSeedIfNeededIsIdempotentAcrossMultipleRuns() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()

        SeedDataService.seedIfNeeded(context: context)

        let firstCounts = SnapshotCounts(
            appStates: try context.fetch(FetchDescriptor<AppState>()).count,
            pets: try context.fetch(FetchDescriptor<Pet>()).count,
            habits: try context.fetch(FetchDescriptor<Habit>()).count,
            items: try context.fetch(FetchDescriptor<InventoryItem>()).count
        )

        SeedDataService.seedIfNeeded(context: context)

        let secondCounts = SnapshotCounts(
            appStates: try context.fetch(FetchDescriptor<AppState>()).count,
            pets: try context.fetch(FetchDescriptor<Pet>()).count,
            habits: try context.fetch(FetchDescriptor<Habit>()).count,
            items: try context.fetch(FetchDescriptor<InventoryItem>()).count
        )

        XCTAssertEqual(firstCounts, secondCounts)
    }

    @MainActor
    func testSeedIfNeededUpsertsExistingCatalogEntries() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        context.insert(AppState())

        let staleTopHat = InventoryItem(
            type: .outfit,
            name: "Old Hat",
            price: 1,
            owned: false,
            equipped: false,
            assetName: "top_hat",
            petSpecies: nil,
            equipStyle: .overlay,
            outfitClass: .accessory
        )
        context.insert(staleTopHat)

        SeedDataService.seedIfNeeded(context: context)

        let items = try context.fetch(FetchDescriptor<InventoryItem>())
        let updatedTopHat = try XCTUnwrap(items.first(where: {
            $0.type == .outfit
                && $0.assetName == "top_hat"
                && $0.petSpecies == nil
                && $0.equipStyle == .overlay
        }))

        XCTAssertEqual(updatedTopHat.name, "Top Hat")
        XCTAssertEqual(updatedTopHat.price, 50)
        XCTAssertEqual(updatedTopHat.outfitClass, .hat)
    }

    @MainActor
    func testSeedIfNeededRemovesLegacyRoyalCrownFromExistingCatalog() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
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
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        context.insert(AppState())

        SeedDataService.seedIfNeeded(context: context)

        let items = try context.fetch(FetchDescriptor<InventoryItem>())
        XCTAssertFalse(items.contains(where: isLegacyRoyalCrown))
    }

    private func isLegacyRoyalCrown(_ item: InventoryItem) -> Bool {
        item.type == .outfit
            && item.assetName == "crown"
            && item.petSpecies == .cat
            && item.equipStyle == .replaceSprite
    }
}

private struct SnapshotCounts: Equatable {
    let appStates: Int
    let pets: Int
    let habits: Int
    let items: Int
}
