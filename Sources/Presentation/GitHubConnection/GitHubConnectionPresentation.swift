public struct GitHubConnectionPresentation: Sendable {
  public let status: String
  public let isBusy: Bool
  public let canRetry: Bool
  public let canQuery: Bool
  public let accountDescription: String?
  public var canCancel: Bool { isBusy }
  public var canStart: Bool { !isBusy }

  public init(
    status: String, isBusy: Bool, canRetry: Bool, canQuery: Bool, accountDescription: String? = nil
  ) {
    self.status = status
    self.isBusy = isBusy
    self.canRetry = canRetry && !isBusy
    self.canQuery = canQuery && !isBusy
    self.accountDescription = accountDescription
  }
}
