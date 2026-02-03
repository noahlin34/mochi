import SwiftUI

enum AppColors {
    static let background = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let cardPurple = Color(red: 0.86, green: 0.79, blue: 0.94)
    static let cardGreen = Color(red: 0.82, green: 0.93, blue: 0.85)
    static let cardYellow = Color(red: 0.99, green: 0.93, blue: 0.74)
    static let cardPeach = Color(red: 0.99, green: 0.87, blue: 0.80)
    static let accentPurple = Color(red: 0.53, green: 0.32, blue: 0.76)
    static let mutedPurple = Color(red: 0.72, green: 0.62, blue: 0.82)
    static let accentPeach = Color(red: 0.94, green: 0.55, blue: 0.42)
    static let textPrimary = Color(red: 0.20, green: 0.18, blue: 0.24)
    static let progressTrack = Color.black.opacity(0.08)
    static let tabBarBackground = Color.white.opacity(0.9)
    static let coinPill = Color(red: 0.99, green: 0.93, blue: 0.84)
}

extension ShapeStyle where Self == Color {
    static var appBackground: Color { AppColors.background }
}
