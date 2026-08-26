import Foundation

/// An immutable snapshot of the user options submitted for one generation attempt.
struct GenerationHistoryRecord: Codable, Equatable, Hashable, Identifiable, Sendable {
    /// A stable identity unique to this attempt.
    var id: UUID
    /// Every generation option as it was submitted.
    var task: GenerationTask
    /// The time the user confirmed generation.
    var attemptedAt: Date
}
