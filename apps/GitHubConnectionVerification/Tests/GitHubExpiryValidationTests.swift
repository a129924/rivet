import Foundation
import GitHubIntegration
import Testing

@testable import GitHubConnectionVerification

@Suite("Verification controlled clock")
struct GitHubExpiryValidationTests {
  @Test func observeNeverForcesExpiry() {
    let validation = GitHubExpiryValidation(mode: .observe)
    let bundle = GitHubOAuthCredentialBundle(
      accessToken: .init(rawValue: "fake-access"), refreshToken: .init(rawValue: "fake-refresh"),
      accessTokenExpiresAt: .distantFuture, refreshTokenExpiresAt: .distantFuture,
      tokenType: .bearer, grantedScopes: "")
    validation.restored(bundle)
    validation.arm(bundle)
    #expect(!validation.snapshot().forcedExpiryApplied)
    #expect(abs(validation.now().timeIntervalSinceNow) < 2)
  }
}
