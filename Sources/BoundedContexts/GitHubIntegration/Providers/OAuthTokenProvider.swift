import Foundation

public enum OAuthTokenProviderError: Error, Sendable {
  case signedOut
  case missingCredential
  case authenticationRequired
  case restore(underlying: any Error & Sendable)
  case refresh(underlying: any Error & Sendable)
  case persist(underlying: any Error & Sendable)
}

private enum ExpiredRotationExhaustionError: Error, Sendable {
  case reachedLimit
}

public actor OAuthTokenProvider {
  private static let maximumPersistedExpiredRotations = 2

  private let store: any OAuthCredentialStore
  private let fetcher: any OAuthTokenFetcher
  private let now: @Sendable () -> Date
  private let onInFlightTaskJoin: (@Sendable () async -> Void)?

  private var credential: GitHubOAuthCredentialBundle?
  private var currentSnapshot: TokenSnapshot?
  private var version: UInt64 = 0
  private var inFlightTask: Task<TokenSnapshot, any Error>?
  private var retired = false
  private var didClear = false
  private var clearTask: Task<Void, any Error>?
  private var pendingWrite: Task<Void, any Error>?
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

  /// Permanently retires this instance, then clears after any already-started write settles.
  /// Cancellation of a caller does not cancel this shared cleanup.
  public func signOut() async throws(OAuthSignOutError) {
    retired = true
    credential = nil
    currentSnapshot = nil
    if didClear { return }
    if let clearTask { return try await finishClear(clearTask) }
    guard let clearingStore = store as? any OAuthCredentialClearingStore else {
      throw .unsupportedStore
    }
    let write = pendingWrite
    let task: Task<Void, any Error> = Task {
      if let write { _ = await write.result }
      try await clearingStore.clear()
    }
    clearTask = task
    defer { clearTask = nil }
    try await finishClear(task)
  }

  private func finishClear(_ task: Task<Void, any Error>) async throws(OAuthSignOutError) {
    // The creator resets the shared task, so an old waiter cannot clear a newer retry.
    do {
      try await task.value
      didClear = true
    } catch {
      throw .clear(underlying: error)
    }
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
      return publishNextVersion(credential)
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
      try throwIfUnavailable()
      throw .restore(underlying: error)
    }

    try throwIfUnavailable()
    guard let restoredCredential else {
      throw .missingCredential
    }

    credential = restoredCredential
    if isExpired(restoredCredential) {
      return try await refreshAndPublish(from: restoredCredential)
    }
    return publishNextVersion(restoredCredential)
  }

  private func runRefresh(
    from credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenProviderError) -> TokenSnapshot {
    defer { inFlightTask = nil }
    return try await refreshAndPublish(from: credential)
  }

  private func refreshAndPublish(
    from initialCredential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenProviderError) -> TokenSnapshot {
    var credentialToRefresh = initialCredential
    var persistedExpiredRotationCount = 0

    while true {
      try throwIfUnavailable()
      let rotatedCredential: GitHubOAuthCredentialBundle
      do {
        rotatedCredential = try await fetcher.refresh(credentialToRefresh)
      } catch {
        try throwIfUnavailable()
        throw classifyRefreshFailure(error)
      }

      try throwIfUnavailable()
      let store = store
      let write: Task<Void, any Error> = Task { try await store.save(rotatedCredential) }
      pendingWrite = write
      do {
        try await write.value
        pendingWrite = nil
      } catch {
        pendingWrite = nil
        try throwIfUnavailable()
        let error = OAuthTokenProviderError.persist(underlying: error)
        unavailableError = error
        throw error
      }

      try throwIfUnavailable()
      credential = rotatedCredential
      version += 1
      guard !isExpired(rotatedCredential) else {
        persistedExpiredRotationCount += 1
        guard persistedExpiredRotationCount < Self.maximumPersistedExpiredRotations else {
          throw .refresh(underlying: ExpiredRotationExhaustionError.reachedLimit)
        }
        credentialToRefresh = rotatedCredential
        continue
      }
      return publish(rotatedCredential)
    }
  }

  private func classifyRefreshFailure(
    _ failure: OAuthTokenRefreshError
  ) -> OAuthTokenProviderError {
    switch failure {
    case .credentialRejected:
      unavailableError = .authenticationRequired
      return .authenticationRequired
    case .rotationIndeterminate:
      let error = OAuthTokenProviderError.refresh(underlying: failure)
      unavailableError = error
      return error
    case .cancelled(stage: .afterRequestStarted):
      // The current demand is cancelled; later demands receive technical uncertainty.
      unavailableError = .refresh(underlying: OAuthTokenRefreshError.rotationIndeterminate)
      return .refresh(underlying: failure)
    case .clientConfiguration, .knownTechnicalFailure, .cancelled(stage: .beforeRequest):
      return .refresh(underlying: failure)
    }
  }

  private func publish(_ credential: GitHubOAuthCredentialBundle) -> TokenSnapshot {
    let snapshot = TokenSnapshot(accessToken: credential.accessToken, version: version)
    currentSnapshot = snapshot
    return snapshot
  }

  private func publishNextVersion(
    _ credential: GitHubOAuthCredentialBundle
  ) -> TokenSnapshot {
    version += 1
    return publish(credential)
  }

  private func isExpired(_ credential: GitHubOAuthCredentialBundle) -> Bool {
    credential.accessTokenExpiresAt <= now()
  }

  private func throwIfUnavailable() throws(OAuthTokenProviderError) {
    if retired { throw .signedOut }
    if let unavailableError {
      throw unavailableError
    }
  }

  private func value(
    of task: Task<TokenSnapshot, any Error>
  ) async throws(OAuthTokenProviderError) -> TokenSnapshot {
    do {
      let snapshot = try await task.value
      try throwIfUnavailable()
      return snapshot
    } catch let error as OAuthTokenProviderError {
      if retired { throw .signedOut }
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
