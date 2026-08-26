import Foundation

/// The readiness of Homebrew, uv, and the MLX-Gen backend.
enum SystemStatus: Equatable, Sendable {
    /// Dependency inspection has not finished.
    case checking
    /// The Mac does not have Homebrew at its standard Apple Silicon location.
    case homebrewMissing
    /// Homebrew is present but uv is not installed.
    case uvMissing(homebrewVersion: String?)
    /// uv is present but MLX-Gen is not installed as a tool.
    case mlxGenMissing(homebrewVersion: String?, uvVersion: String?)
    /// Every dependency is available.
    case ready(homebrewVersion: String?, uvVersion: String?, mlxGenVersion: String?)
    /// Inspection failed before a more specific state could be established.
    case unavailable

    /// A concise user-facing summary.
    var title: String {
        switch self {
        case .checking: "Checking system…"
        case .homebrewMissing: "Homebrew is required"
        case .uvMissing: "uv is not installed"
        case .mlxGenMissing: "MLX-Gen is not installed"
        case .ready: "Ready to generate"
        case .unavailable: "System status unavailable"
        }
    }

    /// A symbol that communicates the status without relying on color.
    var systemImage: String {
        switch self {
        case .checking: "arrow.trianglehead.2.clockwise.rotate.90"
        case .ready: "checkmark.circle.fill"
        case .homebrewMissing, .uvMissing, .mlxGenMissing: "exclamationmark.triangle.fill"
        case .unavailable: "xmark.circle.fill"
        }
    }

    /// `true` when every backend dependency is available.
    var isReady: Bool {
        if case .ready = self { true } else { false }
    }
}
