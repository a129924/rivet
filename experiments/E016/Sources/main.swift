import AppKit
import CryptoKit
import Foundation
import GitHubIntegration

private enum ProbeFailure: Error { case prerequisite, existingItem, mismatch, unexpectedRefresh }
private let group = "4Q76YL5UQ5.local.rivet.dpkcontinuity.b90f5f16d3c8452faf9186b88d6dc64e"
private func digest(_ data: Data) -> String {
  SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}
private func readJSON(_ url: URL) throws -> [String: Any] {
  guard let value = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
  else { throw ProbeFailure.prerequisite }
  return value
}
private func writeJSON(_ value: [String: Any], _ url: URL) throws {
  guard !FileManager.default.fileExists(atPath: url.path) else { throw ProbeFailure.prerequisite }
  let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
  try data.write(to: url, options: [.atomic])
  try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
}
private func bundle(_ sentinel: Bool) -> GitHubOAuthCredentialBundle {
  let suffix = sentinel ? "sentinel" : "main"
  return GitHubOAuthCredentialBundle(
    accessToken: GitHubAccessToken(rawValue: "e016-fake-access-\(suffix)"),
    refreshToken: GitHubOAuthRefreshToken(rawValue: "e016-fake-refresh-\(suffix)"),
    accessTokenExpiresAt: Date(timeIntervalSince1970: 2_000_000_000),
    refreshTokenExpiresAt: Date(timeIntervalSince1970: 2_100_000_000),
    tokenType: .bearer, grantedScopes: "e016-synthetic")
}
private func same(_ lhs: GitHubOAuthCredentialBundle?, _ rhs: GitHubOAuthCredentialBundle) -> Bool {
  guard let lhs else { return false }
  return lhs.accessToken == rhs.accessToken
    && lhs.refreshToken.rawValue == rhs.refreshToken.rawValue
    && lhs.accessTokenExpiresAt == rhs.accessTokenExpiresAt
    && lhs.refreshTokenExpiresAt == rhs.refreshTokenExpiresAt
    && lhs.tokenType == rhs.tokenType && lhs.grantedScopes == rhs.grantedScopes
}
private actor ForbiddenFetcher: OAuthTokenFetcher {
  typealias Credential = GitHubOAuthCredentialBundle
  private(set) var called = false
  func refresh(_ credential: Credential) async throws(OAuthTokenRefreshError) -> Credential {
    called = true
    throw .knownTechnicalFailure
  }
}

