import GitHubIntegration
import Testing

@Suite("GitHubIntegration public consumer API")
struct PublicAPITests {
  @Test
  func publicTokenAndErrorSurfaceIsAvailableAndSendable() {
    let token = GitHubAccessToken(rawValue: "consumer-token")
    let storeError = TokenStoreError(
      operation: .save,
      underlyingError: StoreFailure()
    )

    #expect(token.rawValue == "consumer-token")
    #expect(storeError.operation == .save)

    switch GitHubCredentialError.tokenStore(storeError) {
    case .tokenStore(let actualError):
      #expect(actualError.operation == .save)
    case .missingCredential:
      Issue.record("Expected the public token-store error case")
    }

    assertSendable(TokenStoreOperation.load)
    assertSendable(storeError)
    assertSendable(GitHubCredentialError.missingCredential)
  }

  @Test
  func providerCanBeUsedThroughPublicStoreAndProviderExistentials() throws {
    let expected = GitHubAccessToken(rawValue: "consumer-token")
    let store: any GitHubTokenStore = ExternalTokenStore(loadResult: .token(expected))
    let provider: any GitHubTokenProvider = TokenStoreGitHubTokenProvider(store: store)

    let actual = try provider.token()

    #expect(actual.rawValue == expected.rawValue)
  }

  @Test
  func providerMapsAnExternalStoreMissingTokenToThePublicMissingCredentialCase() {
    let store: any GitHubTokenStore = ExternalTokenStore(loadResult: .missing)
    let provider: any GitHubTokenProvider = TokenStoreGitHubTokenProvider(store: store)

    do {
      _ = try provider.token()
      Issue.record("Expected a missing credential failure")
    } catch let error {
      guard case .missingCredential = error else {
        Issue.record("Expected GitHubCredentialError.missingCredential")
        return
      }
    }
  }

  @Test
  func providerPreservesAnExternalStoreFailurePayloadIdentity() {
    let expectedPayload = StoreFailure()
    let expectedError = TokenStoreError(
      operation: .load,
      underlyingError: expectedPayload
    )
    let store: any GitHubTokenStore = ExternalTokenStore(loadResult: .failure(expectedError))
    let provider: any GitHubTokenProvider = TokenStoreGitHubTokenProvider(store: store)

    do {
      _ = try provider.token()
      Issue.record("Expected a token store failure")
    } catch let error {
      guard case .tokenStore(let actualError) = error else {
        Issue.record("Expected GitHubCredentialError.tokenStore")
        return
      }
      guard let actualPayload = actualError.underlyingError as? StoreFailure else {
        Issue.record("Expected the external store failure payload")
        return
      }

      #expect(actualError.operation == .load)
      #expect(actualPayload === expectedPayload)
    }
  }
}

private struct ExternalTokenStore: GitHubTokenStore {
  enum LoadResult {
    case token(GitHubAccessToken)
    case missing
    case failure(TokenStoreError)
  }

  let loadResult: LoadResult

  func load() throws(TokenStoreError) -> GitHubAccessToken? {
    switch loadResult {
    case .token(let token):
      token
    case .missing:
      nil
    case .failure(let error):
      throw error
    }
  }

  func save(_ token: GitHubAccessToken) throws(TokenStoreError) {}

  func delete() throws(TokenStoreError) {}
}

private final class StoreFailure: Error, @unchecked Sendable {}

private func assertSendable<Value: Sendable>(_ value: Value) {}
