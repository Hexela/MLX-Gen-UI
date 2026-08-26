import Foundation

/// One MLX-Gen invocation in a planned long-video generation.
struct VideoSegmentPlan: Codable, Equatable, Identifiable, Sendable {
    /// The zero-based segment number.
    let index: Int
    /// The model-valid number of frames to generate.
    let frameCount: Int
    /// The number of frames shared with the preceding segment.
    let overlapFrameCount: Int

    /// The stable list identity.
    var id: Int { index }
}

/// A complete, ordered recipe for generating and assembling a requested duration.
struct LongVideoPlan: Codable, Equatable, Sendable {
    /// The exact number of frames requested in the final artifact.
    let targetFrameCount: Int
    /// The playback rate used by every segment.
    let framesPerSecond: Int
    /// The ordered generation invocations.
    let segments: [VideoSegmentPlan]
    /// The image-to-video model required after the initial segment, when applicable.
    let continuationModelIdentifier: String?

    /// Whether the plan requires extraction, continuation, and assembly.
    var requiresAssembly: Bool { segments.count > 1 }
}

/// Calculates model-valid segments for an exact requested duration.
struct LongVideoPlanner: Sendable {
    /// Creates the generation plan for a task and curated model.
    ///
    /// - Parameters:
    ///   - task: The user's complete generation request.
    ///   - model: The curated capabilities of the selected model.
    /// - Returns: An ordered plan whose assembled content covers the requested frame count.
    func makePlan(for task: GenerationTask, model: WanModel) -> LongVideoPlan {
        let targetFrames = task.targetFrameCount
        let segmentFrames = model.recommendedSegmentFrames
        let overlapFrames = model.supportedContextFrameCounts.first ?? 1

        guard targetFrames > segmentFrames else {
            return LongVideoPlan(
                targetFrameCount: targetFrames,
                framesPerSecond: task.framesPerSecond,
                segments: [.init(index: 0, frameCount: validFrameCount(covering: targetFrames), overlapFrameCount: 0)],
                continuationModelIdentifier: nil
            )
        }

        let additionalFramesPerSegment = max(segmentFrames - overlapFrames, 1)
        let remainingFrames = targetFrames - segmentFrames
        let continuationCount = Int(ceil(Double(remainingFrames) / Double(additionalFramesPerSegment)))
        let segments = (0...continuationCount).map { index in
            let isFinalContinuation = index == continuationCount && index > 0
            let uniqueFramesBeforeFinal = segmentFrames
                + max(index - 1, 0) * additionalFramesPerSegment
            let remainingUniqueFrames = max(targetFrames - uniqueFramesBeforeFinal, 1)
            let requestedFrames = isFinalContinuation
                ? remainingUniqueFrames + overlapFrames
                : segmentFrames
            return VideoSegmentPlan(
                index: index,
                frameCount: validFrameCount(covering: requestedFrames),
                overlapFrameCount: index == 0 ? 0 : overlapFrames
            )
        }
        return LongVideoPlan(
            targetFrameCount: targetFrames,
            framesPerSecond: task.framesPerSecond,
            segments: segments,
            continuationModelIdentifier: model.continuationModelIdentifier
        )
    }

    /// Rounds upward to Wan's temporal `4n + 1` requirement.
    private func validFrameCount(covering frameCount: Int) -> Int {
        guard frameCount > 1 else { return 1 }
        return Int(ceil(Double(frameCount - 1) / 4)) * 4 + 1
    }
}
