import Foundation

/// A locally generated video and the task values that created it.
struct GeneratedVideoRecord: Codable, Equatable, Hashable, Identifiable, Sendable {
    /// A stable history entry identity.
    var id: UUID
    /// The generation task used to create the video.
    var task: GenerationTask
    /// The local video artifact.
    var outputURL: URL
    /// The time generation completed.
    var createdAt: Date
}
