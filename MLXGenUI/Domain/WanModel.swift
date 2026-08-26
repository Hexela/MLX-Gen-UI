import Foundation

/// A curated Wan model that MLXGenUI can download and use.
struct WanModel: Identifiable, Equatable, Hashable, Sendable {
    /// The repository identifier passed to MLX-Gen.
    let id: String
    /// A concise user-facing model name.
    let name: String
    /// The generation workflows supported by the model.
    let workflows: Set<GenerationWorkflow>
    /// Storage guidance shown before a potentially large download.
    let storageSummary: String
    /// A short explanation of the model's intended use.
    let summary: String
    /// The model's recommended frame count for a stable individual shot.
    let recommendedSegmentFrames: Int
    /// Ordered frame counts accepted as continuation context.
    let supportedContextFrameCounts: [Int]
    /// The paired image-to-video model used to continue a text-generated first segment.
    let continuationModelIdentifier: String?

    /// The initial curated Wan model catalog.
    static let catalog: [WanModel] = [
        WanModel(
            id: "AbstractFramework/wan2.2-t2v-a14b-diffusers-8bit",
            name: "Wan 2.2 A14B Text to Video",
            workflows: [.textToVideo],
            storageSummary: "Large download; substantial unified memory required",
            summary: "The preferred quality-focused model for video generated entirely from text.",
            recommendedSegmentFrames: 81,
            supportedContextFrameCounts: [5, 9, 13],
            continuationModelIdentifier: "AbstractFramework/wan2.2-i2v-a14b-diffusers-8bit"
        ),
        WanModel(
            id: "AbstractFramework/wan2.2-i2v-a14b-diffusers-8bit",
            name: "Wan 2.2 A14B Image to Video",
            workflows: [.imageToVideo],
            storageSummary: "Large download; substantial unified memory required",
            summary: "Animates a starting image while preserving its subject and composition.",
            recommendedSegmentFrames: 81,
            supportedContextFrameCounts: [5, 9, 13],
            continuationModelIdentifier: "AbstractFramework/wan2.2-i2v-a14b-diffusers-8bit"
        ),
        WanModel(
            id: "AbstractFramework/wan2.2-ti2v-5b-diffusers-8bit",
            name: "Wan 2.2 TI2V 5B",
            workflows: [.textToVideo, .imageToVideo],
            storageSummary: "Approximately 17 GiB",
            summary: "A smaller package that supports both text and starting-image workflows.",
            recommendedSegmentFrames: 121,
            supportedContextFrameCounts: [],
            continuationModelIdentifier: nil
        )
    ]

    /// Returns curated models that support a workflow.
    ///
    /// - Parameter workflow: The generation workflow to support.
    /// - Returns: Models in their preferred display order.
    static func available(for workflow: GenerationWorkflow) -> [WanModel] {
        catalog.filter { $0.workflows.contains(workflow) }
    }

    /// Finds a curated model by its repository identifier.
    ///
    /// - Parameter identifier: The repository identifier to find.
    /// - Returns: The matching model, or `nil` when it is not in the curated catalog.
    static func model(withIdentifier identifier: String) -> WanModel? {
        catalog.first { $0.id == identifier }
    }
}
