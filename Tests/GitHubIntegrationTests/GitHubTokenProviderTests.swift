import GitHubIntegration
import Testing

@Suite("GitHub token provider")
struct GitHubTokenProviderTests {
  @Test
  func providerReturnsTheStoreTokenUnchanged() throws {
    let token = GitHubAccessToken(rawValue: "test-token")
    let provider = TokenStoreGitHubTokenProvider(store: MockTokenStore(loadResult: .success(token)))

    let provided = try provider.token()

    #expect(provided.rawValue == token.rawValue)
  }

  @Test
  func providerMapsAnAbsentStoreTokenToMissingCredential() {
    let provider = TokenStoreGitHubTokenProvider(store: MockTokenStore(loadResult: .success(nil)))

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
  func providerMapsStoreLoadFailureWithoutChangingItsDetails() {
    let underlyingError = UnderlyingStoreFailure.load
    let storeError = TokenStoreError(operation: .load, underlyingError: underlyingError)
    let provider = TokenStoreGitHubTokenProvider(
      store: MockTokenStore(loadResult: .failure(storeError))
    )

    do {
      _ = try provider.token()
      Issue.record("Expected a token store failure")
    } catch let error {
      guard case .tokenStore(let actualError) = error else {
        Issue.record("Expected GitHubCredentialError.tokenStore")
        return
      }

      switch actualError.operation {
      case .load:
        break
      case .save, .delete:
        Issue.record("Expected the load operation")
      }
      guard let actualUnderlyingError = actualError.underlyingError as? UnderlyingStoreFailure,
        case .load = actualUnderlyingError
      else {
        Issue.record("Expected the original underlying error")
        return
      }
    }
  }

  @Test
  func externalMockStoreAndProviderConformToPublicTypedThrowsContracts() throws {
    let store: any GitHubTokenStore = MockTokenStore(
      loadResult: .success(GitHubAccessToken(rawValue: "test-token"))
    )
    let provider: any GitHubTokenProvider = TokenStoreGitHubTokenProvider(store: store)

    _ = try provider.token()
  }
}

private struct MockTokenStore: GitHubTokenStore {
  let loadResult: Result<GitHubAccessToken?, TokenStoreError>

  func load() throws(TokenStoreError) -> GitHubAccessToken? {
    try loadResult.get()
  }

  func save(_ token: GitHubAccessToken) throws(TokenStoreError) {}

  func delete() throws(TokenStoreError) {}
}

private enum UnderlyingStoreFailure: Error {
  case load
}
