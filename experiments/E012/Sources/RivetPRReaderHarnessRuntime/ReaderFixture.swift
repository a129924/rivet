import RivetPRReader
import RivetPRReaderWebViewBridge

public enum ReaderFixture {
  public static let snapshot = PRContentSnapshot(
    id: ReaderPullRequestID(owner: "rivet", repository: "fixture", number: 42),
    background: ReaderBackground(title: "Local Reader fixture", body: nil, author: "Rivet"),
    conversation: [], reviews: [], inlineThreads: [],
    files: [
      ReaderFile(
        reference: .init(value: "added"), path: "Sources/NewFeature.swift", previousPath: nil,
        change: .added, additions: 1, deletions: 0, patch: "@@ -0,0 +1 @@\n+let feature = true\n"),
      ReaderFile(
        reference: .init(value: "removed"), path: "Sources/OldFeature.swift", previousPath: nil,
        change: .removed, additions: 0, deletions: 1, patch: "@@ -1 +0,0 @@\n-let obsolete = true\n"
      ),
      ReaderFile(
        reference: .init(value: "modified"), path: "Sources/Reader.swift", previousPath: nil,
        change: .modified, additions: 1, deletions: 1,
        patch:
          "@@ -1 +1 @@\n-let title = \"Before\"\n+let title = \"<img src=x onerror=alert(1)>\"\n"),
      ReaderFile(
        reference: .init(value: "renamed"), path: "Sources/Renamed.swift",
        previousPath: "Sources/Original.swift",
        change: .renamed, additions: 1, deletions: 1,
        patch: "@@ -1 +1 @@\n-let name = \"Old\"\n+let name = \"New\"\n"),
      ReaderFile(
        reference: .init(value: "copied"), path: "Assets/Copy.png",
        previousPath: "Assets/Original.png",
        change: .copied, additions: 0, deletions: 0, patch: nil),
      ReaderFile(
        reference: .init(value: "type-changed"), path: "Scripts/setup", previousPath: nil,
        change: .typeChanged, additions: 0, deletions: 0, patch: nil),
    ],
    reviewDecision: nil, checkRollup: nil)
}

public enum HarnessAuthorityFailure: Error, Equatable {
  case invalidIdentity
}

@MainActor public final class HarnessViewedAuthority: ViewedStateAuthority {
  private var values: [String: Bool] = [:]
  public var onSuccessfulWrite: (() -> Void)?

  public init() {}

  public func viewed(
    for pullRequest: ReaderPullRequestID,
    file: ReaderFileReference
  ) throws -> Bool {
    guard pullRequest == ReaderFixture.snapshot.id,
      ReaderFixture.snapshot.files.contains(where: { $0.reference == file })
    else { throw HarnessAuthorityFailure.invalidIdentity }
    return values[file.value] ?? false
  }

  public func setViewed(
    _ viewed: Bool, for pullRequest: ReaderPullRequestID, file: ReaderFileReference
  ) throws {
    guard pullRequest == ReaderFixture.snapshot.id,
      ReaderFixture.snapshot.files.contains(where: { $0.reference == file })
    else { throw HarnessAuthorityFailure.invalidIdentity }
    values[file.value] = viewed
    onSuccessfulWrite?()
  }
}
