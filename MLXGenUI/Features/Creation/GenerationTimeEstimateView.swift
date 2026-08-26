import SwiftUI

/// Presents a live duration estimate alongside the generation action.
struct GenerationTimeEstimateView: View {
    /// The estimate supported by successful local generation history.
    let estimate: GenerationTimeEstimate?

    var body: some View {
        if let estimate {
            Label {
                HStack(spacing: 4) {
                    Text(estimate.confidence == .low ? "Roughly" : "About")
                    Text(estimate.duration, format: durationFormat(for: estimate.duration))
                }
            } icon: {
                Image(systemName: "clock")
            }
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)
            .help(helpText(for: estimate))
        } else {
            Label("Estimate after a similar generation", systemImage: "clock")
                .foregroundStyle(.secondary)
                .help("Time estimates are learned from successful generations on this Mac.")
        }
    }

    /// Uses readable units without presenting second-level precision for long jobs.
    private func durationFormat(
        for duration: Duration
    ) -> Duration.UnitsFormatStyle {
        if duration < .seconds(90) {
            return .units(
                allowed: [.minutes],
                width: .wide,
                maximumUnitCount: 1,
                fractionalPart: .hide(rounded: .up)
            )
        }
        return .units(
            allowed: [.hours, .minutes],
            width: .wide,
            maximumUnitCount: 2
        )
    }

    /// Explains the local data supporting the displayed prediction.
    private func helpText(for estimate: GenerationTimeEstimate) -> String {
        let generationLabel = estimate.sampleCount == 1 ? "generation" : "generations"
        return "Estimated from \(estimate.sampleCount) successful similar \(generationLabel) on this Mac."
    }
}
