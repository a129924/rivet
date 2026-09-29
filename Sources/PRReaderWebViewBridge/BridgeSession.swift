import Foundation
import RivetPRReader

@MainActor public protocol ViewedStateAuthority: AnyObject {
  func viewed(for pullRequest: ReaderPullRequestID, file: ReaderFileReference) throws -> Bool
  func setViewed(_ viewed: Bool, for pullRequest: ReaderPullRequestID, file: ReaderFileReference)
    throws
}

@MainActor public protocol DiffSnapshotSink: AnyObject {
  func receiveSnapshot(_ snapshot: DiffSnapshotWire) throws
}

@MainActor public final class BridgeSession {
  private struct ActiveSnapshot {
    let pullRequest: ReaderPullRequestID
    let pullRequestId: String
    let snapshotId: String
    let references: [String: ReaderFileReference]
  }

  private let authority: any ViewedStateAuthority
  private let sink: any DiffSnapshotSink
  private let diagnostic: (ViewedChangeDiagnostic) -> Void
  private let sessionId: UUID
  private var nextSequence: UInt64 = 0
  private var active: ActiveSnapshot?

  public init(
    authority: any ViewedStateAuthority,
    sink: any DiffSnapshotSink,
    sessionId: UUID = UUID(),
    diagnostic: @escaping (ViewedChangeDiagnostic) -> Void = { _ in }
  ) {
    self.authority = authority
    self.sink = sink
    self.sessionId = sessionId
    self.diagnostic = diagnostic
  }

  @discardableResult public func publish(_ snapshot: PRContentSnapshot) throws -> DiffSnapshotWire {
    if active?.pullRequest != snapshot.id { active = nil }
    guard nextSequence < UInt64.max else { throw BridgeFailure.snapshotIdentityExhausted }
    nextSequence += 1
    let pullRequestId = PullRequestIDEncoding.encode(snapshot.id)
    let snapshotId = "\(sessionId.uuidString):\(nextSequence)"
    var references: [String: ReaderFileReference] = [:]
    var seenReferences = Set<String>()
    var files: [DiffFileWire] = []
    files.reserveCapacity(snapshot.files.count)

    for (index, file) in snapshot.files.enumerated() {
      guard seenReferences.insert(file.reference.value).inserted,
        !file.path.isEmpty,
        file.previousPath.map({ !$0.isEmpty }) ?? true,
        file.additions >= 0, file.additions <= 9_007_199_254_740_991,
        file.deletions >= 0, file.deletions <= 9_007_199_254_740_991
      else { throw BridgeFailure.invalidSnapshot }
      let fileId = "f:\(index)"
      let viewed: Bool
      do { viewed = try authority.viewed(for: snapshot.id, file: file.reference) } catch {
        throw BridgeFailure.viewedReadFailed
      }
      files.append(
        DiffFileWire(
          fileId: fileId,
          filename: file.path,
          previousFilename: file.previousPath,
          status: DiffFileStatusWire(file.change),
          patch: file.patch,
          additions: file.additions,
          deletions: file.deletions,
          viewed: viewed
        ))
      references[fileId] = file.reference
    }

    let wire = DiffSnapshotWire(pullRequestId: pullRequestId, snapshotId: snapshotId, files: files)
    do { try sink.receiveSnapshot(wire) } catch { throw BridgeFailure.deliveryFailed }
    active = ActiveSnapshot(
      pullRequest: snapshot.id, pullRequestId: pullRequestId, snapshotId: snapshotId,
      references: references)
    return wire
  }

  public func receiveViewedChange(_ change: ViewedStateChangeWire) {
    guard let active,
      change.pullRequestId == active.pullRequestId,
      change.snapshotId == active.snapshotId,
      let reference = active.references[change.fileId]
    else {
      diagnostic(.ignoredIdentity)
      return
    }
    do { try authority.setViewed(change.viewed, for: active.pullRequest, file: reference) } catch {
      diagnostic(.authorityUpdateFailed)
    }
  }

  public func invalidate() { active = nil }
}
