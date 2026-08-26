import Foundation

/// A video-generation workflow supported by the initial application release.
enum GenerationWorkflow: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Generates a video using only a text prompt.
    case textToVideo
    /// Animates a user-selected starting image using a text prompt.
    case imageToVideo

    /// The stable identity used by SwiftUI controls.
    var id: Self { self }

    /// The user-facing workflow name.
    var title: String {
        switch self {
        case .textToVideo: "Text to Video"
        case .imageToVideo: "Starting Image to Video"
        }
    }
}
