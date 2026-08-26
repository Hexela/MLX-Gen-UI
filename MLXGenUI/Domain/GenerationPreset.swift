import Foundation

/// A curated collection of defaults for a common video-generation goal.
enum GenerationPreset: String, CaseIterable, Identifiable, Sendable {
    /// A small text-to-video run intended to validate a prompt quickly.
    case quickTextPreview
    /// A balanced A14B text-to-video task.
    case qualityTextVideo
    /// A balanced A14B task that animates a starting image.
    case animateImage
    /// A portrait-oriented starting-image task.
    case portraitImage

    /// The stable identity used by SwiftUI controls.
    var id: Self { self }

    /// The user-facing preset name.
    var title: String {
        switch self {
        case .quickTextPreview: "Quick Text Preview"
        case .qualityTextVideo: "Quality Text Video"
        case .animateImage: "Animate an Image"
        case .portraitImage: "Portrait Image Animation"
        }
    }

    /// A short explanation of when the preset is useful.
    var summary: String {
        switch self {
        case .quickTextPreview: "A short, lower-cost run for checking motion and prompt direction."
        case .qualityTextVideo: "A balanced landscape video generated entirely from your prompt."
        case .animateImage: "Uses a selected image as the opening frame and preserves its aspect ratio."
        case .portraitImage: "A portrait-oriented starting point for people and vertical compositions."
        }
    }

    /// Creates a new, independently editable task from the preset.
    ///
    /// - Returns: A generation task containing the preset's current defaults.
    func makeTask() -> GenerationTask {
        switch self {
        case .quickTextPreview:
            makeTextTask(name: title, width: 480, height: 240, frameCount: 41, stepCount: 12)
        case .qualityTextVideo:
            makeTextTask(name: title, width: 832, height: 480, frameCount: 81, stepCount: 20)
        case .animateImage:
            makeImageTask(name: title, width: 832, height: 480)
        case .portraitImage:
            makeImageTask(name: title, width: 480, height: 832)
        }
    }

    /// Creates the shared form of the text-to-video presets.
    private func makeTextTask(
        name: String,
        width: Int,
        height: Int,
        frameCount: Int,
        stepCount: Int
    ) -> GenerationTask {
        GenerationTask(
            name: name,
            workflow: .textToVideo,
            modelIdentifier: "AbstractFramework/wan2.2-t2v-a14b-diffusers-8bit",
            prompt: "",
            negativePrompt: "",
            width: width,
            height: height,
            frameCount: frameCount,
            targetDurationSeconds: Double(frameCount) / 16,
            framesPerSecond: 16,
            stepCount: stepCount,
            guidance: 4,
            secondaryGuidance: 3,
            flowShift: 3,
            usesLowMemoryMode: true,
            writesMetadata: true
        )
    }

    /// Creates the shared form of the starting-image presets.
    private func makeImageTask(name: String, width: Int, height: Int) -> GenerationTask {
        GenerationTask(
            name: name,
            workflow: .imageToVideo,
            modelIdentifier: "AbstractFramework/wan2.2-i2v-a14b-diffusers-8bit",
            prompt: "Describe the motion you want to see while keeping the subject and composition consistent.",
            negativePrompt: "text, watermark, distorted subject, unstable background",
            width: width,
            height: height,
            frameCount: 81,
            targetDurationSeconds: Double(81) / 16,
            framesPerSecond: 16,
            stepCount: 20,
            guidance: 4,
            secondaryGuidance: 3,
            flowShift: 3,
            usesLowMemoryMode: true,
            writesMetadata: true
        )
    }
}
