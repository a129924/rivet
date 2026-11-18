enum RefreshInboxUseCase: Sendable {
  case reviewRequests(any ReviewRequestSource)
  case selfReview(any SelfReviewSource)

  func execute() async -> Outcome<[InboxItem], PRInboxFailure> {
    switch self {
    case .reviewRequests(let source):
      await source.fetchReviewRequestCandidates().map { candidates in
        candidates.compactMap { candidate in
          guard candidate.isOpen, candidate.isDirectlyRequestedForCurrentUser else {
            return nil
          }
          return candidate.item
        }
      }
    case .selfReview(let source):
      await source.fetchSelfReviewCandidates().map { candidates in
        candidates.compactMap { candidate in
          guard candidate.isOpen, candidate.isAuthoredByCurrentUser else {
            return nil
          }
          return candidate.item
        }
      }
    }
  }
}
