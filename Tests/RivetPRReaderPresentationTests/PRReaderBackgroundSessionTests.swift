import Observation
import RivetPRReader
import Testing

@testable import RivetPRReaderPresentation

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PRReaderBackgroundSessionTests {
  private let source = ControlledBackgroundSource()
  private let first = ReaderPullRequestID(owner: "owner", repository: "repo", number: 1)
  private let second = ReaderPullRequestID(owner: "owner", repository: "repo", number: 2)
  private let original = ReaderBackground(title: "First", body: "Original", author: "reviewer")
  private let updated = ReaderBackground(title: "Updated", body: nil, author: nil)

  @Test("P01: selecting a PR loads and commits its background")
  func selectingPRStartsLoading() async throws {
    let session = makeSession()
    try await loadOriginal(in: session)
    #expect(session.currentRequestCompletion() == nil)
  }

  @Test("P02: switching PRs removes the previous PR's background")
  func switchingPRsClearsPreviousBackground() async throws {
    let session = makeSession()
    try await loadOriginal(in: session)
    session.select(second)
    #expect(session.state == .loading(second))
    #expect(await source.waitForRequest(2) == second)
    try await settle(2, as: .success(updated), in: session)
    #expect(session.state == .loaded(second, updated))
  }

  @Test(
    "P03/P04/P15: an obsolete success or failure cannot update another PR",
    arguments: [true, false])
  func lateResultIsIgnored(succeeds: Bool) async throws {
    let session = makeSession()
    session.select(first)
    let obsolete = try #require(session.currentRequestCompletion())
    #expect(await source.waitForRequest(1) == first)

    session.select(second)
    #expect(await source.waitForRequest(2) == second)
    try await settle(2, as: .success(updated), in: session)

    await source.release(1, as: succeeds ? .success(original) : .failure(.notReadable))
    await obsolete()
    #expect(await source.cancellations[1] == true)
    #expect(session.state == .loaded(second, updated))
    #expect(session.currentRequestCompletion() == nil)
  }

  @Test("P05: a same-PR refresh replaces data once it has succeeded")
  func refreshKeepsLastSuccessUntilCommit() async throws {
    let session = makeSession()
    try await loadOriginal(in: session)

    session.refresh()
    #expect(session.state == .refreshing(first, previous: original))
    #expect(await source.waitForRequest(2) == first)
    try await settle(2, as: .success(updated), in: session)
    #expect(session.state == .loaded(first, updated))
    #expect(session.currentRequestCompletion() == nil)
  }

  @Test("P06/P14: refresh failure preserves data and a retry clears the previous failure")
  func failingRefreshCanBeRetried() async throws {
    let session = makeSession()
    try await loadOriginal(in: session)

    session.refresh()
    #expect(await source.waitForRequest(2) == first)
    try await settle(2, as: .failure(.unavailable), in: session)
    #expect(await source.cancellations[2] == false)
    #expect(session.state == .refreshFailed(first, previous: original, failure: .unavailable))

    session.refresh()
    #expect(session.state == .refreshing(first, previous: original))
    #expect(await source.waitForRequest(3) == first)
    try await settle(3, as: .failure(.notReadable), in: session)
    #expect(session.state == .refreshFailed(first, previous: original, failure: .notReadable))

    session.refresh()
    #expect(session.state == .refreshing(first, previous: original))
    #expect(await source.waitForRequest(4) == first)
    try await settle(4, as: .success(updated), in: session)
    #expect(session.state == .loaded(first, updated))
  }

  @Test("P07: only the latest generation can refresh the same PR")
  func repeatedRefreshKeepsLastCommittedData() async throws {
    let session = makeSession()
    try await loadOriginal(in: session)

    session.refresh()
    let older = try #require(session.currentRequestCompletion())
    #expect(await source.waitForRequest(2) == first)
    session.refresh()
    let replaced = try #require(session.currentRequestCompletion())
    #expect(await source.waitForRequest(3) == first)
    session.refresh()
    #expect(await source.waitForRequest(4) == first)

    await source.release(3, as: .failure(.unavailable))
    await replaced()
    #expect(session.state == .refreshing(first, previous: original))
    try await settle(4, as: .success(updated), in: session)
    await source.release(2, as: .success(original))
    await older()

    #expect(await source.cancellations[2] == true)
    #expect(await source.cancellations[3] == true)
    #expect(await source.cancellations[4] == false)
    #expect(session.state == .loaded(first, updated))
    #expect(session.currentRequestCompletion() == nil)
  }

  @Test(
    "P08/P09: cancelling preserves selection or the last successful background",
    arguments: [false, true])
  func cancelRestoresVisibleState(refreshing: Bool) async throws {
    let session = makeSession()
    if refreshing {
      try await loadOriginal(in: session)
      session.refresh()
    } else {
      session.select(first)
    }

    let index = refreshing ? 2 : 1
    let cancelled = try #require(session.currentRequestCompletion())
    #expect(await source.waitForRequest(index) == first)
    let restored: ReaderBackgroundState = refreshing ? .loaded(first, original) : .selected(first)
    session.cancelLoading()
    #expect(session.state == restored)
    #expect(session.currentRequestCompletion() == nil)

    await source.release(index, as: .failure(.unavailable))
    await cancelled()
    #expect(await source.cancellations[index] == true)
    #expect(session.state == restored)

    session.refresh()
    #expect(await source.waitForRequest(index + 1) == first)
    try await settle(index + 1, as: .success(updated), in: session)
    #expect(session.state == .loaded(first, updated))
  }

  @Test("P10/P16/P17: invalidation cancels, ignores late results and rejects reuse")
  func invalidationIsPermanent() async throws {
    let session = makeSession()
    try await loadOriginal(in: session)
    session.refresh()
    let retired = try #require(session.currentRequestCompletion())
    #expect(await source.waitForRequest(2) == first)

    session.invalidate()
    session.invalidate()
    session.select(second)
    session.refresh()
    session.cancelLoading()
    #expect(session.state == .idle)
    #expect(session.currentRequestCompletion() == nil)

    await source.release(2, as: .success(updated))
    await retired()
    #expect(await source.cancellations[2] == true)
    #expect(session.state == .idle)
    #expect(await source.requests == [first, first])
  }

  @Test("P10: a suspended task does not retain the invalidated session")
  func invalidatedSessionCanBeReleasedBeforeSourceReturns() async throws {
    var session: PRReaderBackgroundSession? = makeSession()
    let weakSession = { [weak session] in session }
    session?.select(first)
    let retired = try #require(session?.currentRequestCompletion())
    #expect(await source.waitForRequest(1) == first)

    session?.invalidate()
    session = nil
    #expect(weakSession() == nil)
    await source.release(1, as: .success(original))
    await retired()
    #expect(await source.cancellations[1] == true)
  }

  @Test("P10: synchronous state observation can invalidate the session")
  func invalidationDuringNotificationCannotRestoreLoading() {
    let session = PRReaderBackgroundSession(
      facade: PRReaderBackgroundFacade(source: ImmediateBackgroundSource())
    )
    withObservationTracking {
      _ = session.state
    } onChange: {
      MainActor.assumeIsolated { session.invalidate() }
    }

    session.select(first)

    #expect(session.state == .idle)
    #expect(session.currentRequestCompletion() == nil)
    session.refresh()
    #expect(session.state == .idle)
  }

  @Test("P11: an active unavailable failure is displayed and can be retried")
  func activeUnavailableIsAFailure() async throws {
    let session = makeSession()
    session.refresh()
    #expect(session.state == .idle)
    session.select(first)
    #expect(await source.waitForRequest(1) == first)
    try await settle(1, as: .failure(.unavailable), in: session)
    #expect(session.state == .failed(first, .unavailable))
    #expect(session.currentRequestCompletion() == nil)

    session.refresh()
    #expect(session.state == .loading(first))
    #expect(await source.waitForRequest(2) == first)
    try await settle(2, as: .success(original), in: session)
    #expect(session.state == .loaded(first, original))
  }

  @Test("P12: the original Task cannot clear the current Task handle", arguments: [false, true])
  func staleCleanupPreservesCurrentTask(cancelCurrent: Bool) async throws {
    let session = makeSession()
    session.select(first)
    let stale = try #require(session.currentRequestCompletion())
    #expect(await source.waitForRequest(1) == first)
    session.select(second)
    let current = try #require(session.currentRequestCompletion())
    #expect(await source.waitForRequest(2) == second)

    await source.release(1, as: .success(original))
    await stale()
    #expect(session.state == .loading(second))

    if cancelCurrent {
      session.cancelLoading()
    }
    await source.release(2, as: .success(updated))
    await current()
    #expect(await source.cancellations[2] == cancelCurrent)
    #expect(session.state == (cancelCurrent ? .selected(second) : .loaded(second, updated)))
    #expect(session.currentRequestCompletion() == nil)
  }

  @Test("P13: selecting the same PR preserves in-flight and settled state")
  func samePRDoesNotStartAnotherRequest() async throws {
    let session = makeSession()
    session.select(first)
    let initial = try #require(session.currentRequestCompletion())
    #expect(await source.waitForRequest(1) == first)

    session.select(first)
    #expect(session.state == .loading(first))
    await source.release(1, as: .success(original))
    await initial()
    #expect(await source.cancellations[1] == false)
    #expect(session.state == .loaded(first, original))

    session.select(first)
    #expect(session.state == .loaded(first, original))
    #expect(session.currentRequestCompletion() == nil)
    #expect(await source.requests == [first])
  }

  @Test(
    "Current task cancellation rejects success and failure", arguments: [false, true],
    [false, true])
  func originalTaskCanCancelItself(refreshing: Bool, succeeds: Bool) async throws {
    let session = makeSession()
    if refreshing {
      try await loadOriginal(in: session)
      session.refresh()
    } else {
      session.select(first)
    }

    let index = refreshing ? 2 : 1
    let completion = try #require(session.currentRequestCompletion())
    #expect(await source.waitForRequest(index) == first)
    await source.release(
      index, as: succeeds ? .success(updated) : .failure(.unavailable), cancellingTask: true
    )
    await completion()

    #expect(await source.cancellations[index] == true)
    #expect(session.state == (refreshing ? .loaded(first, original) : .selected(first)))
    #expect(session.currentRequestCompletion() == nil)
  }

  private func makeSession() -> PRReaderBackgroundSession {
    PRReaderBackgroundSession(facade: PRReaderBackgroundFacade(source: source))
  }

  private func loadOriginal(in session: PRReaderBackgroundSession) async throws {
    session.select(first)
    #expect(session.state == .loading(first))
    #expect(await source.waitForRequest(1) == first)
    try await settle(1, as: .success(original), in: session)
    #expect(session.state == .loaded(first, original))
  }

  private func settle(
    _ index: Int,
    as outcome: Outcome<ReaderBackground, PRReaderFailure>,
    in session: PRReaderBackgroundSession
  ) async throws {
    let completion = try #require(session.currentRequestCompletion())
    await source.release(index, as: outcome)
    await completion()
  }
}

