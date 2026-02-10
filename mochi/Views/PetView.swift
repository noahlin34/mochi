import SwiftUI
import UIKit

struct PetView: View {
    let species: PetSpecies
    let baseOutfitSymbol: String?
    let overlaySymbols: [String]
    let isBouncing: Bool

    @State private var idleOffset: CGFloat = 0
    @State private var tailWag = false
    @State private var blink = false
    @State private var blinkTask: Task<Void, Never>?

    var body: some View {
        petBody
        .overlay {
            PetOverlayItemsView(species: species, overlaySymbols: overlaySymbols)
        }
        .frame(width: 170, height: 170)
        .offset(y: idleOffset)
        .scaleEffect(isBouncing ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isBouncing)
        .onAppear {
            startIdleAnimations()
        }
        .onChange(of: species) { _, _ in
            startIdleAnimations()
        }
        .onChange(of: baseOutfitSymbol) { _, _ in
            startIdleAnimations()
        }
        .onChange(of: overlaySymbols) { _, _ in
            startIdleAnimations()
        }
        .onDisappear {
            stopIdleAnimations()
        }
    }

    @ViewBuilder private var petBody: some View {
        switch species {
        case .cat:
            CatPetView(blink: blink, tailWag: tailWag)
        case .dog:
            DogPetView(blink: blink, tailWag: tailWag, outfitAssetName: baseOutfitSymbol)
        case .bunny:
            BunnyPetView(blink: blink)
        case .penguin:
            PenguinPetView(blink: blink, tailWag: tailWag, outfitAssetName: baseOutfitSymbol)
        case .lion:
            LionPetView(blink: blink, tailWag: tailWag, outfitAssetName: baseOutfitSymbol)
        }
    }

    private func startIdleAnimations() {
        blinkTask?.cancel()
        blinkTask = nil
        idleOffset = 0
        tailWag = false
        blink = false
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            idleOffset = 6
        }

        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            tailWag = true
        }

        blinkTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_600_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        blink = true
                    }
                }
                try? await Task.sleep(nanoseconds: 130_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.14)) {
                        blink = false
                    }
                }
            }
        }
    }

    private func stopIdleAnimations() {
        blinkTask?.cancel()
        blinkTask = nil
    }
}

private struct PetOverlayItemsView: View {
    let species: PetSpecies
    let overlaySymbols: [String]

