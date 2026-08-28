import Foundation

/// All values needed to reproduce one MLX-Gen Wan video-generation request.
struct GenerationTask: Codable, Equatable, Hashable, Sendable {
    /// The current portable document format version.
    static let currentFormatVersion = 1

    /// The default exclusions used for newly created video tasks.
    static let defaultNegativePrompt = """
        blurry, low quality, distorted anatomy, duplicated body parts, extra limbs, fused bodies, distorted faces, waxy skin, flickering, temporal inconsistency, jitter, ghosting, warping, morphing, melting, sudden movement, unnatural movement, unwanted camera movement, text, watermark
        """

    /// Motion guidance appended while seamless-loop generation is enabled.
    static let loopPrompt = """
        Smooth, natural, cyclical movement that gradually returns to the starting pose and composition. Seamless loop with continuous motion
        through the loop point. Consistent appearance, lighting and background. Static locked camera, no cuts or transitions. Realistic natural motion, cinematic quality.
        """

    /// Exclusions appended while seamless-loop generation is enabled.
    static let loopNegativePrompt = """
        abrupt movement, sudden movement, stopping motion, motion discontinuity, drifting composition, permanent pose change, camera movement, camera pan,
        camera tilt, camera zoom, camera rotation, scene transition, cut, changing background, changing lighting, flickering, temporal inconsistency, jitter, ghosting, warping, morphing
        """

    /// The task document format version.
    var formatVersion = currentFormatVersion
    /// A stable identifier retained when the task is saved and reopened.
    var identifier = UUID()
    /// A name chosen by the user or supplied by a preset.
    var name: String
    /// The route used to generate the video.
    var workflow: GenerationWorkflow
    /// The Hugging Face repository identifier passed to MLX-Gen.
    var modelIdentifier: String
    /// The positive generation prompt.
    var prompt: String
    /// An optional prompt describing content to avoid.
    var negativePrompt: String
    /// The selected starting image for image-to-video tasks.
    var sourceImageURL: URL?
    /// The user-selected destination for the generated video.
    var outputURL: URL?
    /// The requested output width in pixels.
    var width: Int
    /// The requested output height in pixels.
    var height: Int
    /// The number of frames to generate.
    var frameCount: Int
    /// The requested finished duration in seconds, or `nil` to use `frameCount` directly.
    var targetDurationSeconds: Double?
    /// The output playback rate in frames per second.
    var framesPerSecond: Int
    /// The number of denoising steps.
    var stepCount: Int
    /// Classifier-free guidance for the first denoising stage.
    var guidance: Double
    /// Classifier-free guidance for the second A14B denoising stage.
    var secondaryGuidance: Double
    /// An optional flow-matching schedule override.
    var flowShift: Double?
    /// A fixed seed, or `nil` when MLX-Gen should choose one.
    var seed: Int?
    /// Whether the starting image should also close the generated video.
    @DefaultFalse var createsLoop = false
    /// The frame count restored when loop creation is disabled.
    var frameCountBeforeLoop: Int?
    /// The requested duration restored when loop creation is disabled.
    var targetDurationSecondsBeforeLoop: Double?
    /// Whether MLX-Gen should reduce peak memory usage where supported.
    var usesLowMemoryMode: Bool
    /// Whether MLX-Gen should save a metadata sidecar.
    var writesMetadata: Bool

    /// The nominal playback duration requested by the task.
    var duration: Duration {
        .seconds(targetDurationSeconds ?? Double(frameCount) / Double(framesPerSecond))
    }

    /// The number of frames required in the finished, assembled video.
    var targetFrameCount: Int {
        guard let targetDurationSeconds else { return frameCount }
        return max(Int(ceil(targetDurationSeconds * Double(framesPerSecond))), 1)
    }

    /// Applies or removes the reversible prompt and timing defaults for loop creation.
    mutating func configureLoop(_ isEnabled: Bool) {
        createsLoop = isEnabled

        if isEnabled {
            guard frameCountBeforeLoop == nil else { return }
            frameCountBeforeLoop = frameCount
            targetDurationSecondsBeforeLoop = targetDurationSeconds
            prompt = Self.appending(Self.loopPrompt, to: prompt)
            negativePrompt = Self.appending(Self.loopNegativePrompt, to: negativePrompt)
            frameCount = 81
            targetDurationSeconds = 81 / Double(framesPerSecond)
        } else {
            prompt = Self.removingAppended(Self.loopPrompt, from: prompt)
            negativePrompt = Self.removingAppended(Self.loopNegativePrompt, from: negativePrompt)
            if let frameCountBeforeLoop {
                frameCount = frameCountBeforeLoop
                targetDurationSeconds = targetDurationSecondsBeforeLoop
            }
            frameCountBeforeLoop = nil
            targetDurationSecondsBeforeLoop = nil
        }
    }

    private static func appending(_ addition: String, to value: String) -> String {
        value.isEmpty ? addition : "\(value)\n\n\(addition)"
    }

    private static func removingAppended(_ addition: String, from value: String) -> String {
        let separatedSuffix = "\n\n\(addition)"
        if value.hasSuffix(separatedSuffix) {
            return String(value.dropLast(separatedSuffix.count))
        }
        return value == addition ? "" : value
    }
}
