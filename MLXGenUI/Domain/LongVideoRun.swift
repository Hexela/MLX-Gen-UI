import Foundation

/// Persistent state for an automated multi-segment generation.
struct LongVideoRun: Codable, Equatable, Sendable {
    /// Lifecycle states written after every completed pipeline phase.
    enum Status: String, Codable, Sendable {
        /// Segment generation is in progress.
        case generating
        /// All segments exist and assembly is in progress.
        case assembling
        /// The final video was validated successfully.
        case completed
        /// The operation stopped before completion.
        case interrupted
    }

    /// The run identifier and workspace directory name.
    let identifier: UUID
    /// The original reproducible request.
    let task: GenerationTask
    /// The calculated segment recipe.
    let plan: LongVideoPlan
    /// The final destination requested by the user.
    let outputURL: URL
    /// Indices of segments known to have completed successfully.
    var completedSegmentIndices: [Int]
    /// The current lifecycle state.
    var status: Status
}