    var body: some View {
        ZStack {
            ForEach(Array(overlaySymbols.enumerated()), id: \.offset) { _, assetName in
                PetOverlayItemView(species: species, assetName: assetName)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct PetOverlayItemView: View {
    let species: PetSpecies
    let assetName: String

    var body: some View {
        if let imageName = resolvedImageName() {
            let placement = resolvedPlacement(for: imageName)
            ChromaKeyedImage(
                name: imageName,
                applyChromaKey: true,
                keyColor: UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0),
                threshold: 0.18,
                smoothing: 0.05,
                resizable: true,
                contentMode: .fit
            )
            .frame(width: placement.size.width, height: placement.size.height)
            .offset(placement.offset)
            .rotationEffect(.degrees(placement.rotationDegrees))
        }
    }

    private func resolvedImageName() -> String? {
        for candidate in overlayAssetCandidates(for: species, assetName: assetName) {
            if UIImage(named: candidate) != nil {
                return candidate
            }
        }
        return nil
    }

    private func resolvedPlacement(for imageName: String) -> OverlayPlacement {
        if imageName != assetName {
            return OverlayPlacement(size: CGSize(width: 160, height: 160), offset: .zero, rotationDegrees: 0)
        }

        switch assetName {
        case "top_hat":
            return topHatPlacement(for: species)
        case "baseball_hat":
            return topHatPlacement(for: species)
        default:
            return OverlayPlacement(size: CGSize(width: 160, height: 160), offset: .zero, rotationDegrees: 0)
        }
    }

    private func topHatPlacement(for species: PetSpecies) -> OverlayPlacement {
        switch species {
        case .cat:
            return OverlayPlacement(size: CGSize(width: 86, height: 86), offset: CGSize(width: 0, height: -58), rotationDegrees: 0)
        case .dog:
            return OverlayPlacement(size: CGSize(width: 90, height: 90), offset: CGSize(width: 0, height: -60), rotationDegrees: 0)
        case .bunny:
            return OverlayPlacement(size: CGSize(width: 82, height: 82), offset: CGSize(width: 0, height: -74), rotationDegrees: 0)
        case .penguin:
            return OverlayPlacement(size: CGSize(width: 76, height: 76), offset: CGSize(width: 0, height: -60), rotationDegrees: 0)
        case .lion:
            return OverlayPlacement(size: CGSize(width: 90, height: 90), offset: CGSize(width: 0, height: -60), rotationDegrees: 0)
        }
    }

    private func overlayAssetCandidates(for species: PetSpecies, assetName: String) -> [String] {
        [
            "\(species.rawValue)_pet_overlay_\(assetName)",
            "\(species.rawValue)_overlay_\(assetName)",
            "pet_overlay_\(assetName)",
            "overlay_\(assetName)",
            assetName
        ]
    }

    private struct OverlayPlacement {
        let size: CGSize
        let offset: CGSize
        let rotationDegrees: Double
    }
}

struct LandscapeBackgroundView: View {
    let assetName: String?

    var body: some View {
        ZStack {
            if let imageName = resolvedBackgroundName() {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.05))
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.74, green: 0.90, blue: 0.90),
                                Color(red: 0.87, green: 0.95, blue: 0.93)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Circle()
                    .fill(Color(red: 0.70, green: 0.86, blue: 0.79))
                    .frame(width: 220, height: 160)
                    .offset(x: -120, y: 40)

                Circle()
                    .fill(Color(red: 0.63, green: 0.82, blue: 0.74))
                    .frame(width: 240, height: 170)
                    .offset(x: 120, y: 50)

                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(red: 0.70, green: 0.82, blue: 0.52))
                            .frame(height: 90)
                        Checkerboard(rows: 3, columns: 6)
                            .frame(height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .opacity(0.5)
                    }
                    .padding(.horizontal, 6)
                }

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func resolvedBackgroundName() -> String? {
        guard let assetName else { return nil }
        let prefixed = "room_\(assetName)"
        if UIImage(named: prefixed) != nil {
            return prefixed
        }
        if UIImage(named: assetName) != nil {
            return assetName
        }
        return nil
    }
}

private struct Checkerboard: View {
    let rows: Int
    let columns: Int

    var body: some View {
        GeometryReader { proxy in
            let cellWidth = proxy.size.width / CGFloat(columns)
            let cellHeight = proxy.size.height / CGFloat(rows)
            ZStack {
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<columns, id: \.self) { column in
                        if (row + column).isMultiple(of: 2) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: cellWidth, height: cellHeight)
                                .position(
                                    x: cellWidth * (CGFloat(column) + 0.5),
                                    y: cellHeight * (CGFloat(row) + 0.5)
                                )
                        }
                    }
                }
            }
        }
    }
}

private struct DogPetView: View {
    let blink: Bool
    let tailWag: Bool
    let outfitAssetName: String?

    var body: some View {
        let spriteName = resolvedSpriteName()
        let staticName = resolvedStaticName()

        if let spriteName {
            DogSpritePetView(imageName: spriteName)
        } else if let staticName {
            DogStaticPetView(imageName: staticName)
        } else {
            DogVectorPetView(blink: blink, tailWag: tailWag)
        }
    }

    private func resolvedSpriteName() -> String? {
        if let outfitAssetName,
           UIImage(named: "dog_spritesheet_\(outfitAssetName)") != nil {
            return "dog_spritesheet_\(outfitAssetName)"
        }
        if UIImage(named: "dog_spritesheet") != nil {
            return "dog_spritesheet"
        }
        return nil
    }

    private func resolvedStaticName() -> String? {
        if let outfitAssetName,
           UIImage(named: "dog_pet_\(outfitAssetName)") != nil {
            return "dog_pet_\(outfitAssetName)"
        }
        if UIImage(named: "dog_pet") != nil {
            return "dog_pet"
        }
        return nil
    }
}

private struct DogStaticPetView: View {
    let imageName: String

    @State private var breathe = false
    @State private var blink = false
    @State private var blinkTask: Task<Void, Never>?

    // Adjust these to align the eyes with your PNG.
    @AppStorage("dogEyeCenterX") private var eyeCenterXStorage: Double = -5
    @AppStorage("dogEyeCenterY") private var eyeCenterYStorage: Double = -21
    @AppStorage("dogEyeSeparation") private var eyeSeparationStorage: Double = 22
    @AppStorage("dogEyeSize") private var eyeSizeStorage: Double = 8

