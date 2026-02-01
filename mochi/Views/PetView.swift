import SwiftUI

struct PetView: View {
    let species: PetSpecies
    let outfitSymbol: String?
    let isBouncing: Bool

    var body: some View {
        ZStack {
            petBody
            petFace
            if let outfitSymbol {
                Image(systemName: outfitSymbol)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(.black.opacity(0.25)))
                    .offset(y: 24)
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
                CatShape(color: .orange)
            case .dog:
                DogShape(color: .brown)
            case .bunny:
                BunnyShape(color: .pink)
            }
        }
    }

    private var petFace: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.black)
                .frame(width: 8, height: 8)
            Circle()
                .fill(.black)
                .frame(width: 8, height: 8)
        }
        .offset(y: -6)
    }
}

struct RoomBackgroundView: View {
    let assetName: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [.mint.opacity(0.4), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))

            if let assetName {
                Image(systemName: assetName)
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.6))
                    .offset(y: 40)
            }
        }
        .padding(16)
    }
}

private struct CatShape: View {
    let color: Color

    var body: some View {
        ZStack {
            Triangle()
                .fill(color)
                .frame(width: 34, height: 30)
                .offset(x: -30, y: -54)
            Triangle()
                .fill(color)
                .frame(width: 34, height: 30)
                .offset(x: 30, y: -54)
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
                .fill(color.opacity(0.9))
                .frame(width: 26, height: 60)
                .offset(x: -60, y: -20)
            Capsule()
                .fill(color.opacity(0.9))
                .frame(width: 26, height: 60)
                .offset(x: 60, y: -20)
            RoundedRectangle(cornerRadius: 45, style: .continuous)
                .fill(color)
                .frame(width: 150, height: 130)
        }
    }
}

private struct BunnyShape: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(color)
                .frame(width: 36, height: 90)
                .offset(x: -30, y: -60)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(color)
                .frame(width: 36, height: 90)
                .offset(x: 30, y: -60)
            Circle()
                .fill(color)
                .frame(width: 140, height: 140)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
