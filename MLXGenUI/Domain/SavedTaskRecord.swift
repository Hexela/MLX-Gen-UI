import Foundation

/// A generation task retained in the app's local task library.
struct SavedTaskRecord: Codable, Equatable, Identifiable, Sendable {
    /// The task identifier used as the library identity.
    var id: UUID { task.identifier }
    /// The complete reproducible generation task.
    var task: GenerationTask
    /// The most recent time the library entry was saved.
    var savedAt: Date
}
