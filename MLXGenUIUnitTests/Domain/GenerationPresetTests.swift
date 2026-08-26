import Testing
@testable import MLXGenUI

/// Verifies that curated presets create valid, independent tasks.
struct GenerationPresetTests {
    /// Every built-in preset should satisfy its non-file validation rules.
    @Test(arguments: GenerationPreset.allCases)
    func presetProducesExpectedWorkflow(_ preset: GenerationPreset) {
        let task = preset.makeTask()

        if task.workflow == .textToVideo {
            #expect(task.modelIdentifier.contains("t2v"))
        } else {
            #expect(task.modelIdentifier.contains("i2v"))
        }
        #expect(task.frameCount > 0)
        #expect(task.framesPerSecond > 0)
        #expect(task.writesMetadata)
    }

    /// Creating a preset twice should produce different document identities.
    @Test func presetCreatesIndependentDocuments() {
        let first = GenerationPreset.quickTextPreview.makeTask()
        let second = GenerationPreset.quickTextPreview.makeTask()

        #expect(first.identifier != second.identifier)
    }
}
