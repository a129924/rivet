import Foundation
import Testing

@testable import GitHubIntegration

@Suite("OAuth initial authorization session")
struct GitHubOAuthAuthorizationSessionTests {
  @Test func authorizationUsesS256AndOnlyOfflineAccess() async throws {
    let session = try makeSession()
    #expect(Mirror(reflecting: session).children.isEmpty)
    var parts = try #require(
      URLComponents(url: session.authorizationURL, resolvingAgainstBaseURL: false))
    #expect(
      parts.queryItems == [
        .init(name: "client_id", value: "fixture-id"),
        .init(name: "redirect_uri", value: "http://127.0.0.1:49152/oauth/callback"),
        .init(name: "scope", value: "offline_access"),
        .init(name: "state", value: "fixture-state"),
        .init(name: "code_challenge", value: "8Dw_rXYDuMBDOofOjlxvMNEALsULmI6c47hS_o9Dkqg"),
        .init(name: "code_challenge_method", value: "S256"),
      ])
    parts.query = nil
    #expect(parts.url?.absoluteString == "https://github.com/login/oauth/authorize")
  }

  @Test func invalidCallbacksDoNotClaimButValidCompletesOnce() async throws {
    let counter = InitialExchangeCounter()
    let session = try makeSession { _, _ in
      await counter.record()
      return initialCredential()
    }
    for query in [
      "state=wrong&code=c", "state=fixture-state&code=a&code=b",
      "state=fixture-state&code=c&error=access_denied",
    ] {
      await #expect(throws: GitHubOAuthAuthorizationError.invalidCallback) {
        try await session.complete(
          callbackURL: URL(string: "http://127.0.0.1:49152/oauth/callback?" + query)!)
      }
    }
    #expect(await counter.count == 0)
    let credential = try await session.complete(callbackURL: callback())
    #expect(credential.accessToken.rawValue == "fixture-access")
    await #expect(throws: GitHubOAuthAuthorizationError.alreadyCompleted) {
      try await session.complete(callbackURL: callback())
    }
    #expect(await counter.count == 1)
  }

  @Test(arguments: [
    "http://localhost:49152/oauth/callback", "http://127.0.0.1:49153/oauth/callback",
    "http://127.0.0.1:49152/other", "http://user@127.0.0.1:49152/oauth/callback",
    "http://127.0.0.1:49152/oauth/callback#fragment", "https://127.0.0.1:49152/oauth/callback",
  ])
  func invalidAuthorityDoesNotExchange(_ base: String) async throws {
    let session = try makeSession()
    await #expect(throws: GitHubOAuthAuthorizationError.invalidCallback) {
      try await session.complete(callbackURL: URL(string: base + "?state=fixture-state&code=c")!)
    }
  }

  @Test func denialAndCancellationAreTerminal() async throws {
    let session = try makeSession()
    await #expect(throws: GitHubOAuthAuthorizationError.denied) {
      try await session.complete(
        callbackURL: callback(query: "state=fixture-state&error=access_denied"))
    }
    await #expect(throws: GitHubOAuthAuthorizationError.alreadyCompleted) {
      try await session.complete(callbackURL: callback())
    }
    let cancelled = try makeSession()
    await cancelled.cancel()
    await #expect(throws: GitHubOAuthAuthorizationError.cancelled) {
      try await cancelled.complete(callbackURL: callback())
    }
  }

  @Test func expiredSessionNeverExchanges() async throws {
    let session = try makeSession(lifetime: .zero)
    await #expect(throws: GitHubOAuthAuthorizationError.expiredSession) {
      try await session.complete(callbackURL: callback())
    }
  }

  @Test func concurrentCallbackOnlyExchangesOnceAndCancellationDropsLateResult() async throws {
    let latch = InitialExchangeLatch()
    let session = try makeSession { _, _ in
      await latch.wait()
      return initialCredential()
    }
    let task = Task { try await session.complete(callbackURL: callback()) }
    await latch.waitUntilStarted()
    await #expect(throws: GitHubOAuthAuthorizationError.alreadyCompleted) {
      try await session.complete(callbackURL: callback())
    }
    await session.cancel()
    await latch.release()
    await #expect(throws: GitHubOAuthAuthorizationError.cancelled) { try await task.value }
  }
}

func makeSession(
  lifetime: Duration = .seconds(300),
  exchange: @escaping @Sendable (String, String) async throws -> GitHubOAuthCredentialBundle =
    defaultInitialExchange
) throws -> GitHubOAuthAuthorizationSession {
  try GitHubOAuthAuthorizationSession(
    configuration: GitHubOAuthAppConfiguration(
      clientID: "fixture-id", clientSecret: "fixture-secret"),
    redirectURI: URL(string: "http://127.0.0.1:49152/oauth/callback")!,
    state: "fixture-state", verifier: "fixture-verifier", lifetime: lifetime, exchange: exchange)
}

func callback(query: String = "state=fixture-state&code=fixture-code") -> URL {
  URL(string: "http://127.0.0.1:49152/oauth/callback?" + query)!
}

func initialCredential() -> GitHubOAuthCredentialBundle {
  GitHubOAuthCredentialBundle(
    accessToken: .init(rawValue: "fixture-access"),
    refreshToken: .init(rawValue: "fixture-refresh"),
    accessTokenExpiresAt: Date().addingTimeInterval(3600),
    refreshTokenExpiresAt: Date().addingTimeInterval(7200),
    tokenType: .bearer, grantedScopes: "")
}

actor InitialExchangeCounter {
  var count = 0
  func record() { count += 1 }
}

actor InitialExchangeLatch {
  private var continuation: CheckedContinuation<Void, Never>?
  private var observers: [CheckedContinuation<Void, Never>] = []
  private var started = false
  func wait() async {
    started = true
    for observer in observers { observer.resume() }
    observers.removeAll()
    await withCheckedContinuation { continuation = $0 }
  }
  func waitUntilStarted() async {
    if !started { await withCheckedContinuation { observers.append($0) } }
  }
  func release() {
    continuation?.resume()
    continuation = nil
  }
}

private func defaultInitialExchange(
  _ code: String, _ verifier: String
) async throws -> GitHubOAuthCredentialBundle {
  initialCredential()
}
