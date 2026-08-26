@preconcurrency import AVFoundation
import Foundation

/// Joins generated segments, removes handover duplication, and trims exact duration.
struct VideoConcatenator {
    /// Assembles an ordered long-video plan into one MP4 file.
    ///
    /// - Parameters:
    ///   - segmentURLs: Generated segment URLs in playback order.
    ///   - plan: The plan describing overlap and exact target length.
    ///   - outputURL: A temporary destination that must not already exist.
    func concatenate(
        segmentURLs: [URL],
        using plan: LongVideoPlan,
        to outputURL: URL
    ) async throws {
        guard segmentURLs.count == plan.segments.count else {
            throw VideoConcatenationError.mismatchedSegmentCount
        }

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw VideoConcatenationError.couldNotCreateComposition
        }
        var cursor = CMTime.zero
        let targetDuration = CMTime(
            value: CMTimeValue(plan.targetFrameCount),
            timescale: CMTimeScale(plan.framesPerSecond)
        )

        for (index, URL) in segmentURLs.enumerated() {
            let asset = AVURLAsset(url: URL)
            guard let sourceTrack = try await asset.loadTracks(withMediaType: .video).first else {
                throw VideoConcatenationError.missingVideoTrack(URL)
            }
            if index == 0 {
                compositionVideoTrack.preferredTransform = try await sourceTrack.load(.preferredTransform)
            }
            let assetDuration = try await asset.load(.duration)
            let nextOverlap = index + 1 < plan.segments.count
                ? plan.segments[index + 1].overlapFrameCount
                : 0
            let overlapDuration = CMTime(
                value: CMTimeValue(nextOverlap),
                timescale: CMTimeScale(plan.framesPerSecond)
            )
            let availableDuration = CMTimeSubtract(assetDuration, overlapDuration)
            let remainingDuration = CMTimeSubtract(targetDuration, cursor)
            let insertionDuration = min(availableDuration, remainingDuration)
            guard insertionDuration > .zero else { break }
            try compositionVideoTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: insertionDuration),
                of: sourceTrack,
                at: cursor
            )
            cursor = CMTimeAdd(cursor, insertionDuration)
        }

        guard cursor >= targetDuration else {
            throw VideoConcatenationError.insufficientDuration
        }
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoConcatenationError.couldNotCreateExporter
        }
        try await exporter.export(to: outputURL, as: .mp4)
    }
}

/// Failures produced while assembling generated segments.
enum VideoConcatenationError: LocalizedError {
    /// The caller supplied a different number of files than the plan requires.
    case mismatchedSegmentCount
    /// AVFoundation could not allocate a mutable video track.
    case couldNotCreateComposition
    /// A generated artifact does not contain a usable video track.
    case missingVideoTrack(URL)
    /// The usable segment ranges end before the exact requested duration.
    case insufficientDuration
    /// AVFoundation could not create an MP4 export session.
    case couldNotCreateExporter

    /// A localized explanation suitable for presentation to the user.
    var errorDescription: String? {
        switch self {
        case .mismatchedSegmentCount: "The generated segment list does not match the video plan."
        case .couldNotCreateComposition: "Could not create a video composition."
        case .missingVideoTrack(let URL): "The segment \(URL.lastPathComponent) does not contain video."
        case .insufficientDuration: "The generated segments do not cover the requested duration."
        case .couldNotCreateExporter: "Could not prepare the finished MP4 export."
        }
    }
}
