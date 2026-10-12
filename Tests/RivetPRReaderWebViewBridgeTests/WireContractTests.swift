import Foundation
import RivetPRReader
import RivetPRReaderWebViewBridge
import Testing

@Suite("PR Reader WebView wire contract") struct WireContractTests {
  @Test func identityEncodingSeparatesUnicodeAndDelimiterCases() {
    let ids: [ReaderPullRequestID] = [
      .init(owner: "a:b", repository: "c", number: 1),
      .init(owner: "a", repository: "b:c", number: 1),
      .init(owner: "é", repository: "repo", number: 1),
      .init(owner: "é", repository: "repo", number: 1),
      .init(owner: "", repository: "", number: 1),
      .init(owner: "", repository: "", number: 2),
    ]
    #expect(Set(ids.map(PullRequestIDEncoding.encode)).count == ids.count)
  }

  @Test func optionalFieldsOmitNilButRetainEmptyPatch() throws {
    let files = [
      DiffFileWire(
        fileId: "f:0", filename: "a", previousFilename: nil, status: .added, patch: nil,
        additions: 0, deletions: 0, viewed: false),
      DiffFileWire(
        fileId: "f:1", filename: "b", previousFilename: "a", status: .copied, patch: "",
        additions: 0, deletions: 0, viewed: true),
    ]
    let wire = DiffSnapshotWire(pullRequestId: "p", snapshotId: "s", files: files)
    let json = try #require(
      JSONSerialization.jsonObject(with: JSONEncoder().encode(wire)) as? [String: Any])
    let encodedFiles = try #require(json["files"] as? [[String: Any]])
    #expect(encodedFiles[0]["patch"] == nil)
    #expect(encodedFiles[0]["previousFilename"] == nil)
    #expect(encodedFiles[1]["patch"] as? String == "")
    #expect(encodedFiles[1]["previousFilename"] as? String == "a")
    #expect(
      try JSONDecoder().decode(DiffSnapshotWire.self, from: JSONEncoder().encode(wire)) == wire)
  }
  @Test @MainActor func sharedFixtureMatchesSwiftDelivery() throws {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("surfaces/pr-reader-webview/test-fixtures/diff-bridge-contract.json")
    let expected = try JSONDecoder().decode(DiffSnapshotWire.self, from: Data(contentsOf: url))
    let authority = FixtureAuthority()
    let sink = FixtureSink()
    let session = BridgeSession(
      authority: authority, sink: sink,
      sessionId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
    let statuses: [FileChange] = [.added, .removed, .modified, .renamed, .copied, .typeChanged]
    let files = expected.files.enumerated().map { index, wire in
      ReaderFile(
        reference: .init(value: "ref-\(index)"), path: wire.filename,
        previousPath: wire.previousFilename, change: statuses[index], additions: wire.additions,
        deletions: wire.deletions, patch: wire.patch)
    }
    let snapshot = PRContentSnapshot(
      id: .init(owner: "a", repository: "b", number: 1),
      background: .init(title: "", body: nil, author: nil), conversation: [], reviews: [],
      inlineThreads: [], files: files, reviewDecision: nil, checkRollup: nil)
    #expect(try session.publish(snapshot) == expected)
    #expect(sink.received == expected)
  }

}

@MainActor private final class FixtureAuthority: ViewedStateAuthority {
  func viewed(for pullRequest: ReaderPullRequestID, file: ReaderFileReference) throws -> Bool {
    ["ref-1", "ref-3", "ref-5"].contains(file.value)
  }
  func setViewed(
    _ viewed: Bool, for pullRequest: ReaderPullRequestID, file: ReaderFileReference
  ) throws {}
}

@MainActor private final class FixtureSink: DiffSnapshotSink {
  var received: DiffSnapshotWire?
  func receiveSnapshot(_ snapshot: DiffSnapshotWire) throws { received = snapshot }
}