    var body: some View {
        ZStack {
            ChromaKeyedImage(name: imageName, resizable: true, contentMode: .fit)

            eyeOverlay
        }
        .frame(width: 160, height: 160)
        .scaleEffect(breathe ? 1.02 : 1.0)
        .rotationEffect(.degrees(breathe ? 0.6 : 0.0))
        .shadow(color: Color.black.opacity(0.18), radius: breathe ? 8 : 6, x: 0, y: 8)
        .padding(.top, 6)
        .onAppear {
            breathe = false
            blink = false
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
            blinkTask?.cancel()
            blinkTask = nil
            startBlinking()
        }
        .onDisappear {
            blinkTask?.cancel()
            blinkTask = nil
        }
    }

    private var eyeOverlay: some View {
        let eyeCenterX = CGFloat(eyeCenterXStorage)
        let eyeCenterY = CGFloat(eyeCenterYStorage)
        let halfSeparation = CGFloat(eyeSeparationStorage) / 2
        let eyeSize = CGFloat(eyeSizeStorage)

        return ZStack {
            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: eyeSize, height: eyeSize)
                .offset(x: eyeCenterX - halfSeparation, y: eyeCenterY)
                .scaleEffect(x: 1.0, y: blink ? 0.6 : 1.0, anchor: .center)

            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: eyeSize, height: eyeSize)
                .offset(x: eyeCenterX + halfSeparation, y: eyeCenterY)
                .scaleEffect(x: 1.0, y: blink ? 0.6 : 1.0, anchor: .center)
        }
    }

    private func startBlinking() {
        guard blinkTask == nil else { return }
        blinkTask = Task {
            while !Task.isCancelled {
                let wait = Double.random(in: 2.4...4.2)
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        blink = true
                    }
                }
                try? await Task.sleep(nanoseconds: 120_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.14)) {
                        blink = false
                    }
                }
            }
        }
    }
}

private struct DogSpritePetView: View {
    let imageName: String

    private let columns = 4
    private let rows = 4
    private let spriteInset: CGFloat = 40

    // Update these indices if you replace the sprite sheet.
    private let idleFrames = Array(0..<16)
    private let fps: Double = 8.0

    var body: some View {
        SpriteSheetAnimator(
            imageName: imageName,
            columns: columns,
            rows: rows,
            frames: idleFrames,
            fps: fps,
            size: CGSize(width: 150, height: 150),
            contentInset: spriteInset,
            applyChromaKey: true
        )
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 8)
        .padding(.top, 6)
    }
}

private struct DogVectorPetView: View {
    let blink: Bool
    let tailWag: Bool

    private let baseColor = Color(red: 0.95, green: 0.75, blue: 0.38)
    private let earColor = Color(red: 0.90, green: 0.64, blue: 0.30)
    private let outlineColor = Color(red: 0.25, green: 0.18, blue: 0.14)
    private let muzzleColor = Color(red: 0.99, green: 0.90, blue: 0.78)
    private let bandanaColor = Color(red: 0.52, green: 0.78, blue: 0.86)
    private let chestColor = Color(red: 0.99, green: 0.90, blue: 0.78)

    var body: some View {
        let tailAngle = tailWag ? Angle.degrees(18) : Angle.degrees(-8)
        ZStack {
            DogBase(color: outlineColor, earColor: earColor, tailAngle: tailAngle, chestColor: chestColor)
                .scaleEffect(1.06)
                .opacity(0.9)
            DogBase(color: .white, earColor: .white, tailAngle: tailAngle, chestColor: .white)
                .scaleEffect(1.03)
            DogBase(color: baseColor, earColor: earColor, tailAngle: tailAngle, chestColor: chestColor)

            DogFaceDetails(muzzleColor: muzzleColor, blink: blink)
            DogBandana(color: bandanaColor)
        }
        .frame(width: 170, height: 170)
        .shadow(color: outlineColor.opacity(0.18), radius: 6, x: 0, y: 8)
    }
}

