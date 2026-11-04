import Foundation
import GitHubIntegration
import RivetHTTPClient
import XCTest

@testable import GitHubConnectionVerification

@MainActor final class GitHubConnectionCoordinatorTests: XCTestCase {
  func testTestModeDoesNotConstructLiveDependencies() {
    XCTAssertEqual(
      ProcessInfo.processInfo.environment["GITHUB_CONNECTION_VERIFICATION_UNIT_TEST_MODE"], "1")
    _ = GitHubConnectionVerificationComposition.makeCoordinator(environment: [
      "GITHUB_CONNECTION_VERIFICATION_UNIT_TEST_MODE": "1"
    ])
    XCTAssertEqual(VerificationDependencyAudit.liveConstructionCount, 0)
    XCTAssertEqual(VerificationDependencyAudit.credentialOperationCount, 0)
    XCTAssertEqual(VerificationDependencyAudit.networkOperationCount, 0)
  }

  func testFirstConnectionSavesConfigurationAndBundleBeforePreparing() async throws {
    let harness = ConnectionHarness()
    let coordinator = harness.coordinator()
    await coordinator.start()
    XCTAssertEqual(coordinator.phase, .configuration)
    await coordinator.connect(clientID: "fake-id", secret: "fake-secret", confirmsRecovery: false)
    XCTAssertEqual(harness.configurationSaves, 1)
    XCTAssertEqual(harness.authorizationCount, 1)
    let actualCount1 = await harness.store.saveCount()
    XCTAssertEqual(actualCount1, 1)
    XCTAssertEqual(harness.providers.count, 1)
    XCTAssertEqual(coordinator.account?.login, "fake-user")
    XCTAssertEqual(harness.events.prefix(2), ["configuration-save", "authorize"])
    let saved = try await harness.store.load()
    XCTAssertEqual(saved?.accessToken.rawValue, "fake-grant-access")
  }

  func testFreshCoordinatorRestoresWithoutOpeningAuthorization() async {
    let harness = ConnectionHarness(configuration: true, credential: true)
    let first = harness.coordinator()
    await first.start()
    XCTAssertEqual(first.account?.login, "fake-user")
    let fresh = harness.coordinator()
    await fresh.start()
    XCTAssertEqual(fresh.account?.login, "fake-user")
    XCTAssertEqual(harness.authorizationCount, 0)
    XCTAssertEqual(harness.providers.count, 2)
  }

  func testRepairTablePrefersOnlyFullyTrustedCredentialID() async {
    for configState in ["missing", "corrupt", "mismatch"] {
      let harness = ConnectionHarness(configuration: configState == "mismatch", credential: true)
      if configState == "corrupt" { harness.configurationError = .corrupt }
      if configState == "mismatch" {
        harness.configuration = try? GitHubOAuthAppConfiguration(
          clientID: "other-id", clientSecret: "fake-secret")
      }
      let coordinator = harness.coordinator()
      await coordinator.start()
      XCTAssertEqual(coordinator.trustedClientID, "fake-id")
      XCTAssertTrue(coordinator.presentation.locksClientID)
      XCTAssertTrue(coordinator.presentation.showsConfiguration)
      XCTAssertEqual(harness.providers.count, 0)
      await coordinator.connect(clientID: "other-id", secret: "fake-secret", confirmsRecovery: true)
      XCTAssertEqual(coordinator.failure, .identityMismatch)
      XCTAssertEqual(harness.configurationSaves, 0)
      harness.configurationError = nil
      await coordinator.connect(clientID: "fake-id", secret: "fake-secret", confirmsRecovery: false)
      XCTAssertEqual(coordinator.account?.login, "fake-user")
    }
  }

