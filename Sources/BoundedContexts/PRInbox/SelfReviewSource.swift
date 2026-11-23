public protocol SelfReviewSource: Sendable {
  func fetchSelfReviewCandidates() async -> Outcome<[SelfReviewCandidate], PRInboxFailure>
}

public struct SelfReviewCandidate: Equatable, Sendable {
  public let item: InboxItem
  public let isOpen: Bool
  public let isAuthoredByCurrentUser: Bool

  public init(item: InboxItem, isOpen: Bool, isAuthoredByCurrentUser: Bool) {
    self.item = item
    self.isOpen = isOpen
    self.isAuthoredByCurrentUser = isAuthoredByCurrentUser
  }
}