@MainActor private final class Delegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    Task {
      await run()
      NSApplication.shared.terminate(nil)
    }
  }

  private func authorize(root: URL, phase: String) async throws -> String {
    let attributes = try FileManager.default.attributesOfItem(atPath: root.path)
    guard attributes[.type] as? FileAttributeType == .typeDirectory,
      (attributes[.posixPermissions] as? NSNumber)?.intValue == 0o700,
      (attributes[.ownerAccountID] as? NSNumber)?.uint32Value == getuid()
    else { throw ProbeFailure.prerequisite }
    let frozen = try readJSON(root.appendingPathComponent("frozen.json"))
    guard let runID = frozen["run_id"] as? String, UUID(uuidString: runID) != nil,
      let appPath = frozen["app"] as? String,
      try E016PathIdentity.matches(Bundle.main.bundleURL, expected: appPath),
      Bundle.main.bundleIdentifier
        == "local.rivet.dpkcontinuity.b90f5f16d3c8452faf9186b88d6dc64e",
      let executable = Bundle.main.executableURL,
      let executablePath = frozen["executable"] as? String,
      try E016PathIdentity.matches(executable, expected: executablePath),
      digest(try Data(contentsOf: executable)) == frozen["binary_hash"] as? String,
      digest(
        try Data(
          contentsOf: Bundle.main.bundleURL.appendingPathComponent(
            "Contents/embedded.provisionprofile"))) == frozen["profile_hash"] as? String
    else { throw ProbeFailure.prerequisite }
    try writeJSON(
      [
        "pid": ProcessInfo.processInfo.processIdentifier,
        "path": E016PathIdentity.normalized(executable).path,
        "binary_hash": frozen["binary_hash"]!, "phase": phase, "run_id": runID,
      ], root.appendingPathComponent("\(phase)-hello.json"))
    let permission = root.appendingPathComponent("\(phase)-authorize.json")
    for _ in 0..<300 where !FileManager.default.fileExists(atPath: permission.path) {
      try await Task.sleep(for: .milliseconds(100))
    }
    let authorization = try readJSON(permission)
    guard authorization["pid"] as? Int32 == ProcessInfo.processInfo.processIdentifier,
      authorization["run_id"] as? String == runID,
      authorization["phase"] as? String == phase,
      authorization["binary_hash"] as? String == frozen["binary_hash"] as? String,
      authorization["profile_hash"] as? String == frozen["profile_hash"] as? String,
      authorization["source_hash"] as? String == frozen["source_hash"] as? String
    else { throw ProbeFailure.prerequisite }
    guard let sourceRoot = frozen["source_root"] as? String,
      let source = frozen["source"] as? [String: Any],
      let files = source["files"] as? [String: String],
      let expiry = ISO8601DateFormatter().date(from: "2026-11-17T07:28:08Z"), Date() < expiry
    else { throw ProbeFailure.prerequisite }
    for (path, expected) in files {
      guard !path.hasPrefix("/"), !path.split(separator: "/").contains(".."),
        digest(
          try Data(contentsOf: URL(fileURLWithPath: sourceRoot).appendingPathComponent(path)))
          == expected
      else { throw ProbeFailure.prerequisite }
    }
    return runID
  }

  private func run() async {
    let args = CommandLine.arguments
    guard args.count == 3, ["first", "fresh"].contains(args[1]) else { return }
    let phase = args[1]
    let root = URL(fileURLWithPath: args[2], isDirectory: true).standardizedFileURL
    var receipt: [String: Any] = [
      "schema": "e016.v1", "phase": phase, "outcome": "indeterminate",
      "failureKind": "prerequisite", "write_attempted": false,
    ]
    do {
      let runID = try await authorize(root: root, phase: phase)
      let service = "local.rivet.experiment.e016.logout.\(runID)"
      let stores = try GitHubOAuthDataProtectionStores(accessGroup: group, service: service)
      let sentinel = try GitHubOAuthDataProtectionStores(
        accessGroup: group, service: service + ".sentinel")
      let credentialStore = stores.credentialStore(clientID: "e016-fake-client")
      let sentinelStore = sentinel.credentialStore(clientID: "e016-fake-client")
      let config = try GitHubOAuthAppConfiguration(
        clientID: "e016-fake-client", clientSecret: "e016-fake-secret")
      if phase == "first" {
        let initialCredential = try await credentialStore.load()
        let initialConfiguration = try await stores.configurationStore.load()
        let initialSentinel = try await sentinelStore.load()
        guard initialCredential == nil, initialConfiguration == nil, initialSentinel == nil
        else { throw ProbeFailure.existingItem }
        receipt["seed_absent"] = true
        receipt["write_attempted"] = true
        try writeJSON(
          ["write_attempted": true], root.appendingPathComponent("write-attempted.json"))
        try await stores.configurationStore.save(config)
        try await credentialStore.save(bundle(false))
        try await sentinelStore.save(bundle(true))
        let loadedConfig = try await stores.configurationStore.load()
        guard loadedConfig?.clientID == config.clientID,
          loadedConfig?.clientSecret == config.clientSecret,
          same(try await credentialStore.load(), bundle(false)),
          same(try await sentinelStore.load(), bundle(true))
        else { throw ProbeFailure.mismatch }
        receipt["seed_readback"] = true
        let fetcher = ForbiddenFetcher()
        let provider = OAuthTokenProvider(store: credentialStore, fetcher: fetcher)
        try await provider.signOut()
        guard await !fetcher.called else { throw ProbeFailure.unexpectedRefresh }
        receipt["signout_returned"] = true
      }
      let absent = try await credentialStore.load() == nil
      let remainingConfig = try await stores.configurationStore.load()
      let configIntact =
        remainingConfig?.clientID == config.clientID
        && remainingConfig?.clientSecret == config.clientSecret
      let sentinelIntact = same(try await sentinelStore.load(), bundle(true))
      receipt[phase == "first" ? "same_process_absent" : "fresh_read_verified"] = absent
      receipt["configuration_intact"] = configIntact
      receipt["sentinel_intact"] = sentinelIntact
      guard absent, configIntact, sentinelIntact else { throw ProbeFailure.mismatch }
      receipt["outcome"] = "passed"
      receipt["failureKind"] = "none"
    } catch ProbeFailure.existingItem {
      receipt["failureKind"] = "existing_item"
    } catch ProbeFailure.mismatch {
      receipt["outcome"] = "failed"
      receipt["failureKind"] = "mismatch"
    } catch {
      // Never serialize arbitrary error descriptions or fixture payloads.
      receipt["failureKind"] = "operation_or_prerequisite"
    }
    try? writeJSON(receipt, root.appendingPathComponent("\(phase)-machine.json"))
  }
}
let app = NSApplication.shared
private let delegate = Delegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
