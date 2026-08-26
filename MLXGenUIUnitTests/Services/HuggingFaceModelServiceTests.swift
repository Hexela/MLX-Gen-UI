import Foundation
import Testing
@testable import MLXGenUI

/// Verifies local cache detection and remote revision comparison.
struct HuggingFaceModelServiceTests {
    /// Matching local and remote revisions should disable model downloads.
    @Test func completeMatchingSnapshotIsCurrent() async throws {
        let fixture = try ModelCacheFixture(revision: "abc123")
        defer { fixture.remove() }
        let provider = FixedRevisionProvider(revisions: [fixture.model.id: "abc123"])
        let service = HuggingFaceModelService(
            revisionProvider: provider,
            environment: ["HF_HUB_CACHE": fixture.cacheURL.path],
            homeDirectory: fixture.rootURL
        )

        let statuses = await service.statuses(for: [fixture.model])

        #expect(statuses[fixture.model.id] == .current(revision: "abc123"))
    }

    /// A changed Hub commit should offer an update rather than another download.
    @Test func changedRemoteRevisionOffersUpdate() async throws {
        let fixture = try ModelCacheFixture(revision: "local123")
        defer { fixture.remove() }
        let provider = FixedRevisionProvider(revisions: [fixture.model.id: "remote456"])
        let service = HuggingFaceModelService(
            revisionProvider: provider,
            environment: ["HF_HUB_CACHE": fixture.cacheURL.path],
            homeDirectory: fixture.rootURL
        )

        let statuses = await service.statuses(for: [fixture.model])

        #expect(
            statuses[fixture.model.id]
                == .updateAvailable(localRevision: "local123", remoteRevision: "remote456")
        )
    }

    /// A repository directory without a complete snapshot is not installed.
    @Test func missingSnapshotIsNotInstalled() async throws {
        let rootURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let model = try #require(WanModel.catalog.first)
        let service = HuggingFaceModelService(
            revisionProvider: FixedRevisionProvider(revisions: [:]),
            environment: ["HF_HUB_CACHE": rootURL.path],
            homeDirectory: rootURL
        )

        let statuses = await service.statuses(for: [model])

        #expect(statuses[model.id] == .notInstalled)
    }
}

/// Supplies deterministic Hub revisions without networking.
private struct FixedRevisionProvider: ModelRevisionProviding {
    /// Known revisions keyed by model identifier.
    let revisions: [String: String]

    /// Returns a fixture revision or throws when none was supplied.
    func revision(for modelIdentifier: String) async throws -> String {
        guard let revision = revisions[modelIdentifier] else {
            throw FixedRevisionError.missingRevision
        }
        return revision
    }
}

/// A missing remote revision in a test fixture.
private enum FixedRevisionError: Error {
    /// No revision was configured for the requested model.
    case missingRevision
}

/// A disposable Hugging Face cache containing one complete model snapshot.
private struct ModelCacheFixture {
    /// The disposable root directory.
    let rootURL: URL
    /// The configured Hub cache directory.
    let cacheURL: URL
    /// The model represented by the fixture.
    let model: WanModel

    /// Creates the reference and matching snapshot directory expected by the Hub cache.
    init(revision: String) throws {
        model = try #require(WanModel.catalog.first)
        rootURL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        cacheURL = rootURL.appending(path: "hub")
        let repositoryURL = cacheURL.appending(
            path: "models--\(model.id.replacingOccurrences(of: "/", with: "--"))"
        )
        try FileManager.default.createDirectory(
            at: repositoryURL.appending(path: "refs"),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: repositoryURL.appending(path: "snapshots/\(revision)"),
            withIntermediateDirectories: true
        )
        try Data(revision.utf8).write(to: repositoryURL.appending(path: "refs/main"))
    }

    /// Removes the disposable cache.
    func remove() {
        try? FileManager.default.removeItem(at: rootURL)
    }
}
