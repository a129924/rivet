import CryptoKit
import Darwin
import Foundation
import GitHubIntegration
import Testing

// 所有案例及依賴組裝都位於 test bundle，host 只有 lifecycle。
struct OAuthStartupHostedTests {
  @Test func first() async throws { try await phase("first") }
  @Test func fresh() async throws { try await phase("fresh") }
}

func exclusive<Value: Encodable>(_ value: Value, at url: URL) throws {
  let data = try JSONEncoder().encode(value)
  let descriptor = open(url.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, S_IRUSR | S_IWUSR)
  guard descriptor >= 0 else { throw ProbeError.control }
  defer { close(descriptor) }
  let count = data.withUnsafeBytes { write(descriptor, $0.baseAddress, $0.count) }
  guard count == data.count, fsync(descriptor) == 0 else { throw ProbeError.control }
}

func secureFile(_ url: URL) throws -> Data {
  var info = stat()
  guard lstat(url.path, &info) == 0, info.st_uid == getuid(),
    info.st_mode & S_IFMT == S_IFREG, info.st_mode & 0o077 == 0
  else { throw ProbeError.control }
  return try Data(contentsOf: url)
}

func phase(_ phase: String) async throws {
  guard let path = ProcessInfo.processInfo.environment["HOSTED_RUN_ROOT"] else {
    throw ProbeError.control
  }
  let root = URL(fileURLWithPath: path)
  let control = try await admit(root: root, phase: phase)
  var receipt: Receipt
  if control.mode == "live" {
    #if HOSTED_LIVE
      receipt = await performLive(control, phase: phase)
    #else
      throw ProbeError.control
    #endif
  } else {
    receipt = try await performOffline(control, root: root, phase: phase)
  }
  if phase == "fresh" {
    let first = try JSONDecoder().decode(
      Receipt.self, from: secureFile(root.appendingPathComponent("first.machine.json")))
    receipt.sameCredential =
      !receipt.initialCredentialTag.isEmpty
      && receipt.initialCredentialTag == first.finalCredentialTag
    receipt.sameAccount =
      control.mode == "offline"
      || (!receipt.accountTag.isEmpty && receipt.accountTag == first.accountTag)
  }
  try exclusive(receipt, at: root.appendingPathComponent(phase + ".machine.json"))
  // Bool/counter expressions only: credentials and responses never enter XCTest diagnostics.
  let ready = receipt.outcome == "ready"
  let persisted = receipt.completeReadback
  let configurationKept = receipt.configurationUnchanged
  let authenticated = control.mode == "offline" || receipt.apiAuthenticated
  let crossProcess = phase == "first" || (receipt.sameCredential && receipt.sameAccount)
  #expect(ready)
  #expect(persisted)
  #expect(configurationKept)
  #expect(authenticated)
  #expect(crossProcess)
  #expect(receipt.phasePassed)
  let refreshedBeforeReady =
    !receipt.initiallyExpired
    || (receipt.prepare.refreshAccepted > 0 && receipt.prepare.saves > 0)
  #expect(refreshedBeforeReady)
  if control.mode == "offline" {
    #expect(receipt.liveOperations == 0)
    #expect(receipt.prepare.refreshAccepted == (phase == "first" ? 1 : 0))
    #expect(receipt.prepare.saves == (phase == "first" ? 1 : 0))
  }
  if control.negative == "assert" { #expect(Bool(false)) }
  if control.negative == "throw" { throw ProbeError.selfTest }
}

func admit(root: URL, phase: String) async throws -> Control {
  let control = try JSONDecoder().decode(
    Control.self, from: secureFile(root.appendingPathComponent("control.json")))
  guard ["offline", "live"].contains(control.mode), !control.group.contains("*"),
    Bundle.main.bundleIdentifier == control.bundleID
  else { throw ProbeError.control }
  #if !HOSTED_LIVE
    guard control.mode == "offline" else { throw ProbeError.control }
  #endif
  let executable = Bundle.main.executableURL!.resolvingSymlinksInPath().path
  try exclusive(
    ["runID": control.runID, "phase": phase, "pid": String(getpid()), "executable": executable],
    at: root.appendingPathComponent(phase + ".hello.json"))
  let authorization = root.appendingPathComponent(phase + ".authorize.json")
  let deadline = ContinuousClock.now.advanced(by: .seconds(30))
  while !FileManager.default.fileExists(atPath: authorization.path) {
    guard ContinuousClock.now < deadline else { throw ProbeError.control }
    try await Task.sleep(for: .milliseconds(50))
  }
  let admission = try JSONDecoder().decode([String: String].self, from: secureFile(authorization))
  guard admission == ["runID": control.runID, "phase": phase] else { throw ProbeError.control }
  return control
}

actor OfflineConfiguration: GitHubOAuthAppConfigurationStore {
  let value: GitHubOAuthAppConfiguration
  init() throws { value = try .init(clientID: "offline-client", clientSecret: "offline-secret") }
  func load() async throws(any Error & Sendable) -> GitHubOAuthAppConfiguration? { value }
  func save(_ value: GitHubOAuthAppConfiguration) async throws(any Error & Sendable) {
    throw ProbeError.forbidden
  }
}

struct FakeBundle: Codable {
  let access: String
  let expires: Double
  init(_ value: GitHubOAuthCredentialBundle) {
    access = value.accessToken.rawValue
    expires = value.accessTokenExpiresAt.timeIntervalSince1970
  }
  var credential: GitHubOAuthCredentialBundle {
    .init(
      accessToken: .init(rawValue: access), refreshToken: .init(rawValue: "offline-refresh"),
      accessTokenExpiresAt: Date(timeIntervalSince1970: expires),
      refreshTokenExpiresAt: .distantFuture,
      tokenType: .bearer, grantedScopes: "offline")
  }
}

actor OfflineStore: OAuthCredentialStore {
  let file: URL
  init(root: URL) { file = root.appendingPathComponent("fake-credential.json") }
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    try JSONDecoder().decode(FakeBundle.self, from: secureFile(file)).credential
  }
  func save(_ value: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    let data = try JSONEncoder().encode(FakeBundle(value))
    // Test-only fixture. This path is never used for a real credential.
    try data.write(to: file, options: .atomic)
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
  }
}

