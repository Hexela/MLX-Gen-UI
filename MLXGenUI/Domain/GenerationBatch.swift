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

    /// Creates a final MP4 URL whose name identifies its creation time, seed, and model.
    static func outputURL(
        baseURL: URL?,
        seed: Int,
        modelIdentifier: String,
        createdAt: Date,
        moviesDirectory: URL,
        timeZone: TimeZone = .current
    ) -> URL {
        let timestamp = createdAt.formatted(
            .verbatim(
                "\(year: .defaultDigits)\(month: .twoDigits)\(day: .twoDigits)\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased))\(minute: .twoDigits)",
                locale: Locale(identifier: "en_US_POSIX"),
                timeZone: timeZone,
                calendar: Calendar(identifier: .gregorian)
            )
        )
        let directory = baseURL?.deletingLastPathComponent() ?? moviesDirectory
        let repositoryName = modelIdentifier.split(separator: "/").last.map(String.init) ?? "model"
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let safeModelName = repositoryName
            .components(separatedBy: allowedCharacters.inverted)
            .filter { $0.isEmpty == false }
            .joined(separator: "-")
        let modelName = safeModelName.isEmpty ? "model" : safeModelName
        return directory.appending(path: "\(timestamp)-\(seed)-\(modelName).mp4")
    }
}
