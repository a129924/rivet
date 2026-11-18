import CryptoKit
import Foundation
import GitHubIntegration
import RivetHTTPClient

private enum ProbeError: Error { case control, forbidden, selfTest }

private struct Control: Codable {
  let runID: String
  let group: String
  let service: String
  let keyBase64: String
  let bundleID: String
}

private struct Stats: Codable, Sendable {
  var configurationLoads = 0
  var credentialLoads = 0
  var refreshAttempts = 0
  var refreshAccepted = 0
  var saveAttempts = 0
  var saves = 0
}

private struct Receipt: Codable {
  var schema = "e018.machine.v1"
  var phase: String
  var outcome = "incomplete"
  var failureKind = "none"
  var phasePassed = false
  var prepare = Stats()
  var final = Stats()
  var initiallyExpired = false
  var initialCredentialTag = ""
  var finalCredentialTag = ""
  var accountTag = ""
  var apiAuthenticated = false
  var completeReadback = false
  var configurationUnchanged = false
  var naturalRefreshObserved = false
  var promptCount: Int?
}

private struct Observation: Sendable {
  var stats = Stats()
  var configuration: GitHubOAuthAppConfiguration?
  var oracle: GitHubOAuthCredentialBundle?
  var initialTag = ""
  var initiallyExpired = false
}

private func tag(_ fields: [String], key: SymmetricKey) -> String {
  var payload = Data()
  for field in fields {
    payload.append(contentsOf: String(field.utf8.count).utf8)
    payload.append(0)
    payload.append(contentsOf: field.utf8)
  }
  return HMAC<SHA256>.authenticationCode(for: payload, using: key)
    .map { String(format: "%02x", $0) }.joined()
}

private func credentialTag(_ credential: GitHubOAuthCredentialBundle, key: SymmetricKey) -> String {
  tag(
    [
      credential.accessToken.rawValue, credential.refreshToken.rawValue,
      String(
        format: "%.0f", (credential.accessTokenExpiresAt.timeIntervalSince1970 * 1000).rounded()),
      String(
        format: "%.0f", (credential.refreshTokenExpiresAt.timeIntervalSince1970 * 1000).rounded()),
      credential.tokenType.rawValue, credential.grantedScopes,
    ], key: key)
}

private actor Observer {
  let key: SymmetricKey
  private var value = Observation()
  init(key: SymmetricKey) { self.key = key }
  func configurationLoaded(_ configuration: GitHubOAuthAppConfiguration?) {
    value.stats.configurationLoads += 1
    value.configuration = configuration
  }
  func loaded(_ credential: GitHubOAuthCredentialBundle?) {
    value.stats.credentialLoads += 1
    guard let credential else { return }
    if value.initialTag.isEmpty {
      value.initialTag = credentialTag(credential, key: key)
      value.initiallyExpired = credential.accessTokenExpiresAt <= Date()
    }
    value.oracle = credential
  }
  func saving() { value.stats.saveAttempts += 1 }
  func saved(_ credential: GitHubOAuthCredentialBundle) {
    value.stats.saves += 1
    value.oracle = credential
  }
  func refreshing() { value.stats.refreshAttempts += 1 }
  func accepted() { value.stats.refreshAccepted += 1 }
  func snapshot() -> Observation { value }
}

private struct ObservedConfiguration: GitHubOAuthAppConfigurationStore {
  let base: any GitHubOAuthAppConfigurationStore
  let observer: Observer
  func load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration? {
    let configuration = try await base.load()
    await observer.configurationLoaded(configuration)
    return configuration
  }
  func save(_ configuration: GitHubOAuthAppConfiguration) async throws(any Error & Sendable) {
    throw ProbeError.forbidden
  }
}

private struct ObservedStore: OAuthCredentialStore {
  let base: any OAuthCredentialStore
  let observer: Observer
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    let credential = try await base.load()
    await observer.loaded(credential)
    return credential
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    await observer.saving()
    try await base.save(credential)
    await observer.saved(credential)
  }
}

private struct ObservedFetcher: OAuthTokenFetcher {
  let base: any OAuthTokenFetcher
  let observer: Observer
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    await observer.refreshing()
    let refreshed = try await base.refresh(credential)
    await observer.accepted()
    return refreshed
  }
}

private func failureKind(_ outcome: GitHubOAuthStartupRestoreOutcome) -> String {
  switch outcome {
  case .ready: "none"
  case .notConfigured: "notConfigured"
  case .notSignedIn: "notSignedIn"
  case .authenticationRequired: "authenticationRequired"
  case .cancelled: "cancelled"
  case .busy: "busy"
  case .failed(let failure): startupFailureKind(failure)
  }
}

