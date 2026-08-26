import Foundation

/// Persists a run manifest alongside its intermediate video files.
actor LongVideoRunStore {
    /// Creates and returns a private workspace for a new run.
    func createWorkspace(for runIdentifier: UUID) throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appending(path: "MLXGenUI/LongVideoRuns/\(runIdentifier.uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    /// Atomically writes the latest resumable run state.
    func save(_ run: LongVideoRun, in workspaceURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(run).write(
            to: workspaceURL.appending(path: "run.json"),
            options: .atomic
        )
    }
}
