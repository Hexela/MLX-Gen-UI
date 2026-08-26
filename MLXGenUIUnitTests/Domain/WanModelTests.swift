import Testing
@testable import MLXGenUI

/// Verifies workflow-aware model selection behavior.
struct WanModelTests {
    /// Every model returned for a workflow must explicitly support it.
    @Test(arguments: GenerationWorkflow.allCases)
    func availableModelsSupportWorkflow(_ workflow: GenerationWorkflow) {
        let models = WanModel.available(for: workflow)

        #expect(models.isEmpty == false)
        #expect(models.allSatisfy { $0.workflows.contains(workflow) })
    }

    /// Repository identifiers should resolve to their curated model values.
    @Test func modelLookupUsesRepositoryIdentifier() throws {
        let expected = try #require(WanModel.catalog.first)

        #expect(WanModel.model(withIdentifier: expected.id) == expected)
        #expect(WanModel.model(withIdentifier: "unknown/model") == nil)
    }
}
