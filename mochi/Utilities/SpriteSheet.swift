import SwiftUI
import UIKit

struct SpriteSheet {
    let image: UIImage
    let columns: Int
    let rows: Int

    var frameSize: CGSize {
        CGSize(
            width: image.size.width / CGFloat(columns),
            height: image.size.height / CGFloat(rows)
        )
    }

    func cgImage(at index: Int, contentInset: CGFloat = 0) -> CGImage? {
        guard let cgImage = image.cgImage else { return nil }

        let scale = image.scale
        let pixelWidth = image.size.width * scale
        let pixelHeight = image.size.height * scale
        let framePixelWidth = CGFloat(Int(pixelWidth / CGFloat(columns)))
        let framePixelHeight = CGFloat(Int(pixelHeight / CGFloat(rows)))

        let col = index % columns
        let row = index / columns

        let insetPixels = contentInset * scale
        let originX = CGFloat(col) * framePixelWidth + insetPixels
        let originY = CGFloat(row) * framePixelHeight + insetPixels
        let rect = CGRect(
            x: originX,
            y: originY,
            width: framePixelWidth - insetPixels * 2,
            height: framePixelHeight - insetPixels * 2
        )

        guard rect.maxX <= pixelWidth + 0.5, rect.maxY <= pixelHeight + 0.5 else {
            return nil
        }

        return cgImage.cropping(to: rect)
    }
}

struct SpriteSheetAnimator: View {
    let imageName: String
    let columns: Int
    let rows: Int
    let frames: [Int]
    let fps: Double
    let size: CGSize
    let contentInset: CGFloat
    var applyChromaKey: Bool = false

    @State private var startTime = Date()

    var body: some View {
        let uiImage = applyChromaKey
            ? ChromaKeyProcessor.shared.image(named: imageName)
            : UIImage(named: imageName)

        if let uiImage {
            TimelineView(.animation(minimumInterval: 1.0 / fps)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                let index = frameIndex(for: elapsed)
                let sheet = SpriteSheet(image: uiImage, columns: columns, rows: rows)

                if let cgImage = sheet.cgImage(at: index, contentInset: contentInset) {
                    Image(decorative: cgImage, scale: uiImage.scale, orientation: .up)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: size.width, height: size.height)
                } else {
                    fallback
                }
            }
            .onAppear { startTime = Date() }
        } else {
            fallback
        }
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.2))
            .frame(width: size.width, height: size.height)
    }

    private func frameIndex(for elapsed: TimeInterval) -> Int {
        guard !frames.isEmpty else { return 0 }
        let rawIndex = Int(elapsed * fps) % frames.count
        return frames[rawIndex]
    }
}