private actor ControlledBackgroundSource: PRBackgroundSource {
  private struct Delivery {
    let outcome: Outcome<ReaderBackground, PRReaderFailure>
    let cancellingTask: Bool
  }

  private var pending: [Int: CheckedContinuation<Delivery, Never>] = [:]
  private var waiters: [Int: CheckedContinuation<ReaderPullRequestID, Never>] = [:]
  private(set) var requests: [ReaderPullRequestID] = []
  private(set) var cancellations: [Int: Bool] = [:]

  func fetchBackground(for id: ReaderPullRequestID) async -> Outcome<
    ReaderBackground, PRReaderFailure
  > {
    requests.append(id)
    let index = requests.count
    let delivery = await withCheckedContinuation { continuation in
      pending[index] = continuation
      waiters.removeValue(forKey: index)?.resume(returning: id)
    }
    if delivery.cancellingTask {
      withUnsafeCurrentTask { $0?.cancel() }
    }
    cancellations[index] = Task.isCancelled
    return delivery.outcome
  }

  func waitForRequest(_ index: Int) async -> ReaderPullRequestID {
    if index <= requests.count {
      return requests[index - 1]
    }
    return await withCheckedContinuation { waiters[index] = $0 }
  }

  func release(
    _ index: Int,
    as outcome: Outcome<ReaderBackground, PRReaderFailure>,
    cancellingTask: Bool = false
  ) {
    pending.removeValue(forKey: index)?.resume(
      returning: Delivery(outcome: outcome, cancellingTask: cancellingTask)
    )
  }
}

private struct ImmediateBackgroundSource: PRBackgroundSource {
  func fetchBackground(
    for id: ReaderPullRequestID
  ) async -> Outcome<ReaderBackground, PRReaderFailure> {
    .failure(.unavailable)
  }
}
