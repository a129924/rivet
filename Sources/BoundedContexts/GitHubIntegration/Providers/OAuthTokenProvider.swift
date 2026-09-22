import Foundation

public enum OAuthTokenProviderError: Error, Sendable {
  case missingCredential
  case restore(underlying: any Error & Sendable)
  case refresh(underlying: any Error & Sendable)
  case persist(underlying: any Error & Sendable)
}

public actor OAuthTokenProvider {
  private let store: any OAuthCredentialStore
  private let fetcher: any OAuthTokenFetcher
  private let now: @Sendable () -> Date
  private let onInFlightTaskJoin: (@Sendable () async -> Void)?

  private var credential: GitHubOAuthCredentialBundle?
  private var currentSnapshot: TokenSnapshot?
  private var inFlightTask: Task<TokenSnapshot, any Error>?
  private var unavailableError: OAuthTokenProviderError?

  public init(
    store: any OAuthCredentialStore,
    fetcher: any OAuthTokenFetcher,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.store = store
    self.fetcher = fetcher
    self.now = now
    onInFlightTaskJoin = nil
  }

  init(
    store: any OAuthCredentialStore,
    fetcher: any OAuthTokenFetcher,
    now: @escaping @Sendable () -> Date = Date.init,
    onInFlightTaskJoin: @escaping @Sendable () async -> Void
  ) {
    self.store = store
    self.fetcher = fetcher
    self.now = now
    self.onInFlightTaskJoin = onInFlightTaskJoin
  }

  public func snapshot() async throws(OAuthTokenProviderError) -> TokenSnapshot {
    try throwIfUnavailable()

    if let inFlightTask {
      return try await join(inFlightTask)
    }

    if let currentSnapshot, let credential {
      if isExpired(credential) {
        return try await startRefresh(from: credential)
      }
      return currentSnapshot
    }

    if let credential {
      if isExpired(credential) {
        return try await startRefresh(from: credential)
      }
      return publish(credential)
    }

    return try await startRestore()
  }

  public func replacementSnapshot(
    afterUnauthorized usedSnapshot: TokenSnapshot
  ) async throws(OAuthTokenProviderError) -> TokenSnapshot {
    try throwIfUnavailable()

    guard let currentSnapshot else {
      return try await snapshot()
    }

    guard currentSnapshot.hasSameVersion(as: usedSnapshot) else {
      return currentSnapshot
    }

    if let inFlightTask {
      return try await join(inFlightTask)
    }

    guard let credential else {
      return try await snapshot()
    }

    return try await startRefresh(from: credential)
  }

  private func startRestore() async throws(OAuthTokenProviderError) -> TokenSnapshot {
    if let inFlightTask {
      return try await join(inFlightTask)
    }

    let task: Task<TokenSnapshot, any Error> = Task { [self] in
      try await runRestore()
    }
    inFlightTask = task
    return try await value(of: task)
  }

  private func startRefresh(
    from credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenProviderError) -> TokenSnapshot {
    if let inFlightTask {
      return try await join(inFlightTask)
    }

    let task: Task<TokenSnapshot, any Error> = Task { [self] in
      try await runRefresh(from: credential)
    }
    inFlightTask = task
    return try await value(of: task)
  }

  private func runRestore() async throws(OAuthTokenProviderError) -> TokenSnapshot {
    defer { inFlightTask = nil }

    let restoredCredential: GitHubOAuthCredentialBundle?
    do {
      restoredCredential = try await store.load()
    } catch {
      throw .restore(underlying: error)
    }

    guard let restoredCredential else {
      throw .missingCredential
    }

    credential = restoredCredential
    if isExpired(restoredCredential) {
      return try await refreshAndPublish(from: restoredCredential)
    }
    return publish(restoredCredential)
  }

  private func runRefresh(
    from credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenProviderError) -> TokenSnapshot {
    defer { inFlightTask = nil }
    return try await refreshAndPublish(from: credential)
  }

  private func refreshAndPublish(
    from currentCredential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenProviderError) -> TokenSnapshot {
    let rotatedCredential: GitHubOAuthCredentialBundle
    do {
      rotatedCredential = try await fetcher.refresh(currentCredential)
    } catch {
      throw .refresh(underlying: error)
    }

    do {
      try await store.save(rotatedCredential)
    } catch {
      let error = OAuthTokenProviderError.persist(underlying: error)
      unavailableError = error
      throw error
    }

    credential = rotatedCredential
    return publish(rotatedCredential)
  }

  private func publish(_ credential: GitHubOAuthCredentialBundle) -> TokenSnapshot {
    let version = (currentSnapshot?.version ?? 0) + 1
    let snapshot = TokenSnapshot(accessToken: credential.accessToken, version: version)
    currentSnapshot = snapshot
    return snapshot
  }

  private func isExpired(_ credential: GitHubOAuthCredentialBundle) -> Bool {
    credential.accessTokenExpiresAt <= now()
  }

  private func throwIfUnavailable() throws(OAuthTokenProviderError) {
    if let unavailableError {
      throw unavailableError
    }
  }

  private func value(
    of task: Task<TokenSnapshot, any Error>
  ) async throws(OAuthTokenProviderError) -> TokenSnapshot {
    do {
      return try await task.value
    } catch let error as OAuthTokenProviderError {
      throw error
    } catch {
      preconditionFailure("OAuthTokenProvider work must only throw OAuthTokenProviderError")
    }
  }

  private func join(
    _ task: Task<TokenSnapshot, any Error>
  ) async throws(OAuthTokenProviderError) -> TokenSnapshot {
    if let onInFlightTaskJoin {
      await onInFlightTaskJoin()
    }
    return try await value(of: task)
  }
}
