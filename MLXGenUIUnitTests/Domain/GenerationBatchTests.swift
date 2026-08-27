import Foundation
import Testing
@testable import MLXGenUI

/// Verifies batch seed assignment and traceable output naming.
struct GenerationBatchTests {
    @Test func singleVideoPreservesFixedSeed() {
        #expect(GenerationBatch.seeds(count: 1, fixedSeed: 42) == [42])
    }

    @Test func batchUsesUniqueValidSeeds() {
        let seeds = GenerationBatch.seeds(count: 20, fixedSeed: 42)

        #expect(seeds.count == 20)
        #expect(Set(seeds).count == 20)
        #expect(seeds.allSatisfy { (0...GenerationTaskValidator.maximumSeed).contains($0) })
    }

    @Test func outputNameContainsISODateAndSeed() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-08-27T14:15:16Z"))
        let URL = GenerationBatch.outputURL(
            baseURL: URL(filePath: "/tmp/my-video.mp4"),
            seed: 1234,
            createdAt: date,
            moviesDirectory: URL(filePath: "/unused")
        )

        #expect(URL.lastPathComponent == "my-video-2026-08-27T14:15:16Z-seed-1234.mp4")
    }
}
