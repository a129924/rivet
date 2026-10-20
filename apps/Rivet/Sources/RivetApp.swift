import Foundation
import RivetPresentation
import SwiftUI

@main
struct RivetApp: App {
  @State private var connection: GitHubConnectionCoordinator

  init() {
    let testing = ProcessInfo.processInfo.environment["RIVET_UNIT_TEST_MODE"] == "1"
    _connection = State(
      initialValue: GitHubConnectionCoordinator(dependencies: testing ? .disabled : .live))
  }

  var body: some Scene {
    WindowGroup("Rivet") {
      GitHubConnectionView(
        clientID: $connection.clientID, clientSecret: $connection.clientSecret,
        input: connection.presentation, signIn: connection.signIn, cancel: connection.cancel,
        retry: connection.retry, query: connection.query)
    }
    .defaultSize(width: 660, height: 410)
    .windowResizability(.contentMinSize)
  }
}
