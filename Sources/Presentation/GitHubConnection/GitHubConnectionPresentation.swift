/// Display-ready connection state. OAuth and persistence types stay outside Presentation.
public struct GitHubConnectionPresentation: Equatable, Sendable {
  public let title: String
  public let detail: String
  public let account: String?
  public let clientID: String
  public let locksClientID: Bool
  public let showsConfiguration: Bool
  public let requiresRecoveryConfirmation: Bool
  public let isBusy: Bool
  public let canCancel: Bool
  public let canRetry: Bool
  public let canReauthorize: Bool

  public init(
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
