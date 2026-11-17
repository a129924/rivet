/// Display-ready copy. It carries no authentication result or session state.
public struct RivetLoginStatusContent: Equatable, Sendable {
  public let title: String
  public let message: String
  public let announcement: String

  public init(title: String, message: String, announcement: String) {
    self.title = title
    self.message = message
    self.announcement = announcement
  }
}

public struct RivetLoginContent: Equatable, Sendable {
  public let waitingDescription: String
  public let waitingStatus: String
  public let waitingNote: String
  public let waitingCancelAccessibilityLabel: String
  public let verifyingAccount: RivetLoginStatusContent
  public let verifyingToken: RivetLoginStatusContent
  public let connected: RivetLoginStatusContent
  public let tokenFieldAccessibilityLabel: String
  public let createTokenUnavailableMessage: String

  public init(
    waitingDescription: String, waitingStatus: String, waitingNote: String,
    waitingCancelAccessibilityLabel: String, verifyingAccount: RivetLoginStatusContent,
    verifyingToken: RivetLoginStatusContent, connected: RivetLoginStatusContent,
    tokenFieldAccessibilityLabel: String, createTokenUnavailableMessage: String
  ) {
    self.waitingDescription = waitingDescription
    self.waitingStatus = waitingStatus
    self.waitingNote = waitingNote
    self.waitingCancelAccessibilityLabel = waitingCancelAccessibilityLabel
    self.verifyingAccount = verifyingAccount
    self.verifyingToken = verifyingToken
    self.connected = connected
    self.tokenFieldAccessibilityLabel = tokenFieldAccessibilityLabel
    self.createTokenUnavailableMessage = createTokenUnavailableMessage
  }

  public static let standard = RivetLoginContent(
    waitingDescription: "Finish the sign-in steps on GitHub, then return to Rivet.",
    waitingStatus: "Waiting for authorization…",
    waitingNote: "You can cancel this sign-in attempt at any time.",
    waitingCancelAccessibilityLabel: "Waiting for authorization. Cancel sign in.",
    verifyingAccount: .init(
      title: "Verifying account…", message: "Please wait while this sign-in attempt is checked.",
      announcement: "Verifying account."
    ),
    verifyingToken: .init(
      title: "Verifying token…", message: "Please wait while this sign-in attempt is checked.",
      announcement: "Verifying token."
    ),
    connected: .init(
      title: "Sign-in completed.", message: "This sign-in attempt completed successfully.",
      announcement: "Sign-in completed."
    ),
    tokenFieldAccessibilityLabel: "Personal access token",
    createTokenUnavailableMessage: "Token creation is unavailable here."
  )
}
