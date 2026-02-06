import SwiftUI

struct SplashView: View {
    @State private var isFloating = false
    @State private var isPulsing = false
    @State private var isWobbling = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.cardGreen.opacity(0.95),
                    AppColors.cardPurple.opacity(0.85),
                    AppColors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(AppColors.cardYellow.opacity(0.35))
                .frame(width: 300, height: 300)
                .offset(x: -120, y: -260)
                .blur(radius: 2)

            Circle()
                .fill(AppColors.cardPeach.opacity(0.35))
                .frame(width: 260, height: 260)
                .offset(x: 140, y: 260)
                .blur(radius: 2)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 122, height: 122)
                        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)

                    Circle()
                        .stroke(AppColors.accentPurple.opacity(0.2), lineWidth: 8)
                        .frame(width: 140, height: 140)

                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.accentPurple, AppColors.accentPeach],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(isPulsing ? 1.05 : 0.95)
                .rotationEffect(.degrees(isWobbling ? 2 : -2))

                Text("mochi")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Build habits. Care for your pet.")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.7))
            }
            .offset(y: isFloating ? -6 : 6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isFloating.toggle()
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                isPulsing.toggle()
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isWobbling.toggle()
            }
        }
    }
}

#Preview {
    SplashView()
}
