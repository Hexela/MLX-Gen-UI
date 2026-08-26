import Foundation

/// A safely separated executable and argument list for one backend invocation.
struct GenerationCommand: Equatable, Sendable {
    /// The executable to launch.
    let executableURL: URL
    /// Arguments passed directly to the executable without shell interpretation.
    let arguments: [String]

    /// A human-readable shell representation suitable for copying into Terminal.
    ///
    /// - Important: Execution must continue using ``executableURL`` and ``arguments`` directly. This string is for display only.
    var displayString: String {
        ([executableURL.path] + arguments).map(Self.shellQuoted).joined(separator: " ")
    }

    /// Quotes one value for display in a POSIX-compatible shell.
    private static func shellQuoted(_ value: String) -> String {
        guard value.allSatisfy({ $0.isLetter || $0.isNumber || "-._/:".contains($0) }) else {
            return "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
        }
        return value
    }
}
