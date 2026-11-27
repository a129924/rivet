import SwiftUI

@main
struct InboxI2VerificationApp: App {
  private let mode: InboxVerificationMode = {
    let arguments = ProcessInfo.processInfo.arguments
    if arguments.contains("--live") {
      let configuration = Bundle.main.infoDictionary
      return .live(
        LiveConnection(
          accessGroup: configuration?["RivetOAuthAccessGroup"] as? String,
          service: configuration?["RivetOAuthService"] as? String))
    }
    let initial =
      arguments.lazy.compactMap { argument in
        argument.hasPrefix("--fixture=")
          ? InboxFixture(rawValue: String(argument.dropFirst(10))) : nil
      }.first ?? .candidates
    return .controlled(initial)
  }()

  var body: some Scene {
    Window("PR Inbox · I2 驗證", id: "inbox") {
      InboxVerificationWindow(mode: mode)
        .frame(minWidth: 420, minHeight: 390)
    }
    .defaultSize(width: 940, height: 560)
    .windowResizability(.contentMinSize)
  }
}

enum InboxVerificationMode {
  case controlled(InboxFixture)
  case live(LiveConnection)

  var initialFixture: InboxFixture {
    switch self {
    case .controlled(let fixture): fixture
    case .live: .candidates
    }
  }
}
