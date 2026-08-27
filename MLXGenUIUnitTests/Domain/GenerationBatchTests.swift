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

    @Test func outputNameContainsCompactDateSeedAndModelWithoutSlashes() throws {
        let date = try #require(
            Calendar(identifier: .gregorian).date(
                from: DateComponents(
                    timeZone: TimeZone(secondsFromGMT: 0),
                    year: 2026,
                    month: 8,
                    day: 27,
                    hour: 14,
                    minute: 15,
                    second: 16
                )
            )
        )
        let URL = GenerationBatch.outputURL(
            baseURL: URL(filePath: "/tmp/my-video.mp4"),
            seed: 1234,
            modelIdentifier: "AbstractFramework/wan2.2-ti2v-5b-diffusers-8bit",
            createdAt: date,
            moviesDirectory: URL(filePath: "/unused"),
            timeZone: try #require(TimeZone(secondsFromGMT: 0))
        )

        #expect(URL.lastPathComponent == "202608271415-1234-wan2.2-ti2v-5b-diffusers-8bit.mp4")
        #expect(URL.lastPathComponent.contains("/") == false)
    }
}
