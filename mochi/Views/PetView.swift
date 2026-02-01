import SwiftUI

struct PetView: View {
    let species: PetSpecies
    let outfitSymbol: String?
    let isBouncing: Bool

    var body: some View {
        ZStack {
            petBody
            petFace
            petPaws
            if let outfitSymbol {
                Image(systemName: outfitSymbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(.black.opacity(0.2)))
                    .offset(y: 36)
            }
        }
        .frame(width: 160, height: 160)
        .scaleEffect(isBouncing ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isBouncing)
    }

    private var petBody: some View {
        ZStack {
            switch species {
            case .cat:
                CatShape(color: .purple)
            case .dog:
                DogShape(color: .orange)
            case .bunny:
                BunnyShape(color: .pink)
            }
        }
    }

    private var petFace: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().fill(.white)
                Circle().fill(.black).frame(width: 8, height: 8)
            }
            .frame(width: 18, height: 18)

            ZStack {
                Circle().fill(.white)
                Circle().fill(.black).frame(width: 8, height: 8)
            }
            .frame(width: 18, height: 18)
        }
        .offset(y: -10)
    }

    private var petPaws: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.white.opacity(0.5))
                .frame(width: 20, height: 16)
            Circle()
                .fill(.white.opacity(0.5))
                .frame(width: 20, height: 16)
        }
        .offset(y: 38)
    }
}

struct RoomBackgroundView: View {
    let assetName: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.35))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.45))
                .frame(width: 120, height: 80)
                .offset(x: 60, y: -20)

            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 60, height: 60)
                .offset(x: -90, y: 60)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.25))
                .frame(width: 70, height: 70)
                .offset(x: 90, y: 80)

            if let assetName {
                Image(systemName: assetName)
                    .font(.system(size: 54))
                    .foregroundStyle(.white.opacity(0.6))
                    .offset(y: 40)
            }
        }
    }
}

private struct CatShape: View {
    let color: Color

    var body: some View {
        ZStack {
            Triangle()
                .fill(color.opacity(0.9))
                .frame(width: 30, height: 26)
                .offset(x: -30, y: -50)
            Triangle()
                .fill(color.opacity(0.9))
                .frame(width: 30, height: 26)
                .offset(x: 30, y: -50)
            Circle()
                .fill(color)
                .frame(width: 140, height: 140)
        }
    }
}

private struct DogShape: View {
    let color: Color

    var body: some View {
        ZStack {
            Capsule()
                .fill(color.opacity(0.85))
                .frame(width: 30, height: 60)
                .offset(x: -60, y: -20)
            Capsule()
                .fill(color.opacity(0.85))
                .frame(width: 30, height: 60)
                .offset(x: 60, y: -20)
            RoundedRectangle(cornerRadius: 55, style: .continuous)
                .fill(color)
                .frame(width: 150, height: 130)
        }
    }
}

private struct BunnyShape: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.opacity(0.9))
                .frame(width: 34, height: 90)
                .offset(x: -30, y: -60)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.opacity(0.9))
                .frame(width: 34, height: 90)
                .offset(x: 30, y: -60)
            Circle()
                .fill(color)
                .frame(width: 140, height: 140)
        }
    }
}
