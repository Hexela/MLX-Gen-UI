import Foundation

/// User-visible state for the single backend operation managed by the app.
struct BackendOperationState: Equatable, Sendable {
    /// The operation's user-facing title.
    var title: String
    /// The most recent meaningful status message.
    var message: String
    /// Determinate progress when reported by MLX-Gen.
    var progressFraction: Double?
    /// Recent diagnostic output retained for troubleshooting.
    var outputLines: [String]
    /// `true` after the process exits successfully.
    var isComplete: Bool
    /// `true` while the child process is active or starting.
    var isRunning: Bool

    /// Creates the initial state for a newly started operation.
    ///
    /// - Parameter title: The operation's user-facing title.
    init(title: String) {
        self.title = title
        message = "Preparing…"
        progressFraction = nil
        outputLines = []
        isComplete = false
        isRunning = true
    }

    /// Adds a diagnostic line while retaining a bounded in-memory history.
    ///
    /// - Parameter line: The new output line.
    mutating func appendOutput(_ line: String) {
        outputLines.append(line)
        if outputLines.count > 200 {
            outputLines.removeFirst(outputLines.count - 200)
        }
    }
}
