import Foundation
import Testing

@testable import GitHubIntegration

@Suite("OAuth token provider")
struct OAuthTokenProviderTests {
  @Test
  func snapshotSeparatesFullEqualityFromVersionEquality() {
    let first = snapshot(.initial, version: 1)
    let sameVersionDifferentToken = snapshot(.alternate, version: 1)
    let differentVersionSameToken = snapshot(.initial, version: 2)
    let exactCopy = snapshot(.initial, version: 1)

    #expect(first.hasSameVersion(as: sameVersionDifferentToken))
    #expect(!first.hasSameVersion(as: differentVersionSameToken))
    #expect(areSnapshotsFullyEqual(first, exactCopy))
    #expect(!areSnapshotsFullyEqual(first, sameVersionDifferentToken))
    #expect(!areSnapshotsFullyEqual(first, differentVersionSameToken))
  }

  @Test
  func validCredentialRestoresAndPublishesTheFirstSnapshotWithoutRefreshing() async throws {
    let now = testDate
    let credential = credential(.initial, accessExpiry: now.addingTimeInterval(1))
    let store = TestCredentialStore(loadResults: [.success(credential)])
    let fetcher = TestTokenFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { now })

    let result = try await provider.snapshot()

    #expect(hasAccessToken(result, .initial))
    #expect(result.version == 1)
    #expect(await store.loadInvocationCount() == 1)
    #expect(await store.saveInvocationCount() == 0)
    #expect(await fetcher.refreshInvocationCount() == 0)
  }

  @Test
  func exactExpiryRefreshesBeforePublishingTheFirstSnapshot() async throws {
    let now = testDate
    let expired = credential(.initial, accessExpiry: now)
    let replacement = credential(.replacement, accessExpiry: now.addingTimeInterval(1))
    let store = TestCredentialStore(loadResults: [.success(expired)])
    let fetcher = TestTokenFetcher(refreshResults: [.success(replacement)])
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { now })

    let result = try await provider.snapshot()

    #expect(hasAccessToken(result, .replacement))
    #expect(result.version == 1)
    #expect(await store.loadInvocationCount() == 1)
    #expect(await fetcher.refreshInvocationCount() == 1)
    #expect(await store.saveInvocationCount() == 1)
    #expect(await store.hasSavedAccessToken(.replacement))
  }
}

