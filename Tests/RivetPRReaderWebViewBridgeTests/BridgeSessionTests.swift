import Foundation
import RivetPRReader
import RivetPRReaderWebViewBridge
import Testing

@MainActor private final class AuthoritySpy: ViewedStateAuthority {
  var values: [String: Bool] = [:]
  var updates: [(String, Bool)] = []
  var failRead = false
  var failUpdate = false
  func viewed(for pullRequest: ReaderPullRequestID, file: ReaderFileReference) throws -> Bool {
    if failRead { throw TestFailure.failed }
    return values[file.value] ?? false
  }
  func setViewed(
    _ viewed: Bool, for pullRequest: ReaderPullRequestID, file: ReaderFileReference
  ) throws {
    if failUpdate { throw TestFailure.failed }
    updates.append((file.value, viewed))
  }
}

@MainActor private final class SinkSpy: DiffSnapshotSink {
  var received: [DiffSnapshotWire] = []
  var fail = false
  func receiveSnapshot(_ snapshot: DiffSnapshotWire) throws {
    if fail { throw TestFailure.failed }
    received.append(snapshot)
  }
}

private enum TestFailure: Error { case failed }

@Suite("PR Reader WebView bridge session") @MainActor struct BridgeSessionTests {
  private func file(
    _ reference: String, path: String = "a.swift", previous: String? = nil,
    change: FileChange = .modified, patch: String? = nil, additions: Int = 1, deletions: Int = 0
  ) -> ReaderFile {
    ReaderFile(
      reference: .init(value: reference), path: path, previousPath: previous, change: change,
      additions: additions, deletions: deletions, patch: patch)
  }
  private func snapshot(
    _ files: [ReaderFile], id: ReaderPullRequestID = .init(owner: "a", repository: "b", number: 1)
  ) -> PRContentSnapshot {
    PRContentSnapshot(
      id: id, background: .init(title: "", body: nil, author: nil), conversation: [], reviews: [],
      inlineThreads: [], files: files, reviewDecision: nil, checkRollup: nil)
  }
  private func event(
    _ wire: DiffSnapshotWire, fileId: String = "f:0", viewed: Bool = true
  ) -> ViewedStateChangeWire {
    .init(
      pullRequestId: wire.pullRequestId, snapshotId: wire.snapshotId, fileId: fileId, viewed: viewed
    )
  }

  @Test func preservesOrderFieldsAndRoutesViewed() throws {
    let authority = AuthoritySpy()
    authority.values = ["first": true]
    let sink = SinkSpy()
    let session = BridgeSession(authority: authority, sink: sink)
    let files = [
      file("first", path: "renamed.swift", previous: "old.swift", change: .renamed, patch: ""),
      file("second", path: "copy.swift", previous: "source.swift", change: .copied),
      file("third", change: .typeChanged),
    ]
    let wire = try session.publish(snapshot(files))
    #expect(sink.received == [wire])
    #expect(wire.files.map(\.fileId) == ["f:0", "f:1", "f:2"])
    #expect(wire.files.map(\.status) == [.renamed, .copied, .typeChanged])
    #expect(wire.files[0].previousFilename == "old.swift")
    #expect(wire.files[0].patch == "")
    #expect(wire.files[1].patch == nil)
    #expect(wire.files.map(\.viewed) == [true, false, false])
    session.receiveViewedChange(event(wire, fileId: "f:1"))
    #expect(authority.updates.count == 1)
    #expect(authority.updates.first?.0 == "second")
    #expect(authority.updates.first?.1 == true)
  }

  @Test func staleUnknownAndMismatchedEventsAreIgnored() throws {
    let authority = AuthoritySpy()
    let sink = SinkSpy()
    var diagnostics: [ViewedChangeDiagnostic] = []
    let session = BridgeSession(
      authority: authority, sink: sink, diagnostic: { diagnostics.append($0) })
    let first = try session.publish(snapshot([file("a")]))
    let second = try session.publish(snapshot([file("a")]))
    #expect(first.snapshotId != second.snapshotId)
    session.receiveViewedChange(event(first))
    session.receiveViewedChange(event(second, fileId: "unknown"))
    session.receiveViewedChange(
      .init(pullRequestId: "wrong", snapshotId: second.snapshotId, fileId: "f:0", viewed: true))
    #expect(authority.updates.isEmpty)
    #expect(diagnostics == [.ignoredIdentity, .ignoredIdentity, .ignoredIdentity])
    session.invalidate()
    session.receiveViewedChange(event(second))
    #expect(authority.updates.isEmpty)
  }

  @Test func failedCandidatesNeverBecomeActiveAndPRSwitchInvalidates() throws {
    let authority = AuthoritySpy()
    let sink = SinkSpy()
    let session = BridgeSession(authority: authority, sink: sink)
    let old = try session.publish(snapshot([file("old")]))
    sink.fail = true
    #expect(throws: BridgeFailure.deliveryFailed) { try session.publish(snapshot([file("new")])) }
    sink.fail = false
    session.receiveViewedChange(event(old))
    #expect(authority.updates.count == 1)
    let next = try session.publish(snapshot([file("new")]))
    #expect(next.snapshotId != old.snapshotId)
    authority.updates.removeAll()
    #expect(throws: BridgeFailure.invalidSnapshot) {
      try session.publish(
        snapshot([file("bad", path: "")], id: .init(owner: "x", repository: "y", number: 2)))
    }
    session.receiveViewedChange(event(next))
    #expect(authority.updates.isEmpty)
  }

  @Test func invalidOrUnreadableSnapshotNeverReachesSink() throws {
    let authority = AuthoritySpy()
    let sink = SinkSpy()
    let session = BridgeSession(authority: authority, sink: sink)
    #expect(throws: BridgeFailure.invalidSnapshot) {
      try session.publish(snapshot([file("same"), file("same")]))
    }
    #expect(throws: BridgeFailure.invalidSnapshot) {
      try session.publish(snapshot([file("x", additions: -1)]))
    }
    authority.failRead = true
    #expect(throws: BridgeFailure.viewedReadFailed) { try session.publish(snapshot([file("x")])) }
    #expect(sink.received.isEmpty)
  }

  @Test func emptyButUniqueReaderReferenceCanBeLookedUp() throws {
    let authority = AuthoritySpy()
    let sink = SinkSpy()
    let session = BridgeSession(authority: authority, sink: sink)
    let wire = try session.publish(snapshot([file("")]))
    session.receiveViewedChange(event(wire))
    #expect(authority.updates.first?.0 == "")
  }

  @Test func updateFailureOnlyEmitsDiagnostic() throws {
    let authority = AuthoritySpy()
    let sink = SinkSpy()
    var diagnostics: [ViewedChangeDiagnostic] = []
    let session = BridgeSession(
      authority: authority, sink: sink, diagnostic: { diagnostics.append($0) })
    let wire = try session.publish(snapshot([file("x")]))
    authority.failUpdate = true
    session.receiveViewedChange(event(wire))
    #expect(diagnostics == [.authorityUpdateFailed])
  }
}
