import Foundation
import GitHubIntegration
import Testing

@Suite("Public typed OAuth refresh contract")
struct OAuthRefreshContractTests {
  @Test
  func externalFetcherCanConformAndCallerCanExhaustivelyClassify() async {
    let fetcher: any OAuthTokenFetcher = ConsumerRefreshFetcher()
    let credential = GitHubOAuthCredentialBundle(
      accessToken: .init(rawValue: "consumer-access"),
      refreshToken: .init(rawValue: "consumer-refresh"),
      accessTokenExpiresAt: .distantFuture, refreshTokenExpiresAt: .distantFuture,
      tokenType: .bearer, grantedScopes: "")
    do {
      _ = try await fetcher.refresh(credential)
      Issue.record("Expected a typed refresh rejection")
    } catch {
      switch error {
      case .credentialRejected: break
      case .clientConfiguration, .knownTechnicalFailure, .rotationIndeterminate, .cancelled:
        Issue.record("Expected credential rejection")
      }
    }
    requireSendable(OAuthTokenRefreshError.credentialRejected)
    requireSendable(OAuthTokenRefreshError.CancellationStage.beforeRequest)
    requireSendable(OAuthTokenProviderError.authenticationRequired)
  }
}

private struct ConsumerRefreshFetcher: OAuthTokenFetcher {
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    throw .credentialRejected
  }
}

private func requireSendable<Value: Sendable>(_ value: Value) {}
