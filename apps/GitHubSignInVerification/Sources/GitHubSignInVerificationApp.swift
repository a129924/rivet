import Foundation
import GitHubIntegration
import SwiftUI

@main
struct GitHubSignInVerificationApp: App {
  @State private var connection: GitHubConnectionCoordinator

  init() {
    _connection = State(
      initialValue: GitHubVerificationComposition.makeCoordinator(
        environment: ProcessInfo.processInfo.environment))
  }

  var body: some Scene {
    WindowGroup("GitHubSignInVerification — GitHub 登入驗證") {
      GitHubConnectionView(
        clientID: $connection.clientID, clientSecret: $connection.clientSecret,
        input: connection.presentation, signIn: connection.signIn,
        manualSignIn: connection.startManualSignIn,
        copyAuthorizationURL: connection.copyAuthorizationURL, cancel: connection.cancel,
        retry: connection.retry, query: connection.query)
    }
    .defaultSize(width: 660, height: 410)
    .windowResizability(.contentMinSize)
  }
}

@MainActor enum GitHubVerificationComposition {
  static func configuration(environment: [String: String]) throws -> GitHubOAuthAppConfiguration {
    guard let clientID = environment["RIVET_VERIFY_GITHUB_CLIENT_ID"],
      let secret = environment["RIVET_VERIFY_GITHUB_CLIENT_SECRET"]
    else { throw GitHubOAuthAuthorizationError.clientConfiguration }
    return try GitHubOAuthAppConfiguration(clientID: clientID, clientSecret: secret)
  }

  static func makeCoordinator(environment: [String: String]) -> GitHubConnectionCoordinator {
    // Test mode never loads App settings or constructs live dependencies.
    guard environment["GITHUB_SIGN_IN_VERIFICATION_UNIT_TEST_MODE"] != "1" else {
      return GitHubConnectionCoordinator(dependencies: .disabled, allowsManualConfiguration: false)
    }
    guard let configuration = try? configuration(environment: environment) else {
      return GitHubConnectionCoordinator(dependencies: .disabled, allowsManualConfiguration: false)
    }
    return GitHubConnectionCoordinator(
      dependencies: .live, configuration: configuration, allowsManualConfiguration: false)
  }
}
