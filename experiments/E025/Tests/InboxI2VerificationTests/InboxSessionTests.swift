import RivetPRInbox
import Testing

@testable import InboxI2Verification

@MainActor
struct InboxSessionTests {
  @Test func preservesTheNonFirstSelectionThroughReorderAndRename() async {
    let session = InboxSession()
    let core = InboxItem(owner: "sample", repository: "core", number: 42, title: "原生清單")
    let uiPullRequest = InboxItem(owner: "sample", repository: "ui", number: 42, title: "選取")
    let third = InboxItem(owner: "sample", repository: "runtime", number: 17, title: "還原")
    let renamed = InboxItem(owner: "sample", repository: "ui", number: 42, title: "保留選取")
    await session.refresh { .success([core, uiPullRequest, third]) }
    session.select(InboxRow(uiPullRequest).id)
    await session.refresh { .success([core, third, renamed]) }
    #expect(session.snapshot.rows.last == InboxRow(renamed))
    #expect(session.snapshot.selection == InboxRow(uiPullRequest).id)
  }
}

extension InboxSessionTests {
  @Test func presentsOnlyOwnOpenCandidatesIncludingDraftInSourceOrder() async {
    let session = InboxSession()
    await refresh(session, .candidates)
    #expect(session.snapshot.status == .ready)
    #expect(
      session.snapshot.rows.map(\.repositoryLabel) == [
        "sample/core", "sample/ui", "sample/runtime",
      ])
    #expect(session.snapshot.rows.map(\.numberLabel) == ["#42", "#42", "#17"])
    #expect(
      session.snapshot.rows.map(\.title) == [
        "整理 Inbox 重新整理狀態", "保留原生清單選取", "整理啟動時的連線還原",
      ])
  }

  @Test func realFixtureReorderAndRemovalKeepTheFullIdentity() async {
    let session = InboxSession()
    await refresh(session, .candidates)
    let first = session.snapshot.rows.first?.id
    let selected = session.snapshot.rows.dropFirst().first?.id
    session.select(selected)
    await refresh(session, .reordered)
    #expect(session.snapshot.rows.last?.id == selected)
    #expect(session.snapshot.selection == selected)
    #expect(session.snapshot.rows.last?.title == "重新整理後保留原生清單選取")
    await refresh(session, .removed)
    #expect(session.snapshot.selection == first)
  }

  @Test(arguments: [false, true])
  func emptySuccessClearsSelection(hadRows: Bool) async {
    let session = InboxSession()
    if hadRows { await refresh(session, .candidates) }
    await refresh(session, .empty)
    #expect(session.snapshot.status == .empty)
    #expect(session.snapshot.rows.isEmpty)
    #expect(session.snapshot.selection == nil)
  }

  @Test(arguments: [false, true])
  func failureUsesOnlyTheLastCompleteSnapshot(hadRows: Bool) async {
    let session = InboxSession()
    if hadRows { await refresh(session, .candidates) }
    session.select(session.snapshot.rows.dropFirst().first?.id)
    let before = session.snapshot
    await refresh(session, .failure)
    #expect(session.snapshot.status == (hadRows ? .stale : .unavailable))
    #expect(session.snapshot.rows == before.rows)
    #expect(session.snapshot.selection == before.selection)
  }

  @Test(arguments: [false, true])
  func secondPageWaitAndFailureNeverPublishFirstPageRows(hadRows: Bool) async {
    let session = InboxSession()
    if hadRows { await refresh(session, .candidates) }
    session.select(session.snapshot.rows.dropFirst().first?.id)
    let before = session.snapshot
    let arrived = AsyncStream<Bool>.makeStream()
    let release = AsyncStream<Void>.makeStream()

    let load = Task {
      defer { arrived.continuation.finish() }
      let rest = FixtureREST(fixture: .pageFailure) {
        arrived.continuation.yield(true)
        var iterator = release.stream.makeAsyncIterator()
        _ = await iterator.next()
      }
      await session.refresh { await loadInbox(using: rest) }
    }
    let timer = Task {
      try? await Task.sleep(for: .seconds(2))
      arrived.continuation.finish()
    }
    var iterator = arrived.stream.makeAsyncIterator()
    #expect(await iterator.next() == true)
    timer.cancel()
    #expect(session.snapshot.status == .loading)
    #expect(session.snapshot.rows == before.rows)
    #expect(session.snapshot.selection == before.selection)
    release.continuation.finish()
    await load.value
    #expect(session.snapshot.status == (hadRows ? .stale : .unavailable))
    #expect(session.snapshot.rows == before.rows)
    #expect(session.snapshot.selection == before.selection)
  }

  @Test func missingLiveConfigurationStopsBeforeTheInboxQuery() async {
    let session = InboxSession()
    let connection = LiveConnection(accessGroup: nil, service: nil)
    await session.refresh { await connection.refresh() }
    #expect(session.snapshot.status == .liveNotRun(.missingConfiguration))
    #expect(session.snapshot.rows.isEmpty)
    #expect(session.snapshot.selection == nil)
  }

  private func refresh(_ session: InboxSession, _ fixture: InboxFixture) async {
    await session.refresh { await loadInbox(using: FixtureREST(fixture: fixture)) }
  }
}
