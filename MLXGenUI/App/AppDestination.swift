import Foundation

/// A top-level destination in the application sidebar.
enum AppDestination: String, CaseIterable, Hashable, Identifiable {
    /// The task editor for creating a video.
    case createVideo
    /// Previously saved generation tasks.
    case savedTasks
    /// Videos generated through the app.
    case generatedVideos
    /// Downloaded and available backend models.
    case models
    /// Homebrew, uv, and MLX-Gen readiness.
    case systemStatus

    /// The stable identity used by SwiftUI lists.
    var id: Self { self }

    /// The localized, user-facing destination name.
    var title: String {
        switch self {
        case .createVideo: "Create Video"
        case .savedTasks: "Saved Tasks"
        case .generatedVideos: "Generated Videos"
        case .models: "Models"
        case .systemStatus: "System Status"
        }
    }

    /// The SF Symbols name representing the destination.
    var systemImage: String {
        switch self {
        case .createVideo: "film.stack"
        case .savedTasks: "doc.on.doc"
        case .generatedVideos: "play.rectangle.on.rectangle"
        case .models: "shippingbox"
        case .systemStatus: "checkmark.circle"
        }
    }
}
