import Foundation

/// Persists saved tasks and generated-video history in Application Support.
actor LibraryStore {
    /// The filesystem used to read and write library data.
    private let fileManager: FileManager
    /// The directory containing both library JSON files.
    private let directoryURL: URL

    /// Creates a library store at an injectable location.
    ///
    /// - Parameters:
    ///   - directoryURL: The directory used for library files, or the app's Application Support directory by default.
    ///   - fileManager: The filesystem used for persistence.
    init(directoryURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL ?? fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "MLXGenUI")
    }

    /// Loads saved tasks, returning an empty library when no file exists.
    func loadTasks() throws -> [SavedTaskRecord] {
        try load(
            [SavedTaskRecord].self,
            from: directoryURL.appending(path: "SavedTasks.json"),
            default: []
        )
    }

    /// Adds or replaces a task and persists the resulting library.
    ///
    /// - Parameters:
    ///   - task: The task to retain.
    ///   - records: The caller's current library snapshot.
    /// - Returns: The updated library sorted most-recently saved first.
    func save(_ task: GenerationTask, in records: [SavedTaskRecord]) throws -> [SavedTaskRecord] {
        var updated = records.filter { $0.id != task.identifier }
        updated.append(SavedTaskRecord(task: task, savedAt: .now))
        updated.sort { $0.savedAt > $1.savedAt }
        try persist(updated, to: directoryURL.appending(path: "SavedTasks.json"))
        return updated
    }

    /// Loads generated-video history, returning an empty library when no file exists.
    func loadVideos() throws -> [GeneratedVideoRecord] {
        try load(
            [GeneratedVideoRecord].self,
            from: directoryURL.appending(path: "GeneratedVideos.json"),
            default: []
        )
    }

    /// Adds a generated artifact and persists the resulting history.
    ///
    /// - Parameters:
    ///   - record: The completed generation to retain.
    ///   - records: The caller's current history snapshot.
    /// - Returns: The updated history sorted newest first.
    func add(_ record: GeneratedVideoRecord, to records: [GeneratedVideoRecord]) throws -> [GeneratedVideoRecord] {
        var updated = records.filter { $0.id != record.id }
        updated.append(record)
        updated.sort { $0.createdAt > $1.createdAt }
        try persist(updated, to: directoryURL.appending(path: "GeneratedVideos.json"))
        return updated
    }

    /// Decodes a library file when present.
    private func load<Value: Decodable>(
        _ type: Value.Type,
        from URL: URL,
        default defaultValue: Value
    ) throws -> Value {
        guard fileManager.fileExists(atPath: URL.path) else { return defaultValue }
        return try JSONDecoder().decode(type, from: Data(contentsOf: URL))
    }

    /// Atomically writes a Codable library value.
    private func persist<Value: Encodable>(_ value: Value, to URL: URL) throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: URL, options: .atomic)
    }
}
