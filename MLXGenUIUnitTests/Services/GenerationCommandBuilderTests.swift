import Foundation
import Testing
@testable import MLXGenUI

/// Verifies safe and reproducible MLX-Gen argument construction.
struct GenerationCommandBuilderTests {
    /// Text-to-video should not include an image argument.
    @Test func textTaskBuildsExpectedArguments() throws {
        var task = GenerationPreset.quickTextPreview.makeTask()
        task.prompt = "A red kite flying over the sea."
        task.seed = 42

        let command = try GenerationCommandBuilder().makeCommand(
            for: task,
            executableURL: URL(filePath: "/tmp/mlxgen"),
            outputURL: URL(filePath: "/tmp/video output.mp4")
        )

        #expect(command.arguments.starts(with: ["generate", "--model", task.modelIdentifier]))
        #expect(command.arguments.contains("--image") == false)
        #expect(command.arguments.contains("--json-events"))
        #expect(command.arguments.contains("42"))
        #expect(command.displayString.contains("'/tmp/video output.mp4'"))
    }

    /// Image-to-video should preserve a source path as one argument even when it contains spaces.
    @Test func imagePathRemainsSingleArgument() throws {
        var task = GenerationPreset.animateImage.makeTask()
        task.sourceImageURL = URL(filePath: "/tmp/source image.png")

        let command = try GenerationCommandBuilder().makeCommand(
            for: task,
            executableURL: URL(filePath: "/tmp/mlxgen"),
            outputURL: URL(filePath: "/tmp/output.mp4")
        )

        let imageIndex = try #require(command.arguments.firstIndex(of: "--image"))
        #expect(command.arguments[imageIndex + 1] == "/tmp/source image.png")
    }
}
