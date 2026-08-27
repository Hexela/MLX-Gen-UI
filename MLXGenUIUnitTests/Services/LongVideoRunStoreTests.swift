import Foundation
import Testing
@testable import MLXGenUI

struct LongVideoRunStoreTests {
    @Test func defaultWorkspaceIsCreatedUnderTmp() async throws {
        let expectedRoot = URL(filePath: "/tmp", directoryHint: .isDirectory)
            .appending(path: "MLXGenUI/LongVideoRuns", directoryHint: .isDirectory)
        let store = LongVideoRunStore()
        let runIdentifier = UUID()

        let workspaceURL = try await store.createWorkspace(for: runIdentifier)
        defer { try? FileManager.default.removeItem(at: workspaceURL) }

        #expect(workspaceURL == expectedRoot.appending(path: runIdentifier.uuidString))
        #expect(FileManager.default.fileExists(atPath: workspaceURL.path))
    }

    @Test func existingManifestCanBeUpdated() async throws {
        let workspaceURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: workspaceURL) }
        let store = LongVideoRunStore(rootURL: workspaceURL.deletingLastPathComponent())
        let task = GenerationPreset.qualityTextVideo.makeTask()
        let plan = LongVideoPlanner().makePlan(for: task, model: WanModel.catalog[0])
        var run = LongVideoRun(
            identifier: UUID(),
            task: task,
            plan: plan,
            outputURL: workspaceURL.appending(path: "output.mp4"),
            completedSegmentIndices: [],
            status: .generating
        )

        try await store.save(run, in: workspaceURL)
        run.completedSegmentIndices = [0]
        run.status = .interrupted
        try await store.save(run, in: workspaceURL)

        let data = try Data(contentsOf: workspaceURL.appending(path: "run.json"))
        let restored = try JSONDecoder().decode(LongVideoRun.self, from: data)
        #expect(restored == run)
    }
}
