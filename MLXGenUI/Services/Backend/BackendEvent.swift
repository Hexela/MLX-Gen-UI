import Foundation

/// A normalized event emitted by a running backend process.
enum BackendEvent: Equatable, Sendable {
    /// The process started successfully.
    case started
    /// A human-readable output line that was not a structured MLX-Gen event.
    case output(String)
    /// MLX-Gen reported a structured runtime event.
    case structured(MLXGenEvent)
    /// The process exited successfully.
    case completed
}

/// The documented subset of MLX-Gen's newline-delimited JSON event format used by the app.
struct MLXGenEvent: Codable, Equatable, Sendable {
    /// The event name, such as `start`, `progress`, or `save`.
    let type: String
    /// A human-readable event message when supplied by the backend.
    let message: String?
    /// The current denoising step when supplied.
    let step: Int?
    /// The total number of denoising steps when supplied.
    let totalSteps: Int?
    /// A backend-provided fractional or percentage progress value.
    let progress: Double?
    /// The saved artifact path for save events.
    let path: String?
    /// The resolved output width.
    let width: Int?
    /// The resolved output height.
    let height: Int?
    /// The saved output frame rate.
    let framesPerSecond: Double?
    /// The number of frames in the saved artifact.
    let totalFrames: Int?

    /// Maps MLX-Gen's snake-case event keys to Swift API names.
    enum CodingKeys: String, CodingKey {
        case type
        case message
        case step
        case totalSteps = "total_steps"
        case progress
        case path
        case width
        case height
        case framesPerSecond = "fps"
        case totalFrames = "total_frames"
    }

    /// A normalized progress fraction in the closed range `0...1` when enough information exists.
    var progressFraction: Double? {
        if let step, let totalSteps, totalSteps > 0 {
            return min(max(Double(step) / Double(totalSteps), 0), 1)
        }
        if let progress {
            let fraction = progress > 1 ? progress / 100 : progress
            return min(max(fraction, 0), 1)
        }
        return nil
    }
}
