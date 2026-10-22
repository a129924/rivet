import Foundation

public struct RivetLoginFailure: Equatable, Sendable {
  public enum Origin: String, CaseIterable, Sendable {
    case browser
    case token
  }

  public let message: String
  public let origin: Origin

  public init(message: String, origin: Origin) {
    self.message = message
    self.origin = origin
  }
}

public enum RivetLoginPhase: Equatable, Sendable {
  case welcome
  case tokenEntry
  case waitingForBrowser
  case verifyingAccount
  case verifyingToken
  case failure(RivetLoginFailure)
  case connected

  public var isTokenForm: Bool {
    switch self {
    case .tokenEntry: true
    case .failure(let failure): failure.origin == .token
    default: false
    }
  }
}

public enum RivetLoginIntent: Equatable, Sendable {
  case beginGitHubSignIn
  case showTokenEntry
  case backToWelcome
  case cancelSignIn
  case submitToken(String)
  case retry
}

/// Ephemeral editing state. No validation or credential storage takes place here.
struct RivetLoginTokenInput {
  var text = ""
  var showsToken = false

  var canSubmit: Bool { !normalized.isEmpty }
  private var normalized: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

  mutating func takeSubmission() -> String? {
    let value = normalized
    clear()
    return value.isEmpty ? nil : value
  }

  mutating func clear() {
    text = ""
    showsToken = false
  }
}
