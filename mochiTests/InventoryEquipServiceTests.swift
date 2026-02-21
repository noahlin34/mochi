import XCTest
@testable import mochi

final class InventoryEquipServiceTests: XCTestCase {
    @MainActor
    func testApplyEquipStacksOverlayItemsInSameClassForActiveSpecies() {
        let equippedHat = InventoryItem(
            type: .outfit,
            name: "Top Hat",
            price: 50,
            owned: true,
            equipped: true,
            assetName: "top_hat",
            equipStyle: .overlay,
            outfitClass: .hat
        )
        let newHat = InventoryItem(
            type: .outfit,
            name: "Baseball Hat",
            price: 50,
            owned: true,
            equipped: false,
            assetName: "baseball_hat",
            equipStyle: .overlay,
            outfitClass: .hat
        )

        let changed = InventoryEquipService.applyEquip(
            for: newHat,
            in: [equippedHat, newHat],
            activeSpecies: .dog
        )

        XCTAssertTrue(changed)
        XCTAssertTrue(equippedHat.isEquipped(for: .dog))
        XCTAssertTrue(newHat.isEquipped(for: .dog))
    }

    @MainActor
    func testApplyEquipUnequipsExistingReplaceSpriteItemInSameClass() {
        let equippedBody = InventoryItem(
            type: .outfit,
            name: "Bandana",
            price: 30,
            owned: true,
            equipped: true,
            assetName: "bandana",
            petSpecies: .dog,
            equipStyle: .replaceSprite,
            outfitClass: .body
        )
        let newBody = InventoryItem(
            type: .outfit,
            name: "Scarf",
            price: 30,
            owned: true,
            equipped: false,
            assetName: "scarf",
            petSpecies: .dog,
            equipStyle: .replaceSprite,
            outfitClass: .body
        )

        let changed = InventoryEquipService.applyEquip(
            for: newBody,
            in: [equippedBody, newBody],
            activeSpecies: .dog
        )

        XCTAssertTrue(changed)
        XCTAssertFalse(equippedBody.isEquipped(for: .dog))
        XCTAssertTrue(newBody.isEquipped(for: .dog))
    }

    @MainActor
    func testApplyEquipKeepsOtherClassesEquippedForActiveSpecies() {
        let equippedAccessory = InventoryItem(
            type: .outfit,
            name: "Charm",
            price: 45,
            owned: true,
            equipped: true,
            assetName: "sparkles",
            equipStyle: .overlay,
            outfitClass: .accessory
        )
        let newHat = InventoryItem(
            type: .outfit,
            name: "Top Hat",
            price: 50,
            owned: true,
            equipped: false,
            assetName: "top_hat",
            equipStyle: .overlay,
            outfitClass: .hat
        )

        let changed = InventoryEquipService.applyEquip(
            for: newHat,
            in: [equippedAccessory, newHat],
            activeSpecies: .dog
        )

        XCTAssertTrue(changed)
        XCTAssertTrue(equippedAccessory.isEquipped(for: .dog))
        XCTAssertTrue(newHat.isEquipped(for: .dog))
    }

    @MainActor
    func testApplyEquipDoesNotForceExclusivityAcrossEquipStyles() {
        let spriteBody = InventoryItem(
            type: .outfit,
            name: "Bandana",
            price: 30,
            owned: true,
            equipped: true,
            assetName: "bandana",
            petSpecies: .dog,
            equipStyle: .replaceSprite,
            outfitClass: .body
        )
        let overlayBody = InventoryItem(
            type: .outfit,
            name: "Body Overlay",
            price: 30,
            owned: true,
            equipped: false,
            assetName: "body_overlay",
            equipStyle: .overlay,
            outfitClass: .body
        )

        let changed = InventoryEquipService.applyEquip(
            for: overlayBody,
            in: [spriteBody, overlayBody],
            activeSpecies: .dog
        )

        XCTAssertTrue(changed)
        XCTAssertTrue(spriteBody.isEquipped(for: .dog))
        XCTAssertTrue(overlayBody.isEquipped(for: .dog))
    }