private func startupFailureKind(_ failure: GitHubOAuthStartupRestoreFailure) -> String {
  switch failure {
  case .configurationStore: "configurationStore"
  case .configurationLoad: "configurationLoad"
  case .fetcherCreation: "fetcherCreation"
  case .preparationFailed: "preparationFailed"
  case .preparation(let error): preparationFailureKind(error)
  }
}

private func preparationFailureKind(_ error: GitHubClientPreparationError) -> String {
  switch error {
  case .missingCredential: "notSignedIn"
  case .authenticationRequired: "authenticationRequired"
  case .invalidAuthorizationToken: "invalidAuthorizationToken"
  case .credentialLifecycle(stage: .restore): "restore"
  case .credentialLifecycle(stage: .refresh): "refresh"
  case .credentialLifecycle(stage: .persist): "persist"
  }
}

private struct Account: Decodable {
  let id: Int64
  let login: String
}

private func validAccount(_ response: RivetHTTPClient.HTTPResponse) -> Account? {
  guard response.statusCode == 200,
    let account = try? JSONDecoder().decode(Account.self, from: response.body),
    account.id > 0, !account.login.isEmpty
  else { return nil }
  return account
}

private func perform(_ control: Control, phase: String) async -> Receipt {
  var receipt = Receipt(phase: phase)
  guard let keyData = Data(base64Encoded: control.keyBase64), keyData.count == 32 else {
    receipt.failureKind = "control"
    return receipt
  }
  let key = SymmetricKey(data: keyData)
  let observer = Observer(key: key)
  do {
    let stores = try GitHubOAuthDataProtectionStores(
      accessGroup: control.group, service: control.service)
    let owner = GitHubOAuthStartupRestorer(
      configurationStore: ObservedConfiguration(
        base: stores.configurationStore, observer: observer),
      makeCredentialStore: { clientID in
        ObservedStore(base: stores.credentialStore(clientID: clientID), observer: observer)
      },
      makeTokenFetcher: { configuration in
        ObservedFetcher(
          base: try GitHubOAuth.makeTokenFetcher(configuration: configuration), observer: observer)
      })
    let outcome = await owner.restore()
    let prepared = await observer.snapshot()
    receipt.prepare = prepared.stats
    receipt.initialCredentialTag = prepared.initialTag
    receipt.initiallyExpired = prepared.initiallyExpired
    receipt.failureKind = failureKind(outcome)
    guard case .ready(let scope) = outcome else {
      receipt.final = prepared.stats
      return receipt
    }
    receipt.outcome = "ready"
    do {
      let request = HTTPRequest(
        url: try HTTPURL(URL(string: "https://api.github.com/user")!), method: .get,
        headers: [.accept: "application/vnd.github+json"])
      let response = try await scope.rest.executeGet(request)
      if let account = validAccount(response) {
        receipt.apiAuthenticated = true
        receipt.accountTag = tag([String(account.id)], key: key)
      }
    } catch {
      receipt.failureKind = "api"
    }
    // Freeze the oracle before witness reads; witness reads must not update the observer.
    let final = await observer.snapshot()
    receipt.final = final.stats
    if let oracle = final.oracle, let configuration = final.configuration {
      let expected = credentialTag(oracle, key: key)
      let readback = try await stores.credentialStore(clientID: configuration.clientID).load()
      if let readback {
        receipt.finalCredentialTag = credentialTag(readback, key: key)
        receipt.completeReadback = receipt.finalCredentialTag == expected
      }
      let configurationReadback = try await stores.configurationStore.load()
      receipt.configurationUnchanged =
        configurationReadback?.clientID == configuration.clientID
        && configurationReadback?.clientSecret == configuration.clientSecret
    }
    receipt.naturalRefreshObserved =
      prepared.initiallyExpired
      && prepared.stats.refreshAccepted > 0 && prepared.stats.saves > 0
    receipt.phasePassed =
      receipt.apiAuthenticated && receipt.completeReadback
      && receipt.configurationUnchanged && prepared.stats.configurationLoads == 1
    if !receipt.phasePassed, receipt.failureKind == "none" { receipt.failureKind = "verification" }
  } catch {
    receipt.failureKind = "readbackOrStore"
  }
  return receipt
}

private func writeExclusive<Value: Encodable>(_ value: Value, to url: URL) throws {
  let data = try JSONEncoder().encode(value)
  let descriptor = open(url.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, S_IRUSR | S_IWUSR)
  guard descriptor >= 0 else { throw ProbeError.control }
  defer { close(descriptor) }
  let written = data.withUnsafeBytes { raw in write(descriptor, raw.baseAddress, raw.count) }
  guard written == data.count else { throw ProbeError.control }
  guard fsync(descriptor) == 0 else { throw ProbeError.control }
}

