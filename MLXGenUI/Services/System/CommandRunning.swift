import Foundation

/// The captured result of a short-lived command-line process.
struct CommandResult: Sendable {
    /// The process termination status.
    let exitCode: Int32
    /// UTF-8 text written to standard output.
    let standardOutput: String
    /// UTF-8 text written to standard error.
    let standardError: String
}

/// Runs short-lived command-line processes without invoking a shell.
protocol CommandRunning: Sendable {
    /// Launches an executable and captures its output.
    ///
    /// - Parameters:
    ///   - executableURL: The executable to launch.
    ///   - arguments: Arguments passed directly to the executable.
    /// - Returns: The process exit status and captured output.
    func run(executableURL: URL, arguments: [String]) async throws -> CommandResult
}
