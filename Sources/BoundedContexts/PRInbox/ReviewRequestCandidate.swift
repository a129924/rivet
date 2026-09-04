public struct ReviewRequestCandidate: Equatable, Sendable {
  public let item: InboxItem
  public let isOpen: Bool
  public let isDirectlyRequestedForCurrentUser: Bool

  public init(
    item: InboxItem,
    isOpen: Bool,
    isDirectlyRequestedForCurrentUser: Bool
  ) {
    self.item = item
    self.isOpen = isOpen
    self.isDirectlyRequestedForCurrentUser = isDirectlyRequestedForCurrentUser
  }
}
