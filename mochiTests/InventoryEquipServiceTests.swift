import XCTest
@testable import mochi

final class InventoryEquipServiceTests: XCTestCase {
    @MainActor
    func testApplyEquipUnequipsExistingSameClassItem() {
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
            in: [equippedHat, newHat]
        )

        XCTAssertTrue(changed)
        XCTAssertFalse(equippedHat.equipped)
        XCTAssertTrue(newHat.equipped)
    }

    @MainActor
    func testApplyEquipKeepsOtherClassesEquipped() {
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
            in: [equippedAccessory, newHat]
        )

        XCTAssertTrue(changed)
        XCTAssertTrue(equippedAccessory.equipped)
        XCTAssertTrue(newHat.equipped)
    }

    @MainActor
    func testApplyEquipUsesClassExclusivityAcrossEquipStyles() {
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
            in: [spriteBody, overlayBody]
        )

        XCTAssertTrue(changed)
        XCTAssertFalse(spriteBody.equipped)
        XCTAssertTrue(overlayBody.equipped)
    }

    @MainActor
    func testApplyEquipRoomUnequipsOtherRoomsOnly() {
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
            in: [equippedRoom, newRoom, equippedHat]
        )

        XCTAssertTrue(changed)
        XCTAssertFalse(equippedRoom.equipped)
        XCTAssertTrue(newRoom.equipped)
        XCTAssertTrue(equippedHat.equipped)
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
            in: [ownedHat, unownedHat]
        )

        XCTAssertFalse(changed)
        XCTAssertTrue(ownedHat.equipped)
        XCTAssertFalse(unownedHat.equipped)
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
