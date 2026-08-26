import Testing
@testable import MLXGenUI

/// Verifies bounded diagnostic storage for long-running backend operations.
struct BackendOperationStateTests {
    /// Retained process output should remain bounded during very verbose operations.
    @Test func outputHistoryIsBounded() {
        var state = BackendOperationState(title: "Download")

        for index in 0..<250 {
            state.appendOutput("Line \(index)")
        }

        #expect(state.outputLines.count == 200)
        #expect(state.outputLines.first == "Line 50")
        #expect(state.outputLines.last == "Line 249")
    }
}
