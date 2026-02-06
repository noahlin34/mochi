import SwiftUI

struct SplashView: View {
    @State private var isFloating = false
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            AppColors.cardGreen
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image("LaunchMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .scaleEffect(isPulsing ? 1.04 : 0.98)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)

                Text("mochi")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Build habits. Care for your pet.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.75))
            }
            .offset(y: isFloating ? -20 : -12)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isFloating.toggle()
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing.toggle()
            }
        }
    }
}

#Preview {
    SplashView()
}
