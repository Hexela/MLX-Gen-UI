import Foundation
import Testing
@testable import MLXGenUI

/// Verifies persistent task and generated-video libraries.
struct LibraryStoreTests {
    /// Saving the same task identity should replace rather than duplicate it.
    @Test func taskSaveReplacesExistingRecord() async throws {
        let directoryURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let store = LibraryStore(directoryURL: directoryURL)
        var task = GenerationPreset.quickTextPreview.makeTask()
        task.prompt = "First prompt"

        var records = try await store.save(task, in: [])
        task.prompt = "Updated prompt"
        records = try await store.save(task, in: records)
        let loaded = try await store.loadTasks()

        #expect(loaded.count == 1)
        #expect(loaded.first?.task.prompt == "Updated prompt")
    }

    /// Generated-video history should round-trip its task and artifact URL.
    @Test func generatedVideoRoundTrips() async throws {
        let directoryURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let store = LibraryStore(directoryURL: directoryURL)
        var task = GenerationPreset.quickTextPreview.makeTask()
        task.prompt = "A lighthouse in a storm"
        let record = GeneratedVideoRecord(
            id: UUID(),
            task: task,
            outputURL: directoryURL.appending(path: "result.mp4"),
            createdAt: .now
        )

        _ = try await store.add(record, to: [])
        let loaded = try await store.loadVideos()

        #expect(loaded == [record])
    }
}