private struct DogBase: View {
    let color: Color
    let earColor: Color
    let tailAngle: Angle
    let chestColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(earColor)
                .frame(width: 58, height: 82)
                .rotationEffect(.degrees(-8))
                .offset(x: -52, y: -20)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(earColor)
                .frame(width: 58, height: 82)
                .rotationEffect(.degrees(8))
                .offset(x: 52, y: -20)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.25))
                .frame(width: 40, height: 58)
                .rotationEffect(.degrees(-10))
                .offset(x: -52, y: -16)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.25))
                .frame(width: 40, height: 58)
                .rotationEffect(.degrees(10))
                .offset(x: 52, y: -16)

            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(color)
                .frame(width: 132, height: 112)
                .offset(y: -8)

            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(color)
                .frame(width: 116, height: 92)
                .offset(y: 42)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(chestColor.opacity(0.9))
                .frame(width: 74, height: 64)
                .offset(y: 34)

            Capsule()
                .fill(color)
                .frame(width: 56, height: 20)
                .rotationEffect(tailAngle, anchor: .leading)
                .offset(x: 72, y: 34)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color)
                .frame(width: 22, height: 36)
                .offset(x: -30, y: 64)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color)
                .frame(width: 22, height: 36)
                .offset(x: 30, y: 64)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(width: 28, height: 20)
                .offset(x: -32, y: 88)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(width: 28, height: 20)
                .offset(x: 32, y: 88)

            HStack(spacing: 10) {
                Capsule().fill(color.opacity(0.7)).frame(width: 10, height: 4)
                Capsule().fill(color.opacity(0.7)).frame(width: 10, height: 4)
            }
            .offset(y: 94)

            HStack(spacing: 26) {
                PawToeDetails(color: color.opacity(0.6))
                PawToeDetails(color: color.opacity(0.6))
            }
            .offset(y: 90)
        }
    }
}

private struct PawToeDetails: View {
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Capsule().fill(color).frame(width: 4, height: 2)
            Capsule().fill(color).frame(width: 4, height: 2)
            Capsule().fill(color).frame(width: 4, height: 2)
        }
    }
}

private struct DogFaceDetails: View {
    let muzzleColor: Color
    let blink: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 18, height: 12)
                .offset(x: -22, y: -30)
            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 18, height: 12)
                .offset(x: 22, y: -30)

            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 10, height: 10)
                .offset(x: -14, y: -38)
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 10, height: 10)
                .offset(x: 14, y: -38)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(muzzleColor)
                .frame(width: 72, height: 54)
                .offset(y: 10)

            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: 16, height: 16)
                .offset(x: -24, y: -6)
                .scaleEffect(y: blink ? 0.6 : 1.0)
            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: 16, height: 16)
                .offset(x: 24, y: -6)
                .scaleEffect(y: blink ? 0.6 : 1.0)

            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 5, height: 5)
                .offset(x: -28, y: -10)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 5, height: 5)
                .offset(x: 20, y: -10)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(red: 0.30, green: 0.20, blue: 0.16))
                .frame(width: 18, height: 12)
                .offset(y: 6)

            DogSmilePath()
                .stroke(Color(red: 0.28, green: 0.18, blue: 0.16), lineWidth: 2)
                .frame(width: 26, height: 12)
                .offset(y: 16)
        }
    }
}

private struct DogSmilePath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let midY = rect.midY
        path.move(to: CGPoint(x: midX - 10, y: midY - 2))
        path.addQuadCurve(
            to: CGPoint(x: midX, y: midY + 4),
            control: CGPoint(x: midX - 4, y: midY + 6)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX + 10, y: midY - 2),
            control: CGPoint(x: midX + 4, y: midY + 6)
        )
        return path
    }
}

private struct DogBandana: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.92))
                .frame(width: 74, height: 20)
                .offset(y: 38)

            Triangle()
                .fill(color)
                .frame(width: 52, height: 42)
                .offset(y: 50)

            HStack(spacing: 6) {
                PawPrint()
                PawPrint()
                PawPrint()
            }
            .offset(y: 50)
        }
    }
}

private struct PawPrint: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.7)).frame(width: 6, height: 6)
            Circle().fill(Color.white.opacity(0.7)).frame(width: 2, height: 2).offset(x: -4, y: -4)
            Circle().fill(Color.white.opacity(0.7)).frame(width: 2, height: 2).offset(x: 4, y: -4)
        }
    }
}

private struct CatPetView: View {
    let blink: Bool
    let tailWag: Bool

    private let baseColor = Color(red: 0.82, green: 0.68, blue: 0.93)
    private let outlineColor = Color(red: 0.25, green: 0.18, blue: 0.14)
    private let muzzleColor = Color(red: 0.98, green: 0.92, blue: 0.96)

