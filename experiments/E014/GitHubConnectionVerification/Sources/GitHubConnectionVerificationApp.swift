import AppKit
import Foundation
import GitHubIntegration
import SwiftUI

@main struct GitHubConnectionVerificationApp: App {
  @State private var coordinator: GitHubConnectionCoordinator
  private let isTesting: Bool

  init() {
    let environment = ProcessInfo.processInfo.environment
    isTesting = environment["GITHUB_CONNECTION_VERIFICATION_UNIT_TEST_MODE"] == "1"
    _coordinator = State(
      initialValue: GitHubConnectionVerificationComposition.makeCoordinator(
        environment: environment))
  }

  var body: some Scene {
    WindowGroup("GitHubConnectionVerification — GitHub 持續連線驗證") {
      if isTesting {
        Text("GitHubConnectionVerification unit tests")
      } else {
        GitHubConnectionView(
          presentation: coordinator.presentation,
          onConnect: { id, secret, confirmation in
            Task {
              await coordinator.connect(
                clientID: id, secret: secret, confirmsRecovery: confirmation)
            }
          }, onCancel: { Task { await coordinator.cancelAuthorization() } },
          onRetry: { Task { await coordinator.retry() } },
          onReauthorize: { Task { await coordinator.reauthorize() } }
        )
        .task { await coordinator.start() }
      }
    }
    .defaultSize(width: 520, height: 380)
  }
}

@MainActor enum VerificationDependencyAudit {
  static var liveConstructionCount = 0
  static var credentialOperationCount = 0
  static var networkOperationCount = 0
}

@MainActor enum GitHubConnectionVerificationComposition {
  static func makeCoordinator(environment: [String: String]) -> GitHubConnectionCoordinator {
    // This guard precedes even construction of DPK, authorization, listeners and restore tasks.
    if environment["GITHUB_CONNECTION_VERIFICATION_UNIT_TEST_MODE"] == "1" {
      return GitHubConnectionCoordinator(dependencies: unavailableDependencies())
    }
    VerificationDependencyAudit.liveConstructionCount += 1
    guard
      let group = Bundle.main.object(
        forInfoDictionaryKey: "GitHubConnectionVerificationKeychainAccessGroup") as? String,
      !group.isEmpty, !group.contains("$("),
      FileManager.default.fileExists(
        atPath: Bundle.main.bundleURL.appendingPathComponent("Contents/embedded.provisionprofile")
          .path)
    else { return GitHubConnectionCoordinator(dependencies: unavailableDependencies()) }
    let validation: GitHubExpiryValidation?
    do { validation = try GitHubExpiryValidation.from(environment: environment) } catch {
      return GitHubConnectionCoordinator(dependencies: unavailableDependencies())
    }
    let stores = GitHubOAuthDataProtectionStores(
      accessGroup: group, service: "local.rivet.github-connection-verification.oauth.v1")
    let dependencies = GitHubConnectionDependencies(
      loadConfiguration: {
        VerificationDependencyAudit.credentialOperationCount += 1
        return try await stores.configurationStore.load()
      },
      inspectCredential: {
        VerificationDependencyAudit.credentialOperationCount += 1
        return try await stores.inspectCredential().map {
          SavedGitHubCredential(clientID: $0.clientID, bundle: $0.bundle)
        }
      },
      saveConfiguration: {
        VerificationDependencyAudit.credentialOperationCount += 1
        try await stores.configurationStore.save($0)
      },
      credentialStore: {
        let store = stores.credentialStore(clientID: $0)
        guard let validation else { return store }
        return ValidationCredentialStore(base: store, validation: validation)
      },
      makeFetcher: {
        let fetcher = try GitHubOAuth.makeTokenFetcher(configuration: $0)
        guard let validation else { return fetcher }
        return ValidationTokenFetcher(base: fetcher, validation: validation)
      },
      prepare: { provider in
        VerificationDependencyAudit.networkOperationCount += 1
        let scope = try await GitHubClientScope.prepare(provider: provider)
        return GitHubReadyConnection {
          VerificationDependencyAudit.networkOperationCount += 1
          return try await GitHubAccountProbe.load(using: scope.rest)
        }
      },
      makeAuthorization: { configuration in
        VerificationDependencyAudit.networkOperationCount += 1
        // The only AppKit bridge opens the browser; no window or presentation state moves into AppKit.
        return LiveGitHubAuthorizationFlow(
          configuration: configuration, openBrowser: { NSWorkspace.shared.open($0) })
      })
    return GitHubConnectionCoordinator(dependencies: dependencies, expiryValidation: validation)
  }

  private static func unavailableDependencies() -> GitHubConnectionDependencies {
    GitHubConnectionDependencies(
      loadConfiguration: { throw GitHubConnectionFailure.hostConfiguration },
      inspectCredential: { throw GitHubConnectionFailure.hostConfiguration },
      saveConfiguration: { _ in throw GitHubConnectionFailure.hostConfiguration },
      credentialStore: { _ in UnavailableCredentialStore() },
      makeFetcher: { _ in throw GitHubConnectionFailure.hostConfiguration },
      prepare: { _ in throw GitHubConnectionFailure.hostConfiguration },
      makeAuthorization: { _ in UnavailableAuthorizationFlow() })
  }
}

private struct UnavailableCredentialStore: OAuthCredentialStore {
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    throw GitHubConnectionFailure.hostConfiguration
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    throw GitHubConnectionFailure.hostConfiguration
  }
}

@MainActor private final class UnavailableAuthorizationFlow: GitHubAuthorizationFlow {
  func run(
    onExchange: @escaping @MainActor () -> Void
  ) async throws -> GitHubOAuthCredentialBundle {
    throw GitHubConnectionFailure.hostConfiguration
  }
  func cancel() async {}
}
