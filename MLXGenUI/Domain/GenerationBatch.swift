import Foundation

/// Plans reproducible seeds and output names for one or more queued videos.
struct GenerationBatch: Sendable {
    /// The largest batch exposed by the editor.
    static let maximumCount = 20

    /// Returns one valid seed per video.
    ///
    /// A fixed seed is honored for a single video. Batches always receive distinct random seeds.
    static func seeds(count: Int, fixedSeed: Int?) -> [Int] {
        guard count > 0 else { return [] }
        if count == 1, let fixedSeed {
            return [fixedSeed]
        }

        var seeds: Set<Int> = []
        while seeds.count < count {
            seeds.insert(Int.random(in: 0...GenerationTaskValidator.maximumSeed))
        }
        return Array(seeds)
    }

    /// Creates a final MP4 URL whose name identifies both its creation time and seed.
    static func outputURL(baseURL: URL?, seed: Int, createdAt: Date, moviesDirectory: URL) -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: createdAt)

        let directory = baseURL?.deletingLastPathComponent() ?? moviesDirectory
        let baseName = baseURL?.deletingPathExtension().lastPathComponent ?? "mlxgen"
        return directory.appending(path: "\(baseName)-\(timestamp)-seed-\(seed).mp4")
    }
}
