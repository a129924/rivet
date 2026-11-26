import RivetPRReader

package struct ReaderFileViewed: Sendable {
  package let path: String
  package let change: FileChange
  package let additions: Int
  package let deletions: Int
  package let viewedState: ReaderFileViewedState
}

package enum ReaderFileViewedState: Equatable, Sendable {
  case unviewed
  case viewed
  case dismissed
}