    var body: some View {
        let tailAngle = tailWag ? Angle.degrees(10) : Angle.degrees(-6)
        ZStack {
            CatBase(color: outlineColor, tailAngle: tailAngle)
                .scaleEffect(1.06)
                .opacity(0.9)
            CatBase(color: .white, tailAngle: tailAngle)
                .scaleEffect(1.03)
            CatBase(color: baseColor, tailAngle: tailAngle)
            CatFaceDetails(muzzleColor: muzzleColor, blink: blink)
        }
        .frame(width: 170, height: 170)
    }
}

private struct CatBase: View {
    let color: Color
    let tailAngle: Angle

    var body: some View {
        ZStack {
            Triangle()
                .fill(color)
                .frame(width: 30, height: 26)
                .offset(x: -34, y: -62)
            Triangle()
                .fill(color)
                .frame(width: 30, height: 26)
                .offset(x: 34, y: -62)
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(color)
                .frame(width: 130, height: 116)
                .offset(y: -4)
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(color)
                .frame(width: 114, height: 92)
                .offset(y: 44)
            Capsule()
                .fill(color)
                .frame(width: 48, height: 16)
                .rotationEffect(tailAngle, anchor: .leading)
                .offset(x: -58, y: 40)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(width: 20, height: 32)
                .offset(x: -28, y: 64)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(width: 20, height: 32)
                .offset(x: 28, y: 64)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 24, height: 18)
                .offset(x: -28, y: 86)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 24, height: 18)
                .offset(x: 28, y: 86)
        }
    }
}

private struct CatFaceDetails: View {
    let muzzleColor: Color
    let blink: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(muzzleColor)
                .frame(width: 60, height: 40)
                .offset(y: 16)

            Circle().fill(.black.opacity(0.85)).frame(width: 12, height: 12).offset(x: -22, y: -6).scaleEffect(y: blink ? 0.6 : 1.0)
            Circle().fill(.black.opacity(0.85)).frame(width: 12, height: 12).offset(x: 22, y: -6).scaleEffect(y: blink ? 0.6 : 1.0)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.8))
                .frame(width: 12, height: 10)
                .offset(y: 10)
        }
    }
}

private struct BunnyPetView: View {
    let blink: Bool

    private let baseColor = Color(red: 0.98, green: 0.74, blue: 0.79)
    private let outlineColor = Color(red: 0.25, green: 0.18, blue: 0.14)
    private let muzzleColor = Color(red: 0.98, green: 0.92, blue: 0.92)

    var body: some View {
        ZStack {
            BunnyBase(color: outlineColor)
                .scaleEffect(1.06)
                .opacity(0.9)
            BunnyBase(color: .white)
                .scaleEffect(1.03)
            BunnyBase(color: baseColor)
            BunnyFaceDetails(muzzleColor: muzzleColor, blink: blink)
        }
        .frame(width: 170, height: 170)
    }
}

private struct BunnyBase: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color)
                .frame(width: 34, height: 90)
                .offset(x: -30, y: -62)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color)
                .frame(width: 34, height: 90)
                .offset(x: 30, y: -62)
            RoundedRectangle(cornerRadius: 46, style: .continuous)
                .fill(color)
                .frame(width: 130, height: 120)
                .offset(y: 4)
            Circle()
                .fill(color)
                .frame(width: 26, height: 26)
                .offset(x: 42, y: 40)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(width: 20, height: 30)
                .offset(x: -26, y: 66)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color)
                .frame(width: 20, height: 30)
                .offset(x: 26, y: 66)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 24, height: 18)
                .offset(x: -26, y: 86)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 24, height: 18)
                .offset(x: 26, y: 86)
        }
    }
}

private struct BunnyFaceDetails: View {
    let muzzleColor: Color
    let blink: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(muzzleColor)
                .frame(width: 64, height: 46)
                .offset(y: 16)

            Circle().fill(.black.opacity(0.85)).frame(width: 12, height: 12).offset(x: -18, y: -4).scaleEffect(y: blink ? 0.6 : 1.0)
            Circle().fill(.black.opacity(0.85)).frame(width: 12, height: 12).offset(x: 18, y: -4).scaleEffect(y: blink ? 0.6 : 1.0)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.8))
                .frame(width: 10, height: 8)
                .offset(y: 10)
        }
    }
}

private struct PenguinPetView: View {
    let blink: Bool
    let tailWag: Bool
    let outfitAssetName: String?

    var body: some View {
        if let staticName = resolvedStaticName() {
            PenguinStaticPetView(imageName: staticName)
        } else {
            PenguinVectorPetView(blink: blink)
        }
    }

