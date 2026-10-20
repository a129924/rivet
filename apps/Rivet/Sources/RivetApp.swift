import AppKit
import CryptoKit
import Darwin
import Foundation
import GitHubIntegration
import RivetPresentation
import SwiftUI
import Synchronization

@main struct RivetApp: App {
  @State private var coordinator: GitHubConnectionCoordinator
  private let isTesting: Bool

  init() {
    let environment = ProcessInfo.processInfo.environment
    isTesting = environment["RIVET_UNIT_TEST_MODE"] == "1"
    _coordinator = State(initialValue: RivetComposition.makeCoordinator(environment: environment))
  }

  var body: some Scene {
    WindowGroup("Rivet") {
      if isTesting {
        Text("Rivet unit tests")
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

@MainActor enum RivetDependencyAudit {
  static var liveConstructionCount = 0
  static var credentialOperationCount = 0
  static var networkOperationCount = 0
}

@MainActor enum RivetComposition {
  static func makeCoordinator(environment: [String: String]) -> GitHubConnectionCoordinator {
    // This guard precedes even construction of DPK, authorization, listeners and restore tasks.
    if environment["RIVET_UNIT_TEST_MODE"] == "1" {
      return GitHubConnectionCoordinator(dependencies: unavailableDependencies())
    }
    RivetDependencyAudit.liveConstructionCount += 1
    guard
      let group = Bundle.main.object(forInfoDictionaryKey: "RivetKeychainAccessGroup") as? String,
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
      accessGroup: group, service: "local.rivet.github.oauth.v1")
    let dependencies = GitHubConnectionDependencies(
      loadConfiguration: {
        RivetDependencyAudit.credentialOperationCount += 1
        return try await stores.configurationStore.load()
      },
      inspectCredential: {
        RivetDependencyAudit.credentialOperationCount += 1
        return try await stores.inspectCredential().map {
          SavedGitHubCredential(clientID: $0.clientID, bundle: $0.bundle)
        }
      },
      saveConfiguration: {
        RivetDependencyAudit.credentialOperationCount += 1
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
        RivetDependencyAudit.networkOperationCount += 1
        let scope = try await GitHubClientScope.prepare(provider: provider)
        return GitHubReadyConnection {
          RivetDependencyAudit.networkOperationCount += 1
          return try await GitHubAccountProbe.load(using: scope.rest)
        }
      },
      makeAuthorization: { configuration in
        RivetDependencyAudit.networkOperationCount += 1
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

/// Private, explicit acceptance mode. It never changes token receipt dates or stored credentials.
final class GitHubExpiryValidation: Sendable {
  enum Mode: String, Encodable, Sendable {
    case expireRestoredOnce = "expire-restored-once"
    case observe
  }
  struct Snapshot: Encodable, Sendable {
    let schemaVersion = 1
    let processID = ProcessInfo.processInfo.processIdentifier
    let observationID = UUID()
    let mode: Mode
    var forcedExpiryApplied = false
    var clockReturnedToRealTime = false
    var refreshAttempts = 0
    var acceptedRefreshes = 0
    var successfulSaves = 0
    var restoredCredentialDigest: String?
    var providerLoadedCredentialDigest: String?
    var acceptedCredentialDigest: String?
    var persistedCredentialDigest: String?
    var tokenPairChanged: Bool?
    var accountConfirmed = false
  }
  private struct State {
    var observation: Snapshot
    var expiry: Date?
    var armedOnce = false
    var originalPairDigest: String?
  }
  private let state: Mutex<State>
  private let receiptURL: URL?

  init(mode: Mode, receiptURL: URL? = nil) {
    state = Mutex(State(observation: Snapshot(mode: mode)))
    self.receiptURL = receiptURL
  }

  static func from(environment: [String: String]) throws -> GitHubExpiryValidation? {
    if environment["RIVET_UNIT_TEST_MODE"] == "1" { return nil }
    guard let value = environment["RIVET_GITHUB_VALIDATION_MODE"] else { return nil }
    guard let mode = Mode(rawValue: value),
      let path = environment["RIVET_GITHUB_VALIDATION_RECEIPT"], path.hasPrefix("/")
    else { throw GitHubConnectionFailure.hostConfiguration }
    let url = URL(fileURLWithPath: path)
    let attributes = try FileManager.default.attributesOfItem(
      atPath: url.deletingLastPathComponent().path)
    guard attributes[.type] as? FileAttributeType == .typeDirectory,
      (attributes[.ownerAccountID] as? NSNumber)?.uint32Value == getuid(),
      let permissions = attributes[.posixPermissions] as? NSNumber,
      permissions.intValue & 0o077 == 0,
      !FileManager.default.fileExists(atPath: url.path)
    else { throw GitHubConnectionFailure.hostConfiguration }
    return GitHubExpiryValidation(mode: mode, receiptURL: url)
  }

  func restored(_ credential: GitHubOAuthCredentialBundle) {
    state.withLock {
      $0.observation.restoredCredentialDigest = Self.digest(credential)
      $0.originalPairDigest = Self.pairDigest(credential)
    }
  }

  func arm(_ credential: GitHubOAuthCredentialBundle) {
    state.withLock {
      guard $0.observation.mode == .expireRestoredOnce, !$0.armedOnce else { return }
      $0.armedOnce = true
      $0.expiry = credential.accessTokenExpiresAt
      $0.observation.forcedExpiryApplied = credential.accessTokenExpiresAt > Date()
    }
  }

  func now() -> Date { state.withLock { max(Date(), $0.expiry ?? .distantPast) } }
  func snapshot() -> Snapshot { state.withLock { $0.observation } }

  func providerLoaded(_ credential: GitHubOAuthCredentialBundle) {
    state.withLock { $0.observation.providerLoadedCredentialDigest = Self.digest(credential) }
  }
  func refreshBegan() { state.withLock { $0.observation.refreshAttempts += 1 } }
  func refreshAccepted(_ credential: GitHubOAuthCredentialBundle) {
    state.withLock {
      $0.observation.acceptedRefreshes += 1
      $0.observation.acceptedCredentialDigest = Self.digest(credential)
      if let original = $0.originalPairDigest {
        $0.observation.tokenPairChanged = original != Self.pairDigest(credential)
      }
    }
  }
  func persisted(_ credential: GitHubOAuthCredentialBundle) {
    state.withLock {
      $0.observation.successfulSaves += 1
      let digest = Self.digest(credential)
      $0.observation.persistedCredentialDigest = digest
      if $0.expiry != nil, let digest, digest == $0.observation.acceptedCredentialDigest {
        // This occurs after the actual store save, before the provider checks the rotated expiry.
        $0.expiry = nil
        $0.observation.clockReturnedToRealTime = true
      }
    }
  }
  func endAttempt() {
    state.withLock {
      if $0.expiry != nil { $0.observation.clockReturnedToRealTime = true }
      $0.expiry = nil
      $0.armedOnce = true
    }
  }

  func exportReceipt(accountConfirmed: Bool? = nil) {
    guard let receiptURL else { return }
    let observation = state.withLock {
      if let accountConfirmed { $0.observation.accountConfirmed = accountConfirmed }
      return $0.observation
    }
    guard let data = try? JSONEncoder().encode(observation) else { return }
    // One exclusive, private receipt per process/run; an earlier receipt is never overwritten.
    let descriptor = open(receiptURL.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
    guard descriptor >= 0 else { return }
    let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    try? handle.write(contentsOf: data)
    try? handle.synchronize()
    try? handle.close()
  }

  private static func digest(_ credential: GitHubOAuthCredentialBundle) -> String? {
    let access = credential.accessTokenExpiresAt.timeIntervalSince1970 * 1000
    let refresh = credential.refreshTokenExpiresAt.timeIntervalSince1970 * 1000
    guard access.isFinite, refresh.isFinite else { return nil }
    return hash([
      "accessToken": credential.accessToken.rawValue,
      "refreshToken": credential.refreshToken.rawValue,
      "accessTokenExpiresAt": String(access), "refreshTokenExpiresAt": String(refresh),
      "tokenType": credential.tokenType.rawValue, "grantedScopes": credential.grantedScopes,
    ])
  }
  private static func pairDigest(_ credential: GitHubOAuthCredentialBundle) -> String? {
    hash(["access": credential.accessToken.rawValue, "refresh": credential.refreshToken.rawValue])
  }
  private static func hash(_ fields: [String: String]) -> String? {
    guard let data = try? JSONSerialization.data(withJSONObject: fields, options: .sortedKeys)
    else { return nil }
    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }
}

struct ValidationCredentialStore: OAuthCredentialStore {
  let base: any OAuthCredentialStore
  let validation: GitHubExpiryValidation
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    let credential = try await base.load()
    if let credential { validation.providerLoaded(credential) }
    return credential
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    try await base.save(credential)
    validation.persisted(credential)
  }
}

struct ValidationTokenFetcher: OAuthTokenFetcher {
  let base: any OAuthTokenFetcher
  let validation: GitHubExpiryValidation
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    validation.refreshBegan()
    // The unchanged production fetcher uses Date.init for the real response receipt.
    let result = try await base.refresh(credential)
    validation.refreshAccepted(result)
    return result
  }
}
