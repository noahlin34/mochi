import Foundation

enum LaunchTipRotationHelper {
    static func isWindowActive(
        startedAt: Date?,
        now: Date,
        windowDuration: TimeInterval
    ) -> Bool {
        guard let startedAt, windowDuration > 0 else { return false }
        return now.timeIntervalSince(startedAt) < windowDuration
    }

    static func selectRandomTip(tips: [String]) -> String? {
        var randomGenerator = SystemRandomNumberGenerator()
        return selectRandomTip(tips: tips, using: &randomGenerator)
    }

    static func selectRandomTip<R: RandomNumberGenerator>(
        tips: [String],
        using randomGenerator: inout R
    ) -> String? {
        guard !tips.isEmpty else { return nil }
        let randomIndex = Int.random(in: 0..<tips.count, using: &randomGenerator)
        return tips[randomIndex]
    }
}