    @MainActor
    func testApplyEquipRoomUnequipsOtherRoomsOnlyForActiveSpecies() {
        let equippedRoom = InventoryItem(
            type: .room,
            name: "Cozy Home",
            price: 40,
            owned: true,
            equipped: true,
            assetName: "house"
        )
        let newRoom = InventoryItem(
            type: .room,
            name: "Beach Resort",
            price: 55,
            owned: true,
            equipped: false,
            assetName: "beach"
        )
        let equippedHat = InventoryItem(
            type: .outfit,
            name: "Top Hat",
            price: 50,
            owned: true,
            equipped: true,
            assetName: "top_hat",
            equipStyle: .overlay,
            outfitClass: .hat
        )

        let changed = InventoryEquipService.applyEquip(
            for: newRoom,
            in: [equippedRoom, newRoom, equippedHat],
            activeSpecies: .dog
        )

        XCTAssertTrue(changed)
        XCTAssertFalse(equippedRoom.isEquipped(for: .dog))
        XCTAssertTrue(newRoom.isEquipped(for: .dog))
        XCTAssertTrue(equippedHat.isEquipped(for: .dog))
    }

    @MainActor
    func testApplyEquipFailsForUnownedItem() {
        let ownedHat = InventoryItem(
            type: .outfit,
            name: "Top Hat",
            price: 50,
            owned: true,
            equipped: true,
            assetName: "top_hat",
            equipStyle: .overlay,
            outfitClass: .hat
        )
        let unownedHat = InventoryItem(
            type: .outfit,
            name: "Baseball Hat",
            price: 50,
            owned: false,
            equipped: false,
            assetName: "baseball_hat",
            equipStyle: .overlay,
            outfitClass: .hat
        )

        let changed = InventoryEquipService.applyEquip(
            for: unownedHat,
            in: [ownedHat, unownedHat],
            activeSpecies: .dog
        )

        XCTAssertFalse(changed)
        XCTAssertTrue(ownedHat.isEquipped(for: .dog))
        XCTAssertFalse(unownedHat.isEquipped(for: .dog))
    }

    @MainActor
    func testApplyEquipDoesNotUnequipOtherSpeciesState() {
        let topHat = InventoryItem(
            type: .outfit,
            name: "Top Hat",
            price: 50,
            owned: true,
            equipped: false,
            assetName: "top_hat",
            equipStyle: .overlay,
            outfitClass: .hat
        )
        topHat.setEquipped(true, for: .dog)

        let baseballHat = InventoryItem(
            type: .outfit,
            name: "Baseball Hat",
            price: 50,
            owned: true,
            equipped: false,
            assetName: "baseball_hat",
            equipStyle: .overlay,
            outfitClass: .hat
        )

        let changed = InventoryEquipService.applyEquip(
            for: baseballHat,
            in: [topHat, baseballHat],
            activeSpecies: .cat
        )

        XCTAssertTrue(changed)
        XCTAssertTrue(topHat.isEquipped(for: .dog))
        XCTAssertFalse(topHat.isEquipped(for: .cat))
        XCTAssertTrue(baseballHat.isEquipped(for: .cat))
        XCTAssertFalse(baseballHat.isEquipped(for: .dog))
    }

    @MainActor
    func testLegacyMigrationAssignsSharedEquippedItemToActiveSpecies() {
        let sharedHat = InventoryItem(
            type: .outfit,
            name: "Top Hat",
            price: 50,
            owned: true,
            equipped: true,
            assetName: "top_hat",
            equipStyle: .overlay,
            outfitClass: .hat
        )

        InventoryEquipService.migrateLegacyEquippedStatesIfNeeded(
            in: [sharedHat],
            activeSpecies: .dog
        )

        XCTAssertTrue(sharedHat.isEquipped(for: .dog))
        XCTAssertFalse(sharedHat.isEquipped(for: .cat))
    }

    @MainActor
    func testLegacyMigrationUsesItemSpeciesWhenPresent() {
        let speciesLockedBandana = InventoryItem(
            type: .outfit,
            name: "Bandana",
            price: 30,
            owned: true,
            equipped: true,
            assetName: "bandana",
            petSpecies: .dog,
            equipStyle: .replaceSprite,
            outfitClass: .body
        )

        InventoryEquipService.migrateLegacyEquippedStatesIfNeeded(
            in: [speciesLockedBandana],
            activeSpecies: .cat
        )

        XCTAssertTrue(speciesLockedBandana.isEquipped(for: .dog))
        XCTAssertFalse(speciesLockedBandana.isEquipped(for: .cat))
    }

    @MainActor
    func testOutfitClassFallbackUsesBodyForInvalidRawValue() {
        let item = InventoryItem(
            type: .outfit,
            name: "Mystery",
            price: 1,
            owned: false,
            equipped: false,
            assetName: "mystery",
            outfitClass: .hat
        )
        item.outfitClassRaw = "not-a-class"

        XCTAssertEqual(item.outfitClass, .body)
    }
}
