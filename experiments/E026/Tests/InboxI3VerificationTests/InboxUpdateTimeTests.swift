import InboxExperimentSupport
import Testing

@testable import InboxI3Verification

@MainActor
struct InboxUpdateTimeTests {
  @Test func malformedTimesOnlyRemoveTheirOwnLabels() async {
    let session = InboxExperimentSession()
    await refresh(session, .candidates)

    #expect(
      session.snapshot.rows.map(\.id) == [
        "sample/core#42", "sample/ui#42", "sample/missing#17", "sample/null#18",
        "sample/type#19", "sample/invalid#20",
      ])
    #expect(session.snapshot.rows.map(\.relativeTimeLabel) == ["3 小時前", "2 小時前", "", "", "", ""])
    session.select("sample/invalid#20")
    #expect(session.snapshot.selection == "sample/invalid#20")
  }

  @Test func completeRefreshKeepsTheSelectedIdentityAndReplacesItsTime() async {
    let session = InboxExperimentSession()
    await refresh(session, .candidates)
    session.select("sample/ui#42")
    await observeSecondPage(session, fixture: .reordered)

    #expect(
      session.snapshot.rows.map(\.id) == ["sample/core#42", "sample/missing#17", "sample/ui#42"])
    #expect(session.snapshot.rows.map(\.relativeTimeLabel) == ["3 小時前", "", "1 小時前"])
    #expect(session.snapshot.selection == "sample/ui#42")

    await refresh(session, .missingTime)
    #expect(session.snapshot.rows.last?.relativeTimeLabel == "")
    #expect(session.snapshot.selection == "sample/ui#42")

    await refresh(session, .removed)
    #expect(session.snapshot.selection == "sample/core#42")
    await refresh(session, .empty)
    #expect(session.snapshot.status == .empty)
    #expect(session.snapshot.selection == nil)
  }

  @Test func failureRetainsOnlyTheLastCompleteSnapshot() async {
    let session = InboxExperimentSession()
    await refresh(session, .failure)
    #expect(session.snapshot.status == .unavailable)
    #expect(session.snapshot.rows.isEmpty)

    await refresh(session, .candidates)
    session.select("sample/ui#42")
    let previous = session.snapshot
    await observeSecondPage(session, fixture: .pageFailure)
    #expect(session.snapshot.rows == previous.rows)
    #expect(session.snapshot.selection == previous.selection)
    #expect(session.snapshot.status == .stale)
  }

  @Test func cancellationRestoresStatusInsteadOfPublishingNewDates() async {
    let session = InboxExperimentSession()
    await refresh(session, .candidates)
    session.select("sample/ui#42")
    let previous = session.snapshot
    await observeSecondPage(session, fixture: .reordered, cancel: true)
    #expect(session.snapshot == previous)
  }

  private func refresh(_ session: InboxExperimentSession, _ fixture: InboxI3Fixture) async {
    await session.refresh {
      await loadInboxI3(
        using: InboxI3FixtureREST(fixture: fixture), referenceDate: inboxI3ReferenceDate)
    }
  }

  private func observeSecondPage(
    _ session: InboxExperimentSession, fixture: InboxI3Fixture, cancel: Bool = false
  ) async {
    let previous = session.snapshot
    let reached = AsyncStream<Bool>.makeStream()
    let release = AsyncStream<Void>.makeStream()
    let task = Task {
      defer { reached.continuation.finish() }
      await session.refresh {
        let rest = InboxI3FixtureREST(fixture: fixture) {
          reached.continuation.yield(true)
          var iterator = release.stream.makeAsyncIterator()
          _ = await iterator.next()
        }
        return await loadInboxI3(using: rest, referenceDate: inboxI3ReferenceDate)
      }
    }

    var iterator = reached.stream.makeAsyncIterator()
    #expect(await iterator.next() == true)
    #expect(session.snapshot.status == .loading)
    #expect(session.snapshot.rows == previous.rows)
    #expect(session.snapshot.selection == previous.selection)
    if cancel {
      task.cancel()
    }
    release.continuation.finish()
    await task.value
  }
}
