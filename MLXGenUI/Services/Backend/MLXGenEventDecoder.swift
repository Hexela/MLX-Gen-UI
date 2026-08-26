import Foundation

/// Decodes individual newline-delimited JSON events produced by MLX-Gen.
struct MLXGenEventDecoder: Sendable {
    /// Decodes a structured event when a line contains supported JSON.
    ///
    /// - Parameter line: One complete UTF-8 output line.
    /// - Returns: A decoded event, or `nil` for ordinary diagnostic output.
    func decode(_ line: String) -> MLXGenEvent? {
        guard let data = line.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MLXGenEvent.self, from: data)
    }
}