struct OfflineFetcher: OAuthTokenFetcher {
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    FakeBundleValue.fresh
  }
}

enum FakeBundleValue {
  static var fresh: GitHubOAuthCredentialBundle {
    .init(
      accessToken: .init(rawValue: "offline-new"), refreshToken: .init(rawValue: "offline-refresh"),
      accessTokenExpiresAt: Date(timeIntervalSince1970: 4_000_000_000),
      refreshTokenExpiresAt: .distantFuture,
      tokenType: .bearer, grantedScopes: "offline")
  }
}

func performOffline(_ control: Control, root: URL, phase: String) async throws -> Receipt {
  guard let key = Data(base64Encoded: control.keyBase64), key.count == 32 else {
    throw ProbeError.control
  }
  let observer = Observer(key: SymmetricKey(data: key))
  let store = OfflineStore(root: root)
  let configuration = try OfflineConfiguration()
  let owner = GitHubOAuthStartupRestorer(
    configurationStore: ObservedConfiguration(base: configuration, observer: observer),
    makeCredentialStore: { _ in ObservedStore(base: store, observer: observer) },
    makeTokenFetcher: { _ in ObservedFetcher(base: OfflineFetcher(), observer: observer) })
  let outcome = await owner.restore()
  var receipt = Receipt(phase: phase)
  let frozen = await observer.snapshot()
  receipt.prepare = frozen.stats
  receipt.final = frozen.stats
  receipt.initiallyExpired = frozen.initiallyExpired
  receipt.initialCredentialTag = frozen.initialTag
  if case .ready = outcome { receipt.outcome = "ready" }
  let readback = try await store.load()
  if let oracle = frozen.oracle, let readback {
    receipt.finalCredentialTag = credentialTag(readback, key: SymmetricKey(data: key))
    receipt.completeReadback =
      receipt.finalCredentialTag == credentialTag(oracle, key: SymmetricKey(data: key))
  }
  receipt.configurationUnchanged = frozen.configuration != nil
  receipt.naturalRefreshObserved = false  // Synthetic expiry is not live coverage.
  receipt.phasePassed = receipt.outcome == "ready" && receipt.completeReadback
  return receipt
}
