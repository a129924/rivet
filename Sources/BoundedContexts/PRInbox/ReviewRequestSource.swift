public protocol ReviewRequestSource: Sendable {
  func fetchReviewRequestCandidates() async
    -> Outcome<[ReviewRequestCandidate], PRInboxFailure>
}
