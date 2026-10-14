import Foundation
import GRDB
import GitHubIntegration

public enum RuntimeScenarios {
  public static func restore(path: String, name: String) async throws {
    let fetcher = FakeTokenFetcher()
    let store = SQLiteCredentialStore(path: path)
    try require(
      FakeCredentials.matches(try await store.load(), FakeCredentials.bundle(name)),
      "all six fields must round-trip")
    let provider = OAuthTokenProvider(
      store: store, fetcher: fetcher, now: { FakeCredentials.initialTime })
    let snapshot = try await provider.snapshot()
    try require(
      snapshot.accessToken.rawValue == FakeCredentials.bundle(name).accessToken.rawValue,
      "restored snapshot")
    try require(await fetcher.calls == 0, "restore must not refresh")
  }

  public static func rotation(path: String) async throws {
    let store = SQLiteCredentialStore(path: path)
    try await store.save(FakeCredentials.bundle("A"))
    let clock = ProbeClock()
    let fetcher = FakeTokenFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: clock.now)
    let previous = try await provider.snapshot()
    clock.expireA()
    let rotated = try await provider.snapshot()
    try require(
      rotated.accessToken.rawValue == FakeCredentials.bundle("B").accessToken.rawValue,
      "rotated snapshot")
    try require(rotated.version == previous.version + 1, "snapshot version advances")
    try require(await fetcher.calls == 1, "one fake rotation")
    try require(await fetcher.acceptedB, "fake accepted rotation")
    try require(
      FakeCredentials.matches(
        try await SQLiteCredentialStore(path: path).load(), FakeCredentials.bundle("B")),
      "complete B persisted")
  }

  public static func singleFlight(path: String) async throws {
    let store = SQLiteCredentialStore(path: path)
    try await store.save(FakeCredentials.bundle("A"))
    let clock = ProbeClock()
    let fetcher = FakeTokenFetcher(paused: true)
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: clock.now)
    let previous = try await provider.snapshot()
    clock.expireA()
    let demands = ProbeDemands()
    let snapshots = try await withThrowingTaskGroup(of: TokenSnapshot.self) { group in
      group.addTask { try await demands.snapshot(using: provider) }
      await fetcher.waitUntilStarted()
      for _ in 1..<12 {
        group.addTask { try await demands.snapshot(using: provider) }
      }
      await demands.waitFor(12)
      try require(await fetcher.calls == 1, "one refresh while 12 demands overlap")
      await fetcher.release()
      var values: [TokenSnapshot] = []
      for try await snapshot in group { values.append(snapshot) }
      return values
    }
    try require(snapshots.count == 12, "all demands completed")
    let current = try await provider.snapshot()
    try require(snapshots.allSatisfy { $0 == current }, "same snapshot for all demands")
    try require(
      current.accessToken.rawValue == FakeCredentials.bundle("B").accessToken.rawValue,
      "B published")
    let replacement = try await provider.replacementSnapshot(afterUnauthorized: previous)
    try require(replacement == current, "stale unauthorized uses current snapshot")
    try require(await fetcher.calls == 1, "stale unauthorized does not refresh again")
  }

  public static func rollback(path: String) async throws {
    let store = SQLiteCredentialStore(path: path)
    try await store.save(FakeCredentials.bundle("A"))
    await store.armPartialWriteFailure()
    do {
      try await store.save(FakeCredentials.bundle("B"))
      throw ProbeFailure.assertion("injected save must fail")
    } catch ProbeStoreError.injectedAfterPartialWrite {
      try require(await store.observedPartialWrite, "SQL change visible before rollback")
    }
    try require(
      FakeCredentials.matches(
        try await SQLiteCredentialStore(path: path).load(), FakeCredentials.bundle("A")),
      "rollback preserves complete A")
  }

  public static func persistenceFailure(path: String) async throws {
    let store = SQLiteCredentialStore(path: path)
    try await store.save(FakeCredentials.bundle("A"))
    let clock = ProbeClock()
    let fetcher = FakeTokenFetcher()
    let provider = OAuthTokenProvider(store: store, fetcher: fetcher, now: clock.now)
    let initial = try await provider.snapshot()
    await store.armPartialWriteFailure()
    clock.expireA()
    try await expectPersist { try await provider.snapshot() }
    try await expectPersist { try await provider.snapshot() }
    try await expectPersist { try await provider.replacementSnapshot(afterUnauthorized: initial) }
    try require(await fetcher.calls == 1, "rotate once, then stop")
    try require(await fetcher.acceptedB, "accepted B")
    try require(await store.saveCalls == 2, "no second save attempt after terminal failure")
    try require(await store.observedPartialWrite, "real partial SQL write preceded failure")
    try require(
      FakeCredentials.matches(
        try await SQLiteCredentialStore(path: path).load(), FakeCredentials.bundle("A")),
      "failed rotation preserves complete A; no B snapshot delivered")
  }

  public static func storageFailures(directory: URL) async throws {
    let emptyPath = directory.appendingPathComponent("empty.sqlite").path
    let empty = SQLiteCredentialStore(path: emptyPath)
    let fetcher = FakeTokenFetcher()
    let provider = OAuthTokenProvider(store: empty, fetcher: fetcher)
    do {
      _ = try await provider.snapshot()
      throw ProbeFailure.assertion("empty store must fail")
    } catch OAuthTokenProviderError.missingCredential {}
    let corruptPath = directory.appendingPathComponent("corrupt.sqlite")
    try Data("not a sqlite database".utf8).write(to: corruptPath)
    let corrupt = OAuthTokenProvider(
      store: SQLiteCredentialStore(path: corruptPath.path), fetcher: fetcher)
    do {
      _ = try await corrupt.snapshot()
      throw ProbeFailure.assertion("corrupt database must fail")
    } catch OAuthTokenProviderError.restore(let underlying) {
      guard let databaseError = underlying as? DatabaseError else {
        throw ProbeFailure.assertion("corrupt database must retain SQLite error")
      }
      try require(
        databaseError.resultCode == .SQLITE_NOTADB, "corrupt fixture produces SQLITE_NOTADB")
    }
    let path = directory.appendingPathComponent("readonly.sqlite").path
    try await SQLiteCredentialStore(path: path).save(FakeCredentials.bundle("A"))
    let readOnly = SQLiteCredentialStore(path: path, readOnly: true)
    try require(
      FakeCredentials.matches(try await readOnly.load(), FakeCredentials.bundle("A")),
      "readonly load works")
    do {
      try await readOnly.save(FakeCredentials.bundle("B"))
      throw ProbeFailure.assertion("readonly write must fail")
    } catch let error as DatabaseError {
      try require(error.resultCode == .SQLITE_READONLY, "SQLite rejects read-only writes")
      // A real SQLite read-only failure, not an empty credential result.
      try require(
        FakeCredentials.matches(
          try await SQLiteCredentialStore(path: path).load(), FakeCredentials.bundle("A")),
        "readonly failure preserves A")
    }
    try require(await fetcher.calls == 0, "storage failures must not refresh")
  }

  private static func expectPersist(
    _ operation: () async throws -> TokenSnapshot
  ) async throws {
    do {
      _ = try await operation()
      throw ProbeFailure.assertion("unavailable provider must not return snapshot")
    } catch OAuthTokenProviderError.persist(let underlying) {
      try require(underlying is ProbeStoreError, "preserve experiment persistence failure")
    }
  }
}
