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
}
