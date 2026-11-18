import Foundation

struct LoginAcceptanceConfiguration: Equatable, Sendable {
  enum Scene: String, CaseIterable, Sendable {
    case welcome, pat, waiting
    case verifyingAccount = "verifying-account"
    case verifyingToken = "verifying-token"
    case browserFailure = "browser-failure"
    case tokenFailure = "token-failure"
    case completed
  }
  enum Appearance: String, Sendable { case system, light, dark }

  static let usage = """
    RivetLoginAcceptance [--state welcome|pat|waiting|verifying-account|verifying-token|browser-failure|token-failure|completed]
      [--appearance system|light|dark] [--text-size 13...21]
    """
  let scene: Scene
  let appearance: Appearance
  let bodyPointSize: CGFloat

  init(arguments: [String]) throws(LoginAcceptanceConfigurationError) {
    var scene = Scene.welcome
    var appearance = Appearance.system
    var pointSize: CGFloat = 13
    var seen = Set<String>()
    var index = 0
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

enum LoginAcceptanceConfigurationError: Error, Equatable, Sendable { case invalidArguments }
