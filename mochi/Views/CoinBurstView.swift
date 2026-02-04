import SwiftUI

struct CoinBurstView: View {
    let amount: Int
    let onComplete: () -> Void

    @State private var animate = false

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppColors.coinPill)
                    .frame(width: 28, height: 28)
                Image(systemName: "circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.accentPeach)
            }

            Text("+\(amount)")
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
                .foregroundStyle(AppColors.accentPeach)
                .offset(x: 18, y: -14)
                .opacity(animate ? 1 : 0)
                .scaleEffect(animate ? 1.1 : 0.6)
        )
        .offset(y: animate ? -32 : 12)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onComplete()
            }
        }
    }
}

#Preview {
    CoinBurstView(amount: 12, onComplete: { })
        .padding()
        .background(Color.appBackground)
}
