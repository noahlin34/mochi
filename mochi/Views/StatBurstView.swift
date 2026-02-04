import SwiftUI

struct StatBurstView: View {
    let burst: StatBurst

    @State private var animate = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(burst.kind.tint.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: burst.kind.iconName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(burst.kind.tint)
                )

            Text("+\(burst.amount) \(burst.kind.label)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
        .overlay(
            Image(systemName: "sparkles")
                .foregroundStyle(burst.kind.tint)
                .offset(x: 16, y: -14)
                .opacity(animate ? 1 : 0)
                .scaleEffect(animate ? 1.1 : 0.6)
        )
        .offset(y: animate ? -26 : 10)
        .opacity(animate ? 1 : 0)
        .scaleEffect(animate ? 1 : 0.9)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animate = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeIn(duration: 0.2)) {
                    animate = false
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatBurstView(burst: StatBurst(kind: .energy, amount: 3))
        StatBurstView(burst: StatBurst(kind: .hunger, amount: 5))
        StatBurstView(burst: StatBurst(kind: .cleanliness, amount: 2))
    }
    .padding()
    .background(Color.appBackground)
}
