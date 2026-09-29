import Foundation
import RivetPRReader

public struct DiffSnapshotWire: Codable, Equatable, Sendable {
  public let pullRequestId: String
  public let snapshotId: String
  public let files: [DiffFileWire]

  public init(pullRequestId: String, snapshotId: String, files: [DiffFileWire]) {
    self.pullRequestId = pullRequestId
    self.snapshotId = snapshotId
    self.files = files
  }
}

public struct DiffFileWire: Codable, Equatable, Sendable {
  public let fileId: String
  public let filename: String
  public let previousFilename: String?
  public let status: DiffFileStatusWire
  public let patch: String?
  public let additions: Int
  public let deletions: Int
  public let viewed: Bool

  public init(
    fileId: String, filename: String, previousFilename: String?, status: DiffFileStatusWire,
    patch: String?, additions: Int, deletions: Int, viewed: Bool
  ) {
    self.fileId = fileId
    self.filename = filename
    self.previousFilename = previousFilename
    self.status = status
    self.patch = patch
    self.additions = additions
    self.deletions = deletions
    self.viewed = viewed
  }
}

public enum DiffFileStatusWire: String, Codable, Sendable {
  case added, removed, modified, renamed, copied, typeChanged

  init(_ change: FileChange) {
    switch change {
    case .added: self = .added
    case .removed: self = .removed
    case .modified: self = .modified
    case .renamed: self = .renamed
    case .copied: self = .copied
    case .typeChanged: self = .typeChanged
    }
  }
}

public struct ViewedStateChangeWire: Codable, Equatable, Sendable {
  public let pullRequestId: String
  public let snapshotId: String
  public let fileId: String
  public let viewed: Bool

  public init(pullRequestId: String, snapshotId: String, fileId: String, viewed: Bool) {
    self.pullRequestId = pullRequestId
    self.snapshotId = snapshotId
    self.fileId = fileId
    self.viewed = viewed
  }
}

public enum BridgeFailure: Error, Equatable, Sendable {
  case invalidSnapshot
  case viewedReadFailed
  case deliveryFailed
  case snapshotIdentityExhausted
}

public enum ViewedChangeDiagnostic: Equatable, Sendable {
  case ignoredIdentity
  case authorityUpdateFailed
}

public enum PullRequestIDEncoding {
  public static func encode(_ id: ReaderPullRequestID) -> String {
    "rivet-pr-v1:\(id.owner.utf8.count):\(id.owner):\(id.repository.utf8.count):\(id.repository):\(id.number)"
  }
}