extension OAuthTokenProviderTests {
  @Test
  func expiredRestoreRotationThatExpiresDuringPersistencePublishesVersionTwo() async throws {
    let now = testDate
    let expiringRotationExpiry = now.addingTimeInterval(1)
    let usableRotationExpiry = now.addingTimeInterval(2)
    let clock = TestClock(now: now)
    let saveGate = TestGate()
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: now))],
      saveGate: saveGate
    )
    let fetcher = TestTokenFetcher(
      refreshResults: [
        .success(credential(.alternate, accessExpiry: expiringRotationExpiry)),
        .success(credential(.replacement, accessExpiry: usableRotationExpiry)),
      ]
    )
    let joinObservation = TestInFlightJoinObservation()
    let provider = OAuthTokenProvider(
      store: store,
      fetcher: fetcher,
      now: { clock.now() },
      onInFlightTaskJoin: { await joinObservation.recordJoin() }
    )
    let firstDemand = Task { try await provider.snapshot() }
    await saveGate.waitForArrival()
    let secondDemand = Task { try await provider.snapshot() }
    await joinObservation.waitForJoin()
    clock.advance(to: expiringRotationExpiry)
    await saveGate.open()
    let first = try await firstDemand.value
    let second = try await secondDemand.value
    #expect(hasAccessToken(first, .replacement))
    #expect(!hasAccessToken(first, .alternate))
    #expect(areSnapshotsFullyEqual(first, second))
    #expect(first.version == 2)
    #expect(second.version == 2)
    #expect(clock.now() < usableRotationExpiry)
    #expect(await joinObservation.count() == 1)
    #expect(await store.loadInvocationCount() == 1)
    #expect(await fetcher.refreshInvocationCount() == 2)
    #expect(await store.saveInvocationCount() == 2)
    #expect(await store.hasSavedAccessToken(.alternate))
    #expect(await store.hasSavedAccessToken(.replacement))
  }

  @Test
  func rotationThatExpiresDuringPersistenceRefreshesBeforePublishing() async throws {
    let now = testDate
    let expiringRotationExpiry = now.addingTimeInterval(1)
    let usableRotationExpiry = now.addingTimeInterval(2)
    let clock = TestClock(now: now)
    let saveGate = TestGate()
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: expiringRotationExpiry))],
      saveGate: saveGate
    )
    let fetcher = TestTokenFetcher(
      refreshResults: [
        .success(credential(.alternate, accessExpiry: expiringRotationExpiry)),
        .success(credential(.replacement, accessExpiry: usableRotationExpiry)),
      ]
    )
    let joinObservation = TestInFlightJoinObservation()
    let provider = OAuthTokenProvider(
      store: store,
      fetcher: fetcher,
      now: { clock.now() },
      onInFlightTaskJoin: { await joinObservation.recordJoin() }
    )
    let usedSnapshot = try await provider.snapshot()
    let firstRecovery = Task {
      try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)
    }
    await saveGate.waitForArrival()
    let secondRecovery = Task {
      try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)
    }
    await joinObservation.waitForJoin()
    clock.advance(to: expiringRotationExpiry)
    await saveGate.open()
    let first = try await firstRecovery.value
    let second = try await secondRecovery.value
    #expect(usedSnapshot.version == 1)
    #expect(hasAccessToken(first, .replacement))
    #expect(!hasAccessToken(first, .alternate))
    #expect(areSnapshotsFullyEqual(first, second))
    #expect(first.version == 3)
    #expect(clock.now() < usableRotationExpiry)
    #expect(await joinObservation.count() == 1)
    #expect(await fetcher.refreshInvocationCount() == 2)
    #expect(await store.saveInvocationCount() == 2)
    #expect(await store.hasSavedAccessToken(.alternate))
    #expect(await store.hasSavedAccessToken(.replacement))
  }

  @Test
  func expiredRotationFollowedByRefreshFailureRemainsRetryable() async throws {
    let now = testDate
    let expiringRotationExpiry = now.addingTimeInterval(1)
    let usableRotationExpiry = now.addingTimeInterval(2)
    let clock = TestClock(now: now)
    let saveGate = TestGate()
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: expiringRotationExpiry))],
      saveGate: saveGate
    )
    let fetcher = TestTokenFetcher(
      refreshResults: [
        .success(credential(.alternate, accessExpiry: expiringRotationExpiry)),
        .failure(.refresh),
        .success(credential(.replacement, accessExpiry: usableRotationExpiry)),
      ]
    )
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { clock.now() })
    let usedSnapshot = try await provider.snapshot()
    let firstRecovery = Task {
      try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)
    }
    await saveGate.waitForArrival()
    clock.advance(to: expiringRotationExpiry)
    await saveGate.open()
    await expectRefreshFailure(firstRecovery)
    let result = try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)
    #expect(hasAccessToken(result, .replacement))
    #expect(result.version == 3)
    #expect(await fetcher.refreshInvocationCount() == 3)
    #expect(await store.saveInvocationCount() == 2)
  }

  @Test
  func expiredRotationFollowedByPersistenceFailureMakesProviderUnavailable() async throws {
    let now = testDate
    let expiringRotationExpiry = now.addingTimeInterval(1)
    let usableRotationExpiry = now.addingTimeInterval(2)
    let clock = TestClock(now: now)
    let saveGate = TestGate()
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: expiringRotationExpiry))],
      saveResults: [.success(()), .failure(.persist)],
      saveGate: saveGate
    )
    let fetcher = TestTokenFetcher(
      refreshResults: [
        .success(credential(.alternate, accessExpiry: expiringRotationExpiry)),
        .success(credential(.replacement, accessExpiry: usableRotationExpiry)),
      ]
    )
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { clock.now() })
    let usedSnapshot = try await provider.snapshot()
    let firstRecovery = Task {
      try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)
    }
    await saveGate.waitForArrival()
    clock.advance(to: expiringRotationExpiry)
    await saveGate.open()
    await expectPersistFailure(firstRecovery)
    await expectPersistFailure(provider)
    #expect(await fetcher.refreshInvocationCount() == 2)
    #expect(await store.saveInvocationCount() == 2)
  }

  @Test
  func concurrentExpiredSnapshotDemandsShareOneRefreshAndOnePersistence() async throws {
    let now = testDate
    let replacement = credential(.replacement, accessExpiry: now.addingTimeInterval(1))
    let refreshGate = TestGate()
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: now))]
    )
    let fetcher = TestTokenFetcher(
      refreshResults: [.success(replacement)],
      refreshGate: refreshGate
    )
    let joinObservation = TestInFlightJoinObservation()
    let provider = OAuthTokenProvider(
      store: store,
      fetcher: fetcher,
      now: { now },
      onInFlightTaskJoin: { await joinObservation.recordJoin() }
    )
    let firstDemand = Task { try await provider.snapshot() }
    await refreshGate.waitForArrival()
    let secondDemand = Task { try await provider.snapshot() }
    await joinObservation.waitForJoin()
    #expect(await joinObservation.count() == 1)
    #expect(await fetcher.refreshInvocationCount() == 1)
    #expect(await store.saveInvocationCount() == 0)
    await refreshGate.open()
    let first = try await firstDemand.value
    let second = try await secondDemand.value
    #expect(hasAccessToken(first, .replacement))
    #expect(areSnapshotsFullyEqual(first, second))
    #expect(first.version == 1)
    #expect(second.version == first.version)
    #expect(await fetcher.refreshInvocationCount() == 1)
    #expect(await store.saveInvocationCount() == 1)
  }

  @Test
  func concurrentInitialRestoresShareOneLoad() async throws {
    let now = testDate
    let loadGate = TestGate()
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: now.addingTimeInterval(1)))],
      loadGate: loadGate
    )
    let fetcher = TestTokenFetcher()
    let joinObservation = TestInFlightJoinObservation()
    let provider = OAuthTokenProvider(
      store: store,
      fetcher: fetcher,
      now: { now },
      onInFlightTaskJoin: { await joinObservation.recordJoin() }
    )
    let firstDemand = Task { try await provider.snapshot() }
    await loadGate.waitForArrival()
    let secondDemand = Task { try await provider.snapshot() }
    await joinObservation.waitForJoin()
    #expect(await joinObservation.count() == 1)
    #expect(await store.loadInvocationCount() == 1)
    await loadGate.open()
    let first = try await firstDemand.value
    let second = try await secondDemand.value
    #expect(areSnapshotsFullyEqual(first, second))
    #expect(await fetcher.refreshInvocationCount() == 0)
  }

  @Test
  func sameVersionConcurrentUnauthorizedRecoverySharesOneRefresh() async throws {
    let now = testDate
    let replacement = credential(.replacement, accessExpiry: now.addingTimeInterval(1))
    let refreshGate = TestGate()
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: now.addingTimeInterval(1)))]
    )
    let fetcher = TestTokenFetcher(
      refreshResults: [.success(replacement)],
      refreshGate: refreshGate
    )
    let joinObservation = TestInFlightJoinObservation()
    let provider = OAuthTokenProvider(
      store: store,
      fetcher: fetcher,
      now: { now },
      onInFlightTaskJoin: { await joinObservation.recordJoin() }
    )
    let usedSnapshot = try await provider.snapshot()
    let firstRecovery = Task {
      try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)
    }
    await refreshGate.waitForArrival()
    let secondRecovery = Task {
      try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)
    }
    await joinObservation.waitForJoin()
    #expect(await joinObservation.count() == 1)
    #expect(await fetcher.refreshInvocationCount() == 1)
    await refreshGate.open()
    let first = try await firstRecovery.value
    let second = try await secondRecovery.value
    #expect(hasAccessToken(first, .replacement))
    #expect(areSnapshotsFullyEqual(first, second))
    #expect(first.version == 2)
    #expect(await store.saveInvocationCount() == 1)
  }
}

