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

    static func selectNextTip(
        tips: [String],
        previous: String?
    ) -> String? {
        var randomGenerator = SystemRandomNumberGenerator()
        return selectNextTip(tips: tips, previous: previous, using: &randomGenerator)
    }

    static func selectNextTip<R: RandomNumberGenerator>(
        tips: [String],
        previous: String?,
        using randomGenerator: inout R
    ) -> String? {
        guard !tips.isEmpty else { return nil }
        guard tips.count > 1 else { return tips[0] }

        let filteredTips = tips.filter { $0 != previous }
        let eligibleTips = filteredTips.isEmpty ? tips : filteredTips
        let randomIndex = Int.random(in: 0..<eligibleTips.count, using: &randomGenerator)
        return eligibleTips[randomIndex]
    }
}
