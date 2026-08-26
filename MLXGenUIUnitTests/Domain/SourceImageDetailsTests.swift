import Testing
@testable import MLXGenUI

struct SourceImageDetailsTests {
    @Test func matchingImageNeedsNoRecommendation() {
        let details = SourceImageDetails(width: 1664, height: 960)

        #expect(details.recommendations(targetWidth: 832, targetHeight: 480).isEmpty)
    }

    @Test func smallImageExplainsResolutionRisk() {
        let details = SourceImageDetails(width: 416, height: 240)

        let recommendations = details.recommendations(targetWidth: 832, targetHeight: 480)

        #expect(recommendations.count == 1)
        #expect(recommendations[0].contains("smaller"))
    }

    @Test func mismatchedImageExplainsCroppingRisk() {
        let details = SourceImageDetails(width: 1000, height: 1000)

        let recommendations = details.recommendations(targetWidth: 832, targetHeight: 480)

        #expect(recommendations.count == 1)
        #expect(recommendations[0].contains("aspect ratio"))
    }
}
