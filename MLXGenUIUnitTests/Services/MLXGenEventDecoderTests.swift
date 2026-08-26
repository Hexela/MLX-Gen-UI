import Testing
@testable import MLXGenUI

/// Verifies normalization of MLX-Gen newline-delimited JSON events.
struct MLXGenEventDecoderTests {
    /// Step counts should take precedence when deriving determinate progress.
    @Test func decodesProgressEvent() throws {
        let line = #"{"type":"progress","message":"Denoising","step":5,"total_steps":20,"progress":90}"#

        let event = try #require(MLXGenEventDecoder().decode(line))

        #expect(event.type == "progress")
        #expect(event.message == "Denoising")
        #expect(event.progressFraction == 0.25)
    }

    /// Percentage values should be normalized to a `0...1` fraction.
    @Test func normalizesPercentageProgress() throws {
        let event = try #require(MLXGenEventDecoder().decode(#"{"type":"download","progress":75}"#))

        #expect(event.progressFraction == 0.75)
    }

    /// Ordinary command output must remain available as diagnostic text.
    @Test func rejectsUnstructuredOutput() {
        #expect(MLXGenEventDecoder().decode("Downloading model files…") == nil)
    }
}
