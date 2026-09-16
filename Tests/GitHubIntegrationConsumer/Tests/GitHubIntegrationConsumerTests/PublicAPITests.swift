import Foundation
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
    case .missingCredential, .tokenAcquisition:
      Issue.record("Expected the public token-store error case")
    }

    assertSendable(TokenStoreOperation.load)
    assertSendable(storeError)
    assertSendable(GitHubCredentialError.missingCredential)
    assertSendable(GitHubCredentialError.tokenAcquisition(StoreFailure()))
  }

  @Test
  func publicOAuthCredentialBundleSurfaceIsAvailableAndSendable() {
    let accessToken = GitHubAccessToken(rawValue: "consumer-access-token")
    let refreshToken = GitHubOAuthRefreshToken(rawValue: "consumer-refresh-token")
    let accessTokenExpiresAt = Date.distantFuture
    let refreshTokenExpiresAt = Date.distantPast
    let bundle = GitHubOAuthCredentialBundle(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessTokenExpiresAt,
      refreshTokenExpiresAt: refreshTokenExpiresAt,
      tokenType: .bearer,
      grantedScopes: "repo,gist"
    )

    let hasExpectedAccessTokenPrefix = bundle.accessToken.rawValue.hasPrefix("consumer-")
    let hasExpectedRefreshTokenPrefix = bundle.refreshToken.rawValue.hasPrefix("consumer-")

    #expect(hasExpectedAccessTokenPrefix)
    #expect(hasExpectedRefreshTokenPrefix)
    #expect(bundle.accessTokenExpiresAt == accessTokenExpiresAt)
    #expect(bundle.refreshTokenExpiresAt == refreshTokenExpiresAt)
    #expect(bundle.tokenType == .bearer)
    #expect(bundle.grantedScopes == "repo,gist")
    assertSendable(refreshToken)
    assertSendable(bundle.tokenType)
    assertSendable(bundle)
  }

  @Test
  func asyncAccessTokenProviderCanBeUsedThroughThePublicContract() async throws {
    let expected = GitHubAccessToken(rawValue: "consumer-token")
    let provider: any GitHubAccessTokenProvider = ExternalAccessTokenProvider(token: expected)

    let actual = try await provider.token()

    #expect(actual.rawValue == expected.rawValue)
    assertSendable(provider)
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
  func inMemoryStoreCanBeUsedThroughThePublicStoreExistential() throws {
    let store: any GitHubTokenStore = InMemoryGitHubTokenStore()
    let expected = GitHubAccessToken(rawValue: "consumer-token")

    try store.save(expected)
    #expect(try store.load()?.rawValue == expected.rawValue)

    try store.delete()
    #expect(try store.load() == nil)
  }

  @Test
  func keychainStoreCanBeConstructedThroughThePublicStoreExistential() {
    let store: any GitHubTokenStore = KeychainTokenStore()

    _ = store
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

private struct ExternalAccessTokenProvider: GitHubAccessTokenProvider {
  let providedToken: GitHubAccessToken

  init(token: GitHubAccessToken) {
    providedToken = token
  }

  func token() async throws(GitHubCredentialError) -> GitHubAccessToken {
    providedToken
  }
}

private func assertSendable<Value: Sendable>(_ value: Value) {}
