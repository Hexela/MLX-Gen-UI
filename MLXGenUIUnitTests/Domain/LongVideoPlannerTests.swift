import Testing
@testable import MLXGenUI

struct LongVideoPlannerTests {
    @Test func shortRequestUsesOneModelValidSegment() {
        var task = GenerationPreset.qualityTextVideo.makeTask()
        task.targetDurationSeconds = 3

        let plan = LongVideoPlanner().makePlan(for: task, model: WanModel.catalog[0])

        #expect(plan.segments == [.init(index: 0, frameCount: 49, overlapFrameCount: 0)])
        #expect(plan.requiresAssembly == false)
    }

    @Test func longRequestAccountsForHandoverOverlap() {
        var task = GenerationPreset.qualityTextVideo.makeTask()
        task.targetDurationSeconds = 12

        let plan = LongVideoPlanner().makePlan(for: task, model: WanModel.catalog[0])

        #expect(plan.targetFrameCount == 192)
        #expect(plan.segments.count == 3)
        #expect(plan.segments.map(\.overlapFrameCount) == [0, 5, 5])
        #expect(plan.segments.map(\.frameCount) == [81, 81, 41])
        #expect(plan.continuationModelIdentifier == "AbstractFramework/wan2.2-i2v-a14b-diffusers-8bit")
    }
}
