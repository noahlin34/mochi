import Foundation
import Combine

@MainActor
final class PetReactionController: ObservableObject {
    @Published var pulse: Int = 0

    func trigger() {
        pulse += 1
    }
}