extension OAuthTokenProviderTests {
  @Test
  func differentVersionUnauthorizedRecoveryReturnsCurrentSnapshotWithoutRefreshing() async throws {
    let now = testDate
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: now.addingTimeInterval(1)))]
    )
    let fetcher = TestTokenFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { now })
    let current = try await provider.snapshot()
    let usedSnapshot = snapshot(.initial, version: current.version + 1)

    let replacement = try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)

    #expect(areSnapshotsFullyEqual(replacement, current))
    #expect(await fetcher.refreshInvocationCount() == 0)
    #expect(await store.saveInvocationCount() == 0)
  }

  @Test
  func recoveryWithoutACurrentSnapshotUsesNormalRestoreBehavior() async throws {
    let now = testDate
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: now.addingTimeInterval(1)))]
    )
    let fetcher = TestTokenFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { now })

    let result = try await provider.replacementSnapshot(
      afterUnauthorized: snapshot(.alternate, version: 99)
    )

    #expect(hasAccessToken(result, .initial))
    #expect(result.version == 1)
    #expect(await store.loadInvocationCount() == 1)
    #expect(await fetcher.refreshInvocationCount() == 0)
  }

  @Test
  func missingCredentialIsNotPermanentAndTheNextDemandRestoresAgain() async throws {
    let now = testDate
    let store = TestCredentialStore(
      loadResults: [
        .success(nil),
        .success(credential(.initial, accessExpiry: now.addingTimeInterval(1))),
      ]
    )
    let fetcher = TestTokenFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { now })

    await expectMissingCredential(provider)
    let result = try await provider.snapshot()

    #expect(hasAccessToken(result, .initial))
    #expect(await store.loadInvocationCount() == 2)
    #expect(await fetcher.refreshInvocationCount() == 0)
  }

  @Test
  func restoreFailureIsMappedAndTheNextDemandCanRetry() async throws {
    let now = testDate
    let store = TestCredentialStore(
      loadResults: [
        .failure(.load),
        .success(credential(.initial, accessExpiry: now.addingTimeInterval(1))),
      ]
    )
    let fetcher = TestTokenFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { now })

    await expectRestoreFailure(provider)
    let result = try await provider.snapshot()

    #expect(hasAccessToken(result, .initial))
    #expect(await store.loadInvocationCount() == 2)
  }

  @Test
  func refreshFailureRetainsTheCredentialAndAllowsARetry() async throws {
    let now = testDate
    let replacement = credential(.replacement, accessExpiry: now.addingTimeInterval(1))
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: now.addingTimeInterval(1)))]
    )
    let fetcher = TestTokenFetcher(refreshResults: [.failure(.refresh), .success(replacement)])
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { now })
    let usedSnapshot = try await provider.snapshot()

    await expectRefreshFailure(provider, afterUnauthorized: usedSnapshot)
    let result = try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)

    #expect(hasAccessToken(result, .replacement))
    #expect(result.version == 2)
    #expect(await store.loadInvocationCount() == 1)
    #expect(await fetcher.refreshInvocationCount() == 2)
    #expect(await store.saveInvocationCount() == 1)
  }

  @Test
  func persistenceFailureAfterRotationMakesProviderUnavailable() async throws {
    let now = testDate
    let store = TestCredentialStore(
      loadResults: [.success(credential(.initial, accessExpiry: now.addingTimeInterval(1)))],
      saveResults: [.failure(.persist)]
    )
    let fetcher = TestTokenFetcher(
      refreshResults: [.success(credential(.replacement, accessExpiry: now.addingTimeInterval(1)))]
    )
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: { now })
    let usedSnapshot = try await provider.snapshot()

    await expectPersistFailure(provider, afterUnauthorized: usedSnapshot)
    await expectPersistFailure(provider)

    #expect(await store.loadInvocationCount() == 1)
    #expect(await fetcher.refreshInvocationCount() == 1)
    #expect(await store.saveInvocationCount() == 1)
  }

  @Test
  func publicProviderContractsAreSendable() {
    let store = TestCredentialStore()
    let fetcher = TestTokenFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher)

    assertSendable(store)
    assertSendable(fetcher)
    assertSendable(provider)
    assertSendable(snapshot(.initial, version: 1))
    assertSendable(OAuthTokenProviderError.missingCredential)
  }
}

