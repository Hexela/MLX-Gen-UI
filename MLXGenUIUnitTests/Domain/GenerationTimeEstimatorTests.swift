import Foundation
import Testing
@testable import MLXGenUI

/// Verifies predictions learned from successful local generation history.
struct GenerationTimeEstimatorTests {
    /// Comparable work should scale with resolution while retaining the historical rate.
    @Test func estimateScalesWithResolution() throws {
        let sampleTask = GenerationPreset.quickTextPreview.makeTask()
        var targetTask = sampleTask
        targetTask.width *= 2
        let record = successfulRecord(task: sampleTask, duration: 100)

        let estimate = try #require(
            GenerationTimeEstimator().estimate(for: targetTask, from: [record])
        )

        #expect(estimate.duration == .seconds(200))
        #expect(estimate.confidence == .low)
        #expect(estimate.sampleCount == 1)
    }

    /// The median rate should prevent an unusually slow run from dominating predictions.
    @Test func estimateUsesMedianNormalizedRate() throws {
        let task = GenerationPreset.quickTextPreview.makeTask()
        let records = [100.0, 110.0, 10_000.0].map {
            successfulRecord(task: task, duration: $0)
        }

        let estimate = try #require(
            GenerationTimeEstimator().estimate(for: task, from: records)
        )

        #expect(abs(seconds(in: estimate.duration) - 110) < 0.000_001)
        #expect(estimate.confidence == .medium)
    }

    /// Samples with an exact memory-mode match should be preferred over broader history.
    @Test func estimatePrefersMatchingMemoryMode() throws {
        var lowMemoryTask = GenerationPreset.quickTextPreview.makeTask()
        lowMemoryTask.usesLowMemoryMode = true
        var fullMemoryTask = lowMemoryTask
        fullMemoryTask.usesLowMemoryMode = false
        let records = [
            successfulRecord(task: lowMemoryTask, duration: 200),
            successfulRecord(task: fullMemoryTask, duration: 50)
        ]

        let estimate = try #require(
            GenerationTimeEstimator().estimate(for: lowMemoryTask, from: records)
        )

        #expect(estimate.duration == .seconds(200))
        #expect(estimate.sampleCount == 1)
    }

    /// Performance from a different model must not be used as a prediction.
    @Test func estimateDoesNotMixModels() {
        let targetTask = GenerationPreset.quickTextPreview.makeTask()
        let otherTask = GenerationPreset.animateImage.makeTask()
        let record = successfulRecord(task: otherTask, duration: 100)

        let estimate = GenerationTimeEstimator().estimate(for: targetTask, from: [record])

        #expect(estimate == nil)
    }

    /// Records without valid successful timing data should be ignored.
    @Test func estimateIgnoresMissingAndInvalidDurations() {
        let task = GenerationPreset.quickTextPreview.makeTask()
        let records = [
            successfulRecord(task: task, duration: nil),
            successfulRecord(task: task, duration: 0),
            successfulRecord(task: task, duration: -.infinity)
        ]

        let estimate = GenerationTimeEstimator().estimate(for: task, from: records)

        #expect(estimate == nil)
    }

    /// Creates a completed video record with injectable performance data.
    private func successfulRecord(
        task: GenerationTask,
        duration: Double?
    ) -> GeneratedVideoRecord {
        GeneratedVideoRecord(
            id: UUID(),
            task: task,
            outputURL: URL(filePath: "/tmp/result.mp4"),
            createdAt: .now,
            generationDurationSeconds: duration
        )
    }

    /// Converts a duration for tolerance-based floating-point assertions.
    private func seconds(in duration: Duration) -> Double {
        let parts = duration.components
        return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
    }
}
