import Foundation
import Testing

@testable import GitHubIntegration

@Suite("Formal OAuth login channel (loopback only)")
struct GitHubLoginOAuthFlowTests {
  @Test func invalidCallbackContinuesThenExchangesOnce() async throws {
    let count = LoginTrace()
    let relay = GitHubLoginCallbackRelay()
    let value = try await GitHubLoginOAuthFlow.authorize(
      configuration: Self.configuration(), relay: relay,
      makeSession: { configuration, redirect in
        try GitHubOAuthAuthorizationSession(
          configuration: configuration, redirectURI: redirect, state: "fixture-state",
          verifier: "fixture-verifier",
          exchange: { code, _ in
            #expect(code == "fixture-code")
            await count.append("exchange")
            return GitHubLoginServiceTests.bundle()
          })
      },
      browser: { url in
        try await Self.sendCallback(url, query: "state=wrong&code=fixture-code")
        try await Self.sendCallback(url, query: "state=fixture-state&code=fixture-code")
      })
    #expect(value.refreshToken.rawValue == "oauth-refresh")
    #expect(await count.values == ["exchange"])
    await #expect(throws: (any Error).self) { try await relay.next() }
    await relay.shutdown()
  }

  @Test func browserFailureClosesChannel() async throws {
    let relay = GitHubLoginCallbackRelay()
    await #expect(throws: (any Error).self) {
      try await GitHubLoginOAuthFlow.authorize(
        configuration: Self.configuration(), relay: relay,
        browser: { _ in throw LoginTestFailure.failed })
    }
    await #expect(throws: (any Error).self) { try await relay.next() }
    await relay.shutdown()
  }

  @Test func timeoutClosesChannel() async throws {
    let relay = GitHubLoginCallbackRelay()
    await #expect(throws: GitHubOAuthAuthorizationError.expiredSession) {
      try await GitHubLoginOAuthFlow.authorize(
        configuration: Self.configuration(), relay: relay, browser: { _ in }, timeout: .zero)
    }
    await #expect(throws: (any Error).self) { try await relay.next() }
    await relay.shutdown()
  }

  @Test func cancellationClosesOriginalChannelBeforeReturning() async throws {
    let relay = GitHubLoginCallbackRelay()
    let opened = LoginGate()
    let task = Task {
      try await GitHubLoginOAuthFlow.authorize(
        configuration: Self.configuration(), relay: relay, browser: { _ in await opened.open() })
    }
    await opened.wait()
    task.cancel()
    await #expect(throws: (any Error).self) { try await task.value }
    await #expect(throws: (any Error).self) { try await relay.next() }
    await relay.shutdown()
  }

  @Test func unavailableRelayFailsWithoutOpeningBrowser() async throws {
    let relay = GitHubLoginCallbackRelay()
    await relay.shutdown()
    await #expect(throws: (any Error).self) {
      try await GitHubLoginOAuthFlow.authorize(
        configuration: Self.configuration(), relay: relay,
        browser: { _ in Issue.record("Browser must not open") })
    }
  }

  private static func configuration() throws -> GitHubOAuthAppConfiguration {
    try GitHubOAuthAppConfiguration(clientID: "fixture-id", clientSecret: "fixture-secret")
  }

  private static func sendCallback(_ authorization: URL, query: String) async throws {
    let parts = try #require(URLComponents(url: authorization, resolvingAgainstBaseURL: false))
    let redirect = try #require(parts.queryItems?.first { $0.name == "redirect_uri" }?.value)
    let url = try #require(URL(string: redirect + "?" + query))
    _ = try await URLSession.shared.data(from: url)
  }
}
