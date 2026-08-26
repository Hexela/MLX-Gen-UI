import Foundation

/// Predicts generation duration from successful local generation history.
struct GenerationTimeEstimator: Sendable {
    /// Produces the best estimate supported by compatible historical samples.
    ///
    /// The calculation normalizes each run by its generated pixels, frames, and
    /// denoising steps. It prefers runs with the same memory and segment shape,
    /// then progressively broadens within the same model. Different models are
    /// never mixed because their performance characteristics vary substantially.
    func estimate(
        for task: GenerationTask,
        from records: [GeneratedVideoRecord]
    ) -> GenerationTimeEstimate? {
        guard let targetProfile = profile(for: task) else { return nil }

        let samples = records.compactMap { record -> Sample? in
            guard let duration = record.generationDurationSeconds,
                  duration.isFinite,
                  duration > 0,
                  let profile = profile(for: record.task) else {
                return nil
            }
            return Sample(profile: profile, secondsPerWorkUnit: duration / profile.workUnits)
        }

        let matchingSamples = preferredSamples(from: samples, for: targetProfile)
        guard matchingSamples.isEmpty == false else { return nil }

        let rates = matchingSamples.map(\.secondsPerWorkUnit).sorted()
        let middle = rates.count / 2
        let medianRate = rates.count.isMultiple(of: 2)
            ? (rates[middle - 1] + rates[middle]) / 2
            : rates[middle]
        let predictedSeconds = medianRate * targetProfile.workUnits
        guard predictedSeconds.isFinite, predictedSeconds > 0 else { return nil }

        return GenerationTimeEstimate(
            duration: .seconds(predictedSeconds),
            confidence: confidence(for: matchingSamples.count),
            sampleCount: matchingSamples.count
        )
    }

    /// Selects the narrowest useful group of samples for the current task.
    private func preferredSamples(from samples: [Sample], for target: Profile) -> [Sample] {
        let sameModel = samples.filter { $0.profile.modelIdentifier == target.modelIdentifier }
        let sameWorkflow = sameModel.filter { $0.profile.workflow == target.workflow }
        let sameMemoryMode = sameWorkflow.filter {
            $0.profile.usesLowMemoryMode == target.usesLowMemoryMode
        }
        let sameSegmentShape = sameMemoryMode.filter {
            $0.profile.requiresAssembly == target.requiresAssembly
        }

        if sameSegmentShape.isEmpty == false { return sameSegmentShape }
        if sameMemoryMode.isEmpty == false { return sameMemoryMode }
        if sameWorkflow.isEmpty == false { return sameWorkflow }
        return sameModel
    }

    /// Converts a generation task into comparable computational work.
    private func profile(for task: GenerationTask) -> Profile? {
        guard task.width > 0,
              task.height > 0,
              task.stepCount > 0,
              let model = WanModel.model(withIdentifier: task.modelIdentifier) else {
            return nil
        }

        let plan = LongVideoPlanner().makePlan(for: task, model: model)
        let generatedFrames = plan.segments.reduce(0) { $0 + $1.frameCount }
        let workUnits = Double(task.width)
            * Double(task.height)
            * Double(generatedFrames)
            * Double(task.stepCount)
        guard workUnits.isFinite, workUnits > 0 else { return nil }

        return Profile(
            modelIdentifier: task.modelIdentifier,
            workflow: task.workflow,
            usesLowMemoryMode: task.usesLowMemoryMode,
            requiresAssembly: plan.requiresAssembly,
            workUnits: workUnits
        )
    }

    /// Maps sample volume to a simple user-facing confidence tier.
    private func confidence(for sampleCount: Int) -> GenerationTimeEstimateConfidence {
        switch sampleCount {
        case 6...: .high
        case 3...5: .medium
        default: .low
        }
    }

    /// Comparable generation characteristics and their normalized work.
    private struct Profile: Sendable {
        let modelIdentifier: String
        let workflow: GenerationWorkflow
        let usesLowMemoryMode: Bool
        let requiresAssembly: Bool
        let workUnits: Double
    }

    /// One historical run represented as time per normalized work unit.
    private struct Sample: Sendable {
        let profile: Profile
        let secondsPerWorkUnit: Double
    }
}
