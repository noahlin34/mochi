import XCTest
@testable import mochi

final class PetReactionControllerTests: XCTestCase {
    private static var retainedControllers: [PetReactionController] = []

    @MainActor
    private func makeController() -> PetReactionController {
        let controller = PetReactionController()
        Self.retainedControllers.append(controller)
        return controller
    }

    @MainActor
    func testTriggerMoodBoostDoesNotPulseWhenNoPositiveDeltas() {
        let controller = makeController()

        let fired = controller.triggerMoodBoostIfNeeded(
            energyDelta: 0,
            hungerDelta: -2,
            cleanlinessDelta: 0
        )

        XCTAssertFalse(fired)
        XCTAssertEqual(controller.moodBoostPulse, 0)
    }

    @MainActor
    func testTriggerMoodBoostPulsesWhenSingleDeltaIsPositive() {
        let controller = makeController()

        let fired = controller.triggerMoodBoostIfNeeded(
            energyDelta: 3,
            hungerDelta: 0,
            cleanlinessDelta: 0
        )

        XCTAssertTrue(fired)
        XCTAssertEqual(controller.moodBoostPulse, 1)
    }

    @MainActor
    func testTriggerMoodBoostPulsesOnlyOnceWhenMultipleDeltasArePositive() {
        let controller = makeController()

        let fired = controller.triggerMoodBoostIfNeeded(
            energyDelta: 3,
            hungerDelta: 5,
            cleanlinessDelta: 2
        )

        XCTAssertTrue(fired)
        XCTAssertEqual(controller.moodBoostPulse, 1)
    }

    @MainActor
    func testTriggerMoodBoostPulsesMonotonicallyAcrossRepeatedCalls() {
        let controller = makeController()

        XCTAssertTrue(
            controller.triggerMoodBoostIfNeeded(
                energyDelta: 1,
                hungerDelta: 0,
                cleanlinessDelta: 0
            )
        )
        XCTAssertTrue(
            controller.triggerMoodBoostIfNeeded(
                energyDelta: 0,
                hungerDelta: 2,
                cleanlinessDelta: 0
            )
        )
        XCTAssertFalse(
            controller.triggerMoodBoostIfNeeded(
                energyDelta: 0,
                hungerDelta: 0,
                cleanlinessDelta: 0
            )
        )
        XCTAssertTrue(
            controller.triggerMoodBoostIfNeeded(
                energyDelta: 0,
                hungerDelta: 0,
                cleanlinessDelta: 3
            )
        )

        XCTAssertEqual(controller.moodBoostPulse, 3)
    }
}
