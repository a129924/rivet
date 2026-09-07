struct RefreshInboxUseCase: Sendable {
  let source: any ReviewRequestSource

  func execute() async -> Outcome<[InboxItem], PRInboxFailure> {
    switch await source.fetchReviewRequestCandidates() {
    case .success(let candidates):
      .success(
        candidates.compactMap { candidate in
          guard candidate.isOpen, candidate.isDirectlyRequestedForCurrentUser else {
            return nil
          }

          return candidate.item
        }
      )
    case .failure(let failure):
      .failure(failure)
    }
  }
}
