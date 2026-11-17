import Foundation
import RivetPresentation

public enum LoginPreviewConfigurationError: Error, Equatable, Sendable {
  case invalidArguments
}

/// App-local launch selection for the clean preview, never an authentication configuration.
public struct LoginPreviewConfiguration: Equatable, Sendable {
  public enum Scene: String, CaseIterable, Sendable {
    case welcome
    case pat
    case waiting
    case verifyingAccount = "verifying-account"
    case verifyingToken = "verifying-token"
    case browserFailure = "browser-failure"
    case tokenFailure = "token-failure"
    case completed

    var phase: RivetLoginPhase {
      switch self {
      case .welcome: .welcome
      case .pat: .tokenEntry
      case .waiting: .waitingForBrowser
      case .verifyingAccount: .verifyingAccount
      case .verifyingToken: .verifyingToken
      case .browserFailure:
        .failure(
          .init(message: "Sign-in couldn't be completed. Please try again.", origin: .browser))
      case .tokenFailure:
        .failure(
          .init(message: "The token couldn't be verified. Check it and try again.", origin: .token))
      case .completed: .connected
      }
    }
  }

  public enum Appearance: String, Sendable { case system, light, dark }

  public static let bundleIdentifier = "local.rivet.login-ui-preview"
  public static let footer = "Connect your GitHub account to Rivet."
  public static let usage = """
    RivetLoginDemo --preview [--state welcome|pat|waiting|verifying-account|verifying-token|browser-failure|token-failure|completed]
      [--appearance system|light|dark] [--text-size 13...21]
    """

  public let scene: Scene
  public let appearance: Appearance
  public let bodyPointSize: CGFloat

  public init(arguments: [String]) throws(LoginPreviewConfigurationError) {
    guard arguments.first == "--preview" else { throw .invalidArguments }
    var scene = Scene.welcome
    var appearance = Appearance.system
    var pointSize: CGFloat = 13
    var seen = Set<String>()
    var index = 1
    while index < arguments.count {
      let option = arguments[index]
      guard seen.insert(option).inserted, index + 1 < arguments.count else {
        throw .invalidArguments
      }
      let value = arguments[index + 1]
      switch option {
      case "--state":
        guard let selected = Scene(rawValue: value) else { throw .invalidArguments }
        scene = selected
      case "--appearance":
        guard let selected = Appearance(rawValue: value) else { throw .invalidArguments }
        appearance = selected
      case "--text-size":
        guard let selected = Double(value), selected.isFinite, (13...21).contains(selected) else {
          throw .invalidArguments
        }
        pointSize = CGFloat(selected)
      default: throw .invalidArguments
      }
      index += 2
    }
    self.scene = scene
    self.appearance = appearance
    self.bodyPointSize = pointSize
  }
}
