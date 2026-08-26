import Foundation

/// Inspects Hugging Face's local cache and compares cached revisions with the Hub.
actor HuggingFaceModelService {
    /// The filesystem used to inspect cache files.
    private let fileManager: FileManager
    /// The provider used for lightweight remote revision checks.
    private let revisionProvider: any ModelRevisionProviding
    /// The process environment used to honor Hugging Face cache overrides.
    private let environment: [String: String]
    /// The current user's home directory.
    private let homeDirectory: URL

    /// Creates a model inspection service with injectable system dependencies.
    ///
    /// - Parameters:
    ///   - fileManager: The filesystem used to inspect local snapshots.
    ///   - revisionProvider: The provider used to fetch current Hub revisions.
    ///   - environment: Environment variables used to locate custom caches.
    ///   - homeDirectory: The current user's home directory.
    init(
        fileManager: FileManager = .default,
        revisionProvider: any ModelRevisionProviding = HubModelRevisionProvider(),
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.fileManager = fileManager
        self.revisionProvider = revisionProvider
        self.environment = environment
        self.homeDirectory = homeDirectory
    }

    /// Returns installation and update state for each requested model.
    ///
    /// - Parameter models: The model catalog to inspect.
    /// - Returns: A dictionary keyed by model repository identifier.
    func statuses(for models: [WanModel]) async -> [String: ModelInstallationStatus] {
        await withTaskGroup(of: (String, ModelInstallationStatus).self) { group in
            for model in models {
                group.addTask(name: "Inspect \(model.name)") {
                    (model.id, await self.status(for: model))
                }
            }

            var statuses: [String: ModelInstallationStatus] = [:]
            for await (identifier, status) in group {
                statuses[identifier] = status
            }
            return statuses
        }
    }

    /// Returns the local and remote revision state of one model.
    private func status(for model: WanModel) async -> ModelInstallationStatus {
        let repositoryURL = cacheRoot
            .appending(path: "models--\(model.id.replacingOccurrences(of: "/", with: "--"))")
        let localRevision = localRevision(in: repositoryURL)

        guard hasCompleteSnapshot(in: repositoryURL, revision: localRevision) else {
            return .notInstalled
        }

        guard let localRevision else {
            return .installed(localRevision: nil)
        }

        do {
            let remoteRevision = try await revisionProvider.revision(for: model.id)
            return remoteRevision == localRevision
                ? .current(revision: localRevision)
                : .updateAvailable(localRevision: localRevision, remoteRevision: remoteRevision)
        } catch {
            return .installed(localRevision: localRevision)
        }
    }

    /// The effective Hugging Face Hub cache directory.
    private var cacheRoot: URL {
        if let cache = environment["HF_HUB_CACHE"], cache.isEmpty == false {
            return URL(filePath: cache)
        }
        if let home = environment["HF_HOME"], home.isEmpty == false {
            return URL(filePath: home).appending(path: "hub")
        }
        return homeDirectory.appending(path: ".cache/huggingface/hub")
    }

    /// Reads the commit referenced by the cached `main` branch.
    private func localRevision(in repositoryURL: URL) -> String? {
        let referenceURL = repositoryURL.appending(path: "refs/main")
        guard let data = fileManager.contents(atPath: referenceURL.path),
              let revision = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              revision.isEmpty == false else {
            return nil
        }
        return revision
    }

    /// Checks for a populated snapshot matching the local reference.
    private func hasCompleteSnapshot(in repositoryURL: URL, revision: String?) -> Bool {
        let snapshotsURL = repositoryURL.appending(path: "snapshots")
        if let revision {
            var isDirectory: ObjCBool = false
            let snapshotURL = snapshotsURL.appending(path: revision)
            return fileManager.fileExists(atPath: snapshotURL.path, isDirectory: &isDirectory)
                && isDirectory.boolValue
        }
        let contents = try? fileManager.contentsOfDirectory(
            at: snapshotsURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        return contents?.isEmpty == false
    }

}

/// Provides the current remote revision for a model repository.
protocol ModelRevisionProviding: Sendable {
    /// Returns the current commit hash for a model.
    ///
    /// - Parameter modelIdentifier: The Hub repository identifier.
    func revision(for modelIdentifier: String) async throws -> String
}

/// Fetches current model revisions from the Hugging Face Hub API.
struct HubModelRevisionProvider: ModelRevisionProviding, Sendable {
    /// The network session used for model metadata requests.
    private let URLSession: URLSession

    /// Creates a Hub revision provider.
    ///
    /// - Parameter URLSession: The session used for network requests.
    init(URLSession: URLSession = .shared) {
        self.URLSession = URLSession
    }

    /// Fetches the current model repository commit from the Hugging Face Hub API.
    func revision(for modelIdentifier: String) async throws -> String {
        guard let encodedIdentifier = modelIdentifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let URL = URL(string: "https://huggingface.co/api/models/\(encodedIdentifier)") else {
            throw ModelInspectionError.invalidIdentifier(modelIdentifier)
        }
        let (data, response) = try await URLSession.data(from: URL)
        guard let HTTPResponse = response as? HTTPURLResponse,
              (200..<300).contains(HTTPResponse.statusCode) else {
            throw ModelInspectionError.invalidResponse
        }
        return try JSONDecoder().decode(HubModelResponse.self, from: data).sha
    }
}

/// The minimal Hugging Face model response needed for update checks.
private struct HubModelResponse: Decodable {
    /// The current repository commit hash.
    let sha: String
}

/// Errors encountered before a model revision can be compared.
private enum ModelInspectionError: Error {
    /// The model identifier could not form a valid Hub URL.
    case invalidIdentifier(String)
    /// The Hub returned an unsuccessful or unexpected response.
    case invalidResponse
}
