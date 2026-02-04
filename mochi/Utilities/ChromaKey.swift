import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

final class ChromaKeyProcessor {
    static let shared = ChromaKeyProcessor()

    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 64
    }

    func image(
        named name: String,
        keyColor: UIColor = .red,
        threshold: CGFloat = 0.28,
        smoothing: CGFloat = 0.08
    ) -> UIImage? {
        let cacheKey = "\(name)_\(threshold)_\(smoothing)" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        guard let source = UIImage(named: name) else { return nil }
        guard let processed = chromaKey(image: source, keyColor: keyColor, threshold: threshold, smoothing: smoothing) else {
            return source
        }

        cache.setObject(processed, forKey: cacheKey)
        return processed
    }

    private func chromaKey(
        image: UIImage,
        keyColor: UIColor,
        threshold: CGFloat,
        smoothing: CGFloat
    ) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let dimension = 64
        guard let cubeData = makeCubeData(
            dimension: dimension,
            keyColor: keyColor,
            threshold: threshold,
            smoothing: smoothing
        ) else {
            return nil
        }

        let filter = CIFilter.colorCube()
        filter.cubeDimension = dimension
        filter.cubeData = cubeData
        filter.inputImage = ciImage

        guard let output = filter.outputImage else { return nil }
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func makeCubeData(
        dimension: Int,
        keyColor: UIColor,
        threshold: CGFloat,
        smoothing: CGFloat
    ) -> Data? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        keyColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let size = dimension * dimension * dimension * 4
        var cubeData = [Float](repeating: 0, count: size)

        var index = 0
        for z in 0..<dimension {
            let b = Float(z) / Float(dimension - 1)
            for y in 0..<dimension {
                let g = Float(y) / Float(dimension - 1)
                for x in 0..<dimension {
                    let r = Float(x) / Float(dimension - 1)

                    let dr = r - Float(red)
                    let dg = g - Float(green)
                    let db = b - Float(blue)
                    let distance = sqrt(dr * dr + dg * dg + db * db)

                    let alphaValue = smoothstep(
                        edge0: Float(threshold),
                        edge1: Float(threshold + smoothing),
                        x: distance
                    )

                    cubeData[index] = r
                    cubeData[index + 1] = g
                    cubeData[index + 2] = b
                    cubeData[index + 3] = alphaValue
                    index += 4
                }
            }
        }

        return Data(buffer: UnsafeBufferPointer(start: &cubeData, count: cubeData.count))
    }

    private func smoothstep(edge0: Float, edge1: Float, x: Float) -> Float {
        guard edge0 < edge1 else { return x < edge0 ? 0 : 1 }
        let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

struct ChromaKeyedImage: View {
    let name: String
    var applyChromaKey: Bool = true

    var body: some View {
        if applyChromaKey, let uiImage = ChromaKeyProcessor.shared.image(named: name) {
            Image(uiImage: uiImage)
        } else {
            Image(name)
        }
    }
}
