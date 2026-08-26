import Foundation

/// The confidence attached to a historical generation-time estimate.
enum GenerationTimeEstimateConfidence: Equatable, Sendable {
    /// The estimate is based on one or two relevant generations.
    case low
    /// The estimate is based on three to five relevant generations.
    case medium
    /// The estimate is based on at least six relevant generations.
    case high
}

/// A duration prediction learned from successful generations on this Mac.
struct GenerationTimeEstimate: Equatable, Sendable {
    /// The predicted generation duration.
    let duration: Duration
    /// How much matching history supports the prediction.
    let confidence: GenerationTimeEstimateConfidence
    /// The number of successful generations included in the calculation.
    let sampleCount: Int
}