  func testValidConfigurationWithMissingOrCorruptCredentialKeepsItsIdentity() async {
    for corrupt in [false, true] {
      let harness = ConnectionHarness(configuration: true)
      if corrupt { harness.credentialError = .corrupt }
      let coordinator = harness.coordinator()
      await coordinator.start()
      XCTAssertEqual(coordinator.trustedClientID, "fake-id")
      XCTAssertEqual(coordinator.phase, .authorization)
      XCTAssertEqual(harness.providers.count, 0)
      harness.credentialError = nil
      await coordinator.reauthorize()
      XCTAssertEqual(coordinator.account?.login, "fake-user")
    }
  }

  func testCorruptWithoutTrustedIDRequiresExplicitOriginalAppConfirmation() async {
    let harness = ConnectionHarness()
    harness.configurationError = .corrupt
    harness.credentialError = .corrupt
    let coordinator = harness.coordinator()
    await coordinator.start()
    XCTAssertNil(coordinator.trustedClientID)
    XCTAssertTrue(coordinator.needsRecoveryConfirmation)
    await coordinator.connect(clientID: "fake-id", secret: "fake-secret", confirmsRecovery: false)
    XCTAssertEqual(coordinator.failure, .recoveryConfirmationRequired)
    XCTAssertEqual(harness.configurationSaves, 0)
    harness.configurationError = nil
    harness.credentialError = nil
    await coordinator.connect(clientID: "fake-id", secret: "fake-secret", confirmsRecovery: true)
    XCTAssertEqual(coordinator.account?.login, "fake-user")
  }

  func testDeniedAndUnavailableNeverOverwriteAndRequireExplicitRetry() async {
    for error in [GitHubOAuthStoreError.denied, .unavailable] {
      for configurationItem in [false, true] {
        let harness = ConnectionHarness(configuration: true, credential: true)
        if configurationItem {
          harness.configurationError = error
        } else {
          harness.credentialError = error
        }
        let coordinator = harness.coordinator()
        await coordinator.start()
        XCTAssertEqual(coordinator.failure, error == .denied ? .storageDenied : .storageUnavailable)
        await coordinator.connect(
          clientID: "fake-id", secret: "fake-secret", confirmsRecovery: true)
        await coordinator.reauthorize()
        XCTAssertEqual(harness.configurationSaves, 0)
        XCTAssertEqual(harness.authorizationCount, 0)
        let actualCount2 = await harness.store.saveCount()
        XCTAssertEqual(actualCount2, 0)
        harness.configurationError = nil
        harness.credentialError = nil
        await coordinator.retry()
        XCTAssertEqual(coordinator.account?.login, "fake-user")
      }
    }
  }

  func testConfigurationSaveFailureNeverStartsBrowser() async {
    let harness = ConnectionHarness()
    harness.configurationSaveError = .unavailable
    let coordinator = harness.coordinator()
    await coordinator.start()
    await coordinator.connect(clientID: "fake-id", secret: "fake-secret", confirmsRecovery: false)
    XCTAssertEqual(coordinator.failure, .storageUnavailable)
    XCTAssertEqual(harness.authorizationCount, 0)
    XCTAssertEqual(harness.providers.count, 0)
  }

  func testTemporaryPrepareRetryUsesExactlyTheSameProvider() async {
    let harness = ConnectionHarness(configuration: true, credential: true)
    harness.prepareFailures = 1
    let coordinator = harness.coordinator()
    await coordinator.start()
    XCTAssertEqual(coordinator.failure, .prepare)
    await coordinator.retry()
    XCTAssertEqual(coordinator.account?.login, "fake-user")
    XCTAssertEqual(harness.providers.count, 2)
    XCTAssertTrue(harness.providers[0] === harness.providers[1])
    XCTAssertEqual(harness.fetcherConstructions, 1)
  }

