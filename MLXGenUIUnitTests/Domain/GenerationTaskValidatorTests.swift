import Foundation
import Testing
@testable import MLXGenUI

/// Verifies task validation at workflow boundaries.
struct GenerationTaskValidatorTests {
    /// Image-to-video requires both a prompt and a selected image.
    @Test func imageWorkflowReportsMissingInputs() {
        var task = GenerationPreset.animateImage.makeTask()
        task.prompt = "  "
        task.sourceImageURL = nil

        let issues = GenerationTaskValidator().issues(in: task)

        #expect(issues.map(\.kind).contains(.missingPrompt))
        #expect(issues.map(\.kind).contains(.missingSourceImage))
    }

    /// A complete text preset should have no validation issues after adding a prompt.
    @Test func completeTextTaskIsValid() {
        var task = GenerationPreset.quickTextPreview.makeTask()
        task.prompt = "A paper boat floating down a sunlit stream."

        #expect(GenerationTaskValidator().issues(in: task).isEmpty)
    }

    /// Seeds outside the backend's supported unsigned 32-bit range are rejected.
    @Test(arguments: [-1, GenerationTaskValidator.maximumSeed + 1])
    func invalidSeedIsReported(seed: Int) {
        var task = GenerationPreset.quickTextPreview.makeTask()
        task.prompt = "A paper boat floating down a sunlit stream."
        task.seed = seed

        #expect(GenerationTaskValidator().issues(in: task).contains { $0.id == "seed" })
    }

    /// The 5B model rejects dimensions that MLX-Gen would otherwise silently expand.
    @Test func ti2vCanvasMustUse32PixelIncrements() {
        var task = GenerationPreset.quickTextPreview.makeTask()
        task.prompt = "A paper boat floating down a sunlit stream."
        task.modelIdentifier = "AbstractFramework/wan2.2-ti2v-5b-diffusers-8bit"
        task.height = 240

        #expect(GenerationTaskValidator().issues(in: task).contains { $0.id == "canvasMultiple" })

        task.height = 256
        #expect(GenerationTaskValidator().issues(in: task).isEmpty)
    }

    /// A14B models use their smaller 16-pixel spatial increment.
    @Test func a14BCanvasUses16PixelIncrements() {
        var task = GenerationPreset.quickTextPreview.makeTask()
        task.prompt = "A paper boat floating down a sunlit stream."
        task.height = 240

        #expect(GenerationTaskValidator().issues(in: task).isEmpty)
    }
}
