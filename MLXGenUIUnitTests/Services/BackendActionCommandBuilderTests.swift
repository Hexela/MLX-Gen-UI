import Foundation
import Testing
@testable import MLXGenUI

/// Verifies package-management and model-download command construction.
struct BackendActionCommandBuilderTests {
    /// Every maintenance action should use a direct executable rather than a shell.
    @Test(
        arguments: [
            BackendAction.installUV,
            .installMLXGen,
            .updateMLXGen
        ]
    )
    func actionUsesDirectExecutable(_ action: BackendAction) {
        let command = BackendActionCommandBuilder().makeCommand(
            for: action,
            homeDirectory: URL(filePath: "/Users/example")
        )

        #expect(command.executableURL.path != "/bin/sh")
        #expect(command.executableURL.path != "/bin/zsh")
        #expect(command.arguments.isEmpty == false)
    }

    /// Model identifiers containing punctuation must remain one process argument.
    @Test func modelIdentifierRemainsSingleArgument() throws {
        let model = try #require(WanModel.catalog.first)
        let command = BackendActionCommandBuilder().makeCommand(
            for: .downloadModel(model),
            homeDirectory: URL(filePath: "/Users/example")
        )

        #expect(command.arguments == ["download", "--model", model.id])
    }
}
