import Foundation

/// The local and remote revision state of a curated model.
enum ModelInstallationStatus: Equatable, Sendable {
    /// Cache and remote-revision inspection has not completed.
    case checking
    /// No complete local snapshot was found.
    case notInstalled
    /// A local snapshot exists but the remote revision could not be checked.
    case installed(localRevision: String?)
    /// The local `main` snapshot matches the current Hub revision.
    case current(revision: String)
    /// The Hub reports a newer `main` revision than the local snapshot.
    case updateAvailable(localRevision: String, remoteRevision: String)

    /// A concise status label for the model row.
    var title: String {
        switch self {
        case .checking: "Checking…"
        case .notInstalled: "Not downloaded"
        case .installed: "Downloaded"
        case .current: "Up to date"
        case .updateAvailable: "Update available"
        }
    }

    /// The action title appropriate to this state, if an action is available.
    var actionTitle: String? {
        switch self {
        case .notInstalled: "Download Model"
        case .updateAvailable: "Update Model"
        case .checking, .installed, .current: nil
        }
    }

    /// A symbol that communicates state without relying on color.
    var systemImage: String {
        switch self {
        case .checking: "arrow.trianglehead.2.clockwise.rotate.90"
        case .notInstalled: "icloud.and.arrow.down"
        case .installed: "checkmark.circle"
        case .current: "checkmark.circle.fill"
        case .updateAvailable: "arrow.down.circle.fill"
        }
    }

    /// `true` when a complete local snapshot can be used for generation.
    var isInstalled: Bool {
        switch self {
        case .installed, .current, .updateAvailable: true
        case .checking, .notInstalled: false
        }
    }
}