  func testStoppedAndAuthenticationRequiredProvidersCannotBeRebuiltByRetry() async {
    for failure in [OAuthTokenRefreshError.rotationIndeterminate, .credentialRejected] {
      let harness = ConnectionHarness(configuration: true, credential: true, expired: true)
      await harness.fetcher.setFailure(failure)
      let coordinator = harness.coordinator()
      await coordinator.start()
      if case .credentialRejected = failure {
        XCTAssertEqual(coordinator.failure, .authenticationRequired)
      } else {
        XCTAssertEqual(coordinator.failure, .stopped)
      }
      await coordinator.retry()
      XCTAssertEqual(harness.fetcherConstructions, 1)
      XCTAssertEqual(harness.providers.count, 1)
      let actualCount3 = await harness.fetcher.count()
      XCTAssertEqual(actualCount3, 1)
    }
  }

  func testEveryFailedReauthorizationRetiresProviderAndClearsAccount() async {
    for failure in [GitHubOAuthError.cancelled, .denied, .invalidCallback, .transport] {
      let harness = ConnectionHarness(configuration: true, credential: true)
      let coordinator = harness.coordinator()
      await coordinator.start()
      XCTAssertNotNil(coordinator.account)
      harness.authorizationFailure = failure
      await coordinator.reauthorize()
      XCTAssertNil(coordinator.account)
      XCTAssertEqual(harness.providers.count, 1)
      await coordinator.retry()
      XCTAssertEqual(coordinator.phase, .authorization)
      XCTAssertEqual(harness.providers.count, 1)
      harness.authorizationFailure = nil
      await coordinator.reauthorize()
      XCTAssertEqual(harness.providers.count, 2)
      XCTAssertFalse(harness.providers[0] === harness.providers[1])
      XCTAssertNotNil(coordinator.account)
    }
  }

  func testSameAppRepairFailureAlsoRetiresOldProvider() async {
    let harness = ConnectionHarness(configuration: true, credential: true)
    let coordinator = harness.coordinator()
    await coordinator.start()
    harness.configurationSaveError = .corrupt
    await coordinator.connect(
      clientID: "fake-id", secret: "changed-fake-secret", confirmsRecovery: false)
    XCTAssertEqual(coordinator.failure, .configurationSave)
    XCTAssertNil(coordinator.account)
    await coordinator.retry()
    XCTAssertEqual(coordinator.phase, .authorization)
    XCTAssertEqual(harness.providers.count, 1)
  }

  func testNewBundleSaveFailureNeverResurrectsOldProvider() async {
    let harness = ConnectionHarness(configuration: true, credential: true)
    let coordinator = harness.coordinator()
    await coordinator.start()
    await harness.store.setSaveFailure(true)
    await coordinator.reauthorize()
    XCTAssertEqual(coordinator.failure, .credentialSave)
    XCTAssertNil(coordinator.account)
    XCTAssertEqual(harness.fetcherConstructions, 1)
    await coordinator.retry()
    XCTAssertEqual(coordinator.phase, .authorization)
    XCTAssertEqual(harness.providers.count, 1)
  }

  func testCancelledCallerCannotAdmitNewWritesBeforeOldRotationSaveSettles() async throws {
    let gate = ConnectionLatch()
    let harness = ConnectionHarness(
      configuration: true, credential: true, expired: true, saveGate: gate)
    let coordinator = harness.coordinator()
    let caller = Task { await coordinator.start() }
    await gate.waitForArrival()
    caller.cancel()
    coordinator.cancelOperation()
    await coordinator.connect(
      clientID: "fake-id", secret: "new-fake-secret", confirmsRecovery: false)
    XCTAssertEqual(coordinator.failure, .operationInProgress)
    await coordinator.reauthorize()
    XCTAssertEqual(coordinator.failure, .operationInProgress)
    XCTAssertTrue(coordinator.isBusy)
    XCTAssertEqual(harness.configurationSaves, 0)
    XCTAssertEqual(harness.authorizationCount, 0)
    await gate.open()
    await caller.value
    XCTAssertFalse(coordinator.isBusy)
    let actualCount4 = await harness.store.saveCount()
    XCTAssertEqual(actualCount4, 1)
    await coordinator.connect(
      clientID: "fake-id", secret: "new-fake-secret", confirmsRecovery: false)
    XCTAssertEqual(coordinator.account?.login, "fake-user")
    let saved = try await harness.store.load()
    XCTAssertEqual(saved?.accessToken.rawValue, "fake-grant-access")
    let actualCount5 = await harness.store.saveCount()
    XCTAssertEqual(actualCount5, 2)
  }

