import Foundation
import GitHubIntegration
import Synchronization

public enum ProbeFailure: Error, Sendable {
  case assertion(String)
}

public func require(_ condition: Bool, _ message: String) throws {
  if !condition { throw ProbeFailure.assertion(message) }
}

public enum FakeCredentials {
  public static let initialTime = Date(timeIntervalSince1970: 2_000_000_000)

  public static func bundle(_ name: String) -> GitHubOAuthCredentialBundle {
    GitHubOAuthCredentialBundle(
      accessToken: GitHubAccessToken(rawValue: "fake-access-\(name)-'quoted'"),
      refreshToken: GitHubOAuthRefreshToken(rawValue: "fake-refresh-\(name)-多位元組"),
      accessTokenExpiresAt: initialTime.addingTimeInterval(name == "A" ? 120.125 : 3600.25),
      refreshTokenExpiresAt: initialTime.addingTimeInterval(name == "A" ? 8640.5 : 17280.75),
      tokenType: .bearer,
      grantedScopes: name == "A" ? "repo read:user" : "repo read:user workflow")
  }

  public static func matches(
    _ actual: GitHubOAuthCredentialBundle?, _ expected: GitHubOAuthCredentialBundle
  ) -> Bool {
    guard let actual else { return false }
    return actual.accessToken.rawValue == expected.accessToken.rawValue
      && actual.refreshToken.rawValue == expected.refreshToken.rawValue
      && actual.accessTokenExpiresAt == expected.accessTokenExpiresAt
      && actual.refreshTokenExpiresAt == expected.refreshTokenExpiresAt
      && actual.tokenType == expected.tokenType
      && actual.grantedScopes == expected.grantedScopes
  }
}

public final class ProbeClock: Sendable {
  private let value = Mutex(FakeCredentials.initialTime)

  public init() {}

  public func now() -> Date { value.withLock { $0 } }

  public func expireA() {
    value.withLock { $0 = FakeCredentials.bundle("A").accessTokenExpiresAt }
  }
}

public actor FakeTokenFetcher: OAuthTokenFetcher {
  private let paused: Bool
  private var released = false
  private var releaseWaiters: [CheckedContinuation<Void, Never>] = []
  private var startWaiters: [CheckedContinuation<Void, Never>] = []
  public private(set) var calls = 0
  public private(set) var acceptedB = false

  public init(paused: Bool = false) { self.paused = paused }

  public func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    calls += 1
    guard FakeCredentials.matches(credential, FakeCredentials.bundle("A")) else {
      throw .knownTechnicalFailure
    }
    let waiters = startWaiters
    startWaiters.removeAll()
    for waiter in waiters { waiter.resume() }
    if paused && !released {
      await withCheckedContinuation { releaseWaiters.append($0) }
    }
    acceptedB = true
    return FakeCredentials.bundle("B")
  }

  public func waitUntilStarted() async {
    if calls > 0 { return }
    await withCheckedContinuation { startWaiters.append($0) }
  }

  public func release() {
    released = true
    let waiters = releaseWaiters
    releaseWaiters.removeAll()
    for waiter in waiters { waiter.resume() }
  }
}

/// Counts black-box demands while refresh remains paused; no provider internal hook.
actor ProbeDemands {
  private var started = 0
  private var waiters: [(Int, CheckedContinuation<Void, Never>)] = []

  func snapshot(using provider: OAuthTokenProvider) async throws -> TokenSnapshot {
    started += 1
    let ready = waiters.filter { $0.0 <= started }
    waiters.removeAll { $0.0 <= started }
    for (_, waiter) in ready { waiter.resume() }
    return try await provider.snapshot()
  }

  func waitFor(_ count: Int) async {
    if started >= count { return }
    await withCheckedContinuation { waiters.append((count, $0)) }
  }
}
