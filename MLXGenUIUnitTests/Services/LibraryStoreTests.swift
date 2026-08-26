import Foundation
import Testing
@testable import MLXGenUI

/// Verifies persistent task, generation-attempt, and generated-video libraries.
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
            createdAt: .now,
            generationDurationSeconds: 123
        )

        _ = try await store.add(record, to: [])
        let loaded = try await store.loadVideos()

        #expect(loaded == [record])
    }

    /// Video records written before timing was introduced should continue to decode.
    @Test func generatedVideoWithoutTimingRemainsCompatible() throws {
        let record = GeneratedVideoRecord(
            id: UUID(),
            task: GenerationPreset.quickTextPreview.makeTask(),
            outputURL: URL(filePath: "/tmp/legacy.mp4"),
            createdAt: .now
        )
        let data = try JSONEncoder().encode(record)

        let decoded = try JSONDecoder().decode(GeneratedVideoRecord.self, from: data)

        #expect(decoded.generationDurationSeconds == nil)
    }

    /// Every generation attempt should retain all submitted task options independently.
    @Test func generationHistoryRetainsEachAttempt() async throws {
        let directoryURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let store = LibraryStore(directoryURL: directoryURL)
        var firstTask = GenerationPreset.animateImage.makeTask()
        firstTask.prompt = "First motion"
        firstTask.sourceImageURL = URL(filePath: "/tmp/source image.png")
        var secondTask = firstTask
        secondTask.prompt = "Second motion"
        secondTask.guidance = 6
        let firstRecord = GenerationHistoryRecord(id: UUID(), task: firstTask, attemptedAt: .now)
        let secondRecord = GenerationHistoryRecord(
            id: UUID(),
            task: secondTask,
            attemptedAt: firstRecord.attemptedAt.addingTimeInterval(1)
        )

        var records = try await store.add(firstRecord, to: [])
        records = try await store.add(secondRecord, to: records)
        let loaded = try await store.loadGenerationHistory()

        #expect(loaded == [secondRecord, firstRecord])
        #expect(loaded.last?.task.sourceImageURL == firstTask.sourceImageURL)
        #expect(loaded.first?.task.guidance == 6)
    }
}
