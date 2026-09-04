public struct ReviewRequestCandidate: Equatable, Sendable {
  public let item: InboxItem
  public let isOpen: Bool
  public let isDirectlyRequestedForCurrentUser: Bool
}
