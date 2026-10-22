struct GitHubConnectionPresentation: Sendable {
  let status: String
  let isBusy: Bool
  let canRetry: Bool
  let canQuery: Bool
  let accountDescription: String?
  var canCancel: Bool { isBusy }
  var canStart: Bool { !isBusy }

  init(
    status: String, isBusy: Bool, canRetry: Bool, canQuery: Bool, accountDescription: String? = nil
  ) {
    self.status = status
    self.isBusy = isBusy
    self.canRetry = canRetry && !isBusy
    self.canQuery = canQuery && !isBusy
    self.accountDescription = accountDescription
  }
}
