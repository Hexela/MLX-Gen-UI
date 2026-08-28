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
        #expect(task.negativePrompt == GenerationTask.defaultNegativePrompt)
    }

    /// Creating a preset twice should produce different document identities.
    @Test func presetCreatesIndependentDocuments() {
        let first = GenerationPreset.quickTextPreview.makeTask()
        let second = GenerationPreset.quickTextPreview.makeTask()

        #expect(first.identifier != second.identifier)
    }

    /// Enabling and disabling loop creation should restore the original task values.
    @Test func loopConfigurationIsReversible() {
        var task = GenerationPreset.quickTextPreview.makeTask()
        task.prompt = "A dancer turns slowly."
        let original = task

        task.configureLoop(true)

        #expect(task.createsLoop)
        #expect(task.frameCount == 81)
        #expect(task.targetFrameCount == 81)
        #expect(task.prompt.hasSuffix(GenerationTask.loopPrompt))
        #expect(task.negativePrompt.hasSuffix(GenerationTask.loopNegativePrompt))

        task.configureLoop(false)

        #expect(task.prompt == original.prompt)
        #expect(task.negativePrompt == original.negativePrompt)
        #expect(task.frameCount == original.frameCount)
        #expect(task.targetDurationSeconds == original.targetDurationSeconds)
        #expect(task.createsLoop == false)
    }

    /// Switching timing units preserves the requested playback length.
    @Test func switchingLengthUnitsPreservesDuration() {
        var task = GenerationPreset.quickTextPreview.makeTask()
        task.targetDurationSeconds = 3.1

        task.specifyLengthInFrames()

        #expect(task.targetDurationSeconds == nil)
        #expect(task.frameCount == 50)

        task.specifyLengthInSeconds()

        #expect(task.targetDurationSeconds == 3.125)
    }
}
