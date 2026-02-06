import SwiftUI

struct SplashView: View {
    @State private var enteredMotion = false
    @State private var bobbing = false
    @State private var pulsing = false
    @State private var spinning = false
    @State private var drifting = false
    @State private var dotPulse = false

    var body: some View {
        ZStack {
            AppColors.cardGreen
                .ignoresSafeArea()

            Circle()
                .fill(enteredMotion ? AppColors.cardYellow : AppColors.cardGreen)
                .frame(width: 240, height: 240)
                .offset(x: drifting ? -120 : -86, y: -290)

            Circle()
                .fill(enteredMotion ? AppColors.cardPeach : AppColors.cardGreen)
                .frame(width: 260, height: 260)
                .offset(x: drifting ? 146 : 106, y: 304)

            Circle()
                .fill(enteredMotion ? AppColors.cardPurple : AppColors.cardGreen)
                .frame(width: 170, height: 170)
                .offset(x: drifting ? 134 : 112, y: -250)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(
                            enteredMotion ? AppColors.accentPurple : Color.clear,
                            lineWidth: 7
                        )
                        .frame(width: 148, height: 148)
                        .rotationEffect(.degrees(spinning ? 360 : 0))

                    Image("LaunchBadge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 124, height: 124)
                        .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 10)
                        .scaleEffect(pulsing ? 1.04 : 1.0)
                }

                VStack(spacing: 8) {
                    Text("mochi")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Build habits. Care for your pet.")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                }

                HStack(spacing: 8) {
                    dot(active: dotPulse, delay: 0.0)
                    dot(active: dotPulse, delay: 0.1)
                    dot(active: dotPulse, delay: 0.2)
                }
                .padding(.top, 6)
            }
            .offset(y: bobbing ? -20 : -12)
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    private func dot(active: Bool, delay: Double) -> some View {
        Circle()
            .fill(active ? AppColors.accentPurple : AppColors.mutedPurple)
            .frame(width: active ? 8 : 6, height: active ? 8 : 6)
            .animation(
                .easeInOut(duration: 0.55)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: active
            )
    }

    private func startAnimationSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                enteredMotion = true
            }

            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                bobbing.toggle()
            }

            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulsing.toggle()
            }

            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                spinning.toggle()
            }

            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                drifting.toggle()
            }

            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                dotPulse.toggle()
            }
        }
    }
}

#Preview {
    SplashView()
}
