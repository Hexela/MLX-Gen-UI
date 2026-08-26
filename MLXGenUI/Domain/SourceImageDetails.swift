import Foundation
import ImageIO

/// Pixel metadata and quality guidance for a selected starting image.
struct SourceImageDetails: Equatable, Sendable {
    /// The image width in pixels.
    let width: Int
    /// The image height in pixels.
    let height: Int

    /// A concise resolution suitable for display in the generation form.
    var resolutionDescription: String {
        "\(width) × \(height) pixels"
    }

    /// The source image's width-to-height ratio.
    private var aspectRatio: Double {
        Double(width) / Double(height)
    }

    /// Returns actionable quality advice for the selected video canvas.
    ///
    /// - Parameters:
    ///   - targetWidth: The requested video width in pixels.
    ///   - targetHeight: The requested video height in pixels.
    /// - Returns: An empty array when the image is a strong match, otherwise one or more recommendations.
    func recommendations(targetWidth: Int, targetHeight: Int) -> [String] {
        guard width > 0, height > 0, targetWidth > 0, targetHeight > 0 else { return [] }

        var recommendations: [String] = []
        if width < targetWidth || height < targetHeight {
            recommendations.append(
                "This image is smaller than the \(targetWidth) × \(targetHeight) video canvas, so fine detail may look soft. Use an image at least as large as the canvas, or choose a smaller canvas."
            )
        }

        let targetAspectRatio = Double(targetWidth) / Double(targetHeight)
        let relativeAspectDifference = abs(aspectRatio - targetAspectRatio) / targetAspectRatio
        if relativeAspectDifference > 0.05 {
            recommendations.append(
                "Its aspect ratio does not closely match the video canvas, so the image may be cropped or stretched. Crop it to \(targetWidth):\(targetHeight), or change the canvas to match the image."
            )
        }

        return recommendations
    }

    /// Reads pixel dimensions without decoding the full image into memory.
    ///
    /// - Parameter URL: The selected local image URL.
    /// - Returns: Image details, or `nil` when the file's dimensions cannot be read.
    static func load(from URL: URL) -> SourceImageDetails? {
        let didAccessSecurityScopedResource = URL.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScopedResource {
                URL.stopAccessingSecurityScopedResource()
            }
        }

        guard let source = CGImageSourceCreateWithURL(URL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }

        return SourceImageDetails(width: width, height: height)
    }
}
