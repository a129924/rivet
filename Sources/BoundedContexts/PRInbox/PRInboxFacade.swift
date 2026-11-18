public struct PRInboxFacade: Sendable {
  private let refreshInboxUseCase: RefreshInboxUseCase

  public init(source: any ReviewRequestSource) {
    refreshInboxUseCase = .reviewRequests(source)
  }

  public init(selfReviewSource: any SelfReviewSource) {
    refreshInboxUseCase = .selfReview(selfReviewSource)
  }

  public func refresh() async -> Outcome<[InboxItem], PRInboxFailure> {
    await refreshInboxUseCase.execute()
  }
}
