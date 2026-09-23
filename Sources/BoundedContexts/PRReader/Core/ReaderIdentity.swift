public struct ReaderPullRequestID: Equatable, Sendable {
  public let owner: String
  public let repository: String
  public let number: Int

  public init(owner: String, repository: String, number: Int) {
    self.owner = owner
    self.repository = repository
    self.number = number
  }
}

public struct ReaderFileReference: Equatable, Sendable {
  public let value: String

  public init(value: String) {
    self.value = value
  }
}
