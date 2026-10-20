import Foundation
import SwiftUI

@main
struct GitHubSignInVerificationApp: App {
  @State private var connection: GitHubConnectionCoordinator

  init() {
    let testing =
      ProcessInfo.processInfo.environment["GITHUB_SIGN_IN_VERIFICATION_UNIT_TEST_MODE"] == "1"
    _connection = State(
      initialValue: GitHubConnectionCoordinator(dependencies: testing ? .disabled : .live))
  }

  var body: some Scene {
    WindowGroup("GitHubSignInVerification — GitHub 登入驗證") {
      GitHubConnectionView(
        clientID: $connection.clientID, clientSecret: $connection.clientSecret,
        input: connection.presentation, signIn: connection.signIn, cancel: connection.cancel,
        retry: connection.retry, query: connection.query)
    }
    .defaultSize(width: 660, height: 410)
    .windowResizability(.contentMinSize)
  }
}
