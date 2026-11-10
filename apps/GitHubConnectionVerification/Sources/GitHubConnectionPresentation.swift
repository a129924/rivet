/// Display-ready connection state. OAuth and persistence types stay outside Presentation.
struct GitHubConnectionPresentation: Equatable, Sendable {
  let title: String
  let detail: String
  let account: String?
  let clientID: String
  let locksClientID: Bool
  let showsConfiguration: Bool
  let requiresRecoveryConfirmation: Bool
  let isBusy: Bool
  let canCancel: Bool
  let canRetry: Bool
  let canReauthorize: Bool

  init(
    title: String, detail: String, account: String? = nil, clientID: String = "",
    locksClientID: Bool = false, showsConfiguration: Bool = false,
    requiresRecoveryConfirmation: Bool = false, isBusy: Bool = false,
    canCancel: Bool = false, canRetry: Bool = false, canReauthorize: Bool = false
  ) {
    self.title = title
    self.detail = detail
    self.account = account
    self.clientID = clientID
    self.locksClientID = locksClientID
    self.showsConfiguration = showsConfiguration
    self.requiresRecoveryConfirmation = requiresRecoveryConfirmation
    self.isBusy = isBusy
    self.canCancel = canCancel
    self.canRetry = canRetry
    self.canReauthorize = canReauthorize
  }
}