private let testDate = Date(timeIntervalSinceReferenceDate: 1_000)

private enum TokenFixture {
  case initial
  case replacement
  case alternate

  var accessToken: GitHubAccessToken {
    GitHubAccessToken(rawValue: rawValue)
  }

  private var rawValue: String {
    switch self {
    case .initial:
      "oauth-provider-initial"
    case .replacement:
      "oauth-provider-replacement"
    case .alternate:
      "oauth-provider-alternate"
    }
  }
}

private func credential(
  _ token: TokenFixture,
  accessExpiry: Date
) -> GitHubOAuthCredentialBundle {
  GitHubOAuthCredentialBundle(
    accessToken: token.accessToken,
    refreshToken: GitHubOAuthRefreshToken(rawValue: "oauth-provider-refresh"),
    accessTokenExpiresAt: accessExpiry,
    refreshTokenExpiresAt: .distantFuture,
    tokenType: .bearer,
    grantedScopes: "repo"
  )
}

private func snapshot(_ token: TokenFixture, version: UInt64) -> TokenSnapshot {
  TokenSnapshot(accessToken: token.accessToken, version: version)
}

private func hasAccessToken(_ snapshot: TokenSnapshot, _ expected: TokenFixture) -> Bool {
  snapshot.accessToken.rawValue == expected.accessToken.rawValue
}

