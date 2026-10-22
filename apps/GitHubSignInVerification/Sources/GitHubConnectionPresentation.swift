struct GitHubConnectionPresentation: Sendable {
  let status: String
  let isBusy: Bool
  let canRetry: Bool
  let canQuery: Bool
  let accountDescription: String?
  var canCancel: Bool { isBusy }
  let canStart: Bool
  let canCopyAuthorizationURL: Bool
  let hasPreparedConfiguration: Bool
  let showsConfigurationFields: Bool

  init(
    status: String, isBusy: Bool, canRetry: Bool, canQuery: Bool, canStart: Bool = true,
    canCopyAuthorizationURL: Bool = false, hasPreparedConfiguration: Bool = false,
    showsConfigurationFields: Bool = true, accountDescription: String? = nil
  ) {
    self.hasPreparedConfiguration = hasPreparedConfiguration
    self.showsConfigurationFields = showsConfigurationFields
    self.status = status
    self.isBusy = isBusy
    self.canStart = canStart && !isBusy
    self.canCopyAuthorizationURL = canCopyAuthorizationURL && isBusy
    self.canRetry = canRetry && !isBusy
    self.canQuery = canQuery && !isBusy
    self.accountDescription = accountDescription
  }
}