private func run() async {
  if CommandLine.arguments == [CommandLine.arguments[0], "--self-test"] {
    do {
      try await selfTest()
      print("{\"selfTestPassed\":true,\"liveOperations\":0}")
    } catch {
      print("{\"selfTestPassed\":false,\"liveOperations\":0}")
      exit(1)
    }
    return
  }
  guard CommandLine.arguments.count == 5, CommandLine.arguments[1] == "--run-root",
    CommandLine.arguments[3] == "--phase", ["first", "fresh"].contains(CommandLine.arguments[4])
  else {
    print("{\"hostStarted\":false,\"failureKind\":\"arguments\"}")
    return
  }
  let root = URL(fileURLWithPath: CommandLine.arguments[2]).resolvingSymlinksInPath()
  let phase = CommandLine.arguments[4]
  do {
    let control = try JSONDecoder().decode(
      Control.self, from: Data(contentsOf: root.appendingPathComponent("control.json")))
    guard control.service == "local.rivet.github-connection-verification.oauth.v1",
      !control.group.contains("*"), Bundle.main.bundleIdentifier == control.bundleID
    else { throw ProbeError.control }
    let executable = Bundle.main.executableURL!.resolvingSymlinksInPath().path
    try writeExclusive(
      ["runID": control.runID, "phase": phase, "pid": String(getpid()), "executable": executable],
      to: root.appendingPathComponent(phase + ".hello.json"))
    let authorization = root.appendingPathComponent(phase + ".authorize.json")
    let deadline = ContinuousClock.now.advanced(by: .seconds(30))
    while !FileManager.default.fileExists(atPath: authorization.path) {
      guard ContinuousClock.now < deadline else { throw ProbeError.control }
      try await Task.sleep(for: .milliseconds(100))
    }
    let admission = try JSONDecoder().decode(
      [String: String].self, from: Data(contentsOf: authorization))
    guard admission == ["runID": control.runID, "phase": phase] else { throw ProbeError.control }
    let receipt = await perform(control, phase: phase)
    try writeExclusive(receipt, to: root.appendingPathComponent(phase + ".machine.json"))
  } catch {
    // Fixed diagnostic only; never emit underlying errors, configuration or tokens.
    print("{\"hostStarted\":true,\"failureKind\":\"control\"}")
  }
}

private actor FakeConfiguration: GitHubOAuthAppConfigurationStore {
  let value: GitHubOAuthAppConfiguration
  init() throws { value = try .init(clientID: "offline-client", clientSecret: "offline-secret") }
  func load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration? { value }
  func save(_ configuration: GitHubOAuthAppConfiguration) async throws(any Error & Sendable) {
    throw ProbeError.forbidden
  }
}

private actor FakeStore: OAuthCredentialStore {
  var value: GitHubOAuthCredentialBundle?
  init(expired: Bool) { value = fakeCredential(expired: expired) }
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? { value }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    value = credential
  }
}

private struct FakeFetcher: OAuthTokenFetcher {
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    fakeCredential(expired: false)
  }
}

private func fakeCredential(expired: Bool) -> GitHubOAuthCredentialBundle {
  .init(
    accessToken: .init(rawValue: expired ? "offline-old" : "offline-new"),
    refreshToken: .init(rawValue: "offline-refresh"),
    accessTokenExpiresAt: expired ? .distantPast : .distantFuture,
    refreshTokenExpiresAt: .distantFuture, tokenType: .bearer, grantedScopes: "offline")
}

private func selfTest() async throws {
  for expired in [false, true] {
    let key = SymmetricKey(data: Data(repeating: 1, count: 32))
    let observer = Observer(key: key)
    let store = FakeStore(expired: expired)
    let owner = GitHubOAuthStartupRestorer(
      configurationStore: ObservedConfiguration(base: try FakeConfiguration(), observer: observer),
      makeCredentialStore: { _ in ObservedStore(base: store, observer: observer) },
      makeTokenFetcher: { _ in ObservedFetcher(base: FakeFetcher(), observer: observer) })
    guard case .ready = await owner.restore() else { throw ProbeError.selfTest }
    let beforeWitness = await observer.snapshot()
    guard let oracle = beforeWitness.oracle, let readback = try await store.load(),
      credentialTag(oracle, key: key) == credentialTag(readback, key: key),
      beforeWitness.stats.refreshAccepted == (expired ? 1 : 0),
      beforeWitness.stats.saves == (expired ? 1 : 0)
    else { throw ProbeError.selfTest }
  }
}

Task {
  await run()
  exit(0)
}
dispatchMain()