private func areSnapshotsFullyEqual(_ lhs: TokenSnapshot, _ rhs: TokenSnapshot) -> Bool {
  lhs == rhs
}

private func assertSendable<Value: Sendable>(_ value: Value) {}

private func expectMissingCredential(_ provider: OAuthTokenProvider) async {
  do {
    _ = try await provider.snapshot()
    Issue.record("Expected the provider to report a missing credential")
  } catch {
    #expect(isMissingCredentialError(error))
  }
}

private func expectRestoreFailure(_ provider: OAuthTokenProvider) async {
  do {
    _ = try await provider.snapshot()
    Issue.record("Expected the provider to map a restore failure")
  } catch {
    #expect(isRestoreFailure(error))
  }
}

private func expectRefreshFailure(
  _ provider: OAuthTokenProvider,
  afterUnauthorized usedSnapshot: TokenSnapshot
) async {
  do {
    _ = try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)
    Issue.record("Expected the provider to map a refresh failure")
  } catch {
    #expect(isRefreshFailure(error))
  }
}

private func expectRefreshFailure(_ task: Task<TokenSnapshot, any Error>) async {
  do {
    _ = try await task.value
    Issue.record("Expected the provider to map a refresh failure")
  } catch let error as OAuthTokenProviderError {
    #expect(isRefreshFailure(error))
  } catch {
    Issue.record("Expected OAuthTokenProviderError.refresh")
  }
}

private func expectPersistFailure(
  _ provider: OAuthTokenProvider,
  afterUnauthorized usedSnapshot: TokenSnapshot? = nil
) async {
  do {
    if let usedSnapshot {
      _ = try await provider.replacementSnapshot(afterUnauthorized: usedSnapshot)
    } else {
      _ = try await provider.snapshot()
    }
    Issue.record("Expected the provider to remain unavailable after a persistence failure")
  } catch {
    #expect(isPersistFailure(error))
  }
}

private func expectPersistFailure(_ task: Task<TokenSnapshot, any Error>) async {
  do {
    _ = try await task.value
    Issue.record("Expected the provider to remain unavailable after a persistence failure")
  } catch let error as OAuthTokenProviderError {
    #expect(isPersistFailure(error))
  } catch {
    Issue.record("Expected OAuthTokenProviderError.persist")
  }
}

private func isMissingCredentialError(_ error: OAuthTokenProviderError) -> Bool {
  guard case .missingCredential = error else {
    return false
  }
  return true
}

private func isRestoreFailure(_ error: OAuthTokenProviderError) -> Bool {
  guard case .restore(let underlying) = error else {
    return false
  }
  return matches(underlying, .load)
}

private func isRefreshFailure(_ error: OAuthTokenProviderError) -> Bool {
  guard case .refresh(let underlying) = error else {
    return false
  }
  return matches(underlying, .refresh)
}

private func isPersistFailure(_ error: OAuthTokenProviderError) -> Bool {
  guard case .persist(let underlying) = error else {
    return false
  }
  return matches(underlying, .persist)
}

private func matches(_ error: any Error & Sendable, _ expected: TestPortFailure) -> Bool {
  guard let actual = error as? TestPortFailure else {
    return false
  }
  return actual == expected
}

private enum TestPortFailure: Error, Equatable, Sendable {
  case load
  case refresh
  case persist
  case exhausted
}

