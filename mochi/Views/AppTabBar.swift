import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case habits
    case store
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .habits: return "Habits"
        case .store: return "Shop"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .habits: return "sparkles"
        case .store: return "bag.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct AppTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 20) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(selection == tab ? AppColors.accentPurple : .secondary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(selection == tab ? AppColors.cardPurple : Color.clear)
                            )

                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(selection == tab ? AppColors.accentPurple : .secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppColors.tabBarBackground)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
        )
        .padding(.horizontal, 24)
    }
}
