public struct PRInboxFacade: Sendable {
  private let refreshInboxUseCase: RefreshInboxUseCase

  public init(source: any ReviewRequestSource) {
    refreshInboxUseCase = RefreshInboxUseCase(source: source)
  }

  public func refresh() async -> Outcome<[InboxItem], PRInboxFailure> {
    await refreshInboxUseCase.execute()
  }
}
