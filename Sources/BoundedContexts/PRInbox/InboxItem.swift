public struct InboxItem: Equatable, Sendable {
  public let owner: String
  public let repository: String
  public let number: Int
  public let title: String

  public init(owner: String, repository: String, number: Int, title: String) {
    self.owner = owner
    self.repository = repository
    self.number = number
    self.title = title
  }
}
