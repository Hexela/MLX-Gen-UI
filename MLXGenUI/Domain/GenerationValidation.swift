import Foundation

/// A validation problem that should be resolved before generation starts.
struct GenerationValidationIssue: Equatable, Identifiable, Sendable {
    /// The kind of invalid task value.
    enum Kind: Sendable {
        /// The positive prompt is empty.
        case missingPrompt
        /// Image-to-video is selected without a starting image.
        case missingSourceImage
        /// A numeric value falls outside the supported range.
        case invalidValue
    }

    /// A stable identity for display in SwiftUI lists.
    let id: String
    /// The category of validation failure.
    let kind: Kind
    /// A concise explanation for the user.
    let message: String
}

/// Validates generation tasks before they reach the command-line backend.
struct GenerationTaskValidator: Sendable {
    /// The largest seed accepted by the generation backend.
    static let maximumSeed = Int(UInt32.max)

    /// Returns every known problem with a generation task.
    ///
    /// - Parameter task: The task to validate.
    /// - Returns: Validation issues in the order they should be shown.
    func issues(in task: GenerationTask) -> [GenerationValidationIssue] {
        var issues: [GenerationValidationIssue] = []

        if task.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.init(id: "prompt", kind: .missingPrompt, message: "Enter a prompt describing the video."))
        }
        if task.workflow == .imageToVideo, task.sourceImageURL == nil {
            issues.append(.init(id: "sourceImage", kind: .missingSourceImage, message: "Choose a starting image."))
        }
        if task.width <= 0 || task.height <= 0 {
            issues.append(.init(id: "canvas", kind: .invalidValue, message: "Width and height must be positive."))
        }
        if task.frameCount <= 0 || task.framesPerSecond <= 0 {
            issues.append(.init(id: "timing", kind: .invalidValue, message: "Frames and frame rate must be positive."))
        }
        if let duration = task.targetDurationSeconds, duration <= 0 {
            issues.append(.init(id: "duration", kind: .invalidValue, message: "Duration must be positive."))
        }
        if task.stepCount <= 0 {
            issues.append(.init(id: "steps", kind: .invalidValue, message: "Denoising steps must be positive."))
        }
        if let seed = task.seed, (0...Self.maximumSeed).contains(seed) == false {
            issues.append(
                .init(
                    id: "seed",
                    kind: .invalidValue,
                    message: "Seed must be between 0 and \(Self.maximumSeed)."
                )
            )
        }

        return issues
    }
}
