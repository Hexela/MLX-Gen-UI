import Foundation

/// All values needed to reproduce one MLX-Gen Wan video-generation request.
struct GenerationTask: Codable, Equatable, Hashable, Sendable {
    /// The current portable document format version.
    static let currentFormatVersion = 1

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
    /// Whether MLX-Gen should reduce peak memory usage where supported.
    var usesLowMemoryMode: Bool
    /// Whether MLX-Gen should save a metadata sidecar.
    var writesMetadata: Bool

    /// The nominal playback duration requested by the task.
    var duration: Duration {
        .seconds(Double(frameCount) / Double(framesPerSecond))
    }
}