  func testPendingRefreshAlsoBlocksReauthorizationUntilSettled() async {
    let gate = ConnectionLatch()
    let harness = ConnectionHarness(
      configuration: true, credential: true, expired: true, refreshGate: gate)
    let coordinator = harness.coordinator()
    let caller = Task { await coordinator.start() }
    await gate.waitForArrival()
    coordinator.cancelOperation()
    await coordinator.reauthorize()
    XCTAssertEqual(coordinator.failure, .operationInProgress)
    XCTAssertEqual(harness.authorizationCount, 0)
    XCTAssertEqual(harness.configurationSaves, 0)
    await gate.open()
    await caller.value
    await coordinator.reauthorize()
    XCTAssertEqual(harness.authorizationCount, 1)
    XCTAssertNotNil(coordinator.account)
  }

  func testWaitingCancellationRemainsTrackedAndExchangeDisablesCancel() async {
    let gate = ConnectionLatch()
    let harness = ConnectionHarness(configuration: true)
    harness.authorizationGate = gate
    let coordinator = harness.coordinator()
    await coordinator.start()
    let caller = Task { await coordinator.reauthorize() }
    await gate.waitForArrival()
    XCTAssertTrue(coordinator.presentation.canCancel)
    await coordinator.reauthorize()
    XCTAssertEqual(coordinator.failure, .operationInProgress)
    XCTAssertEqual(harness.authorizationCount, 1)
    await coordinator.cancelAuthorization()
    await caller.value
    XCTAssertEqual(coordinator.failure, .cancelled)
    XCTAssertFalse(coordinator.isBusy)
  }

  func testAcceptedCallbackClearsOldAccountAndDisablesCancellationUntilSaveSettles() async {
    let harness = ConnectionHarness(configuration: true, credential: true)
    let coordinator = harness.coordinator()
    await coordinator.start()
    XCTAssertNotNil(coordinator.account)
    let gate = ConnectionLatch()
    harness.exchangeGate = gate
    let caller = Task { await coordinator.reauthorize() }
    await gate.waitForArrival()
    XCTAssertEqual(coordinator.phase, .exchanging)
    XCTAssertNil(coordinator.account)
    XCTAssertFalse(coordinator.presentation.canCancel)
    await coordinator.cancelAuthorization()
    XCTAssertTrue(coordinator.isBusy)
    await gate.open()
    await caller.value
    XCTAssertNotNil(coordinator.account)
    XCTAssertEqual(harness.providers.count, 2)
    XCTAssertFalse(harness.providers[0] === harness.providers[1])
  }

  func testProbeFailureClearsAccountAndRetryKeepsProviderAndScope() async {
    let harness = ConnectionHarness(configuration: true, credential: true)
    harness.probeFailures = 1
    let coordinator = harness.coordinator()
    await coordinator.start()
    XCTAssertEqual(coordinator.failure, .probe)
    XCTAssertNil(coordinator.account)
    await coordinator.retry()
    XCTAssertNotNil(coordinator.account)
    XCTAssertEqual(harness.providers.count, 1)
  }