    private func resolvedStaticName() -> String? {
        if let outfitAssetName,
           UIImage(named: "penguin_pet_\(outfitAssetName)") != nil {
            return "penguin_pet_\(outfitAssetName)"
        }
        if UIImage(named: "penguin_pet") != nil {
            return "penguin_pet"
        }
        return nil
    }
}

private struct PenguinStaticPetView: View {
    let imageName: String

    @State private var breathe = false
    @State private var blink = false
    @State private var blinkTask: Task<Void, Never>?

    @AppStorage("penguinEyeCenterX") private var eyeCenterXStorage: Double = -10
    @AppStorage("penguinEyeCenterY") private var eyeCenterYStorage: Double = -20
    @AppStorage("penguinEyeSeparation") private var eyeSeparationStorage: Double = 25
    @AppStorage("penguinEyeSize") private var eyeSizeStorage: Double = 9

    var body: some View {
        ZStack {
            ChromaKeyedImage(name: imageName, resizable: true, contentMode: .fit)

            eyeOverlay
        }
        .frame(width: 160, height: 160)
        .scaleEffect(breathe ? 1.02 : 1.0)
        .rotationEffect(.degrees(breathe ? 0.6 : 0.0))
        .shadow(color: Color.black.opacity(0.18), radius: breathe ? 8 : 6, x: 0, y: 8)
        .padding(.top, 6)
        .onAppear {
            breathe = false
            blink = false
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
            blinkTask?.cancel()
            blinkTask = nil
            startBlinking()
        }
        .onDisappear {
            blinkTask?.cancel()
            blinkTask = nil
        }
    }

    private var eyeOverlay: some View {
        let eyeCenterX = CGFloat(eyeCenterXStorage)
        let eyeCenterY = CGFloat(eyeCenterYStorage)
        let halfSeparation = CGFloat(eyeSeparationStorage) / 2
        let eyeSize = CGFloat(eyeSizeStorage)

        return ZStack {
            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: eyeSize, height: eyeSize)
                .offset(x: eyeCenterX - halfSeparation, y: eyeCenterY)
                .scaleEffect(x: 1.0, y: blink ? 0.6 : 1.0, anchor: .center)

            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: eyeSize, height: eyeSize)
                .offset(x: eyeCenterX + halfSeparation, y: eyeCenterY)
                .scaleEffect(x: 1.0, y: blink ? 0.6 : 1.0, anchor: .center)
        }
    }

    private func startBlinking() {
        guard blinkTask == nil else { return }
        blinkTask = Task {
            while !Task.isCancelled {
                let wait = Double.random(in: 2.4...4.2)
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        blink = true
                    }
                }
                try? await Task.sleep(nanoseconds: 120_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.14)) {
                        blink = false
                    }
                }
            }
        }
    }
}

private struct PenguinVectorPetView: View {
    let blink: Bool

    private let outlineColor = Color(red: 0.15, green: 0.18, blue: 0.22)
    private let bodyColor = Color(red: 0.20, green: 0.22, blue: 0.28)
    private let bellyColor = Color(red: 0.96, green: 0.95, blue: 0.94)
    private let beakColor = Color(red: 0.98, green: 0.74, blue: 0.42)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 52, style: .continuous)
                .fill(outlineColor)
                .frame(width: 124, height: 138)
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(bodyColor)
                .frame(width: 116, height: 128)
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(bellyColor)
                .frame(width: 78, height: 90)
                .offset(y: 12)

            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: 12, height: 12)
                .offset(x: -18, y: -14)
                .scaleEffect(y: blink ? 0.6 : 1.0)
            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: 12, height: 12)
                .offset(x: 18, y: -14)
                .scaleEffect(y: blink ? 0.6 : 1.0)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(beakColor)
                .frame(width: 18, height: 12)
                .offset(y: 4)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(bodyColor)
                .frame(width: 26, height: 42)
                .rotationEffect(.degrees(-18))
                .offset(x: -58, y: 8)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(bodyColor)
                .frame(width: 26, height: 42)
                .rotationEffect(.degrees(18))
                .offset(x: 58, y: 8)
        }
        .frame(width: 170, height: 170)
    }
}

private struct LionPetView: View {
    let blink: Bool
    let tailWag: Bool
    let outfitAssetName: String?

