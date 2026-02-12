import XCTest
@testable import mochi

final class LaunchTipRotationHelperTests: XCTestCase {
    func testSelectNextTipAvoidsImmediateRepeatWhenMultipleTipsExist() {
        var randomGenerator = PredictableRandomGenerator()
        let tips = ["Tip A", "Tip B", "Tip C"]

        let next = LaunchTipRotationHelper.selectNextTip(
            tips: tips,
            previous: "Tip A",
            using: &randomGenerator
        )

        XCTAssertEqual(next, "Tip B")
        XCTAssertNotEqual(next, "Tip A")
    }

    func testSelectNextTipReturnsOnlyTipWhenSingleTipExists() {
        var randomGenerator = PredictableRandomGenerator()
        let tips = ["Only Tip"]

        let next = LaunchTipRotationHelper.selectNextTip(
            tips: tips,
            previous: "Only Tip",
            using: &randomGenerator
        )

        XCTAssertEqual(next, "Only Tip")
    }

    func testWindowActiveBeforeThirtySecondsAndInactiveAtThirtySeconds() {
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let activeNow = startedAt.addingTimeInterval(29.999)
        let inactiveNow = startedAt.addingTimeInterval(30)

        XCTAssertTrue(
            LaunchTipRotationHelper.isWindowActive(
                startedAt: startedAt,
                now: activeNow,
                windowDuration: 30
            )
        )

        XCTAssertFalse(
            LaunchTipRotationHelper.isWindowActive(
                startedAt: startedAt,
                now: inactiveNow,
                windowDuration: 30
            )
        )
    }
}

private struct PredictableRandomGenerator: RandomNumberGenerator {
    mutating func next() -> UInt64 {
        0
    }
}
