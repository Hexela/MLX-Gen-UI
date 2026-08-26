import Foundation

/// Inspects the command-line dependencies needed by MLXGenUI.
actor SystemStatusService {
    /// The runner used to retrieve tool versions.
    private let commandRunner: any CommandRunning
    /// The filesystem used to locate installed executables.
    private let fileManager: FileManager

    /// Creates a dependency inspection service.
    ///
    /// - Parameters:
    ///   - commandRunner: The process runner used for version checks.
    ///   - fileManager: The filesystem used to locate executable files.
    init(
        commandRunner: any CommandRunning = ProcessCommandRunner(),
        fileManager: FileManager = .default
    ) {
        self.commandRunner = commandRunner
        self.fileManager = fileManager
    }

    /// Returns the current installation state of every required backend tool.
    ///
    /// - Returns: The first missing dependency, or a ready state with discovered versions.
    func currentStatus() async throws -> SystemStatus {
        try Task.checkCancellation()

        let homebrewURL = URL(filePath: "/opt/homebrew/bin/brew")
        guard fileManager.isExecutableFile(atPath: homebrewURL.path) else {
            return .homebrewMissing
        }
        let homebrewVersion = try await version(of: homebrewURL, arguments: ["--version"])

        let uvURL = URL(filePath: "/opt/homebrew/bin/uv")
        guard fileManager.isExecutableFile(atPath: uvURL.path) else {
            return .uvMissing(homebrewVersion: homebrewVersion)
        }
        let uvVersion = try await version(of: uvURL, arguments: ["--version"])

        let mlxGenURL = fileManager.homeDirectoryForCurrentUser
            .appending(path: ".local/bin/mlxgen")
        guard fileManager.isExecutableFile(atPath: mlxGenURL.path) else {
            return .mlxGenMissing(homebrewVersion: homebrewVersion, uvVersion: uvVersion)
        }
        let mlxGenVersion = try await version(of: mlxGenURL, arguments: ["--version"])
        return .ready(
            homebrewVersion: homebrewVersion,
            uvVersion: uvVersion,
            mlxGenVersion: mlxGenVersion
        )
    }

    /// Retrieves the first line printed by a version command.
    private func version(of executableURL: URL, arguments: [String]) async throws -> String? {
        let result = try await commandRunner.run(executableURL: executableURL, arguments: arguments)
        guard result.exitCode == 0 else { return nil }
        return result.standardOutput.split(whereSeparator: \.isNewline).first.map(String.init)
    }
}
