import SwiftUI

private struct TabBarHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var tabBarHeight: CGFloat {
        get { self[TabBarHeightKey.self] }
        set { self[TabBarHeightKey.self] = newValue }
    }
}

struct TabBarHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    func trackTabBarHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: TabBarHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(TabBarHeightPreferenceKey.self, perform: onChange)
    }
}
