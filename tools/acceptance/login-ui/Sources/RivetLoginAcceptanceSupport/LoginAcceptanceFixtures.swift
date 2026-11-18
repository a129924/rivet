import RivetPresentation

// Acceptance-only input fixtures. These are not authentication requests or outcomes.
enum LoginAcceptanceFixtures {
  static let footer = "Connect your GitHub account to Rivet."

  static func phase(for scene: LoginAcceptanceConfiguration.Scene) -> RivetLoginPhase {
    switch scene {
    case .welcome: .welcome
    case .pat: .tokenEntry
    case .waiting: .waitingForBrowser
    case .verifyingAccount: .verifyingAccount
    case .verifyingToken: .verifyingToken
    case .completed: .connected
    case .browserFailure:
      .failure(.init(message: "Sign-in couldn't be completed. Please try again.", origin: .browser))
    case .tokenFailure:
      .failure(
        .init(message: "The token couldn't be verified. Check it and try again.", origin: .token))
    }
  }

  static func title(for scene: LoginAcceptanceConfiguration.Scene) -> String {
    switch scene {
    case .welcome: "Welcome"
    case .pat: "PAT"
    case .waiting: "Waiting"
    case .verifyingAccount: "Verifying account"
    case .verifyingToken: "Verifying token"
    case .browserFailure: "Browser failure"
    case .tokenFailure: "Token failure"
    case .completed: "Completed"
    }
  }

  static let controlledContent = RivetLoginContent(
    waitingDescription: "Controlled browser-step description.",
    waitingStatus: "Controlled waiting.",
    waitingNote: "Selected acceptance copy.",
    waitingCancelAccessibilityLabel: "Controlled waiting. Cancel sign in.",
    verifyingAccount: .init(
      title: "Controlled account check", message: "Selected acceptance copy.",
      announcement: "Controlled account check."),
    verifyingToken: .init(
      title: "Controlled token check", message: "Selected acceptance copy.",
      announcement: "Controlled token check."),
    connected: .init(
      title: "Controlled completion", message: "Selected acceptance copy.",
      announcement: "Controlled completion."),
    tokenFieldAccessibilityLabel: "Controlled token field",
    createTokenUnavailableMessage: "Creation is disabled in this selected configuration."
  )
}
