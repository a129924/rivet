import Foundation
import Testing

@testable import GitHubConnectionVerification

@Suite("Verification host isolation")
struct VerificationHostIsolationTests {
  @MainActor @Test func testGuardIgnoresMalformedValidationBeforeLiveConstruction() {
    _ = GitHubConnectionVerificationComposition.makeCoordinator(environment: [
      "GITHUB_CONNECTION_VERIFICATION_UNIT_TEST_MODE": "1",
      "GITHUB_CONNECTION_VERIFICATION_MODE": "invalid",
      "GITHUB_CONNECTION_VERIFICATION_RECEIPT": "/invalid-unused-receipt",
    ])
    #expect(VerificationDependencyAudit.liveConstructionCount == 0)
    #expect(VerificationDependencyAudit.credentialOperationCount == 0)
    #expect(VerificationDependencyAudit.networkOperationCount == 0)
    #expect(Bundle.main.bundleIdentifier == "local.rivet.github-connection-verification")
  }
}
