import AppKit
import Foundation

/// A fresh channel/session belongs to each attempt. Neither escapes to the caller.
struct GitHubLoginOAuthFlow {
  static func authorize(
    configuration: GitHubOAuthAppConfiguration,
    relay: GitHubLoginCallbackRelay = GitHubLoginCallbackRelay(),
    makeSession:
      @Sendable (GitHubOAuthAppConfiguration, URL) throws -> GitHubOAuthAuthorizationSession = {
        try GitHubOAuth.makeAuthorizationSession(configuration: $0, redirectURI: $1)
      },
    browser: @escaping @Sendable (URL) async throws -> Void = { url in
      try await MainActor.run { try openBrowser(url) }
    },
    timeout: Duration = .seconds(300)
  ) async throws -> GitHubOAuthCredentialBundle {
    do {
      let redirect = try await relay.start()
      let session = try makeSession(configuration, redirect)
      do {
        let credential = try await complete(
          session: session, relay: relay, browser: browser, timeout: timeout)
        await session.cancel()
        await relay.shutdown()
        return credential
      } catch {
        await session.cancel()
        throw error
      }
    } catch {
      await relay.shutdown()
      throw error
    }
  }

  private static func complete(
    session: GitHubOAuthAuthorizationSession, relay: GitHubLoginCallbackRelay,
    browser: @escaping @Sendable (URL) async throws -> Void, timeout: Duration
  ) async throws -> GitHubOAuthCredentialBundle {
    try await withThrowingTaskGroup(of: GitHubOAuthCredentialBundle.self) { group in
      group.addTask {
        try await browser(session.authorizationURL)
        while true {
          try Task.checkCancellation()
          let callback = try await relay.next()
          do {
            return try await session.complete(callbackURL: callback)
          } catch GitHubOAuthAuthorizationError.invalidCallback {
            continue
          }
        }
      }
      group.addTask {
        try await Task.sleep(for: timeout)
        relay.cancel()
        throw GitHubOAuthAuthorizationError.expiredSession
      }
      defer { group.cancelAll() }
      guard let credential = try await group.next() else { throw CancellationError() }
      return credential
    }
  }

  @MainActor private static func openBrowser(_ url: URL) throws {
    try Task.checkCancellation()
    guard NSWorkspace.shared.open(url) else { throw GitHubOAuthAuthorizationError.transport }
  }
}
