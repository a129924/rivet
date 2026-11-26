import RivetPRReader

package struct ReaderPullRequestReviewMergeState: Equatable, Sendable {
  package let reviewDecision: ReviewDecision?
  package let mergeable: ReaderMergeableState
  package let mergeStateStatus: ReaderMergeStateStatus
  package let isDraft: Bool
  package let headRefOid: String

  package init(
    reviewDecision: ReviewDecision?,
    mergeable: ReaderMergeableState,
    mergeStateStatus: ReaderMergeStateStatus,
    isDraft: Bool,
    headRefOid: String
  ) {
    self.reviewDecision = reviewDecision
    self.mergeable = mergeable
    self.mergeStateStatus = mergeStateStatus
    self.isDraft = isDraft
    self.headRefOid = headRefOid
  }
}

package enum ReaderMergeableState: Equatable, Sendable {
  case conflicting
  case mergeable
  case unknown
}

package enum ReaderMergeStateStatus: Equatable, Sendable {
  case behind
  case blocked
  case clean
  case dirty
  case draft
  case hasHooks
  case unknown
  case unstable
}
