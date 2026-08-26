import Foundation

/// A curated Wan model that MLXGenUI can download and use.
struct WanModel: Identifiable, Equatable, Sendable {
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

    /// The initial curated Wan model catalog.
    static let catalog: [WanModel] = [
        WanModel(
            id: "AbstractFramework/wan2.2-t2v-a14b-diffusers-8bit",
            name: "Wan 2.2 A14B Text to Video",
            workflows: [.textToVideo],
            storageSummary: "Large download; substantial unified memory required",
            summary: "The preferred quality-focused model for video generated entirely from text."
        ),
        WanModel(
            id: "AbstractFramework/wan2.2-i2v-a14b-diffusers-8bit",
            name: "Wan 2.2 A14B Image to Video",
            workflows: [.imageToVideo],
            storageSummary: "Large download; substantial unified memory required",
            summary: "Animates a starting image while preserving its subject and composition."
        ),
        WanModel(
            id: "AbstractFramework/wan2.2-ti2v-5b-diffusers-8bit",
            name: "Wan 2.2 TI2V 5B",
            workflows: [.textToVideo, .imageToVideo],
            storageSummary: "Approximately 17 GiB",
            summary: "A smaller package that supports both text and starting-image workflows."
        )
    ]
}
