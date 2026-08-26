import Foundation

/// Runs command-line tools serially and captures their output.
actor ProcessCommandRunner: CommandRunning {
    /// Launches an executable without passing values through a shell.
    ///
    /// - Parameters:
    ///   - executableURL: The executable to launch.
    ///   - arguments: Arguments passed directly to the executable.
    /// - Returns: The process exit status and captured UTF-8 output.
    func run(executableURL: URL, arguments: [String]) async throws -> CommandResult {
        try Task.checkCancellation()

        let process = Process()
        let standardOutput = Pipe()
        let standardError = Pipe()
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = standardOutput
        process.standardError = standardError

        try process.run()
        process.waitUntilExit()
        try Task.checkCancellation()

        return CommandResult(
            exitCode: process.terminationStatus,
            standardOutput: String(decoding: standardOutput.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
            standardError: String(decoding: standardError.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        )
    }
}