  func testProbeUsesExactReadOnlyRequestAndRejectsNonAccountResults() async throws {
    let client = AccountProbeClient()
    let account = try await GitHubAccountProbe.load(using: client)
    XCTAssertEqual(account.login, "fake-user")
    let recordedRequest = await client.lastRequest()
    let request = try XCTUnwrap(recordedRequest)
    XCTAssertEqual(request.method, .get)
    XCTAssertEqual(request.url, try HTTPURL(URL(string: "https://api.github.com/user")!))
    XCTAssertEqual(request.headers[.accept], "application/vnd.github+json")
    XCTAssertEqual(request.headers[.userAgent], "GitHubConnectionVerification")
    XCTAssertNil(request.body)
    for response in [
      HTTPResponse(statusCode: 403, headers: [:], body: Data("{}".utf8)),
      HTTPResponse(statusCode: 200, headers: [:], body: Data("{\"id\":0,\"login\":\"fake\"}".utf8)),
      HTTPResponse(statusCode: 200, headers: [:], body: Data("{\"id\":1,\"login\":\"\"}".utf8)),
    ] {
      await client.setResponse(response)
      do {
        _ = try await GitHubAccountProbe.load(using: client)
        XCTFail("Expected finite probe failure")
      } catch { XCTAssertTrue(error is GitHubAccountProbeError) }
    }
  }
}

extension GitHubConnectionCoordinatorTests {
  func testValidationIsExplicitOptInAndTestModeIgnoresIt() throws {
    XCTAssertNil(try GitHubExpiryValidation.from(environment: [:]))
    XCTAssertNil(
      try GitHubExpiryValidation.from(environment: [
        "GITHUB_CONNECTION_VERIFICATION_UNIT_TEST_MODE": "1",
        "GITHUB_CONNECTION_VERIFICATION_MODE": "expire-restored-once",
        "GITHUB_CONNECTION_VERIFICATION_RECEIPT": "/invalid-unused-receipt",
      ]))
    XCTAssertThrowsError(
      try GitHubExpiryValidation.from(environment: [
        "GITHUB_CONNECTION_VERIFICATION_MODE": "unknown"
      ]))
    XCTAssertEqual(VerificationDependencyAudit.liveConstructionCount, 0)
    XCTAssertEqual(VerificationDependencyAudit.credentialOperationCount, 0)
    XCTAssertEqual(VerificationDependencyAudit.networkOperationCount, 0)
  }

  func testControlledRestoreRefreshesOnceAndReturnsToRealTimeBeforePublish() async throws {
    let harness = ConnectionHarness(configuration: true, credential: true)
    await harness.fetcher.useRealReceiptTime()
    let control = GitHubExpiryValidation(mode: .expireRestoredOnce)
    harness.expiryValidation = control
    let coordinator = harness.coordinator()
    await coordinator.start()
    XCTAssertEqual(coordinator.account?.login, "fake-user")
    let calls = await harness.fetcher.count()
    XCTAssertEqual(calls, 1)
    let loaded = try await harness.store.load()
    let saved = try XCTUnwrap(loaded)
    XCTAssertLessThan(saved.accessTokenExpiresAt, Date.distantFuture)
    XCTAssertGreaterThan(saved.accessTokenExpiresAt, Date())
    XCTAssertLessThan(abs(control.now().timeIntervalSinceNow), 2)
    let observation = control.snapshot()
    XCTAssertEqual(observation.refreshAttempts, 1)
    XCTAssertEqual(observation.acceptedRefreshes, 1)
    XCTAssertEqual(observation.successfulSaves, 1)
    XCTAssertTrue(observation.forcedExpiryApplied)
    XCTAssertTrue(observation.clockReturnedToRealTime)
    XCTAssertEqual(observation.acceptedCredentialDigest, observation.persistedCredentialDigest)
    XCTAssertNotEqual(observation.restoredCredentialDigest, observation.persistedCredentialDigest)
    await coordinator.retry()
    let laterCalls = await harness.fetcher.count()
    XCTAssertEqual(laterCalls, 1)
  }

