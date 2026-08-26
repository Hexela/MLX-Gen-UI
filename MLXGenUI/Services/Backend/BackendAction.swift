import Foundation

/// A user-authorized backend installation, update, or model-download operation.
enum BackendAction: Equatable, Sendable {
    /// Installs uv with Homebrew.
    case installUV
    /// Installs or upgrades MLX-Gen through uv.
    case installMLXGen
    /// Upgrades an existing MLX-Gen tool installation.
    case updateMLXGen
    /// Downloads a model into MLX-Gen's local cache.
    case downloadModel(WanModel)

    /// A concise title suitable for progress presentation.
    var title: String {
        switch self {
        case .installUV: "Installing uv"
        case .installMLXGen: "Installing MLX-Gen"
        case .updateMLXGen: "Updating MLX-Gen"
        case .downloadModel(let model): "Downloading \(model.name)"
        }
    }
}

/// Creates safe command invocations for user-authorized backend maintenance.
struct BackendActionCommandBuilder: Sendable {
    /// Creates the command for one backend action.
    ///
    /// - Parameters:
    ///   - action: The user-authorized action to perform.
    ///   - homeDirectory: The current user's home directory.
    /// - Returns: An executable and arguments that can be passed directly to `Process`.
    func makeCommand(for action: BackendAction, homeDirectory: URL) -> GenerationCommand {
        switch action {
        case .installUV:
            GenerationCommand(
                executableURL: URL(filePath: "/opt/homebrew/bin/brew"),
                arguments: ["install", "uv"]
            )
        case .installMLXGen:
            GenerationCommand(
                executableURL: URL(filePath: "/opt/homebrew/bin/uv"),
                arguments: ["tool", "install", "--upgrade", "mlx-gen"]
            )
        case .updateMLXGen:
            GenerationCommand(
                executableURL: URL(filePath: "/opt/homebrew/bin/uv"),
                arguments: ["tool", "upgrade", "mlx-gen"]
            )
        case .downloadModel(let model):
            GenerationCommand(
                executableURL: homeDirectory.appending(path: ".local/bin/mlxgen"),
                arguments: ["download", "--model", model.id]
            )
        }
    }
}
