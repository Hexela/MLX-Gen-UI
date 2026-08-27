import Foundation

/// Persists a run manifest alongside its intermediate video files.
actor LongVideoRunStore {
    /// Root directory for transient generation workspaces.
    private let rootURL: URL

    /// Creates a store rooted in `/tmp`, or in an injected directory for tests.
    ///
    /// - Parameter rootURL: Directory that contains per-run workspaces.
    init(
        rootURL: URL = URL(filePath: "/tmp", directoryHint: .isDirectory)
            .appending(path: "MLXGenUI/LongVideoRuns", directoryHint: .isDirectory)
    ) {
        self.rootURL = rootURL
    }

    /// Creates and returns a private workspace for a new run.
    func createWorkspace(for runIdentifier: UUID) throws -> URL {
        let workspaceURL = rootURL.appending(
            path: runIdentifier.uuidString,
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
        return workspaceURL
    }

    /// Atomically writes the latest resumable run state.
    func save(_ run: LongVideoRun, in workspaceURL: URL) throws {
        try FileManager.default.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(run)
        let manifestURL = workspaceURL.appending(path: "run.json")

        do {
            try data.write(to: manifestURL, options: .atomic)
        } catch let error as CocoaError where error.code == .fileWriteNoPermission {
            // Some long-running child processes can leave macOS unable to perform
            // the temporary-file rename used by `.atomic`, even though the existing
            // manifest itself remains writable. A direct overwrite safely preserves
            // resumable state instead of aborting the whole generation.
            try data.write(to: manifestURL)
        }
    }
}