  func testControlledClockUsesCredentialStateRatherThanNumberOfNowCalls() {
    let control = GitHubExpiryValidation(mode: .expireRestoredOnce)
    let original = fakeBundle("unchanged")
    control.arm(original)
    for _ in 0..<12 { XCTAssertEqual(control.now(), original.accessTokenExpiresAt) }
    XCTAssertEqual(original.accessTokenExpiresAt, .distantFuture)
    control.endAttempt()
    XCTAssertLessThan(abs(control.now().timeIntervalSinceNow), 2)
    control.arm(original)
    XCTAssertLessThan(abs(control.now().timeIntervalSinceNow), 2)
  }

  func testAcceptedRefreshPersistenceFailureStopsWithoutControlledRefreshLoop() async {
    let harness = ConnectionHarness(configuration: true, credential: true)
    await harness.fetcher.useRealReceiptTime()
    await harness.store.setSaveFailure(true)
    let control = GitHubExpiryValidation(mode: .expireRestoredOnce)
    harness.expiryValidation = control
    let coordinator = harness.coordinator()
    await coordinator.start()
    XCTAssertEqual(coordinator.failure, .stopped)
    await coordinator.retry()
    let calls = await harness.fetcher.count()
    XCTAssertEqual(calls, 1)
    XCTAssertEqual(control.snapshot().acceptedRefreshes, 1)
    XCTAssertEqual(control.snapshot().successfulSaves, 0)
    await harness.store.setSaveFailure(false)
    await coordinator.reauthorize()
    XCTAssertNotNil(coordinator.account)
    XCTAssertLessThan(abs(control.now().timeIntervalSinceNow), 2)
  }

  func testNewObserveProcessLoadsPersistedRotationWithoutForcedExpiry() async {
    let harness = ConnectionHarness(configuration: true, credential: true)
    await harness.fetcher.useRealReceiptTime()
    let first = GitHubExpiryValidation(mode: .expireRestoredOnce)
    harness.expiryValidation = first
    await harness.coordinator().start()
    let next = GitHubExpiryValidation(mode: .observe)
    harness.expiryValidation = next
    let restored = harness.coordinator()
    await restored.start()
    XCTAssertNotNil(restored.account)
    XCTAssertEqual(
      next.snapshot().restoredCredentialDigest, first.snapshot().persistedCredentialDigest)
    XCTAssertEqual(
      next.snapshot().providerLoadedCredentialDigest, first.snapshot().persistedCredentialDigest)
    XCTAssertEqual(next.snapshot().refreshAttempts, 0)
    XCTAssertFalse(next.snapshot().forcedExpiryApplied)
    // Two fake coordinators are still in this same hosted test process.
    XCTAssertEqual(first.snapshot().processID, next.snapshot().processID)
    XCTAssertNotEqual(first.snapshot().observationID, next.snapshot().observationID)
  }

  func testFiniteValidationReceiptContainsOnlyHashesAndNeverOverwrites() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: directory, withIntermediateDirectories: false,
      attributes: [.posixPermissions: 0o700])
    defer { try? FileManager.default.removeItem(at: directory) }
    let receipt = directory.appendingPathComponent("receipt.json")
    let control = try XCTUnwrap(
      try GitHubExpiryValidation.from(environment: [
        "GITHUB_CONNECTION_VERIFICATION_MODE": "observe",
        "GITHUB_CONNECTION_VERIFICATION_RECEIPT": receipt.path,
      ]))
    let harness = ConnectionHarness(configuration: true, credential: true)
    harness.expiryValidation = control
    await harness.coordinator().start()
    let data = try Data(contentsOf: receipt)
    let output = try XCTUnwrap(String(data: data, encoding: .utf8))
    for raw in [
      "fake-initial", "fake-secret", "fake-id", "client_secret", "callback", receipt.path,
    ] {
      XCTAssertFalse(output.contains(raw))
    }
    let attributes = try FileManager.default.attributesOfItem(atPath: receipt.path)
    XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
    control.exportReceipt()
    XCTAssertEqual(try Data(contentsOf: receipt), data)
    XCTAssertThrowsError(
      try GitHubExpiryValidation.from(environment: [
        "GITHUB_CONNECTION_VERIFICATION_MODE": "observe",
        "GITHUB_CONNECTION_VERIFICATION_RECEIPT": receipt.path,
      ]))
  }
}

