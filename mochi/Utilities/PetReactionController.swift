import Foundation
import Combine
import SwiftUI

@MainActor
final class PetReactionController: ObservableObject {
    @Published var pulse: Int = 0
    @Published var moodBoostPulse: Int = 0
    @Published var coinBurst: CoinBurst?
    @Published var statBursts: [StatBurst] = []

    private let statBurstLifetime: TimeInterval = 2.25

    func trigger() {
        pulse += 1
    }

    @discardableResult
    func triggerMoodBoostIfNeeded(energyDelta: Int, hungerDelta: Int, cleanlinessDelta: Int) -> Bool {
        let shouldBoost = energyDelta > 0 || hungerDelta > 0 || cleanlinessDelta > 0
        guard shouldBoost else { return false }
        moodBoostPulse += 1
        return true
    }

    func triggerCoins(amount: Int) {
        guard amount > 0 else { return }
        coinBurst = CoinBurst(amount: amount)
    }

    func clearCoinBurst() {
        coinBurst = nil
    }

    func triggerStatBurst(kind: PetStatKind, amount: Int) {
        guard amount > 0 else { return }
        let burst = StatBurst(kind: kind, amount: amount)
        statBursts.append(burst)

        DispatchQueue.main.asyncAfter(deadline: .now() + statBurstLifetime) { [weak self] in
            self?.statBursts.removeAll { $0.id == burst.id }
        }
    }
}

struct CoinBurst: Identifiable, Equatable {
    let id = UUID()
    let amount: Int
}

enum PetStatKind: String, CaseIterable {
    case energy
    case hunger
    case cleanliness

    var iconName: String {
        switch self {
        case .energy:
            return "bolt.fill"
        case .hunger:
            return "fork.knife"
        case .cleanliness:
            return "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .energy:
            return AppColors.accentPeach
        case .hunger:
            return .orange
        case .cleanliness:
            return .blue
        }
    }

    var label: String {
        switch self {
        case .energy:
            return "Energy"
        case .hunger:
            return "Hunger"
        case .cleanliness:
            return "Cleanliness"
        }
    }
}

struct StatBurst: Identifiable, Equatable {
    let id = UUID()
    let kind: PetStatKind
    let amount: Int
}