private actor TestCredentialStore: OAuthCredentialStore {
  private var loadResults: [Result<GitHubOAuthCredentialBundle?, TestPortFailure>]
  private var saveResults: [Result<Void, TestPortFailure>]
  private let loadGate: TestGate?
  private let saveGate: TestGate?
  private var loadCount = 0
  private var saveCount = 0
  private var savedCredentials: [GitHubOAuthCredentialBundle] = []

  init(
    loadResults: [Result<GitHubOAuthCredentialBundle?, TestPortFailure>] = [],
    saveResults: [Result<Void, TestPortFailure>] = [],
    loadGate: TestGate? = nil,
    saveGate: TestGate? = nil
  ) {
    self.loadResults = loadResults
    self.saveResults = saveResults
    self.loadGate = loadGate
    self.saveGate = saveGate
  }

  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    loadCount += 1
    if let loadGate {
      await loadGate.wait()
    }
    guard !loadResults.isEmpty else {
      throw TestPortFailure.exhausted
    }
    return try loadResults.removeFirst().get()
  }

  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    saveCount += 1
    savedCredentials.append(credential)
    if let saveGate {
      await saveGate.wait()
    }
    guard !saveResults.isEmpty else {
      return
    }
    try saveResults.removeFirst().get()
  }

  func loadInvocationCount() -> Int {
    loadCount
  }

  func saveInvocationCount() -> Int {
    saveCount
  }

  func hasSavedAccessToken(_ expected: TokenFixture) -> Bool {
    savedCredentials.contains { credential in
      credential.accessToken.rawValue == expected.accessToken.rawValue
    }
  }
}

private actor TestTokenFetcher: OAuthTokenFetcher {
  private var refreshResults: [Result<GitHubOAuthCredentialBundle, TestPortFailure>]
  private let refreshGate: TestGate?
  private var refreshCount = 0

  init(
    refreshResults: [Result<GitHubOAuthCredentialBundle, TestPortFailure>] = [],
    refreshGate: TestGate? = nil
  ) {
    self.refreshResults = refreshResults
    self.refreshGate = refreshGate
  }

  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle {
    refreshCount += 1
    if let refreshGate {
      await refreshGate.wait()
    }
    guard !refreshResults.isEmpty else {
      throw TestPortFailure.exhausted
    }
    return try refreshResults.removeFirst().get()
  }

  func refreshInvocationCount() -> Int {
    refreshCount
  }
}

private actor TestGate {
  private var isOpen = false
  private var waiters: [CheckedContinuation<Void, Never>] = []
  private var arrivalWaiters: [CheckedContinuation<Void, Never>] = []

  func wait() async {
    guard !isOpen else {
      return
    }

    await withCheckedContinuation { continuation in
      waiters.append(continuation)
      let currentArrivalWaiters = arrivalWaiters
      arrivalWaiters.removeAll()
      for waiter in currentArrivalWaiters {
        waiter.resume()
      }
    }
  }

  func waitForArrival() async {
    guard waiters.isEmpty else {
      return
    }

    await withCheckedContinuation { continuation in
      arrivalWaiters.append(continuation)
    }
  }

  func open() {
    isOpen = true
    let currentWaiters = waiters
    waiters.removeAll()
    for waiter in currentWaiters {
      waiter.resume()
    }
  }
}

private actor TestInFlightJoinObservation {
  private var joinCount = 0
  private var waiters: [CheckedContinuation<Void, Never>] = []

  func recordJoin() {
    joinCount += 1
    let currentWaiters = waiters
    waiters.removeAll()
    for waiter in currentWaiters {
      waiter.resume()
    }
  }

  func waitForJoin() async {
    guard joinCount == 0 else {
      return
    }

    await withCheckedContinuation { continuation in
      waiters.append(continuation)
    }
  }

  func count() -> Int {
    joinCount
  }
}

private final class TestClock: @unchecked Sendable {
  private let lock = NSLock()
  private var value: Date

  init(now: Date) {
    value = now
  }

  func now() -> Date {
    lock.lock()
    defer { lock.unlock() }
    return value
  }

  func advance(to date: Date) {
    lock.lock()
    defer { lock.unlock() }
    value = date
  }
}
