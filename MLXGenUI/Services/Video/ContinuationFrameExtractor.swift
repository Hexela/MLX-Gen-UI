@preconcurrency import AVFoundation
import AppKit
import Foundation

/// Extracts an ordered lossless handover window from a generated video.
@MainActor
struct ContinuationFrameExtractor {
    /// Writes the final frames of a video as PNG images.
    ///
    /// - Parameters:
    ///   - count: The total number of ordered handover frames to extract.
    ///   - framesPerSecond: The video's expected playback rate.
    ///   - videoURL: The completed predecessor segment.
    ///   - directoryURL: The directory that receives the PNG files.
    /// - Returns: URLs ordered from the earliest handover frame to the final frame.
    /// - Throws: ``ContinuationFrameExtractionError`` when a frame cannot be encoded.
    func extractLastFrames(
        count: Int,
        framesPerSecond: Int,
        from videoURL: URL,
        into directoryURL: URL
    ) async throws -> [URL] {
        let asset = AVURLAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        var frameURLs: [URL] = []
        for offset in 0..<count {
            let framesFromEnd = count - offset
            let requestedTime = CMTimeSubtract(
                duration,
                CMTime(value: CMTimeValue(framesFromEnd), timescale: CMTimeScale(framesPerSecond))
            )
            let (image, _) = try await generator.image(at: max(requestedTime, .zero))
            let representation = NSBitmapImageRep(cgImage: image)
            guard let data = representation.representation(using: .png, properties: [:]) else {
                throw ContinuationFrameExtractionError.couldNotEncodeFrame(offset)
            }
            let URL = directoryURL.appending(path: "context-\(offset).png")
            try data.write(to: URL, options: .atomic)
            frameURLs.append(URL)
        }
        return frameURLs
    }
}

/// Failures produced while preparing continuation images.
enum ContinuationFrameExtractionError: LocalizedError {
    /// AppKit could not represent one extracted image as PNG data.
    case couldNotEncodeFrame(Int)

    /// A localized explanation suitable for presentation to the user.
    var errorDescription: String? {
        switch self {
        case .couldNotEncodeFrame(let index): "Could not prepare continuation frame \(index + 1)."
        }
    }
}
