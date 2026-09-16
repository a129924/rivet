import GitHubIntegration
import Testing

@Suite("GitHub async access token provider")
struct GitHubAccessTokenProviderTests {
  @Test
  func externalSendableProviderConformsAndReturnsItsToken() async throws {
    let expected = GitHubAccessToken(rawValue: "async-token")
    let provider: any GitHubAccessTokenProvider = ExternalAccessTokenProvider(token: expected)

    let actual = try await provider.token()

    #expect(actual.rawValue == expected.rawValue)
    assertSendable(provider)
  }

  @Test
  func providerCanSurfaceAnAcquisitionFailureWithoutChangingItsPayload() async {
    let provider: any GitHubAccessTokenProvider = FailingAccessTokenProvider()

    do {
      _ = try await provider.token()
      Issue.record("Expected a token acquisition failure")
    } catch let error {
      guard case .tokenAcquisition(let actualError) = error,
        let failure = actualError as? AcquisitionFailure,
        case .unavailable = failure
      else {
        Issue.record("Expected the original acquisition failure")
        return
      }
    }
  }

  @Test
  func publicTokenAndCredentialErrorsAreSendable() {
    let token = GitHubAccessToken(rawValue: "async-token")
    let storeError = TokenStoreError(
      operation: .load,
      underlyingError: AcquisitionFailure.unavailable
    )
    let credentialError = GitHubCredentialError.tokenAcquisition(AcquisitionFailure.unavailable)

    assertSendable(token)
    assertSendable(storeError)
    assertSendable(credentialError)
  }
}

private struct FailingAccessTokenProvider: GitHubAccessTokenProvider {
  func token() async throws(GitHubCredentialError) -> GitHubAccessToken {
    throw .tokenAcquisition(AcquisitionFailure.unavailable)
  }
}

private enum AcquisitionFailure: Error, Sendable {
  case unavailable
}

private func assertSendable<Value: Sendable>(_ value: Value) {}

private struct ExternalAccessTokenProvider: GitHubAccessTokenProvider {
  let providedToken: GitHubAccessToken

  init(token: GitHubAccessToken) {
    providedToken = token
  }

  func token() async throws(GitHubCredentialError) -> GitHubAccessToken {
    providedToken
  }
}
