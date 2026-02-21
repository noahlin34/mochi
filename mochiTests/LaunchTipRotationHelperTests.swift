import XCTest
@testable import mochi

final class LaunchTipRotationHelperTests: XCTestCase {
    func testSelectRandomTipReturnsDeterministicChoiceWithInjectedGenerator() {
        var randomGeneratorA = SeededRandomGenerator(seed: 42)
        var randomGeneratorB = SeededRandomGenerator(seed: 42)
        let tips = ["Tip A", "Tip B", "Tip C"]

        let nextA = LaunchTipRotationHelper.selectRandomTip(
            tips: tips,
            using: &randomGeneratorA
        )
        let nextB = LaunchTipRotationHelper.selectRandomTip(
            tips: tips,
            using: &randomGeneratorB
        )

        XCTAssertEqual(nextA, nextB)
        XCTAssertNotNil(nextA)
        XCTAssertTrue(tips.contains(nextA ?? ""))
    }

    func testSelectRandomTipReturnsOnlyTipWhenSingleTipExists() {
        var randomGenerator = SeededRandomGenerator(seed: 123)
        let tips = ["Only Tip"]

        let next = LaunchTipRotationHelper.selectRandomTip(
            tips: tips,
            using: &randomGenerator
        )

        XCTAssertEqual(next, "Only Tip")
    }

    func testSelectRandomTipReturnsNilForEmptyTips() {
        var randomGenerator = SeededRandomGenerator(seed: 999)
        let tips: [String] = []

        let next = LaunchTipRotationHelper.selectRandomTip(
            tips: tips,
            using: &randomGenerator
        )

        XCTAssertNil(next)
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

private struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // LCG for deterministic but non-degenerate test entropy.
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