@MainActor private final class ConnectionHarness {
  var expiryValidation: GitHubExpiryValidation?
  var configuration: GitHubOAuthAppConfiguration?
  var configurationError: GitHubOAuthStoreError?
  var credentialError: GitHubOAuthStoreError?
  var configurationSaveError: GitHubOAuthStoreError?
  var credentialID = "fake-id"
  var authorizationFailure: GitHubOAuthError?
  var authorizationGate: ConnectionLatch?
  var exchangeGate: ConnectionLatch?
  var configurationSaves = 0
  var authorizationCount = 0
  var fetcherConstructions = 0
  var prepareFailures = 0
  var probeFailures = 0
  var providers: [OAuthTokenProvider] = []
  var events: [String] = []
  let store: ConnectionCredentialStore
  let fetcher: ConnectionFetcher

  init(
    configuration: Bool = false, credential: Bool = false, expired: Bool = false,
    saveGate: ConnectionLatch? = nil, refreshGate: ConnectionLatch? = nil
  ) {
    self.configuration =
      configuration
      ? try? GitHubOAuthAppConfiguration(clientID: "fake-id", clientSecret: "fake-secret") : nil
    store = ConnectionCredentialStore(
      bundle: credential ? fakeBundle("initial", expired: expired) : nil, gate: saveGate)
    fetcher = ConnectionFetcher(gate: refreshGate)
  }

  func coordinator() -> GitHubConnectionCoordinator {
    GitHubConnectionCoordinator(
      dependencies: GitHubConnectionDependencies(
        loadConfiguration: {
          if let error = self.configurationError { throw error }
          return self.configuration
        },
        inspectCredential: {
          if let error = self.credentialError { throw error }
          return try await self.store.load().map {
            SavedGitHubCredential(clientID: self.credentialID, bundle: $0)
          }
        },
        saveConfiguration: {
          self.configurationSaves += 1
          self.events.append("configuration-save")
          if let error = self.configurationSaveError { throw error }
          self.configuration = $0
        },
        credentialStore: { _ in
          guard let validation = self.expiryValidation else { return self.store }
          return ValidationCredentialStore(base: self.store, validation: validation)
        },
        makeFetcher: { _ in
          self.fetcherConstructions += 1
          guard let validation = self.expiryValidation else { return self.fetcher }
          return ValidationTokenFetcher(base: self.fetcher, validation: validation)
        },
        prepare: { provider in
          self.providers.append(provider)
          if self.prepareFailures > 0 {
            self.prepareFailures -= 1
            throw ConnectionTestFailure.failed
          }
          _ = try await provider.snapshot()
          try Task.checkCancellation()
          return GitHubReadyConnection {
            if self.probeFailures > 0 {
              self.probeFailures -= 1
              throw ConnectionTestFailure.failed
            }
            return GitHubAccount(id: 1, login: "fake-user")
          }
        },
        makeAuthorization: { _ in
          self.authorizationCount += 1
          self.events.append("authorize")
          return ConnectionAuthorizationFlow(
            failure: self.authorizationFailure, gate: self.authorizationGate,
            exchangeGate: self.exchangeGate)
        }), expiryValidation: expiryValidation)
  }
}

private enum ConnectionTestFailure: Error { case failed }
private func fakeBundle(_ label: String, expired: Bool = false) -> GitHubOAuthCredentialBundle {
  GitHubOAuthCredentialBundle(
    accessToken: .init(rawValue: "fake-\(label)-access"),
    refreshToken: .init(rawValue: "fake-\(label)-refresh"),
    accessTokenExpiresAt: expired ? .distantPast : .distantFuture,
    refreshTokenExpiresAt: .distantFuture, tokenType: .bearer, grantedScopes: "")
}

