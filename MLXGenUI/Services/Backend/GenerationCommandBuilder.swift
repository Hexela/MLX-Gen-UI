import Foundation

/// Converts a validated generation task into an MLX-Gen command invocation.
struct GenerationCommandBuilder: Sendable {
    /// The validator used before constructing backend arguments.
    private let validator = GenerationTaskValidator()

    /// Creates an MLX-Gen command for a generation task.
    ///
    /// - Parameters:
    ///   - task: The task whose values should become backend arguments.
    ///   - executableURL: The resolved `mlxgen` executable.
    ///   - outputURL: The destination for the generated video.
    /// - Returns: A command containing a separate executable and argument array.
    /// - Throws: ``GenerationCommandError/invalidTask(_:)`` when validation fails.
    func makeCommand(
        for task: GenerationTask,
        executableURL: URL,
        outputURL: URL,
        contextFrameURLs: [URL] = []
    ) throws -> GenerationCommand {
        let issues = validator.issues(in: task)
        guard issues.isEmpty else {
            throw GenerationCommandError.invalidTask(issues)
        }

        var arguments = [
            "generate",
            "--model", task.modelIdentifier,
            "--prompt", task.prompt,
            "--width", String(task.width),
            "--height", String(task.height),
            "--frames", String(task.frameCount),
            "--fps", String(task.framesPerSecond),
            "--steps", String(task.stepCount),
            "--guidance", String(task.guidance)
        ]

        if WanModel.model(withIdentifier: task.modelIdentifier)?.supportsSecondaryGuidance == true {
            arguments += ["--guidance-2", String(task.secondaryGuidance)]
        }

        if task.negativePrompt.isEmpty == false {
            arguments += ["--negative-prompt", task.negativePrompt]
        }
        if let sourceImageURL = task.sourceImageURL {
            arguments += ["--image", sourceImageURL.path]
            if task.createsLoop {
                arguments += ["--last-image", sourceImageURL.path]
            }
        }
        if contextFrameURLs.isEmpty == false {
            arguments.append("--context-frames")
            arguments.append(contentsOf: contextFrameURLs.map(\.path))
        }
        if let flowShift = task.flowShift {
            arguments += ["--flow-shift", String(flowShift)]
        }
        if let seed = task.seed {
            arguments += ["--seed", String(seed)]
        }
        if task.usesLowMemoryMode {
            arguments.append("--low-ram")
        }
        if task.writesMetadata {
            arguments.append("--metadata")
        }
        arguments += ["--json-events", "--output", outputURL.path]

        return GenerationCommand(executableURL: executableURL, arguments: arguments)
    }
}

/// Errors produced while converting a task into a backend command.
enum GenerationCommandError: LocalizedError, Equatable {
    /// One or more task values are not valid for generation.
    case invalidTask([GenerationValidationIssue])

    /// A localized explanation suitable for presentation to the user.
    var errorDescription: String? {
        switch self {
        case .invalidTask(let issues): issues.map(\.message).joined(separator: " ")
        }
    }
}