    var body: some View {
        if let staticName = resolvedStaticName() {
            LionStaticPetView(imageName: staticName)
        } else {
            LionVectorPetView(blink: blink)
        }
    }

    private func resolvedStaticName() -> String? {
        if let outfitAssetName,
           UIImage(named: "lion_pet_\(outfitAssetName)") != nil {
            return "lion_pet_\(outfitAssetName)"
        }
        if UIImage(named: "lion_pet") != nil {
            return "lion_pet"
        }
        return nil
    }
}

private struct LionStaticPetView: View {
    let imageName: String

    @State private var breathe = false
    @State private var blink = false
    @State private var blinkTask: Task<Void, Never>?

    @AppStorage("lionEyeCenterX") private var eyeCenterXStorage: Double = -8
    @AppStorage("lionEyeCenterY") private var eyeCenterYStorage: Double = -16
    @AppStorage("lionEyeSeparation") private var eyeSeparationStorage: Double = 21
    @AppStorage("lionEyeSize") private var eyeSizeStorage: Double = 8

    var body: some View {
        ZStack {
            ChromaKeyedImage(name: imageName, resizable: true, contentMode: .fit)

            eyeOverlay
        }
        .frame(width: 160, height: 160)
        .scaleEffect(breathe ? 1.02 : 1.0)
        .rotationEffect(.degrees(breathe ? 0.6 : 0.0))
        .shadow(color: Color.black.opacity(0.18), radius: breathe ? 8 : 6, x: 0, y: 8)
        .padding(.top, 6)
        .onAppear {
            breathe = false
            blink = false
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
            blinkTask?.cancel()
            blinkTask = nil
            startBlinking()
        }
        .onDisappear {
            blinkTask?.cancel()
            blinkTask = nil
        }
    }

    private var eyeOverlay: some View {
        let eyeCenterX = CGFloat(eyeCenterXStorage)
        let eyeCenterY = CGFloat(eyeCenterYStorage)
        let halfSeparation = CGFloat(eyeSeparationStorage) / 2
        let eyeSize = CGFloat(eyeSizeStorage)

        return ZStack {
            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: eyeSize, height: eyeSize)
                .offset(x: eyeCenterX - halfSeparation, y: eyeCenterY)
                .scaleEffect(x: 1.0, y: blink ? 0.6 : 1.0, anchor: .center)

            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: eyeSize, height: eyeSize)
                .offset(x: eyeCenterX + halfSeparation, y: eyeCenterY)
                .scaleEffect(x: 1.0, y: blink ? 0.6 : 1.0, anchor: .center)
        }
    }

    private func startBlinking() {
        guard blinkTask == nil else { return }
        blinkTask = Task {
            while !Task.isCancelled {
                let wait = Double.random(in: 2.4...4.2)
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        blink = true
                    }
                }
                try? await Task.sleep(nanoseconds: 120_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.14)) {
                        blink = false
                    }
                }
            }
        }
    }
}

private struct LionVectorPetView: View {
    let blink: Bool

    private let outlineColor = Color(red: 0.30, green: 0.18, blue: 0.12)
    private let bodyColor = Color(red: 0.96, green: 0.74, blue: 0.32)
    private let maneColor = Color(red: 0.78, green: 0.48, blue: 0.20)
    private let muzzleColor = Color(red: 0.99, green: 0.92, blue: 0.82)

    var body: some View {
        ZStack {
            Circle()
                .fill(outlineColor)
                .frame(width: 130, height: 130)
            Circle()
                .fill(maneColor)
                .frame(width: 120, height: 120)
            Circle()
                .fill(bodyColor)
                .frame(width: 96, height: 96)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(muzzleColor)
                .frame(width: 48, height: 36)
                .offset(y: 14)

            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: 12, height: 12)
                .offset(x: -18, y: -4)
                .scaleEffect(y: blink ? 0.6 : 1.0)
            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: 12, height: 12)
                .offset(x: 18, y: -4)
                .scaleEffect(y: blink ? 0.6 : 1.0)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.85))
                .frame(width: 14, height: 10)
                .offset(y: 14)
        }
        .frame(width: 170, height: 170)
        .shadow(color: outlineColor.opacity(0.18), radius: 6, x: 0, y: 8)
    }
}

#Preview {
    VStack(spacing: 16) {
        PetView(species: .lion, baseOutfitSymbol: nil, overlaySymbols: ["top_hat"], isBouncing: false)

    }
    .padding()
    .background(Color.appBackground)
}