private actor ConnectionCredentialStore: OAuthCredentialStore {
  private var bundle: GitHubOAuthCredentialBundle?
  private var writes = 0
  private var failSave = false
  private let gate: ConnectionLatch?
  init(bundle: GitHubOAuthCredentialBundle?, gate: ConnectionLatch?) {
    self.bundle = bundle
    self.gate = gate
  }
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? { bundle }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    if let gate { await gate.arriveAndWait() }
    if failSave { throw ConnectionTestFailure.failed }
    writes += 1
    bundle = credential
  }
  func setSaveFailure(_ value: Bool) { failSave = value }
  func saveCount() -> Int { writes }
}

private actor ConnectionFetcher: OAuthTokenFetcher {
  private var failure: OAuthTokenRefreshError?
  private var realReceiptTime = false
  private var calls = 0
  private let gate: ConnectionLatch?
  init(gate: ConnectionLatch?) { self.gate = gate }
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    calls += 1
    if let gate { await gate.arriveAndWait() }
    if let failure { throw failure }
    if realReceiptTime {
      let receivedAt = Date()
      return GitHubOAuthCredentialBundle(
        accessToken: .init(rawValue: "fake-rotation-access"),
        refreshToken: .init(rawValue: "fake-rotation-refresh"),
        accessTokenExpiresAt: receivedAt.addingTimeInterval(60),
        refreshTokenExpiresAt: receivedAt.addingTimeInterval(600), tokenType: .bearer,
        grantedScopes: "")
    }
    return fakeBundle("rotation")
  }
  func useRealReceiptTime() { realReceiptTime = true }
  func setFailure(_ value: OAuthTokenRefreshError) { failure = value }
  func count() -> Int { calls }
}

@MainActor private final class ConnectionAuthorizationFlow: GitHubAuthorizationFlow {
  let failure: GitHubOAuthError?
  let gate: ConnectionLatch?
  let exchangeGate: ConnectionLatch?
  private var cancelled = false
  init(failure: GitHubOAuthError?, gate: ConnectionLatch?, exchangeGate: ConnectionLatch?) {
    self.failure = failure
    self.gate = gate
    self.exchangeGate = exchangeGate
  }
  func run(
    onExchange: @escaping @MainActor () -> Void
  ) async throws -> GitHubOAuthCredentialBundle {
    if let gate { await gate.arriveAndWait() }
    if cancelled { throw GitHubOAuthError.cancelled }
    onExchange()
    if let exchangeGate { await exchangeGate.arriveAndWait() }
    if let failure { throw failure }
    return fakeBundle("grant")
  }
  func cancel() async {
    cancelled = true
    await gate?.open()
  }
}

private actor ConnectionLatch {
  private var arrived = false
  private var opened = false
  private var arrival: CheckedContinuation<Void, Never>?
  private var release: CheckedContinuation<Void, Never>?
  func arriveAndWait() async {
    arrived = true
    arrival?.resume()
    arrival = nil
    if !opened { await withCheckedContinuation { release = $0 } }
  }
  func waitForArrival() async {
    if !arrived { await withCheckedContinuation { arrival = $0 } }
  }
  func open() {
    opened = true
    release?.resume()
    release = nil
  }
}

private actor AccountProbeClient: GitHubRestClient {
  private var request: HTTPRequest?
  private var response = HTTPResponse(
    statusCode: 200, headers: [:], body: Data("{\"id\":1,\"login\":\"fake-user\"}".utf8))
  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    self.request = request
    return response
  }
  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw ConnectionTestFailure.failed
  }
  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw ConnectionTestFailure.failed
  }
  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw ConnectionTestFailure.failed
  }
  func lastRequest() -> HTTPRequest? { request }
  func setResponse(_ value: HTTPResponse) { response = value }
}
