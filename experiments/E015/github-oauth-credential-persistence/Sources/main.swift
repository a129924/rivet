// The fixed single-host boundary keeps actual shared fake checks beside the harness; only file length is waived.
// swiftlint:disable file_length
import CryptoKit
import Darwin
import Foundation
import GitHubIntegration
import Security

#if DPK_VALIDATION_ONLY && LAUNCH_REPORT_ONLY
  #error("Validation purposes are mutually exclusive")
#endif

private enum ProbeFailure: Error {
  case guardRejected
  case comparison
  case cleanup
}

private struct ProbeRequest: Decodable, Sendable {
  let runUUID: String
  let phase: String
  let root: String
  let service: String
  let group: String
  let account: String
  let clientID: String
  let manifestSHA256: String
  let identitySHA256: String
  let compiledMarker: Bool
  let recoveryUUID: String?
}

private enum Probe {
  private static let phases = [
    "save-a", "read-a", "replace-b", "read-b", "rebuilt-read-b", "cleanup",
  ]
  #if CREDENTIAL_STORAGE_REBUILT
    static let compiledMarker = true
  #else
    static let compiledMarker = false
  #endif

  static func require(_ condition: Bool) throws {
    guard condition else { throw ProbeFailure.guardRejected }
  }

  static func sha(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  static func dictionary(_ url: URL) throws -> [String: Any] {
    let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    guard let value = object as? [String: Any] else { throw ProbeFailure.guardRejected }
    return value
  }

  static func safeURL(_ root: URL, _ relative: String) throws -> URL {
    try require(!relative.contains("..") && !relative.hasPrefix("/"))
    var cursor = root
    for component in relative.split(separator: "/") {
      cursor.appendPathComponent(String(component))
      if FileManager.default.fileExists(atPath: cursor.path) {
        let attributes = try FileManager.default.attributesOfItem(atPath: cursor.path)
        try require(attributes[.type] as? FileAttributeType != .typeSymbolicLink)
      }
    }
    try require(cursor.standardizedFileURL.path.hasPrefix(root.path + "/"))
    return cursor
  }

  static func exclusiveJSON(_ value: [String: Any], at url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    let descriptor = open(url.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
    try require(descriptor >= 0)
    defer { close(descriptor) }
    try data.withUnsafeBytes { bytes in
      guard let address = bytes.baseAddress else { throw ProbeFailure.guardRejected }
      var offset = 0
      while offset < bytes.count {
        let count = write(descriptor, address.advanced(by: offset), bytes.count - offset)
        try require(count > 0)
        offset += count
      }
    }
    try require(fsync(descriptor) == 0)
  }

  static func validate(_ request: ProbeRequest) throws -> URL {
    guard let parsed = UUID(uuidString: request.runUUID) else { throw ProbeFailure.guardRejected }
    try require(parsed.uuidString.lowercased() == request.runUUID)
    try require(request.runUUID.split(separator: "-")[2].hasPrefix("4"))
    try require(request.service == "local.rivet.github.oauth.validation." + request.runUUID)
    try require(
      request.account == "credential" && request.clientID == "rivet-validation-fake-client")
    try require(!request.group.isEmpty && !request.group.contains("*"))
    try require(phases.contains(request.phase) && request.compiledMarker == compiledMarker)

    let root = URL(fileURLWithPath: request.root, isDirectory: true).standardizedFileURL
    try require(root.path == request.root && root.resolvingSymlinksInPath().path == root.path)
    try require(root.lastPathComponent == "rivet-credential-storage-" + request.runUUID)
    let attributes = try FileManager.default.attributesOfItem(atPath: root.path)
    try require((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o700)
    try require((attributes[.ownerAccountID] as? NSNumber)?.uint32Value == getuid())

    let manifestURL = try safeURL(root, "run.json")
    try require(sha(Data(contentsOf: manifestURL)) == request.manifestSHA256)
    let manifest = try dictionary(manifestURL)
    try require(manifest["runUUID"] as? String == request.runUUID)
    try require(manifest["service"] as? String == request.service)
    try require(manifest["account"] as? String == request.account)
    try require(manifest["fixedApp"] as? String == Bundle.main.bundleURL.standardizedFileURL.path)
    for key in ["sources", "copiedSources"] {
      guard let sources = manifest[key] as? [String: String], !sources.isEmpty else {
        throw ProbeFailure.guardRejected
      }
      for (path, expected) in sources {
        try require(sha(Data(contentsOf: URL(fileURLWithPath: path))) == expected)
      }
    }
    let identityURL = try safeURL(root, "identity.json")
    try require(sha(Data(contentsOf: identityURL)) == request.identitySHA256)
    let identity = try dictionary(identityURL)
    try require(identity["group"] as? String == request.group)
    try require(identity["appID"] as? String == Bundle.main.bundleIdentifier)
    let project = try safeURL(root, "project/CredentialStorageProbe.xcodeproj/project.pbxproj")
    try require(identity["projectSHA256"] as? String == sha(Data(contentsOf: project)))
    guard let task = SecTaskCreateFromSelf(kCFAllocatorDefault),
      let groups = SecTaskCopyValueForEntitlement(task, "keychain-access-groups" as CFString, nil)
        as? [String]
    else { throw ProbeFailure.guardRejected }
    try require(groups == [request.group])
    return root
  }

  static func fixture(_ replacement: Bool) -> GitHubOAuthCredentialBundle {
    GitHubOAuthCredentialBundle(
      accessToken: GitHubAccessToken(
        rawValue: replacement ? "rivet-fake-access-B" : "rivet-fake-access-A"),
      refreshToken: GitHubOAuthRefreshToken(
        rawValue: replacement ? "rivet-fake-refresh-B" : "rivet-fake-refresh-A"),
      accessTokenExpiresAt: Date(
        timeIntervalSince1970: replacement ? 1_900_000_100 : 1_900_000_000),
      refreshTokenExpiresAt: Date(
        timeIntervalSince1970: replacement ? 1_901_000_100 : 1_901_000_000),
      tokenType: .bearer,
      grantedScopes: replacement ? "read:user user:email" : "read:user")
  }

  static func comparison(
    _ value: GitHubOAuthCredentialBundle?, replacement: Bool
  ) -> [String: Bool] {
    let expected = fixture(replacement)
    return [
      "accessToken": value?.accessToken.rawValue == expected.accessToken.rawValue,
      "refreshToken": value?.refreshToken.rawValue == expected.refreshToken.rawValue,
      "accessTokenExpiresAt": value?.accessTokenExpiresAt == expected.accessTokenExpiresAt,
      "refreshTokenExpiresAt": value?.refreshTokenExpiresAt == expected.refreshTokenExpiresAt,
      "tokenType": value?.tokenType == expected.tokenType,
      "grantedScopes": value?.grantedScopes == expected.grantedScopes,
    ]
  }

  static func ownership(_ request: ProbeRequest) -> [String: Any] {
    [
      "runUUID": request.runUUID, "service": request.service,
      "group": request.group, "account": request.account,
      "manifestSHA256": request.manifestSHA256,
      "absenceConfirmed": true, "writeAttempted": true,
    ]
  }

  static func validateOwnership(_ request: ProbeRequest, root: URL) throws {
    let absence = try dictionary(safeURL(root, "private/absence.json"))
    let attempt = try dictionary(safeURL(root, "private/write-attempt.json"))
    for value in [absence, attempt] {
      for (key, expected) in [
        "runUUID": request.runUUID, "service": request.service, "group": request.group,
        "account": request.account, "manifestSHA256": request.manifestSHA256,
      ] {
        try require(value[key] as? String == expected)
      }
      try require(value["absenceConfirmed"] as? Bool == true)
    }
    try require(attempt["writeAttempted"] as? Bool == true)
  }

  static func perform(
    _ request: ProbeRequest, receipt: inout [String: Any], operations: ProbeOperations
  ) async throws {
    let store = operations.store
    switch request.phase {
    case "save-a":
      try require(try await store.load() == nil)
      try operations.persistAbsence()
      receipt["absenceConfirmed"] = true
      // Durable proof completes before any save that could commit or throw.
      try operations.persistAttempt()
      receipt["writeAttempted"] = true
      receipt["owned"] = true
      try await store.save(fixture(false))
      let result = comparison(try await store.load(), replacement: false)
      receipt["comparison"] = result
      guard result.values.allSatisfy({ $0 }) else { throw ProbeFailure.comparison }
    case "read-a", "read-b", "rebuilt-read-b":
      try operations.validateOwnership()
      let result = comparison(try await store.load(), replacement: request.phase != "read-a")
      receipt["comparison"] = result
      guard result.values.allSatisfy({ $0 }) else { throw ProbeFailure.comparison }
    case "replace-b":
      try operations.validateOwnership()
      let old = comparison(try await store.load(), replacement: false)
      guard old.values.allSatisfy({ $0 }) else { throw ProbeFailure.comparison }
      try await store.save(fixture(true))
      let result = comparison(try await store.load(), replacement: true)
      receipt["comparison"] = result
      guard result.values.allSatisfy({ $0 }) else { throw ProbeFailure.comparison }
    case "cleanup":
      try await performCleanup(request, receipt: &receipt, operations: operations)
    default:
      throw ProbeFailure.guardRejected
    }
  }

  static func performCleanup(
    _ request: ProbeRequest, receipt: inout [String: Any], operations: ProbeOperations
  ) async throws {
    try operations.validateOwnership()
    receipt["owned"] = true
    // This exact query is shared by the live deletion seam and fake operation checks.
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccessGroup as String: request.group,
      kSecAttrService as String: request.service,
      kSecAttrAccount as String: "credential",
      kSecUseDataProtectionKeychain as String: true,
      kSecAttrSynchronizable as String: false,
    ]
    let status = try operations.delete(query)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw ProbeFailure.cleanup
    }
    receipt["deleted"] = true
    let missing = try await operations.store.load() == nil
    receipt["readAbsent"] = missing
    guard missing else { throw ProbeFailure.cleanup }
    try operations.persistCleaned()
  }

  static func failureKind(_ error: any Error) -> String {
    if let error = error as? GitHubOAuthDataProtectionStoreError {
      switch error {
      case .denied: return "credentialDenied"
      case .unavailable: return "credentialUnavailable"
      case .corrupt: return "credentialCorrupt"
      case .identityMismatch: return "identityMismatch"
      case .invalidConfiguration: return "invalidConfiguration"
      }
    }
    if let failure = error as? ProbeFailure {
      switch failure {
      case .guardRejected: return "guard"
      case .comparison: return "comparison"
      case .cleanup: return "cleanup"
      }
    }
    return "other"
  }

  static func run() async {
    // No output containing paths, selectors, payloads, or underlying errors.
    var receipt: [String: Any] = [:]
    var destination: URL?
    do {
      let arguments = CommandLine.arguments
      try require(
        arguments.count == 5 && arguments[1] == "--request" && arguments[3] == "--request-sha")
      let requestURL = URL(fileURLWithPath: arguments[2]).standardizedFileURL
      let data = try Data(contentsOf: requestURL)
      try require(sha(data) == arguments[4])
      let request = try JSONDecoder().decode(ProbeRequest.self, from: data)
      let root = try validate(request)
      var prefix = "private/"
      if let recovery = request.recoveryUUID {
        guard let parsed = UUID(uuidString: recovery) else { throw ProbeFailure.guardRejected }
        try require(request.phase == "cleanup" && parsed.uuidString.lowercased() == recovery)
        try require(recovery.split(separator: "-")[2].hasPrefix("4"))
        prefix += "recovery/" + recovery + "/"
      }
      try require(requestURL.path == safeURL(root, prefix + request.phase + ".request.json").path)
      destination = try safeURL(root, prefix + request.phase + ".app.json")
      receipt = [
        "schemaVersion": 1, "runUUID": request.runUUID, "phase": request.phase,
        "pid": Int(getpid()), "processUUID": UUID().uuidString.lowercased(),
        "compiledMarker": compiledMarker, "status": "unknown",
      ]
      try await perform(
        request, receipt: &receipt, operations: ProbeOperations.live(request, root: root))
      receipt["status"] = "success"
    } catch {
      receipt["status"] = "failure"
      receipt["failureKind"] = failureKind(error)
    }
    if let destination {
      try? exclusiveJSON(receipt, at: destination)
    }
  }
}

private struct ProbeOperations {
  let store: any OAuthCredentialStore
  var persistAbsence: () throws -> Void
  var persistAttempt: () throws -> Void
  let validateOwnership: () throws -> Void
  let delete: ([String: Any]) throws -> OSStatus
  let persistCleaned: () throws -> Void

  static func files(
    _ request: ProbeRequest, root: URL, store: any OAuthCredentialStore,
    delete: @escaping ([String: Any]) throws -> OSStatus
  ) -> ProbeOperations {
    ProbeOperations(
      store: store,
      persistAbsence: {
        var proof = Probe.ownership(request)
        proof["writeAttempted"] = false
        try Probe.exclusiveJSON(proof, at: Probe.safeURL(root, "private/absence.json"))
      },
      persistAttempt: {
        try Probe.exclusiveJSON(
          Probe.ownership(request), at: Probe.safeURL(root, "private/write-attempt.json"))
      },
      validateOwnership: { try Probe.validateOwnership(request, root: root) },
      delete: delete,
      persistCleaned: {
        try Probe.exclusiveJSON(
          [
            "runUUID": request.runUUID, "readAbsent": true,
            "manifestSHA256": request.manifestSHA256,
          ],
          at: Probe.safeURL(
            root,
            request.recoveryUUID.map { "private/recovery/" + $0 + "/item-cleaned.json" }
              ?? "private/item-cleaned.json"))
      })
  }

  static func live(_ request: ProbeRequest, root: URL) throws -> ProbeOperations {
    let stores = try GitHubOAuthDataProtectionStores(
      accessGroup: request.group, service: request.service)
    let store = stores.credentialStore(clientID: request.clientID)
    return files(request, root: root, store: store) { query in
      SecItemDelete(query as CFDictionary)
    }
  }
}

private enum FakeProbeFailure: Error, Sendable {
  case read
  case save
  case interruptionAfterCommit
  case proof
  case delete
}

private final class FakeTrace: @unchecked Sendable {
  private let lock = NSLock()
  private var entries: [String] = []

  func append(_ entry: String) {
    lock.withLock { entries.append(entry) }
  }

  var snapshot: [String] {
    lock.withLock { entries }
  }
}

private final class FakeProbeStore: OAuthCredentialStore, @unchecked Sendable {
  private let lock = NSLock()
  private var value: GitHubOAuthCredentialBundle?
  private var rejectsRead = false
  private var saveFailure: FakeProbeFailure?
  let trace: FakeTrace

  init(_ value: GitHubOAuthCredentialBundle?, trace: FakeTrace) {
    self.value = value
    self.trace = trace
  }

  func configure(readFailure: Bool = false, saveFailure: FakeProbeFailure? = nil) {
    lock.withLock {
      rejectsRead = readFailure
      self.saveFailure = saveFailure
    }
  }

  private func read() throws(FakeProbeFailure) -> GitHubOAuthCredentialBundle? {
    trace.append("load")
    let state = lock.withLock { (value, rejectsRead) }
    if state.1 { throw .read }
    return state.0
  }

  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    try read()
  }

  private func commit(_ credential: GitHubOAuthCredentialBundle) throws(FakeProbeFailure) {
    trace.append("save")
    let failure = lock.withLock { saveFailure }
    if failure == .save { throw .save }
    lock.withLock { value = credential }
    if failure == .interruptionAfterCommit { throw .interruptionAfterCommit }
  }

  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    try commit(credential)
  }

  func remove() {
    lock.withLock { value = nil }
  }
}

private struct FakeOperationFixture {
  let root: URL
  let runUUID: String
  let trace = FakeTrace()
  let store: FakeProbeStore

  init(initial: GitHubOAuthCredentialBundle? = nil) throws {
    runUUID = UUID().uuidString.lowercased()
    root = FileManager.default.temporaryDirectory
      .appendingPathComponent("rivet-probe-fake-" + runUUID, isDirectory: true)
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("private", isDirectory: true),
      withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    store = FakeProbeStore(initial, trace: trace)
  }

  func dispose() {
    try? FileManager.default.removeItem(at: root)
  }

  func request(
    _ phase: String, recovery: String? = nil, group: String = "TEAM.fixture"
  ) -> ProbeRequest {
    ProbeRequest(
      runUUID: runUUID, phase: phase, root: root.path,
      service: "local.rivet.github.oauth.validation." + runUUID,
      group: group, account: "credential", clientID: "rivet-validation-fake-client",
      manifestSHA256: String(repeating: "a", count: 64),
      identitySHA256: String(repeating: "b", count: 64), compiledMarker: Probe.compiledMarker,
      recoveryUUID: recovery)
  }

  func operations(
    _ request: ProbeRequest, rejectDelete: Bool = false, keepAfterDelete: Bool = false,
    notFoundDelete: Bool = false
  ) -> ProbeOperations {
    var operations = ProbeOperations.files(request, root: root, store: store) { query in
      trace.append("delete")
      try Probe.require(
        Set(query.keys)
          == Set([
            kSecClass as String, kSecAttrAccessGroup as String, kSecAttrService as String,
            kSecAttrAccount as String, kSecUseDataProtectionKeychain as String,
            kSecAttrSynchronizable as String,
          ]))
      try Probe.require(query[kSecClass as String] as? String == kSecClassGenericPassword as String)
      try Probe.require(query[kSecAttrAccessGroup as String] as? String == request.group)
      try Probe.require(query[kSecAttrService as String] as? String == request.service)
      try Probe.require(query[kSecAttrAccount as String] as? String == "credential")
      try Probe.require(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
      try Probe.require(query[kSecAttrSynchronizable as String] as? Bool == false)
      if rejectDelete { return errSecAuthFailed }
      if !keepAfterDelete { store.remove() }
      return notFoundDelete ? errSecItemNotFound : errSecSuccess
    }
    let absence = operations.persistAbsence
    operations.persistAbsence = {
      try absence()
      trace.append("durable-absence")
    }
    let attempt = operations.persistAttempt
    operations.persistAttempt = {
      try attempt()
      trace.append("durable-attempt")
    }
    return operations
  }

  func seedOwnership() throws {
    let operations = operations(request("save-a"))
    try operations.persistAbsence()
    try operations.persistAttempt()
  }

  func markerExists() -> Bool {
    FileManager.default.fileExists(
      atPath: root.appendingPathComponent("private/write-attempt.json").path)
  }
}

private enum FakeOperationChecks {
  static func rejectExisting(readFailure: Bool) async throws {
    let fixture = try FakeOperationFixture(initial: Probe.fixture(false))
    defer { fixture.dispose() }
    fixture.store.configure(readFailure: readFailure)
    let request = fixture.request("save-a")
    var receipt: [String: Any] = [:]
    var failed = false
    do {
      try await Probe.perform(request, receipt: &receipt, operations: fixture.operations(request))
    } catch { failed = true }
    try Probe.require(failed && !fixture.trace.snapshot.contains("save") && !fixture.markerExists())
  }

  static func saveOrder(failure: FakeProbeFailure?) async throws {
    let fixture = try FakeOperationFixture()
    defer { fixture.dispose() }
    fixture.store.configure(saveFailure: failure)
    let request = fixture.request("save-a")
    var receipt: [String: Any] = [:]
    var failed = false
    do {
      try await Probe.perform(request, receipt: &receipt, operations: fixture.operations(request))
    } catch { failed = true }
    try Probe.require(failed == (failure != nil))
    let trace = fixture.trace.snapshot
    try Probe.require(
      Array(trace.prefix(4)) == [
        "load", "durable-absence", "durable-attempt", "save",
      ])
    try Probe.require(fixture.markerExists())
    try Probe.validateOwnership(request, root: fixture.root)
    if failure == nil {
      try Probe.require(trace.last == "load")
      try Probe.require(
        (receipt["comparison"] as? [String: Bool])?.values.allSatisfy { $0 } == true)
    }
  }

  static func proofFailure() async throws {
    let fixture = try FakeOperationFixture()
    defer { fixture.dispose() }
    let request = fixture.request("save-a")
    var operations = fixture.operations(request)
    operations.persistAttempt = { throw FakeProbeFailure.proof }
    var receipt: [String: Any] = [:]
    do {
      try await Probe.perform(request, receipt: &receipt, operations: operations)
    } catch {
      try Probe.require(!fixture.trace.snapshot.contains("save") && !fixture.markerExists())
      return
    }
    throw FakeProbeFailure.proof
  }

  static func rejectCleanup(mismatch: Bool) async throws {
    let fixture = try FakeOperationFixture(initial: Probe.fixture(true))
    defer { fixture.dispose() }
    if mismatch { try fixture.seedOwnership() }
    let request = fixture.request("cleanup", group: mismatch ? "OTHER.fixture" : "TEAM.fixture")
    var receipt: [String: Any] = [:]
    do {
      try await Probe.perform(request, receipt: &receipt, operations: fixture.operations(request))
    } catch {
      try Probe.require(!fixture.trace.snapshot.contains("delete"))
      return
    }
    throw FakeProbeFailure.proof
  }

  static func cleanup(
    initiallyMissing: Bool, rejectDelete: Bool, keepAfterDelete: Bool
  ) async throws {
    let fixture = try FakeOperationFixture(initial: initiallyMissing ? nil : Probe.fixture(true))
    defer { fixture.dispose() }
    try fixture.seedOwnership()
    let request = fixture.request("cleanup")
    var receipt: [String: Any] = [:]
    var failed = false
    do {
      try await Probe.perform(
        request, receipt: &receipt,
        operations: fixture.operations(
          request, rejectDelete: rejectDelete, keepAfterDelete: keepAfterDelete,
          notFoundDelete: initiallyMissing))
    } catch { failed = true }
    try Probe.require(failed == (rejectDelete || keepAfterDelete))
    try Probe.require(fixture.markerExists())
    let trace = fixture.trace.snapshot
    try Probe.require(trace.contains("delete"))
    if rejectDelete || keepAfterDelete {
      let recovery = UUID().uuidString.lowercased()
      try FileManager.default.createDirectory(
        at: fixture.root.appendingPathComponent("private/recovery/" + recovery),
        withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
      let retried = fixture.request("cleanup", recovery: recovery)
      var recovered: [String: Any] = [:]
      try await Probe.perform(
        retried, receipt: &recovered, operations: fixture.operations(retried))
      try Probe.require(recovered["readAbsent"] as? Bool == true)
      try Probe.require(fixture.markerExists())
    } else {
      try Probe.require(receipt["readAbsent"] as? Bool == true)
      try Probe.require(trace.last == "load")
    }
  }

  static func run() async {
    let checks: [(String, () async throws -> Void)] = [
      ("exists-zero-save", { try await rejectExisting(readFailure: false) }),
      ("read-error-zero-save", { try await rejectExisting(readFailure: true) }),
      ("durable-proofs-before-save", { try await saveOrder(failure: nil) }),
      ("save-error-retains-proof", { try await saveOrder(failure: .save) }),
      (
        "interruption-after-commit-retains-proof",
        { try await saveOrder(failure: .interruptionAfterCommit) }
      ),
      ("proof-error-zero-save", { try await proofFailure() }),
      ("unowned-zero-delete", { try await rejectCleanup(mismatch: false) }),
      ("selector-mismatch-zero-delete", { try await rejectCleanup(mismatch: true) }),
      (
        "exact-delete-load-nil",
        { try await cleanup(initiallyMissing: false, rejectDelete: false, keepAfterDelete: false) }
      ),
      (
        "not-found-still-load-nil",
        { try await cleanup(initiallyMissing: true, rejectDelete: false, keepAfterDelete: false) }
      ),
      (
        "delete-error-same-root-recovery",
        { try await cleanup(initiallyMissing: false, rejectDelete: true, keepAfterDelete: false) }
      ),
      (
        "nonabsent-same-root-recovery",
        { try await cleanup(initiallyMissing: false, rejectDelete: false, keepAfterDelete: true) }
      ),
    ]
    var failures: [String] = []
    for (name, check) in checks {
      do { try await check() } catch { failures.append(name) }
    }
    let report: [String: Any] = [
      "mode": "fake-only", "passed": checks.count - failures.count, "failures": failures,
    ]
    do {
      let raw = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
      guard let output = String(bytes: raw, encoding: .utf8) else { exit(1) }
      print(output)
    } catch { exit(1) }
    if !failures.isEmpty { exit(1) }
  }
}

private struct DiagnosticHooks {
  let bundleURL: () -> URL
  let bundleID: () -> String?
  let entitlementGroups: () throws -> [String]
  let load: (String, String) async throws -> GitHubOAuthCredentialBundle?
  static var live: DiagnosticHooks {
    DiagnosticHooks(
      bundleURL: { Bundle.main.bundleURL.standardizedFileURL },
      bundleID: { Bundle.main.bundleIdentifier },
      entitlementGroups: {
        guard let task = SecTaskCreateFromSelf(kCFAllocatorDefault),
          let groups = SecTaskCopyValueForEntitlement(
            task, "keychain-access-groups" as CFString, nil)
            as? [String]
        else { throw ProbeFailure.guardRejected }
        return groups
      },
      load: { group, service in
        let stores = try GitHubOAuthDataProtectionStores(accessGroup: group, service: service)
        return try await stores.credentialStore(clientID: "rivet-validation-fake-client").load()
      })
  }
}
private struct DiagnosticContext {
  let root: URL
  let legacyRoot: URL
  let manifest: [String: Any]
  let manifestSHA: String
  let output: URL
  let purpose: String
}
private enum DiagnosticProbe {
  static let legacyID = "8ad8fb3b-51d9-4162-98fb-067521a37b4e"
  static let sourceLeaves = [
    "README.md", "Sources/main.swift", "scripts/credential_storage_live.py",
    "Tests/test_live_protocol.py",
  ]
  static func isHash(_ value: String) -> Bool {
    value.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil
  }
  static func uuid(_ value: String) throws {
    guard let parsed = UUID(uuidString: value) else { throw ProbeFailure.guardRejected }
    try Probe.require(
      parsed.uuidString.lowercased() == value && value.split(separator: "-")[2].hasPrefix("4"))
  }
  static func owned(_ url: URL, in root: URL) throws -> URL {
    try Probe.require(url.standardizedFileURL.path == url.path)
    try Probe.require(url.path == root.path || url.path.hasPrefix(root.path + "/"))
    try Probe.require(url.resolvingSymlinksInPath().path == url.path)
    let relative = String(url.path.dropFirst(root.path.count))
    var cursor = root
    for part in [""] + relative.split(separator: "/").map(String.init) {
      if !part.isEmpty { cursor.appendPathComponent(part) }
      let attributes = try FileManager.default.attributesOfItem(atPath: cursor.path)
      try Probe.require(attributes[.type] as? FileAttributeType != .typeSymbolicLink)
      try Probe.require((attributes[.ownerAccountID] as? NSNumber)?.uint32Value == getuid())
    }
    return url
  }
  static func root(_ url: URL, name: String) throws {
    try Probe.require(url.path == url.standardizedFileURL.path && url.lastPathComponent == name)
    _ = try owned(url, in: url)
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    try Probe.require(attributes[.type] as? FileAttributeType == .typeDirectory)
    try Probe.require((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o700)
  }
  static func bootstrap(_ environment: [String: String]) throws -> DiagnosticContext {
    guard let path = environment["RIVET_DIAGNOSTIC_MANIFEST"],
      let expected = environment["RIVET_DIAGNOSTIC_SHA256"], isHash(expected)
    else { throw ProbeFailure.guardRejected }
    let url = URL(fileURLWithPath: path)
    try Probe.require(url.path == path && url.lastPathComponent == "diagnostic.json")
    let scratch = url.deletingLastPathComponent()
    let raw = try Data(contentsOf: owned(url, in: scratch))
    try Probe.require(Probe.sha(raw) == expected)
    let value = try Probe.dictionary(url)
    let keys: Set<String> = [
      "schemaVersion", "diagnosticUUID", "legacyRunUUID", "purpose", "legacyRoot", "expectedApp",
      "sourceHashes", "binarySHA256", "legacyManifestSHA256", "legacyIdentitySHA256",
      "legacySaveMachineSHA256", "legacySaveHumanSHA256",
    ]
    try Probe.require(Set(value.keys) == keys)
    guard let version = value["schemaVersion"] as? NSNumber,
      CFGetTypeID(version) != CFBooleanGetTypeID(), version.intValue == 1,
      ["i", "q"].contains(String(cString: version.objCType)),
      let id = value["diagnosticUUID"] as? String, let purpose = value["purpose"] as? String,
      let legacyPath = value["legacyRoot"] as? String, let app = value["expectedApp"] as? String,
      let sources = value["sourceHashes"] as? [String: String]
    else { throw ProbeFailure.guardRejected }
    try uuid(id)
    try root(scratch, name: "rivet-credential-storage-diagnostic-" + id)
    try Probe.require(value["legacyRunUUID"] as? String == legacyID)
    try Probe.require(["diagnostic-only", "namespace-read-only"].contains(purpose))
    let legacy = URL(fileURLWithPath: legacyPath)
    try Probe.require(legacy.path == legacyPath)
    try root(legacy, name: "rivet-credential-storage-" + legacyID)
    let expectedApp = scratch.appendingPathComponent("app/CredentialStorageProbe.app")
    try Probe.require(app == expectedApp.path)
    _ = try owned(expectedApp, in: scratch)
    let executable = expectedApp.appendingPathComponent("Contents/MacOS/CredentialStorageProbe")
    try Probe.require(
      value["binarySHA256"] as? String
        == Probe.sha(Data(contentsOf: owned(executable, in: scratch))))
    let expectedSources = Set(
      sourceLeaves.map { scratch.appendingPathComponent("source/" + $0).path })
    try Probe.require(Set(sources.keys) == expectedSources)
    for (path, hash) in sources {
      try Probe.require(isHash(hash))
      try Probe.require(
        Probe.sha(Data(contentsOf: owned(URL(fileURLWithPath: path), in: scratch))) == hash)
    }
    for (leaf, key) in [
      ("run.json", "legacyManifestSHA256"), ("identity.json", "legacyIdentitySHA256"),
      ("private/save-a.public-machine.json", "legacySaveMachineSHA256"),
      ("private/save-a.human.json", "legacySaveHumanSHA256"),
    ] {
      guard let hash = value[key] as? String, isHash(hash) else { throw ProbeFailure.guardRejected }
      try Probe.require(
        Probe.sha(Data(contentsOf: owned(legacy.appendingPathComponent(leaf), in: legacy))) == hash)
    }
    let original = try Probe.dictionary(legacy.appendingPathComponent("run.json"))
    try Probe.require(original["runUUID"] as? String == legacyID)
    let output = scratch.appendingPathComponent(
      purpose == "diagnostic-only" ? "diagnostic.machine.json" : "namespace.machine.json")
    try Probe.require(!FileManager.default.fileExists(atPath: output.path))
    try Probe.require(
      (try? FileManager.default.destinationOfSymbolicLink(atPath: output.path)) == nil)
    return DiagnosticContext(
      root: scratch, legacyRoot: legacy, manifest: value,
      manifestSHA: expected, output: output, purpose: purpose)
  }
  static func validateEarly(
    _ context: DiagnosticContext, arguments: [String], hooks: DiagnosticHooks, stage: inout String
  ) throws -> ProbeRequest {
    try Probe.require(
      arguments.count == 5 && arguments[1] == "--request" && arguments[3] == "--request-sha")
    stage = "request"
    let requestURL = URL(fileURLWithPath: arguments[2])
    try Probe.require(
      requestURL.path
        == context.legacyRoot.appendingPathComponent("private/save-a.request.json").path)
    let raw = try Data(contentsOf: owned(requestURL, in: context.legacyRoot))
    try Probe.require(Probe.sha(raw) == arguments[4])
    let requestKeys = Set(try Probe.dictionary(requestURL).keys)
    let requiredKeys: Set<String> = [
      "runUUID", "phase", "root", "service", "group", "account", "clientID", "manifestSHA256",
      "identitySHA256", "compiledMarker",
    ]
    try Probe.require(
      requiredKeys.isSubset(of: requestKeys)
        && requestKeys.isSubset(of: requiredKeys.union(["recoveryUUID"])))
    let request = try JSONDecoder().decode(ProbeRequest.self, from: raw)
    try Probe.require(
      request.phase == "save-a" && request.recoveryUUID == nil && !request.compiledMarker)
    stage = "root"
    try Probe.require(request.runUUID == legacyID && request.root == context.legacyRoot.path)
    try Probe.require(request.service == "local.rivet.github.oauth.validation." + legacyID)
    try Probe.require(
      request.account == "credential" && request.clientID == "rivet-validation-fake-client")
    try Probe.require(request.manifestSHA256 == context.manifest["legacyManifestSHA256"] as? String)
    let original = try Probe.dictionary(context.legacyRoot.appendingPathComponent("run.json"))
    try Probe.require(
      original["service"] as? String == request.service
        && original["account"] as? String == request.account)
    try Probe.require(
      original["fixedApp"] as? String
        == context.legacyRoot.appendingPathComponent("current/CredentialStorageProbe.app").path)
    stage = "source"
    for key in ["sources", "copiedSources"] {
      guard let hashes = original[key] as? [String: String], !hashes.isEmpty else {
        throw ProbeFailure.guardRejected
      }
      for (path, hash) in hashes {
        let url = URL(fileURLWithPath: path)
        try Probe.require(url.resolvingSymlinksInPath().path == path)
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        try Probe.require((attributes[.ownerAccountID] as? NSNumber)?.uint32Value == getuid())
        try Probe.require(Probe.sha(Data(contentsOf: url)) == hash)
      }
    }
    stage = "identity"
    try Probe.require(request.identitySHA256 == context.manifest["legacyIdentitySHA256"] as? String)
    let identity = try Probe.dictionary(
      context.legacyRoot.appendingPathComponent("identity.json"))
    try Probe.require(
      identity["group"] as? String == request.group && !request.group.isEmpty
        && !request.group.contains("*"))
    let project = try owned(
      context.legacyRoot.appendingPathComponent(
        "project/CredentialStorageProbe.xcodeproj/project.pbxproj"), in: context.legacyRoot)
    try Probe.require(
      identity["projectSHA256"] as? String == Probe.sha(Data(contentsOf: project)))
    stage = "bundle"
    try Probe.require(hooks.bundleURL().path == context.manifest["expectedApp"] as? String)
    try Probe.require(hooks.bundleID() == identity["appID"] as? String)
    stage = "entitlement"
    try Probe.require(try hooks.entitlementGroups() == [request.group])
    return request
  }
  static func execute(
    environment: [String: String], arguments: [String], hooks: DiagnosticHooks
  ) async {
    guard let context = try? bootstrap(environment) else { return }
    let manifest = context.manifest
    var stage = "args"
    var receipt: [String: Any] = [
      "schemaVersion": 1, "diagnosticUUID": manifest["diagnosticUUID"]!, "legacyRunUUID": legacyID,
      "purpose": context.purpose, "status": "unknown", "manifestSHA256": context.manifestSHA,
      "binarySHA256": manifest["binarySHA256"]!, "diagnosticCopy": true,
    ]
    let sources = (manifest["sourceHashes"] as? [String: String]) ?? [:]
    receipt["sourceSHA256"] =
      (try? JSONSerialization.data(withJSONObject: sources, options: [.sortedKeys])).map(Probe.sha)
    do {
      let request = try validateEarly(context, arguments: arguments, hooks: hooks, stage: &stage)
      if context.purpose == "namespace-read-only" {
        do {
          let present = try await hooks.load(request.group, request.service) != nil
          receipt["state"] = present ? "present" : "absent"
          receipt["status"] = present ? "failure" : "success"
        } catch {
          let kind = Probe.failureKind(error)
          let states = [
            "credentialDenied": "denied", "credentialUnavailable": "unavailable",
            "credentialCorrupt": "corrupt", "identityMismatch": "identityMismatch",
          ]
          receipt["state"] = states[kind] ?? "unknown"
          receipt["status"] = "failure"
          receipt["failureKind"] = "unavailable"
        }
      } else {
        receipt["status"] = "success"
      }
      stage = "completed"
    } catch {
      receipt["status"] = "failure"
      receipt["failureKind"] = stage == "args" || stage == "request" ? "input" : "guard"
    }
    receipt["stage"] = stage
    try? Probe.exclusiveJSON(receipt, at: context.output)
  }
  static func run() async {
    await execute(
      environment: ProcessInfo.processInfo.environment, arguments: CommandLine.arguments,
      hooks: .live)
  }
}
private struct DiagnosticFakeFixture {
  let base: URL
  let root: URL
  let legacy: URL
  let id = UUID().uuidString.lowercased()
  let store: FakeProbeStore
  let trace = FakeTrace()
  let purpose: String
  init(purpose: String = "diagnostic-only", present: Bool = false) throws {
    self.purpose = purpose
    base = FileManager.default.temporaryDirectory.appendingPathComponent(
      "rivet-diagnostic-fakes-" + UUID().uuidString.lowercased()
    ).resolvingSymlinksInPath()
    root = base.appendingPathComponent("rivet-credential-storage-diagnostic-" + id)
    legacy = base.appendingPathComponent("rivet-credential-storage-" + DiagnosticProbe.legacyID)
    store = FakeProbeStore(present ? Probe.fixture(false) : nil, trace: trace)
    for url in [root, legacy] {
      try FileManager.default.createDirectory(
        at: url, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    }
    for leaf in DiagnosticProbe.sourceLeaves {
      try write(root.appendingPathComponent("source/" + leaf), Data("fixture-source".utf8))
    }
    try write(
      root.appendingPathComponent(
        "app/CredentialStorageProbe.app/Contents/MacOS/CredentialStorageProbe"),
      Data("fixture-binary".utf8))
    try write(
      legacy.appendingPathComponent("project/CredentialStorageProbe.xcodeproj/project.pbxproj"),
      Data("fixture-project".utf8))
    try write(legacy.appendingPathComponent("source.txt"), Data("legacy-source".utf8))
    try json(
      legacy.appendingPathComponent("identity.json"),
      [
        "group": "TEAM.fixture", "appID": "local.rivet.fixture",
        "projectSHA256": Probe.sha(Data("fixture-project".utf8)),
      ])
    let source = legacy.appendingPathComponent("source.txt")
    try json(
      legacy.appendingPathComponent("run.json"),
      [
        "runUUID": DiagnosticProbe.legacyID,
        "service": "local.rivet.github.oauth.validation." + DiagnosticProbe.legacyID,
        "account": "credential",
        "fixedApp": legacy.appendingPathComponent("current/CredentialStorageProbe.app").path,
        "sources": [source.path: Probe.sha(try Data(contentsOf: source))],
        "copiedSources": [source.path: Probe.sha(try Data(contentsOf: source))],
      ])
    try json(
      legacy.appendingPathComponent("private/save-a.public-machine.json"), ["status": "unknown"])
    try json(legacy.appendingPathComponent("private/save-a.human.json"), ["promptCount": 0])
    try refresh()
  }
  func write(_ url: URL, _ bytes: Data) throws {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o700])
    try bytes.write(to: url)
  }
  func json(_ url: URL, _ value: [String: Any]) throws {
    try write(url, JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]))
  }
  func refresh() throws {
    let manifestURL = legacy.appendingPathComponent("run.json")
    let identityURL = legacy.appendingPathComponent("identity.json")
    try json(
      legacy.appendingPathComponent("private/save-a.request.json"),
      [
        "runUUID": DiagnosticProbe.legacyID, "phase": "save-a", "root": legacy.path,
        "service": "local.rivet.github.oauth.validation." + DiagnosticProbe.legacyID,
        "account": "credential", "group": "TEAM.fixture",
        "clientID": "rivet-validation-fake-client",
        "manifestSHA256": Probe.sha(try Data(contentsOf: manifestURL)),
        "identitySHA256": Probe.sha(try Data(contentsOf: identityURL)), "compiledMarker": false,
      ])
    var sources: [String: String] = [:]
    for leaf in DiagnosticProbe.sourceLeaves {
      let url = root.appendingPathComponent("source/" + leaf)
      sources[url.path] = Probe.sha(try Data(contentsOf: url))
    }
    try json(
      root.appendingPathComponent("diagnostic.json"),
      [
        "schemaVersion": 1, "diagnosticUUID": id, "legacyRunUUID": DiagnosticProbe.legacyID,
        "purpose": purpose, "legacyRoot": legacy.path,
        "expectedApp": root.appendingPathComponent("app/CredentialStorageProbe.app").path,
        "sourceHashes": sources, "binarySHA256": Probe.sha(Data("fixture-binary".utf8)),
        "legacyManifestSHA256": Probe.sha(try Data(contentsOf: manifestURL)),
        "legacyIdentitySHA256": Probe.sha(try Data(contentsOf: identityURL)),
        "legacySaveMachineSHA256": Probe.sha(
          try Data(contentsOf: legacy.appendingPathComponent("private/save-a.public-machine.json"))),
        "legacySaveHumanSHA256": Probe.sha(
          try Data(contentsOf: legacy.appendingPathComponent("private/save-a.human.json"))),
      ])
  }
  var output: URL {
    root.appendingPathComponent(
      purpose == "diagnostic-only" ? "diagnostic.machine.json" : "namespace.machine.json")
  }
  func environment() throws -> [String: String] {
    let url = root.appendingPathComponent("diagnostic.json")
    return [
      "RIVET_DIAGNOSTIC_MANIFEST": url.path,
      "RIVET_DIAGNOSTIC_SHA256": Probe.sha(try Data(contentsOf: url)),
    ]
  }
  func arguments() throws -> [String] {
    let url = legacy.appendingPathComponent("private/save-a.request.json")
    return [
      "fixture", "--request", url.path, "--request-sha", Probe.sha(try Data(contentsOf: url)),
    ]
  }
  func hooks(
    bundleFailure: Bool = false, entitlementFailure: Bool = false,
    readError: GitHubOAuthDataProtectionStoreError? = nil
  ) -> DiagnosticHooks {
    DiagnosticHooks(
      bundleURL: {
        bundleFailure
          ? root.appendingPathComponent("wrong.app")
          : root.appendingPathComponent("app/CredentialStorageProbe.app")
      },
      bundleID: { "local.rivet.fixture" },
      entitlementGroups: { entitlementFailure ? [] : ["TEAM.fixture"] },
      load: { group, service in
        try Probe.require(
          group == "TEAM.fixture"
            && service == "local.rivet.github.oauth.validation." + DiagnosticProbe.legacyID)
        if let readError {
          trace.append("load")
          throw readError
        }
        return try await store.load()
      })
  }
  func dispose() { try? FileManager.default.removeItem(at: base) }
}
private enum DiagnosticFakeChecks {
  static let ids = [
    "bootstrap-sha-zero-output", "bootstrap-purpose-zero-output", "bootstrap-path-zero-output",
    "exclusive-receipt", "args-failure", "request-failure", "identity-failure", "bundle-failure",
    "entitlement-failure", "source-failure", "diagnostic-zero-load", "readonly-absent",
    "readonly-present", "readonly-error-zero-write", "bootstrap-schema-zero-output",
    "bootstrap-uuid-zero-output", "bootstrap-symlink-zero-output", "root-failure",
    "readonly-denied", "readonly-unavailable", "readonly-corrupt", "readonly-identityMismatch",
  ]
  static func prepareBootstrap(
    _ id: String, fixture: DiagnosticFakeFixture, environment: inout [String: String]
  ) throws {
    if id == "bootstrap-sha-zero-output" {
      environment["RIVET_DIAGNOSTIC_SHA256"] = String(repeating: "f", count: 64)
    }
    if id == "bootstrap-purpose-zero-output" {
      var value = try Probe.dictionary(fixture.root.appendingPathComponent("diagnostic.json"))
      value["purpose"] = "save-a"
      try fixture.json(fixture.root.appendingPathComponent("diagnostic.json"), value)
      environment = try fixture.environment()
    }
    if id == "bootstrap-path-zero-output" {
      var value = try Probe.dictionary(fixture.root.appendingPathComponent("diagnostic.json"))
      value["expectedApp"] = fixture.base.appendingPathComponent("outside.app").path
      try fixture.json(fixture.root.appendingPathComponent("diagnostic.json"), value)
      environment = try fixture.environment()
    }
    if id == "bootstrap-schema-zero-output" || id == "bootstrap-uuid-zero-output" {
      var value = try Probe.dictionary(fixture.root.appendingPathComponent("diagnostic.json"))
      if id == "bootstrap-schema-zero-output" {
        value["schemaVersion"] = 1.5
      } else {
        value["diagnosticUUID"] = "invalid"
      }
      try fixture.json(fixture.root.appendingPathComponent("diagnostic.json"), value)
      environment = try fixture.environment()
    }
    if id == "bootstrap-symlink-zero-output" {
      let path = fixture.root.appendingPathComponent("source/README.md")
      let other = fixture.root.appendingPathComponent("source/kept-source")
      try FileManager.default.moveItem(at: path, to: other)
      try FileManager.default.createSymbolicLink(at: path, withDestinationURL: other)
    }
  }
  static func check(_ id: String) async throws {
    let fixture = try DiagnosticFakeFixture(
      purpose: id.hasPrefix("readonly-") ? "namespace-read-only" : "diagnostic-only",
      present: id == "readonly-present")
    defer { fixture.dispose() }
    var environment = try fixture.environment()
    var arguments = try fixture.arguments()
    try prepareBootstrap(id, fixture: fixture, environment: &environment)
    if id == "root-failure" {
      var value = try Probe.dictionary(fixture.legacy.appendingPathComponent("run.json"))
      value["service"] = "PRIVATE_NEVER_EXPORT"
      try fixture.json(fixture.legacy.appendingPathComponent("run.json"), value)
      try fixture.refresh()
      environment = try fixture.environment()
      arguments = try fixture.arguments()
    }
    if id == "exclusive-receipt" { try fixture.write(fixture.output, Data("keep".utf8)) }
    if id == "args-failure" { arguments = ["bad"] }
    if id == "request-failure" {
      try fixture.write(
        fixture.legacy.appendingPathComponent("private/save-a.request.json"), Data("invalid".utf8))
      arguments = try fixture.arguments()
    }
    if id == "identity-failure" {
      var value = try Probe.dictionary(fixture.legacy.appendingPathComponent("identity.json"))
      value["group"] = "PRIVATE_NEVER_EXPORT"
      try fixture.json(fixture.legacy.appendingPathComponent("identity.json"), value)
      try fixture.refresh()
      environment = try fixture.environment()
      arguments = try fixture.arguments()
    }
    if id == "source-failure" {
      try fixture.write(fixture.legacy.appendingPathComponent("source.txt"), Data("changed".utf8))
    }
    if id == "readonly-error-zero-write" { fixture.store.configure(readFailure: true) }
    let errors: [String: GitHubOAuthDataProtectionStoreError] = [
      "readonly-denied": .denied, "readonly-unavailable": .unavailable,
      "readonly-corrupt": .corrupt, "readonly-identityMismatch": .identityMismatch,
    ]
    await DiagnosticProbe.execute(
      environment: environment, arguments: arguments,
      hooks: fixture.hooks(
        bundleFailure: id == "bundle-failure", entitlementFailure: id == "entitlement-failure",
        readError: errors[id]))
    try verify(id, fixture: fixture)
  }
  static func verify(_ id: String, fixture: DiagnosticFakeFixture) throws {
    if id.hasPrefix("bootstrap-") {
      try Probe.require(!FileManager.default.fileExists(atPath: fixture.output.path))
    } else if id == "exclusive-receipt" {
      try Probe.require(try Data(contentsOf: fixture.output) == Data("keep".utf8))
    } else {
      let receipt = try Probe.dictionary(fixture.output)
      let raw = try Data(contentsOf: fixture.output)
      guard let text = String(bytes: raw, encoding: .utf8) else { throw ProbeFailure.guardRejected }
      try Probe.require(!text.contains("PRIVATE_NEVER_EXPORT"))
      try Probe.require(!text.contains(fixture.base.path))
      let stages = [
        "args-failure": "args", "request-failure": "request", "identity-failure": "identity",
        "source-failure": "source", "bundle-failure": "bundle",
        "entitlement-failure": "entitlement", "root-failure": "root",
      ]
      if let stage = stages[id] {
        try Probe.require(
          receipt["stage"] as? String == stage && receipt["status"] as? String == "failure")
      } else if id == "readonly-absent" {
        try Probe.require(
          receipt["state"] as? String == "absent" && receipt["status"] as? String == "success")
      } else if id == "readonly-present" {
        try Probe.require(
          receipt["state"] as? String == "present" && receipt["status"] as? String == "failure")
      } else if id == "readonly-error-zero-write" {
        try Probe.require(
          receipt["state"] as? String == "unknown" && receipt["status"] as? String == "failure")
      } else if id.hasPrefix("readonly-") {
        try Probe.require(
          receipt["state"] as? String == String(id.dropFirst("readonly-".count))
            && receipt["status"] as? String == "failure")
      } else {
        try Probe.require(receipt["status"] as? String == "success")
      }
      let attributes = try FileManager.default.attributesOfItem(atPath: fixture.output.path)
      try Probe.require((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
    }
    try Probe.require(fixture.trace.snapshot == (id.hasPrefix("readonly-") ? ["load"] : []))
    for leaf in ["private/absence.json", "private/write-attempt.json"] {
      let url = fixture.legacy.appendingPathComponent(leaf)
      try Probe.require(!FileManager.default.fileExists(atPath: url.path))
    }
  }
  static func run() async {
    var failures: [String] = []
    for id in ids {
      do { try await check(id) } catch { failures.append(id) }
    }
    let report: [String: Any] = [
      "mode": "diagnostic-fake-only", "caseIDs": ids,
      "passed": ids.count - failures.count, "failures": failures,
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]),
      let text = String(data: data, encoding: .utf8)
    else { exit(1) }
    print(text)
    if !failures.isEmpty { exit(1) }
  }
}
// Isolated launch reporting has no credential, provider, entitlement, or Security hooks.
private enum LaunchReportFailure: Error { case timeout, recorded }

private struct LaunchReportInstance {
  let pid: Int
  let seconds: UInt64
  let microseconds: UInt64
}

private struct LaunchReportHooks {
  var evidenceMode = "signed-host"
  var windowSample: @Sendable () throws -> DPKWindowSample = { try DPKWindowSample.live() }
  var operation: ((LaunchReportBootstrap) throws -> [String: Any])?
  var checkpoint: (String) -> Void = { _ in }
  var executable: () throws -> URL
  var instance: () throws -> LaunchReportInstance
  var wall: () -> Int64
  var monotonic: () -> TimeInterval
  var sleep: () throws -> Void

  static var live: Self {
    Self(
      executable: {
        guard let url = Bundle.main.executableURL else { throw ProbeFailure.guardRejected }
        return url
      },
      instance: {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        let count = proc_pidinfo(getpid(), PROC_PIDTBSDINFO, 1, &info, size)
        try Probe.require(
          count == size && info.pbi_pid == UInt32(getpid()) && info.pbi_uid == getuid())
        try Probe.require([2, 3, 4].contains(info.pbi_status) && info.pbi_start_tvsec > 0)
        try Probe.require(info.pbi_start_tvusec < 1_000_000)
        return LaunchReportInstance(
          pid: Int(getpid()), seconds: info.pbi_start_tvsec, microseconds: info.pbi_start_tvusec)
      },
      wall: { Int64(Date().timeIntervalSince1970 * 1_000_000) },
      monotonic: { ProcessInfo.processInfo.systemUptime },
      sleep: { Thread.sleep(forTimeInterval: 0.01) })
  }
}

private struct LaunchReportBootstrap {
  let root: URL
  var attemptPrefix: String {
    guard let phase = binding["phase"] as? String else { return "attempt" }
    return "phases/" + phase
  }
  let binding: [String: Any]
  let created: Int64
  let contextSHA: String
  let binarySHA: String
  let wire: [String: Any]
  var diagnostic: [String: Any] {
    binding.merging([
      "stage": "bootstrap", "outcome": "entered", "wire": wire,
      "observedBinarySHA256": NSNull(), "pid": NSNull(), "startSeconds": NSNull(),
      "startMicroseconds": NSNull(),
    ]) { _, new in new }
  }
}

private enum LaunchReportFiles {
  static func physicalPath(_ path: String) throws -> String {
    try Probe.require(path.hasPrefix("/") && !path.contains("//"))
    try Probe.require(!path.split(separator: "/").contains { $0 == "." || $0 == ".." })
    guard let resolved = realpath(path, nil) else { throw ProbeFailure.guardRejected }
    defer { free(resolved) }
    return String(cString: resolved)
  }
  static func secureOwned(_ url: URL, in root: URL) throws {
    let path = url.path
    try Probe.require(path == root.path || path.hasPrefix(root.path + "/"))
    // Foundation standardization aliases /private away on this host; POSIX realpath is the physical criterion.
    try Probe.require(physicalPath(path) == path && physicalPath(root.path) == root.path)
    var cursor = root.path
    let components = String(path.dropFirst(root.path.count)).split(separator: "/")
    for part in [""] + components.map(String.init) {
      if !part.isEmpty { cursor += "/" + part }
      var info = stat()
      try Probe.require(lstat(cursor, &info) == 0 && info.st_mode & S_IFMT != S_IFLNK)
      try Probe.require(info.st_uid == getuid())
    }
  }
  static func secureRoot(_ url: URL, name: String) throws {
    try Probe.require(url.lastPathComponent == name)
    try secureOwned(url, in: url)
    var info = stat()
    try Probe.require(lstat(url.path, &info) == 0 && info.st_mode & S_IFMT == S_IFDIR)
    try Probe.require(info.st_mode & 0o777 == 0o700)
  }
}

private typealias LaunchReportWire = (value: [String: Any], pair: [String]?)

private enum LaunchReportWireProtocol {
  static func parse(_ arguments: [String], _ environment: [String: String]) -> LaunchReportWire {
    let expected =
      arguments.count == 5 && arguments[0] == LaunchReport.sentinel
      && arguments[1] == "--request" && arguments[3] == "--request-sha"
    let argvValid = expected && !arguments[2].isEmpty && DiagnosticProbe.isHash(arguments[4])
    let argvState =
      argvValid
      ? "valid"
      : arguments.isEmpty
        ? "missing"
        : arguments.contains("--request") || arguments.contains("--request-sha")
          ? "partial" : "invalid"
    let path = environment[LaunchReport.requestKey]
    let hash = environment[LaunchReport.hashKey]
    let envState =
      path == nil && hash == nil
      ? "missing"
      : path == nil || hash == nil
        ? "partial"
        : !(path!.isEmpty) && DiagnosticProbe.isHash(hash!) ? "valid" : "invalid"
    let argvPair = argvValid ? [arguments[2], arguments[4]] : nil
    let envPair = envState == "valid" ? [path!, hash!] : nil
    return (
      [
        "argvShape": expected && argvValid ? "expected" : arguments.isEmpty ? "missing" : "invalid",
        "argvPair": argvState, "envPair": envState,
        "channelsMatch": argvPair != nil && envPair != nil ? argvPair == envPair : NSNull(),
      ],
      argvPair ?? envPair
    )
  }
}

private enum LaunchReport {
  #if DPK_VALIDATION_ONLY
    static let isDPK = true
  #else
    static let isDPK = false
  #endif
  static let purpose = isDPK ? "dpk-credential-validation" : "launch-report-only"
  static let requestKey = isDPK ? "RIVET_DPK_REQUEST" : "RIVET_LAUNCH_REPORT_REQUEST"
  static let hashKey = isDPK ? "RIVET_DPK_REQUEST_SHA256" : "RIVET_LAUNCH_REPORT_REQUEST_SHA256"
  static let sentinel = isDPK ? "--dpk-validation-only" : "--launch-binding-only"
  static let bindingKeys: Set<String> = Set([
    "schemaVersion", "purpose", "attemptUUID", "contextSHA256", "requestSHA256",
    "expectedBinarySHA256",
  ]).union(isDPK ? ["roundSHA256", "phase"] : [])
  static let sources = [
    "CredentialStorageProbe.xcodeproj/project.pbxproj",
    "CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbe.xcscheme",
    "CredentialStorageProbe.xcodeproj/xcshareddata/xcschemes/CredentialStorageProbeRebuilt.xcscheme",
    "Sources/main.swift", "Resources/Info.plist", "Resources/CredentialStorageProbe.entitlements",
    "scripts/credential_storage_live.py", "Tests/test_live_protocol.py", "README.md",
  ]
  static func selected(_ arguments: [String], _ environment: [String: String]) -> Bool {
    arguments.contains(sentinel) || environment[requestKey] != nil || environment[hashKey] != nil
  }
  static func integer(_ value: Any?) throws -> Int64 {
    guard let number = value as? NSNumber,
      CFGetTypeID(number) != CFBooleanGetTypeID(),
      ["i", "q"].contains(String(cString: number.objCType))
    else { throw ProbeFailure.guardRejected }
    return number.int64Value
  }
  static func keys(_ value: [String: Any], _ expected: Set<String>) throws {
    try Probe.require(Set(value.keys) == expected)
    try Probe.require(
      integer(value["schemaVersion"]) == 1 && value["purpose"] as? String == purpose)
    for (key, item) in value where key.hasSuffix("SHA256") {
      guard let text = item as? String, DiagnosticProbe.isHash(text) else {
        throw ProbeFailure.guardRejected
      }
    }
  }
  static func file(_ url: URL, _ root: URL, executable: Bool = false) throws -> URL {
    try LaunchReportFiles.secureOwned(url, in: root)
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    let mode = (attributes[.posixPermissions] as? NSNumber)?.intValue ?? -1
    try Probe.require(attributes[.type] as? FileAttributeType == .typeRegular)
    try Probe.require(executable ? mode >= 0 && mode & 0o022 == 0 : mode == 0o600)
    return url
  }
  static func read(_ url: URL, _ root: URL) throws -> (value: [String: Any], sha: String) {
    _ = try file(url, root)
    let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW)
    try Probe.require(descriptor >= 0)
    defer { close(descriptor) }
    var info = stat()
    try Probe.require(fstat(descriptor, &info) == 0 && info.st_uid == getuid())
    try Probe.require(info.st_mode & S_IFMT == S_IFREG && info.st_mode & 0o777 == 0o600)
    try Probe.require(info.st_size >= 0 && info.st_size <= 65_536)
    var raw = Data(count: Int(info.st_size))
    try raw.withUnsafeMutableBytes { bytes in
      var offset = 0
      while offset < bytes.count {
        let count = Darwin.read(
          descriptor, bytes.baseAddress!.advanced(by: offset), bytes.count - offset)
        try Probe.require(count > 0)
        offset += count
      }
    }
    guard let value = try JSONSerialization.jsonObject(with: raw) as? [String: Any] else {
      throw ProbeFailure.guardRejected
    }
    return (value, Probe.sha(raw))
  }
  static func same(_ value: [String: Any], _ expected: [String: Any]) throws {
    for (key, item) in expected {
      guard let actual = value[key] else { throw ProbeFailure.guardRejected }
      try Probe.require(NSDictionary(dictionary: [key: actual]).isEqual(to: [key: item]))
    }
  }
  static func publish(
    _ value: [String: Any], root: URL, leaf: String, prefix: String = "attempt"
  ) throws -> String {
    try Probe.require(["host.entry", "host.failure", "host.report", "host.final"].contains(leaf))
    let pending = root.appendingPathComponent(prefix + "/" + leaf + ".pending.json")
    let final = root.appendingPathComponent(prefix + "/" + leaf + ".json")
    try Probe.require(!FileManager.default.fileExists(atPath: final.path))
    try Probe.exclusiveJSON(value, at: pending)
    let sha = Probe.sha(try Data(contentsOf: file(pending, root)))
    let descriptor = open(pending.deletingLastPathComponent().path, O_RDONLY | O_NOFOLLOW)
    try Probe.require(descriptor >= 0)
    defer { close(descriptor) }
    try Probe.require(fsync(descriptor) == 0)
    try Probe.require(link(pending.path, final.path) == 0)
    return sha  // No fallible I/O after publication.
  }
  static func acknowledged(
    _ root: URL, expected: [String: Any], prefix: String = "attempt"
  ) throws -> String? {
    let final = root.appendingPathComponent(prefix + "/ack.json")
    guard FileManager.default.fileExists(atPath: final.path) else { return nil }
    let pending = root.appendingPathComponent(prefix + "/ack.pending.json")
    _ = try file(final, root)
    _ = try file(pending, root)
    var left = stat()
    var right = stat()
    try Probe.require(lstat(final.path, &left) == 0 && lstat(pending.path, &right) == 0)
    try Probe.require(left.st_dev == right.st_dev && left.st_ino == right.st_ino)
    let receipt = try read(final, root)
    try Probe.require(Data(contentsOf: pending) == Data(contentsOf: final))
    try keys(receipt.value, bindingKeys.union(["hostReportSHA256"]))
    try same(receipt.value, expected)
    return receipt.sha
  }
  static let certificateSHA = "5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440"
  static let proofCommon: Set<String> = ["schemaVersion", "purpose", "variant", "evidenceMode"]
  static func proofBoolean(_ value: Any?, equals expected: Bool) throws {
    guard let number = value as? NSNumber else { throw ProbeFailure.guardRejected }
    try Probe.require(CFGetTypeID(number) == CFBooleanGetTypeID() && number.boolValue == expected)
  }
  static func verifyContext(
    root: URL, binding: [String: Any], contextSHA: String, binarySHA: String, mode: String,
    checkpoint: (String) -> Void = { _ in }, window: DPKWindow? = nil
  ) throws {
    let context = try read(
      root.appendingPathComponent(
        isDPK && Probe.compiledMarker ? "context-rebuilt.json" : "context.json"), root)
    try Probe.require(context.sha == contextSHA)
    try keys(
      context.value,
      Set([
        "schemaVersion", "purpose", "contextUUID", "sourceHashes",
        "expectedBinarySHA256", "buildProofSHA256", "signingProofSHA256",
      ]).union(isDPK ? ["roundSHA256", "profileSHA256"] : []).union(
        isDPK && context.value["authoritySHA256"] != nil ? ["authoritySHA256"] : []))
    guard let contextID = context.value["contextUUID"] as? String,
      let hashes = context.value["sourceHashes"] as? [String: String]
    else { throw ProbeFailure.guardRejected }
    try DiagnosticProbe.uuid(contextID)
    try Probe.require(
      Set(hashes.keys) == Set(sources)
        && context.value["expectedBinarySHA256"] as? String == binarySHA)
    checkpoint("source")
    for (leaf, hash) in hashes {
      try Probe.require(DiagnosticProbe.isHash(hash))
      let raw = try Data(contentsOf: file(root.appendingPathComponent("source/" + leaf), root))
      try Probe.require(Probe.sha(raw) == hash)
    }
    checkpoint("proof")
    try verifyProofs(root, context: context.value, binarySHA: binarySHA, mode: mode)
    if isDPK {
      try DPKValidation.verify(
        root: root, binding: binding, context: context.value, mode: mode, window: window)
    }
    let consumedPath =
      isDPK
      ? "phases/" + (binding["phase"] as? String ?? "invalid") + "/binding-consumed.json"
      : "binding-consumed.json"
    let consumed = try read(root.appendingPathComponent(consumedPath), root)
    try keys(
      consumed.value,
      bindingKeys.union(["readyUUID", "readyConfirmed", "runnerSHA256", "evidenceMode"]))
    try same(consumed.value, binding)
    guard let ready = consumed.value["readyUUID"] as? String,
      let confirmed = consumed.value["readyConfirmed"] as? NSNumber,
      let consumedMode = consumed.value["evidenceMode"] as? String
    else { throw ProbeFailure.guardRejected }
    try DiagnosticProbe.uuid(ready)
    try Probe.require(CFGetTypeID(confirmed) == CFBooleanGetTypeID() && confirmed.boolValue)
    try Probe.require(consumedMode == mode)
  }
  static func bootstrap(
    arguments: [String], environment: [String: String]
  ) throws -> LaunchReportBootstrap {
    let transport = LaunchReportWireProtocol.parse(arguments, environment)
    guard let pair = transport.pair else { throw ProbeFailure.guardRejected }
    let path = pair[0]
    let expected = pair[1]
    let requestURL = URL(fileURLWithPath: path)
    try Probe.require(requestURL.path == path && requestURL.lastPathComponent == "request.json")
    let attempt = requestURL.deletingLastPathComponent()
    try Probe.require(
      isDPK
        ? DPKValidation.phases.contains(attempt.lastPathComponent)
        : attempt.lastPathComponent == "attempt")
    let root =
      isDPK
      ? attempt.deletingLastPathComponent().deletingLastPathComponent()
      : attempt.deletingLastPathComponent()
    if isDPK {
      try Probe.require(attempt.deletingLastPathComponent().lastPathComponent == "phases")
    }
    try LaunchReportFiles.secureRoot(root, name: root.lastPathComponent)
    try LaunchReportFiles.secureRoot(attempt, name: attempt.lastPathComponent)
    let request = try read(requestURL, root)
    try Probe.require(request.sha == expected)
    try keys(
      request.value, bindingKeys.subtracting(["requestSHA256"]).union(["createdAtUnixMicroseconds"])
    )
    guard let id = request.value["attemptUUID"] as? String,
      let contextSHA = request.value["contextSHA256"] as? String,
      let binarySHA = request.value["expectedBinarySHA256"] as? String
    else { throw ProbeFailure.guardRejected }
    try DiagnosticProbe.uuid(id)
    if isDPK { try Probe.require(request.value["phase"] as? String == attempt.lastPathComponent) }
    let created = try integer(request.value["createdAtUnixMicroseconds"])
    try Probe.require(created > 0)
    var binding = request.value
    binding.removeValue(forKey: "createdAtUnixMicroseconds")
    binding["requestSHA256"] = expected
    return LaunchReportBootstrap(
      root: root, binding: binding, created: created, contextSHA: contextSHA,
      binarySHA: binarySHA, wire: transport.value)
  }
  static func complete(
    _ input: LaunchReportBootstrap, diagnostic: inout [String: Any], hooks: LaunchReportHooks,
    checkpoint: (String) -> Void
  ) throws {
    let root = input.root
    let binding = input.binding
    let created = input.created
    let contextSHA = input.contextSHA
    let binarySHA = input.binarySHA
    var phase = "clock"
    func mark(_ value: String) {
      phase = value
      checkpoint(value)
    }
    var lastObservedWall = created
    func observeWall() throws -> Int64 {
      let previousStage = phase
      mark("clock")
      let current = hooks.wall()
      try Probe.require(current >= lastObservedWall)
      lastObservedWall = current
      mark(previousStage)
      return current
    }
    let contextItem = try read(
      root.appendingPathComponent(
        isDPK && Probe.compiledMarker ? "context-rebuilt.json" : "context.json"), root)
    let window =
      isDPK && contextItem.value["authoritySHA256"] != nil
      ? try DPKWindow.read(root, mode: hooks.evidenceMode, sample: hooks.windowSample) : nil
    try window?.check(phase: binding["phase"] as? String)
    mark("clock")
    try Probe.require(observeWall() >= created)
    mark("context")
    try verifyContext(
      root: root, binding: binding, contextSHA: contextSHA, binarySHA: binarySHA,
      mode: hooks.evidenceMode, checkpoint: mark, window: window)
    mark("binary")
    let binary = root.appendingPathComponent(
      "app/CredentialStorageProbe.app/Contents/MacOS/CredentialStorageProbe")
    if isDPK { try DPKValidation.time(window: window, phase: binding["phase"] as? String) }
    let actual = try hooks.executable()
    try Probe.require(actual.path == binary.path)
    let observedBinary = Probe.sha(try Data(contentsOf: file(actual, root, executable: true)))
    diagnostic["observedBinarySHA256"] = observedBinary
    try Probe.require(observedBinary == binarySHA)
    mark("instance")
    if isDPK { try DPKValidation.time(window: window, phase: binding["phase"] as? String) }
    let instance = try hooks.instance()
    try Probe.require(
      instance.pid > 0 && instance.seconds > 0 && instance.microseconds < 1_000_000)
    diagnostic.merge([
      "pid": instance.pid, "startSeconds": instance.seconds,
      "startMicroseconds": instance.microseconds,
    ]) { _, new in new }
    mark("clock")
    let start = Int64(instance.seconds) * 1_000_000 + Int64(instance.microseconds)
    try Probe.require(created <= start && start <= observeWall())
    var report = binding
    report.merge([
      "observedBinarySHA256": binarySHA, "pid": instance.pid,
      "startSeconds": instance.seconds, "startMicroseconds": instance.microseconds,
      "processUUID": UUID().uuidString.lowercased(), "stage": "report", "outcome": "awaitingAck",
    ]) { _, new in new }
    mark("publish")
    let reportSHA = try publish(
      report, root: root, leaf: "host.report", prefix: input.attemptPrefix)
    try finish(
      input: input, reportSHA: reportSHA, hooks: hooks, observeWall: observeWall, checkpoint: mark,
      window: window)

  }
  static func finish(
    input: LaunchReportBootstrap, reportSHA: String, hooks: LaunchReportHooks,
    observeWall: () throws -> Int64, checkpoint: (String) -> Void, window: DPKWindow? = nil
  ) throws {
    let root = input.root
    let binding = input.binding
    let created = input.created
    var ackBinding = binding
    ackBinding["hostReportSHA256"] = reportSHA
    let deadline = hooks.monotonic() + 30
    checkpoint("ack")
    while hooks.monotonic() < deadline {
      if isDPK { try DPKValidation.time(window: window, phase: binding["phase"] as? String) }
      try Probe.require(observeWall() >= created)
      if let ackSHA = try acknowledged(root, expected: ackBinding, prefix: input.attemptPrefix) {
        var final = ackBinding
        final["ackSHA256"] = ackSHA
        final["outcome"] = "completed"
        if isDPK {
          checkpoint("operation")
          try DPKValidation.time(window: window, phase: binding["phase"] as? String)
          let before = try hooks.instance()
          let report = try read(
            root.appendingPathComponent(input.attemptPrefix + "/host.report.json"), root)
          try same(
            report.value,
            [
              "pid": before.pid, "startSeconds": before.seconds,
              "startMicroseconds": before.microseconds,
            ])
          final["operationResult"] =
            try hooks.operation?(input) ?? DPKValidation.perform(input, window: window)
          _ = try observeWall()
        }
        if isDPK { try DPKValidation.time(window: window, phase: binding["phase"] as? String) }
        checkpoint("publish")
        _ = try publish(final, root: root, leaf: "host.final", prefix: input.attemptPrefix)
        return
      }
      try hooks.sleep()
    }
    throw LaunchReportFailure.timeout
  }
  static func execute(
    arguments: [String], environment: [String: String], hooks: LaunchReportHooks
  ) throws {
    let input = try bootstrap(arguments: arguments, environment: environment)
    let root = input.root
    let transport = input.wire
    var diagnostic = input.diagnostic
    var stage = "publish"
    func mark(_ value: String) {
      stage = value
      hooks.checkpoint(value)
    }
    do {
      _ = try publish(diagnostic, root: root, leaf: "host.entry", prefix: input.attemptPrefix)
      mark("wire")
      try Probe.require(transport["argvShape"] as? String == "expected")
      try Probe.require(transport["argvPair"] as? String == "valid")
      try Probe.require(transport["envPair"] as? String == "valid")
      try Probe.require(transport["channelsMatch"] as? Bool == true)
      try Probe.require(
        environment.keys.filter {
          $0.hasPrefix("RIVET_") && ![requestKey, hashKey].contains($0)
        }.isEmpty)
      try complete(input, diagnostic: &diagnostic, hooks: hooks, checkpoint: mark)
    } catch {
      let kind =
        error is DPKWindowFailure
        ? "deadline"
        : error is LaunchReportFailure
          ? "timeout"
          : [
            "wire": "input", "context": "binding", "source": "binding", "proof": "schema",
            "binary": "binary", "instance": "instance", "clock": "clock", "publish": "write",
            "ack": "binding", "operation": "operation",
          ][stage] ?? "other"
      diagnostic["stage"] = stage
      diagnostic["outcome"] =
        ["timeout", "write", "deadline"].contains(kind) ? "unknown" : "rejected"
      diagnostic["failureKind"] = kind
      _ = try publish(diagnostic, root: root, leaf: "host.failure", prefix: input.attemptPrefix)
      throw LaunchReportFailure.recorded
    }
  }
  static func run() {
    let arguments = Array(CommandLine.arguments.dropFirst())
    let environment = ProcessInfo.processInfo.environment
    do { try execute(arguments: arguments, environment: environment, hooks: .live) } catch {
      if case LaunchReportFailure.recorded = error { exit(1) }
      let transport = LaunchReportWireProtocol.parse(arguments, environment).value
      let value: [String: Any] = [
        "purpose": purpose, "stage": "bootstrap", "failureKind": "input",
        "argvShape": transport["argvShape"]!, "envPair": transport["envPair"]!,
      ]
      if let bytes = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) {
        FileHandle.standardError.write(bytes + Data([10]))
      }
      exit(1)
    }
  }
}

extension LaunchReport {
  fileprivate static func validateProof(_ value: [String: Any], kind: String, mode: String) throws {
    let buildKeys: Set<String> = [
      "sourceHashes", "compileConditions", "scheme", "configuration",
      "commandSHA256", "unsignedBinarySHA256", "buildSucceeded",
    ]
    let signKeys: Set<String> = [
      "buildProofSHA256", "binarySHA256", "certificateDER_SHA256",
      "teamIdentifierSHA256", "bundleIdentifierSHA256", "codeIdentifierSHA256",
      "designatedRequirementSHA256", "entitlementsEmpty", "embeddedProfilePresent",
      "signatureValid", "certificateValidNow",
    ]
    try Probe.require(["build", "signing"].contains(kind))
    try keys(
      value,
      proofCommon.union(kind == "build" ? buildKeys : signKeys).union(
        isDPK && kind == "signing" ? ["profileSHA256", "entitlementsSHA256", "groupSHA256"] : []
      ).union(isDPK && value["authoritySHA256"] != nil ? ["authoritySHA256"] : []))
    try Probe.require(value["variant"] as? String == (isDPK ? "dpk-entitled" : "profile-free"))
    try Probe.require(
      ["fake-only", "signed-host"].contains(mode) && value["evidenceMode"] as? String == mode)
    if kind == "build" {
      guard let sourceHashes = value["sourceHashes"] as? [String: String] else {
        throw ProbeFailure.guardRejected
      }
      try Probe.require(Set(sourceHashes.keys) == Set(sources))
      try Probe.require(sourceHashes.values.allSatisfy { DiagnosticProbe.isHash($0) })
      let flags =
        ["DEBUG", isDPK ? "DPK_VALIDATION_ONLY" : "LAUNCH_REPORT_ONLY"]
        + (isDPK && Probe.compiledMarker ? ["CREDENTIAL_STORAGE_REBUILT"] : [])
      try Probe.require(value["compileConditions"] as? [String] == flags)
      try Probe.require(
        value["scheme"] as? String
          == (isDPK && Probe.compiledMarker
            ? "CredentialStorageProbeRebuilt" : "CredentialStorageProbe")
          && value["configuration"] as? String
            == (isDPK && Probe.compiledMarker ? "Rebuilt" : "Debug")
      )
      try proofBoolean(value["buildSucceeded"], equals: true)
    } else {
      try Probe.require(value["certificateDER_SHA256"] as? String == certificateSHA)
      try proofBoolean(value["entitlementsEmpty"], equals: !isDPK)
      for key in ["signatureValid", "certificateValidNow"] {
        try proofBoolean(value[key], equals: true)
      }
      try proofBoolean(value["embeddedProfilePresent"], equals: isDPK)
    }
  }
  fileprivate static func verifyProofs(
    _ root: URL, context: [String: Any], binarySHA: String, mode: String
  ) throws {
    let build = try read(
      root.appendingPathComponent(
        isDPK && Probe.compiledMarker ? "rebuild.build.machine.json" : "build.machine.json"), root)
    let signing = try read(
      root.appendingPathComponent(
        isDPK && Probe.compiledMarker ? "rebuild.signing.machine.json" : "signing.machine.json"),
      root)
    try validateProof(build.value, kind: "build", mode: mode)
    try validateProof(signing.value, kind: "signing", mode: mode)
    if isDPK {
      try Probe.require(
        (build.value["authoritySHA256"] as? String) == (context["authoritySHA256"] as? String)
          && (signing.value["authoritySHA256"] as? String)
            == (context["authoritySHA256"] as? String)
      )
    }
    try Probe.require(context["buildProofSHA256"] as? String == build.sha)
    try Probe.require(context["signingProofSHA256"] as? String == signing.sha)
    try Probe.require(signing.value["buildProofSHA256"] as? String == build.sha)
    try Probe.require(signing.value["binarySHA256"] as? String == binarySHA)
    try same(build.value, ["sourceHashes": context["sourceHashes"]!])
  }
}

private struct DPKWindowSample: Sendable {
  let wall: Int64
  let monotonic: Int64
  let bootSHA: String
  static func bootHash(_ raw: Data) throws -> String {
    try Probe.require(raw.count == 37 && raw.last == 0)
    guard let text = String(data: raw.dropLast(), encoding: .ascii),
      text.range(
        of: "^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", options: .regularExpression)
        != nil,
      UUID(uuidString: text) != UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    else { throw ProbeFailure.guardRejected }
    return Probe.sha(Data(("rivet.dpk.boot-session.v1\n" + text.lowercased() + "\n").utf8))
  }
  static func live() throws -> Self {
    func boot() throws -> String {
      var bytes = [UInt8](repeating: 0, count: 64)
      var size = bytes.count
      let result = sysctlbyname("kern.bootsessionuuid", &bytes, &size, nil, 0)
      try Probe.require(result == 0 && size == 37)
      return try bootHash(Data(bytes.prefix(size)))
    }
    let first = try boot()
    var base = mach_timebase_info_data_t()
    try Probe.require(mach_timebase_info(&base) == 0 && base.numer > 0 && base.denom > 0)
    let ticks = mach_continuous_time()
    let quotient = ticks / UInt64(base.denom)
    let remainder = ticks % UInt64(base.denom)
    let (whole, overflow) = quotient.multipliedReportingOverflow(by: UInt64(base.numer))
    let (nanoseconds, additionOverflow) = whole.addingReportingOverflow(
      remainder * UInt64(base.numer) / UInt64(base.denom))
    try Probe.require(!overflow && !additionOverflow && nanoseconds <= UInt64(Int64.max))
    let wall = Int64(Date().timeIntervalSince1970)
    try Probe.require(first == boot())
    return Self(wall: wall, monotonic: Int64(nanoseconds), bootSHA: first)
  }
}

private final class DPKWindow: @unchecked Sendable {
  static let phases = [
    "sign-debug", "context", "save-a", "read-a", "replace-b", "read-b", "rebuild", "sign-rebuilt",
    "context-rebuilt", "rebuilt-read-b",
  ]
  static let fields: Set<String> = [
    "schemaVersion", "purpose", "evidenceMode", "windowUUID", "roundUUID", "descriptorSHA256",
    "humanAuthorizationSHA256", "startsAtUnixSeconds", "expiresAtUnixSeconds",
    "startsAtMonotonicNanoseconds", "expiresAtMonotonicNanoseconds", "bootSessionSHA256",
    "allowedPhases", "promptLimits",
  ]
  let value: [String: Any]
  let sha: String
  let start: Int64
  let end: Int64
  let monoStart: Int64
  let monoEnd: Int64
  let boot: String
  let sample: @Sendable () throws -> DPKWindowSample
  private let lock = NSLock()
  private var previous: DPKWindowSample?
  init(
    _ value: [String: Any], sha: String, mode: String,
    sample: @escaping @Sendable () throws -> DPKWindowSample = { try DPKWindowSample.live() }
  ) throws {
    try LaunchReport.keys(value, Self.fields)
    try Probe.require(DiagnosticProbe.isHash(sha))
    try Probe.require(
      ["signed-host", "fake-only"].contains(mode) && value["evidenceMode"] as? String == mode)
    for key in ["windowUUID", "roundUUID"] {
      guard let id = value[key] as? String else { throw ProbeFailure.guardRejected }
      try DiagnosticProbe.uuid(id)
    }
    start = try LaunchReport.integer(value["startsAtUnixSeconds"])
    end = try LaunchReport.integer(value["expiresAtUnixSeconds"])
    monoStart = try LaunchReport.integer(value["startsAtMonotonicNanoseconds"])
    monoEnd = try LaunchReport.integer(value["expiresAtMonotonicNanoseconds"])
    try Probe.require(
      start > 0 && monoStart > 0 && end > start && end - start <= 3600 && monoEnd > monoStart)
    try Probe.require(monoEnd - monoStart == (end - start) * 1_000_000_000)
    try Probe.require(value["allowedPhases"] as? [String] == Self.phases)
    guard let policy = value["promptLimits"] as? [String: Any],
      let boot = value["bootSessionSHA256"] as? String
    else { throw ProbeFailure.guardRejected }
    let expected = [
      "saveMaxPrompts": 1, "freshReadMaxPrompts": 0, "replaceMaxPrompts": 0,
      "buildSignMaxKeyAuthorizations": 1,
    ]
    try Probe.require(Set(policy.keys) == Set(expected.keys))
    for (key, limit) in expected {
      try Probe.require(LaunchReport.integer(policy[key]) == Int64(limit))
    }
    self.value = value
    self.sha = sha
    self.boot = boot
    self.sample = sample
  }
  static func read(
    _ root: URL, mode: String,
    sample: @escaping @Sendable () throws -> DPKWindowSample = { try DPKWindowSample.live() }
  ) throws -> DPKWindow {
    let item = try LaunchReport.read(root.appendingPathComponent("live-authority.json"), root)
    let window = try DPKWindow(item.value, sha: item.sha, mode: mode, sample: sample)
    try window.check()
    return window
  }
  func check(phase: String? = nil, reserve: TimeInterval = 0) throws {
    try Probe.require(phase == nil || Self.phases.contains(phase!))
    try Probe.require(reserve.isFinite && reserve >= 0 && reserve <= 3600)
    try lock.withLock {
      do {
        let current = try sample()
        try Probe.require(
          current.bootSHA == boot && current.wall >= start && current.monotonic >= monoStart)
        if let previous {
          try Probe.require(
            current.wall >= previous.wall && current.monotonic >= previous.monotonic)
        }
        try Probe.require(
          Double(current.wall) + reserve < Double(end)
            && Double(current.monotonic) + reserve * 1_000_000_000 < Double(monoEnd))
        previous = current
      } catch { throw DPKWindowFailure.deadline }
    }
  }
}
private enum DPKWindowFailure: Error { case deadline }

private final class DPKOperationBox: @unchecked Sendable {
  let done = DispatchSemaphore(value: 0)
  let lock = NSLock()
  var result: Result<Data, any Error>?
  func finish(_ value: Result<Data, any Error>) {
    lock.withLock { result = value }
    done.signal()
  }
  func read() throws -> [String: Any] {
    try Probe.require(done.wait(timeout: .now() + 30) == .success)
    let value = try lock.withLock { try result!.get() }
    guard let dictionary = try JSONSerialization.jsonObject(with: value) as? [String: Any] else {
      throw ProbeFailure.guardRejected
    }
    return dictionary
  }
}

private struct DPKDeadlineStore: OAuthCredentialStore {
  let underlying: any OAuthCredentialStore
  let window: DPKWindow?
  let phase: String
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    try DPKValidation.time(window: window, phase: phase)
    return try await underlying.load()
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    try DPKValidation.time(window: window, phase: phase)
    try await underlying.save(credential)
  }
}

private enum DPKValidation {
  static let phases = ["save-a", "read-a", "replace-b", "read-b", "rebuilt-read-b"]
  static let cutoff: TimeInterval = 1_793_786_789
  static func time(
    reserve: TimeInterval = 0, window: DPKWindow? = nil, phase: String? = nil
  ) throws {
    if let window {
      try window.check(phase: phase, reserve: reserve)
      return
    }
    try Probe.require(Date().timeIntervalSince1970 + reserve < cutoff)
  }
  static func round(_ root: URL) throws -> (value: [String: Any], sha: String) {
    let result = try LaunchReport.read(root.appendingPathComponent("round.json"), root)
    try LaunchReport.keys(
      result.value,
      Set([
        "schemaVersion", "purpose", "roundUUID", "service", "account", "clientID", "group",
        "deadlineUTC", "parentLG59MachineSHA256", "parentLG64ResultSHA256", "sourceHashes",
        "profileSHA256", "certificateSHA256", "initialBuildProofSHA256",
        "initialSigningProofSHA256",
      ]).union(result.value["authoritySHA256"] != nil ? ["authoritySHA256"] : []))
    guard let id = result.value["roundUUID"] as? String,
      let group = result.value["group"] as? String
    else { throw ProbeFailure.guardRejected }
    try DiagnosticProbe.uuid(id)
    try Probe.require(
      result.value["service"] as? String == "local.rivet.github.oauth.validation." + id)
    try Probe.require(
      result.value["account"] as? String == "credential"
        && result.value["clientID"] as? String == "rivet-validation-fake-client")
    try Probe.require(
      !group.isEmpty && !group.contains("*"))
    if result.value["authoritySHA256"] == nil {
      try Probe.require(result.value["deadlineUTC"] as? String == "2026-11-04T10:06:29Z")
    }
    try Probe.require(result.value["certificateSHA256"] as? String == LaunchReport.certificateSHA)
    return result
  }
  static func verify(
    root: URL, binding: [String: Any], context: [String: Any], mode: String,
    window: DPKWindow? = nil
  ) throws {
    try time(window: window, phase: binding["phase"] as? String)
    let item = try round(root)
    if let window {
      try Probe.require(
        context["authoritySHA256"] as? String == window.sha
          && item.value["authoritySHA256"] as? String == window.sha
          && item.value["roundUUID"] as? String == window.value["roundUUID"] as? String)
      let formatter = ISO8601DateFormatter()
      try Probe.require(
        item.value["deadlineUTC"] as? String
          == formatter.string(from: Date(timeIntervalSince1970: TimeInterval(window.end))))
    } else {
      try Probe.require(context["authoritySHA256"] == nil && item.value["authoritySHA256"] == nil)
    }
    try Probe.require(
      binding["roundSHA256"] as? String == item.sha && context["roundSHA256"] as? String == item.sha
    )
    guard let phase = binding["phase"] as? String,
      let profileSHA = item.value["profileSHA256"] as? String
    else { throw ProbeFailure.guardRejected }
    try Probe.require(phases.contains(phase) && (phase == "rebuilt-read-b") == Probe.compiledMarker)
    try Probe.require(context["profileSHA256"] as? String == profileSHA)
    let profile = try Data(
      contentsOf: LaunchReport.file(root.appendingPathComponent("profile.provisionprofile"), root))
    try Probe.require(Probe.sha(profile) == profileSHA)
    let signingName = Probe.compiledMarker ? "rebuild.signing.machine.json" : "signing.machine.json"
    let signing = try LaunchReport.read(root.appendingPathComponent(signingName), root).value
    guard let group = item.value["group"] as? String else { throw ProbeFailure.guardRejected }
    try Probe.require(
      signing["profileSHA256"] as? String == profileSHA
        && signing["groupSHA256"] as? String == Probe.sha(Data(group.utf8)))
    if mode == "signed-host" {
      let app = root.appendingPathComponent("app/CredentialStorageProbe.app")
      try Probe.require(
        Probe.sha(
          Data(
            contentsOf: LaunchReport.file(
              app.appendingPathComponent("Contents/embedded.provisionprofile"), root)))
          == profileSHA)
      guard let task = SecTaskCreateFromSelf(kCFAllocatorDefault),
        let groups = SecTaskCopyValueForEntitlement(task, "keychain-access-groups" as CFString, nil)
          as? [String],
        let appID = SecTaskCopyValueForEntitlement(
          task, "com.apple.application-identifier" as CFString, nil) as? String,
        let team = SecTaskCopyValueForEntitlement(
          task, "com.apple.developer.team-identifier" as CFString, nil) as? String
      else { throw ProbeFailure.guardRejected }
      try Probe.require(groups == [group] && appID == group)
      try Probe.require(signing["teamIdentifierSHA256"] as? String == Probe.sha(Data(team.utf8)))
    }
  }
  static func perform(
    _ input: LaunchReportBootstrap, store supplied: (any OAuthCredentialStore)? = nil,
    window: DPKWindow? = nil
  ) throws -> [String: Any] {
    try time(window: window, phase: input.binding["phase"] as? String)
    let item = try round(input.root)
    try Probe.require((item.value["authoritySHA256"] as? String) == window?.sha)
    guard let phase = input.binding["phase"] as? String,
      let id = item.value["roundUUID"] as? String,
      let group = item.value["group"] as? String, let service = item.value["service"] as? String
    else { throw ProbeFailure.guardRejected }
    let request = ProbeRequest(
      runUUID: id, phase: phase, root: input.root.path, service: service, group: group,
      account: "credential", clientID: "rivet-validation-fake-client", manifestSHA256: item.sha,
      identitySHA256: input.contextSHA, compiledMarker: Probe.compiledMarker, recoveryUUID: nil)
    let box = DPKOperationBox()
    let root = input.root
    Task.detached {
      do {
        let rawStore: any OAuthCredentialStore
        if let supplied {
          rawStore = supplied
        } else {
          rawStore = try GitHubOAuthDataProtectionStores(accessGroup: group, service: service)
            .credentialStore(clientID: request.clientID)
        }
        let store = DPKDeadlineStore(underlying: rawStore, window: window, phase: phase)
        func proof(_ leaf: String) throws -> URL {
          let url = root.appendingPathComponent("ownership/" + leaf)
          try LaunchReportFiles.secureOwned(url.deletingLastPathComponent(), in: root)
          return url
        }
        let operations = ProbeOperations(
          store: store,
          persistAbsence: {
            try time(window: window, phase: phase)
            var value = Probe.ownership(request)
            value["writeAttempted"] = false
            try Probe.exclusiveJSON(value, at: proof("absence.json"))
          },
          persistAttempt: {
            try time(window: window, phase: phase)
            try Probe.exclusiveJSON(Probe.ownership(request), at: proof("write-attempt.json"))
          },
          validateOwnership: {
            for leaf in ["absence.json", "write-attempt.json"] {
              let actual = try LaunchReport.read(proof(leaf), root).value
              var expected = Probe.ownership(request)
              if leaf == "absence.json" { expected["writeAttempted"] = false }
              try LaunchReport.same(actual, expected)
            }
          }, delete: { _ in throw ProbeFailure.guardRejected },
          persistCleaned: { throw ProbeFailure.guardRejected })
        var receipt: [String: Any] = [:]
        try await Probe.perform(request, receipt: &receipt, operations: operations)
        let result: [String: Any] = [
          "phase": phase, "comparison": receipt["comparison"]!, "ownershipVerified": true,
        ]
        box.finish(
          .success(try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])))
      } catch { box.finish(.failure(error)) }
    }
    return try box.read()
  }
}

private final class LaunchReportFixture {
  let root: URL
  let binary: URL
  var attemptPrefix: String {
    LaunchReport.isDPK ? "phases/" + (request["phase"] as? String ?? "save-a") : "attempt"
  }
  var environment: [String: String] = [:]
  var request: [String: Any] = [:]
  var context: [String: Any] = [:]
  var tick: TimeInterval = 0
  var wrongACK = false
  var missingACK = false
  var wrongBinary = false
  var staleInstance = false
  var instanceUnavailable = false
  var wallSamples: [Int64] = []
  var lastSample: Int64 = 2_000_000_001_000_000
  func observeFakeWall() -> Int64 {
    if !wallSamples.isEmpty { lastSample = wallSamples.removeFirst() }
    return lastSample
  }

  init() throws {
    let physical = try LaunchReportFiles.physicalPath(FileManager.default.temporaryDirectory.path)
    root = URL(fileURLWithPath: physical).appendingPathComponent(
      "rivet-binding-fake-" + UUID().uuidString)
    binary = root.appendingPathComponent(
      "app/CredentialStorageProbe.app/Contents/MacOS/CredentialStorageProbe")
    try directory(root)
    try directory(binary.deletingLastPathComponent())
    try bytes(Data("fake binary, never executed".utf8), at: binary)
    var hashes: [String: String] = [:]
    for leaf in LaunchReport.sources {
      let url = root.appendingPathComponent("source/" + leaf)
      try directory(url.deletingLastPathComponent())
      try bytes(Data("fake source".utf8), at: url)
      hashes[leaf] = Probe.sha(Data("fake source".utf8))
    }
    let build: [String: Any] = [
      "schemaVersion": 1, "purpose": LaunchReport.purpose,
      "variant": LaunchReport.isDPK ? "dpk-entitled" : "profile-free", "evidenceMode": "fake-only",
      "sourceHashes": hashes,
      "compileConditions": [
        "DEBUG", LaunchReport.isDPK ? "DPK_VALIDATION_ONLY" : "LAUNCH_REPORT_ONLY",
      ], "scheme": "CredentialStorageProbe",
      "configuration": "Debug", "commandSHA256": String(repeating: "a", count: 64),
      "unsignedBinarySHA256": Probe.sha(Data("fake binary, never executed".utf8)),
      "buildSucceeded": true,
    ]
    let buildURL = root.appendingPathComponent("build.machine.json")
    try Probe.exclusiveJSON(build, at: buildURL)
    let buildSHA = Probe.sha(try Data(contentsOf: buildURL))
    var signing: [String: Any] = [
      "schemaVersion": 1, "purpose": LaunchReport.purpose,
      "variant": LaunchReport.isDPK ? "dpk-entitled" : "profile-free", "evidenceMode": "fake-only",
      "buildProofSHA256": buildSHA,
      "binarySHA256": Probe.sha(Data("fake binary, never executed".utf8)),
      "certificateDER_SHA256": LaunchReport.certificateSHA,
      "teamIdentifierSHA256": String(repeating: "b", count: 64),
      "bundleIdentifierSHA256": String(repeating: "c", count: 64),
      "codeIdentifierSHA256": String(repeating: "c", count: 64),
      "designatedRequirementSHA256": String(repeating: "d", count: 64),
      "entitlementsEmpty": !LaunchReport.isDPK, "embeddedProfilePresent": LaunchReport.isDPK,
      "signatureValid": true, "certificateValidNow": true,
    ]
    if LaunchReport.isDPK {
      let profile = Data("FAKE_ONLY_PROFILE".utf8)
      try bytes(profile, at: root.appendingPathComponent("profile.provisionprofile"))
      signing["profileSHA256"] = Probe.sha(profile)
      signing["entitlementsSHA256"] = String(repeating: "e", count: 64)
      signing["groupSHA256"] = Probe.sha(Data("FAKEGROUP.local.probe".utf8))
    }
    let signingURL = root.appendingPathComponent("signing.machine.json")
    try Probe.exclusiveJSON(signing, at: signingURL)
    let proofs = [buildSHA, Probe.sha(try Data(contentsOf: signingURL))]
    context = [
      "schemaVersion": 1, "purpose": LaunchReport.purpose,
      "contextUUID": UUID().uuidString.lowercased(), "sourceHashes": hashes,
      "expectedBinarySHA256": Probe.sha(Data("fake binary, never executed".utf8)),
      "buildProofSHA256": proofs[0], "signingProofSHA256": proofs[1],
    ]
    if LaunchReport.isDPK { try prepareDPK(hashes: hashes, proofs: proofs, signing: signing) }
    let contextURL = root.appendingPathComponent("context.json")
    try Probe.exclusiveJSON(context, at: contextURL)
    request = [
      "schemaVersion": 1, "purpose": LaunchReport.purpose,
      "attemptUUID": UUID().uuidString.lowercased(),
      "contextSHA256": Probe.sha(try Data(contentsOf: contextURL)),
      "expectedBinarySHA256": context["expectedBinarySHA256"]!,
      "createdAtUnixMicroseconds": Int64(2_000_000_000_000_000),
    ]
    if LaunchReport.isDPK {
      let created = Int64(2_000_000_000_000_000)
      request["createdAtUnixMicroseconds"] = created
      lastSample = created + 1_000_000
      request["roundSHA256"] = context["roundSHA256"]!
      request["phase"] = "save-a"
    }
    try directory(root.appendingPathComponent(attemptPrefix))
    try writeRequest()
  }
  func prepareDPK(hashes: [String: String], proofs: [String], signing: [String: Any]) throws {
    let boot = try DPKWindowSample.bootHash(Data("11111111-1111-4111-8111-111111111111\0".utf8))
    let authority: [String: Any] = [
      "schemaVersion": 1, "purpose": LaunchReport.purpose, "evidenceMode": "fake-only",
      "windowUUID": UUID().uuidString.lowercased(),
      "roundUUID": "11111111-1111-4111-8111-111111111111",
      "descriptorSHA256": String(repeating: "a", count: 64),
      "humanAuthorizationSHA256": String(repeating: "b", count: 64),
      "startsAtUnixSeconds": 2_000_000_000, "expiresAtUnixSeconds": 2_000_003_600,
      "startsAtMonotonicNanoseconds": Int64(10_000_000_000),
      "expiresAtMonotonicNanoseconds": Int64(3_610_000_000_000),
      "bootSessionSHA256": boot, "allowedPhases": DPKWindow.phases,
      "promptLimits": [
        "saveMaxPrompts": 1, "freshReadMaxPrompts": 0, "replaceMaxPrompts": 0,
        "buildSignMaxKeyAuthorizations": 1,
      ],
    ]
    let authorityURL = root.appendingPathComponent("live-authority.json")
    try Probe.exclusiveJSON(authority, at: authorityURL)
    let authoritySHA = Probe.sha(try Data(contentsOf: authorityURL))
    let buildURL = root.appendingPathComponent("build.machine.json")
    var build = try Probe.dictionary(buildURL)
    build["authoritySHA256"] = authoritySHA
    try FileManager.default.removeItem(at: buildURL)
    try Probe.exclusiveJSON(build, at: buildURL)
    let buildSHA = Probe.sha(try Data(contentsOf: buildURL))
    let signingURL = root.appendingPathComponent("signing.machine.json")
    var newSigning = signing
    newSigning["authoritySHA256"] = authoritySHA
    newSigning["buildProofSHA256"] = buildSHA
    try FileManager.default.removeItem(at: signingURL)
    try Probe.exclusiveJSON(newSigning, at: signingURL)
    let signingSHA = Probe.sha(try Data(contentsOf: signingURL))
    context["buildProofSHA256"] = buildSHA
    context["signingProofSHA256"] = signingSHA
    context["authoritySHA256"] = authoritySHA
    let formatter = ISO8601DateFormatter()
    let round: [String: Any] = [
      "authoritySHA256": authoritySHA,
      "schemaVersion": 1, "purpose": LaunchReport.purpose,
      "roundUUID": "11111111-1111-4111-8111-111111111111",
      "service": "local.rivet.github.oauth.validation.11111111-1111-4111-8111-111111111111",
      "account": "credential", "clientID": "rivet-validation-fake-client",
      "group": "FAKEGROUP.local.probe",
      "deadlineUTC": formatter.string(from: Date(timeIntervalSince1970: 2_000_003_600)),
      "parentLG59MachineSHA256": String(repeating: "a", count: 64),
      "parentLG64ResultSHA256": String(repeating: "b", count: 64),
      "sourceHashes": hashes, "profileSHA256": signing["profileSHA256"]!,
      "certificateSHA256": LaunchReport.certificateSHA,
      "initialBuildProofSHA256": buildSHA, "initialSigningProofSHA256": signingSHA,
    ]
    let roundURL = root.appendingPathComponent("round.json")
    try Probe.exclusiveJSON(round, at: roundURL)
    context["roundSHA256"] = Probe.sha(try Data(contentsOf: roundURL))
    context["profileSHA256"] = signing["profileSHA256"]!
    try directory(root.appendingPathComponent("ownership"))
  }
  func directory(_ url: URL) throws {
    try FileManager.default.createDirectory(
      at: url, withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o700])
  }
  func bytes(_ data: Data, at url: URL) throws {
    try data.write(to: url, options: .withoutOverwriting)
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
  }
  func writeRequest() throws {
    let url = root.appendingPathComponent(attemptPrefix + "/request.json")
    if FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.removeItem(at: url)
    }
    try Probe.exclusiveJSON(request, at: url)
    let sha = Probe.sha(try Data(contentsOf: url))
    environment = [LaunchReport.requestKey: url.path, LaunchReport.hashKey: sha]
    let consumed = root.appendingPathComponent(
      LaunchReport.isDPK ? attemptPrefix + "/binding-consumed.json" : "binding-consumed.json")
    if FileManager.default.fileExists(atPath: consumed.path) {
      try FileManager.default.removeItem(at: consumed)
    }
    var binding = request
    binding.removeValue(forKey: "createdAtUnixMicroseconds")
    binding["requestSHA256"] = sha
    binding.merge([
      "readyUUID": UUID().uuidString.lowercased(), "readyConfirmed": true,
      "runnerSHA256": String(repeating: "a", count: 64), "evidenceMode": "fake-only",
    ]) { _, new in new }
    try Probe.exclusiveJSON(binding, at: consumed)
  }
  func mutateSigning(_ key: String, value: Any) throws {
    let signingURL = root.appendingPathComponent("signing.machine.json")
    var signing = try Probe.dictionary(signingURL)
    signing[key] = value
    try FileManager.default.removeItem(at: signingURL)  // Only this owned fake fixture.
    try Probe.exclusiveJSON(signing, at: signingURL)
    context["signingProofSHA256"] = Probe.sha(try Data(contentsOf: signingURL))
    let contextURL = root.appendingPathComponent("context.json")
    try FileManager.default.removeItem(at: contextURL)
    try Probe.exclusiveJSON(context, at: contextURL)
    request["contextSHA256"] = Probe.sha(try Data(contentsOf: contextURL))
    try writeRequest()
  }
  var hooks: LaunchReportHooks {
    LaunchReportHooks(
      evidenceMode: "fake-only",
      windowSample: {
        DPKWindowSample(
          wall: 2_000_000_001, monotonic: 11_000_000_000,
          bootSHA: try DPKWindowSample.bootHash(Data("11111111-1111-4111-8111-111111111111\0".utf8))
        )
      },
      executable: { self.wrongBinary ? self.root.appendingPathComponent("wrong") : self.binary },
      instance: {
        if self.instanceUnavailable { throw ProbeFailure.guardRejected }
        let created = (self.request["createdAtUnixMicroseconds"] as? Int64) ?? 2_000_000_000_000_000
        return LaunchReportInstance(
          pid: 123, seconds: self.staleInstance ? 1 : UInt64(created / 1_000_000),
          microseconds: UInt64(created % 1_000_000))
      },
      wall: { self.observeFakeWall() }, monotonic: { self.tick },
      sleep: {
        self.tick += 1
        let ackURL = self.root.appendingPathComponent(self.attemptPrefix + "/ack.json")
        if !self.missingACK && !FileManager.default.fileExists(atPath: ackURL.path) {
          let reportURL = self.root.appendingPathComponent(self.attemptPrefix + "/host.report.json")
          var ack = try Probe.dictionary(reportURL).filter {
            LaunchReport.bindingKeys.contains($0.key)
          }
          ack["hostReportSHA256"] = Probe.sha(try Data(contentsOf: reportURL))
          if self.wrongACK { ack["requestSHA256"] = String(repeating: "b", count: 64) }
          let pending = self.root.appendingPathComponent(self.attemptPrefix + "/ack.pending.json")
          try Probe.exclusiveJSON(ack, at: pending)
          try Probe.require(link(pending.path, ackURL.path) == 0)
        }
      })
  }
}

private enum DPKWindowFakeChecks {
  static func run() throws -> Int {
    let fixture = try LaunchReportFixture()
    defer { try? FileManager.default.removeItem(at: fixture.root) }
    let item = try LaunchReport.read(
      fixture.root.appendingPathComponent("live-authority.json"), fixture.root)
    guard let boot = item.value["bootSessionSHA256"] as? String else {
      throw ProbeFailure.guardRejected
    }
    let sample = DPKWindowSample(wall: 2_000_000_001, monotonic: 11_000_000_000, bootSHA: boot)
    func reject(_ action: () throws -> Void) throws {
      do { try action() } catch { return }
      throw ProbeFailure.guardRejected
    }
    let lower = try DPKWindowSample.bootHash(Data("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa\0".utf8))
    try Probe.require(
      lower == DPKWindowSample.bootHash(Data("AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA\0".utf8)))
    try reject { _ = try DPKWindowSample.bootHash(Data("invalid\0".utf8)) }
    let window = try DPKWindow(item.value, sha: item.sha, mode: "fake-only", sample: { sample })
    try window.check(phase: "save-a", reserve: 120)
    try window.check(phase: "save-a")  // Equal observed clocks are permitted.
    try reject { try window.check(phase: "cleanup") }
    try reject { try window.check(reserve: 3600) }
    try reject {
      _ = try DPKWindow(item.value, sha: item.sha, mode: "signed-host", sample: { sample })
    }
    for mutation in ["extra", "missing", "boolean", "nanoseconds"] {
      var changed = item.value
      switch mutation {
      case "extra": changed["unexpected"] = true
      case "missing": changed.removeValue(forKey: "bootSessionSHA256")
      case "boolean": changed["startsAtUnixSeconds"] = true
      default: changed["expiresAtMonotonicNanoseconds"] = Int64(3_609_000_000_000)
      }
      let raw = try JSONSerialization.data(withJSONObject: changed)
      guard let decoded = try JSONSerialization.jsonObject(with: raw) as? [String: Any] else {
        throw ProbeFailure.guardRejected
      }
      try reject {
        _ = try DPKWindow(decoded, sha: item.sha, mode: "fake-only", sample: { sample })
      }
    }
    for changed in [
      DPKWindowSample(
        wall: sample.wall, monotonic: sample.monotonic, bootSHA: String(repeating: "f", count: 64)),
      DPKWindowSample(wall: 2_000_003_600, monotonic: 3_610_000_000_000, bootSHA: boot),
    ] {
      let other = try DPKWindow(item.value, sha: item.sha, mode: "fake-only", sample: { changed })
      try reject { try other.check() }
    }
    // One participant must retain its own last-observed samples, rather than only compare with start.
    for reverseWall in [true, false] {
      let samples = DPKWindowSamples([
        sample, DPKWindowSample(wall: 2_000_000_010, monotonic: 20_000_000_000, bootSHA: boot),
        DPKWindowSample(
          wall: reverseWall ? 2_000_000_005 : 2_000_000_010,
          monotonic: reverseWall ? 20_000_000_000 : 15_000_000_000, bootSHA: boot),
      ])
      let other = try DPKWindow(
        item.value, sha: item.sha, mode: "fake-only", sample: { try samples.next() })
      try other.check()
      try other.check()
      try reject { try other.check() }
    }
    return 14
  }
}
private final class DPKWindowSamples: @unchecked Sendable {
  private let lock = NSLock()
  private var values: [DPKWindowSample]
  init(_ values: [DPKWindowSample]) { self.values = values }
  func next() throws -> DPKWindowSample {
    try lock.withLock {
      try Probe.require(!values.isEmpty)
      return values.removeFirst()
    }
  }
}

private enum DPKFakeChecks {
  static func configureWindow(
    _ id: String, fixture: LaunchReportFixture, hooks: inout LaunchReportHooks
  ) throws {
    switch id {
    case "authority-missing-zero-store":
      try FileManager.default.removeItem(
        at: fixture.root.appendingPathComponent("live-authority.json"))
    case "authority-cross-boot-zero-store":
      hooks.windowSample = {
        DPKWindowSample(
          wall: 2_000_000_001, monotonic: 11_000_000_000, bootSHA: String(repeating: "f", count: 64)
        )
      }
    case "authority-context-mismatch-zero-store":
      let url = fixture.root.appendingPathComponent("round.json")
      var changed = try Probe.dictionary(url)
      changed["authoritySHA256"] = String(repeating: "f", count: 64)
      try FileManager.default.removeItem(at: url)
      try Probe.exclusiveJSON(changed, at: url)
    default: break
    }
  }
  static func run() {
    let ids = [
      "actual-save-after-ack", "wrong-ack-zero-store", "env-loss-zero-store",
      "missing-ack-zero-store", "binary-mismatch-zero-store", "save-failure-retains-ownership",
      "authority-missing-zero-store", "authority-cross-boot-zero-store",
      "authority-context-mismatch-zero-store",
    ]
    var failures: [String] = []
    for id in ids {
      do {
        let fixture = try LaunchReportFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let trace = FakeTrace()
        let store = FakeProbeStore(nil, trace: trace)
        if id == "save-failure-retains-ownership" { store.configure(saveFailure: .save) }
        fixture.wrongACK = id == "wrong-ack-zero-store"
        fixture.missingACK = id == "missing-ack-zero-store"
        fixture.wrongBinary = id == "binary-mismatch-zero-store"
        var hooks = fixture.hooks
        try configureWindow(id, fixture: fixture, hooks: &hooks)
        var calls = 0
        let windowSample = hooks.windowSample
        hooks.operation = { input in
          calls += 1
          return try DPKValidation.perform(
            input, store: store,
            window: DPKWindow.read(input.root, mode: "fake-only", sample: windowSample))
        }
        let request = fixture.root.appendingPathComponent(fixture.attemptPrefix + "/request.json")
        let args = [
          LaunchReport.sentinel, "--request", request.path, "--request-sha",
          Probe.sha(try Data(contentsOf: request)),
        ]
        var accepted = false
        do {
          try LaunchReport.execute(
            arguments: args, environment: id == "env-loss-zero-store" ? [:] : fixture.environment,
            hooks: hooks)
          accepted = true
        } catch {}
        if id == "actual-save-after-ack" {
          try Probe.require(accepted && calls == 1 && trace.snapshot == ["load", "save", "load"])
          let final = try LaunchReport.read(
            fixture.root.appendingPathComponent(fixture.attemptPrefix + "/host.final.json"),
            fixture.root
          ).value
          guard let result = final["operationResult"] as? [String: Any],
            let fields = result["comparison"] as? [String: Bool]
          else { throw ProbeFailure.guardRejected }
          try Probe.require(
            fields.count == 6 && fields.values.allSatisfy { $0 }
              && result["ownershipVerified"] as? Bool == true)
        } else if id == "save-failure-retains-ownership" {
          try Probe.require(!accepted && calls == 1 && trace.snapshot == ["load", "save"])
          try Probe.require(
            FileManager.default.fileExists(
              atPath: fixture.root.appendingPathComponent("ownership/write-attempt.json").path))
          try Probe.require(
            !FileManager.default.fileExists(
              atPath: fixture.root.appendingPathComponent(
                fixture.attemptPrefix + "/host.final.json"
              ).path))
        } else {
          try Probe.require(!accepted && calls == 0 && trace.snapshot.isEmpty)
        }
      } catch { failures.append(id) }
    }
    var windowPassed = 0
    do { windowPassed = try DPKWindowFakeChecks.run() } catch { failures.append("window-controls") }
    let result: [String: Any] = [
      "windowPassed": windowPassed, "mode": "dpk-fake-only", "caseIDs": ids,
      "passed": ids.count - failures.count,
      "failures": failures,
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]),
      let text = String(data: data, encoding: .utf8)
    else { exit(1) }
    print(text)
    if !failures.isEmpty { exit(1) }
  }
}

private enum LaunchReportFakeChecks {
  static let ids = [
    "complete-chain", "env-lost", "partial-env", "wrong-argv", "request-sha",
    "request-type", "extra-request-key", "changed-context", "changed-binary", "stale-instance",
    "wrong-ack", "ack-timeout", "existing-output", "symlink-request", "dispatch-fail-closed",
    "clock-reverse-before-report", "clock-reverse-before-final",
    "proof-purpose", "proof-mode", "proof-profile", "proof-claims", "proof-certificate",
    "argv-missing", "both-channels-missing", "duplicate-argv", "unknown-rivet", "entry-existing",
    "instance-unavailable",
  ]
  static func configureWireInput(
    _ id: String, fixture: LaunchReportFixture, arguments: inout [String]
  ) throws {
    switch id {
    case "argv-missing": arguments = []
    case "both-channels-missing":
      arguments = []
      fixture.environment = [:]
    case "duplicate-argv": arguments += ["--request", "DO_NOT_READ"]
    case "unknown-rivet": fixture.environment["RIVET_UNEXPECTED"] = "DO_NOT_READ"
    default: break
    }
  }
  static func configureInput(
    _ id: String, fixture: LaunchReportFixture, arguments: inout [String]
  ) throws {
    try configureWireInput(id, fixture: fixture, arguments: &arguments)
    switch id {
    case "env-lost": fixture.environment = [:]
    case "partial-env": fixture.environment.removeValue(forKey: LaunchReport.hashKey)
    case "wrong-argv": arguments.append("--root")
    case "request-sha":
      fixture.environment[LaunchReport.hashKey] = String(repeating: "f", count: 64)
    case "request-type":
      fixture.request["createdAtUnixMicroseconds"] = true
      try fixture.writeRequest()
    case "extra-request-key":
      fixture.request["unexpected"] = "private"
      try fixture.writeRequest()
    case "changed-context":
      fixture.request["contextSHA256"] = String(repeating: "f", count: 64)
      try fixture.writeRequest()
    default: break
    }
  }
  static func configureResponse(_ id: String, fixture: LaunchReportFixture) throws {
    fixture.instanceUnavailable = id == "instance-unavailable"
    switch id {
    case "clock-reverse-before-report":
      fixture.wallSamples = [2_000_000_010_000_000, 2_000_000_005_000_000]
    case "clock-reverse-before-final":
      fixture.wallSamples = [2_000_000_000_000_000, 2_000_000_010_000_000, 2_000_000_005_000_000]
    case "changed-binary": fixture.wrongBinary = true
    case "stale-instance": fixture.staleInstance = true
    case "wrong-ack": fixture.wrongACK = true
    case "ack-timeout": fixture.missingACK = true
    case "entry-existing":
      try Probe.exclusiveJSON(
        ["partial": true],
        at: fixture.root.appendingPathComponent("attempt/host.entry.pending.json"))
    case "existing-output":
      try Probe.exclusiveJSON(
        ["partial": true],
        at: fixture.root.appendingPathComponent("attempt/host.report.pending.json"))
    case "symlink-request":
      let path = fixture.root.appendingPathComponent("attempt/request.json")
      try FileManager.default.moveItem(
        at: path, to: fixture.root.appendingPathComponent("original.json"))
      try FileManager.default.createSymbolicLink(
        atPath: path.path, withDestinationPath: "../original.json")
    default: break
    }
  }
  static func configureProof(_ id: String, fixture: LaunchReportFixture) throws {
    let mutations: [String: (String, Any)] = [
      "proof-purpose": ("purpose", "namespace-read-only"),
      "proof-mode": ("evidenceMode", "signed-host"),
      "proof-profile": ("embeddedProfilePresent", true),
      "proof-claims": ("entitlementsEmpty", false),
      "proof-certificate": ("certificateDER_SHA256", String(repeating: "e", count: 64)),
    ]
    if let mutation = mutations[id] { try fixture.mutateSigning(mutation.0, value: mutation.1) }
  }
  static func check(_ id: String) throws {
    let fixture = try LaunchReportFixture()
    defer { try? FileManager.default.removeItem(at: fixture.root) }  // Own ordinary fixture only.
    var arguments = [
      LaunchReport.sentinel, "--request", fixture.environment[LaunchReport.requestKey]!,
      "--request-sha", fixture.environment[LaunchReport.hashKey]!,
    ]
    if id == "dispatch-fail-closed" {
      try Probe.require(LaunchReport.selected([LaunchReport.sentinel], [:]))
      try Probe.require(LaunchReport.selected([], [LaunchReport.requestKey: "invalid"]))
      try Probe.require(LaunchReport.selected([], [LaunchReport.hashKey: "invalid"]))
      try Probe.require(!LaunchReport.selected([], [:]))
      return
    }
    try configureInput(id, fixture: fixture, arguments: &arguments)
    try configureResponse(id, fixture: fixture)
    try configureProof(id, fixture: fixture)
    if ![
      "env-lost", "partial-env", "wrong-argv", "request-sha", "argv-missing",
      "both-channels-missing", "duplicate-argv",
    ].contains(id) {
      arguments = [
        LaunchReport.sentinel, "--request", fixture.environment[LaunchReport.requestKey]!,
        "--request-sha", fixture.environment[LaunchReport.hashKey]!,
      ]
    }
    var completed = false
    do {
      try LaunchReport.execute(
        arguments: arguments, environment: fixture.environment, hooks: fixture.hooks)
      completed = true
    } catch {}
    try Probe.require(completed == (id == "complete-chain"))
    let final = fixture.root.appendingPathComponent("attempt/host.final.json")
    try Probe.require(FileManager.default.fileExists(atPath: final.path) == completed)
    let entry = fixture.root.appendingPathComponent("attempt/host.entry.json")
    let failure = fixture.root.appendingPathComponent("attempt/host.failure.json")
    if [
      "env-lost", "partial-env", "wrong-argv", "request-sha", "argv-missing", "duplicate-argv",
      "unknown-rivet",
    ].contains(id) {
      try Probe.require(FileManager.default.fileExists(atPath: entry.path))
      let value = try Probe.dictionary(failure)
      try Probe.require(
        value["stage"] as? String == "wire" && value["failureKind"] as? String == "input")
      let expected = LaunchReport.bindingKeys.union([
        "stage", "outcome", "wire", "observedBinarySHA256", "pid", "startSeconds",
        "startMicroseconds", "failureKind",
      ])
      try Probe.require(Set(value.keys) == expected)
    }
    if id == "both-channels-missing" {
      try Probe.require(
        !FileManager.default.fileExists(atPath: entry.path)
          && !FileManager.default.fileExists(atPath: failure.path))
    }
    if id == "instance-unavailable" {
      let value = try Probe.dictionary(failure)
      try Probe.require(value["stage"] as? String == "instance" && value["pid"] is NSNull)
      try Probe.require(value["startSeconds"] is NSNull && value["startMicroseconds"] is NSNull)
    }
    if completed {
      let report = try Probe.dictionary(
        fixture.root.appendingPathComponent("attempt/host.report.json"))
      let value = try Probe.dictionary(final)
      try Probe.require(value["requestSHA256"] as? String == report["requestSHA256"] as? String)
      try Probe.require(value["outcome"] as? String == "completed")
    }
  }
  static func run() {
    var failures: [String] = []
    for id in ids { do { try check(id) } catch { failures.append(id) } }
    let report: [String: Any] = [
      "mode": "launch-binding-fake-only", "caseIDs": ids,
      "passed": ids.count - failures.count, "failures": failures,
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]),
      let text = String(data: data, encoding: .utf8)
    else { exit(1) }
    print(text)
    if !failures.isEmpty { exit(1) }
  }
}

private enum LaunchStartupChecks {
  static func rejected(_ operation: () throws -> Void) -> Bool {
    do {
      try operation()
      return false
    } catch { return true }
  }
  static func replay(_ path: String, result: inout [String: Any]) throws {

    let root = URL(fileURLWithPath: path)
    try Probe.require(root.lastPathComponent.hasPrefix("rivet-lg54-replay-"))
    try LaunchReportFiles.secureRoot(root, name: root.lastPathComponent)
    let requestURL = root.appendingPathComponent("attempt/request.json")
    let requestRaw = try Data(contentsOf: LaunchReport.file(requestURL, root))
    guard let request = try JSONSerialization.jsonObject(with: requestRaw) as? [String: Any]
    else { throw ProbeFailure.guardRejected }
    let created = try LaunchReport.integer(request["createdAtUnixMicroseconds"])
    let binary = root.appendingPathComponent(
      "app/CredentialStorageProbe.app/Contents/MacOS/CredentialStorageProbe")
    var ticks: TimeInterval = 0
    var lastStage = "bootstrap"
    let hooks = LaunchReportHooks(
      evidenceMode: "signed-host", checkpoint: { lastStage = $0 }, executable: { binary },
      instance: {
        LaunchReportInstance(
          pid: 123, seconds: UInt64((created + 999_999) / 1_000_000), microseconds: 0)
      },
      wall: { created + 2_000_000 }, monotonic: { ticks },
      sleep: {
        ticks += 1
        let reportURL = root.appendingPathComponent("attempt/host.report.json")
        let reportRaw = try Data(contentsOf: reportURL)
        guard let report = try JSONSerialization.jsonObject(with: reportRaw) as? [String: Any]
        else { throw ProbeFailure.guardRejected }
        var ack = report.filter { LaunchReport.bindingKeys.contains($0.key) }
        ack["hostReportSHA256"] = Probe.sha(reportRaw)
        let pending = root.appendingPathComponent("attempt/ack.pending.json")
        let final = root.appendingPathComponent("attempt/ack.json")
        if !FileManager.default.fileExists(atPath: final.path) {
          try Probe.exclusiveJSON(ack, at: pending)
          try Probe.require(link(pending.path, final.path) == 0)
        }
      })
    do {
      try LaunchReport.execute(
        arguments: [
          LaunchReport.sentinel, "--request", requestURL.path, "--request-sha",
          Probe.sha(requestRaw),
        ],
        environment: [
          LaunchReport.requestKey: requestURL.path, LaunchReport.hashKey: Probe.sha(requestRaw),
        ], hooks: hooks)
      result["capturedCoreCompleted"] = true
    } catch {
      result["capturedCoreCompleted"] = false
      result["firstFailureStage"] = lastStage
      throw error
    }
    result["capturedRequestSHA256"] = Probe.sha(requestRaw)

  }
  static func fileNegatives(_ fixture: LaunchReportFixture) throws -> [String: Bool] {
    let oversized = fixture.root.appendingPathComponent("oversized.json")
    try fixture.bytes(Data(repeating: 32, count: 65_537), at: oversized)
    let sizeRejected = rejected { _ = try LaunchReport.read(oversized, fixture.root) }
    let typeRejected = rejected { _ = try LaunchReport.file(fixture.root, fixture.root) }
    let context = fixture.root.appendingPathComponent("context.json")
    try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: context.path)
    let fileModeRejected = rejected { _ = try LaunchReport.read(context, fixture.root) }
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: context.path)
    return [
      "sizeRejected": sizeRejected, "typeRejected": typeRejected,
      "fileModeRejected": fileModeRejected,
    ]
  }
  static func run() {
    var result: [String: Any] = ["mode": "launch-startup-nonlive", "passed": false]
    do {
      let fixture = try LaunchReportFixture()
      defer { try? FileManager.default.removeItem(at: fixture.root) }
      let derived = URL(fileURLWithPath: fixture.environment[LaunchReport.requestKey]!)
        .deletingLastPathComponent().deletingLastPathComponent()
      try LaunchReportFiles.secureRoot(derived, name: derived.lastPathComponent)
      result["physicalCanonicalAccepted"] = true
      let fileChecks = try fileNegatives(fixture)
      try Probe.require(fileChecks.values.allSatisfy { $0 })
      result.merge(fileChecks) { _, new in new }
      result["foundationAliasObserved"] = derived.path != derived.standardizedFileURL.path
      try FileManager.default.setAttributes(
        [.posixPermissions: 0o755], ofItemAtPath: fixture.root.path)
      let modeRejected = rejected {
        try LaunchReportFiles.secureRoot(derived, name: derived.lastPathComponent)
      }
      try FileManager.default.setAttributes(
        [.posixPermissions: 0o700], ofItemAtPath: fixture.root.path)
      let linkURL = fixture.root.appendingPathComponent("untrusted-link")
      try FileManager.default.createSymbolicLink(
        atPath: linkURL.path, withDestinationPath: "context.json")
      let symlinkRejected = rejected { _ = try LaunchReport.file(linkURL, fixture.root) }
      let ownerRejected =
        getuid() != 0
        && rejected {
          try LaunchReportFiles.secureOwned(
            URL(fileURLWithPath: "/"), in: URL(fileURLWithPath: "/"))
        }
      guard
        let numbers = try JSONSerialization.jsonObject(
          with: Data(#"{"integer":1,"bool":true,"fraction":1.5}"#.utf8)) as? [String: Any]
      else { throw ProbeFailure.guardRejected }
      let integerValid = try LaunchReport.integer(numbers["integer"]) == 1
      let booleanRejected = rejected { _ = try LaunchReport.integer(numbers["bool"]) }
      let fractionRejected = rejected { _ = try LaunchReport.integer(numbers["fraction"]) }
      let instance = try LaunchReportHooks.live.instance()  // This process only, never another PID.
      let nativeValid =
        instance.pid == Int(getpid()) && instance.seconds > 0 && instance.microseconds < 1_000_000
      result.merge([
        "modeRejected": modeRejected, "symlinkRejected": symlinkRejected,
        "ownerRejected": ownerRejected,
        "integerValid": integerValid, "booleanRejected": booleanRejected,
        "fractionRejected": fractionRejected,
        "nativeSelfValid": nativeValid, "sdkLayoutPositive": MemoryLayout<proc_bsdinfo>.size > 0,
      ]) { _, new in new }
      try Probe.require(
        modeRejected && symlinkRejected && ownerRejected && integerValid && booleanRejected
          && fractionRejected && nativeValid)
      if let path = ProcessInfo.processInfo.environment["RIVET_CAPTURED_REPLAY_ROOT"] {
        try replay(path, result: &result)
      }
      result["passed"] = true
    } catch { result["failureKind"] = "guard" }
    guard let bytes = try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]),
      let text = String(data: bytes, encoding: .utf8)
    else { exit(1) }
    print(text)
    if result["passed"] as? Bool != true { exit(1) }
  }
}

#if DPK_VALIDATION_ONLY
  if CommandLine.arguments.dropFirst().elementsEqual(["--self-test-dpk"]) {
    DPKFakeChecks.run()
  } else {
    LaunchReport.run()
  }
#elseif LAUNCH_REPORT_ONLY
  LaunchReport.run()
#else
  let diagnosticFakeMode = CommandLine.arguments.dropFirst().elementsEqual([
    "--self-test-diagnostics"
  ]
  )
  let diagnosticEnvironment = ProcessInfo.processInfo.environment
  let diagnosticMode =
    diagnosticEnvironment["RIVET_DIAGNOSTIC_MANIFEST"] != nil
    || diagnosticEnvironment["RIVET_DIAGNOSTIC_SHA256"] != nil
  if CommandLine.arguments.count == 2 && CommandLine.arguments[1] == "--self-test-fakes" {
    await FakeOperationChecks.run()
  } else if CommandLine.arguments.dropFirst().elementsEqual(["--self-test-launch-startup"]) {
    LaunchStartupChecks.run()
  } else if CommandLine.arguments.dropFirst().elementsEqual(["--self-test-launch-binding"]) {
    LaunchReportFakeChecks.run()
  } else if diagnosticFakeMode {
    await DiagnosticFakeChecks.run()
  } else if LaunchReport.selected(Array(CommandLine.arguments.dropFirst()), diagnosticEnvironment) {
    LaunchReport.run()
  } else if diagnosticMode {
    await DiagnosticProbe.run()
  } else {
    await Probe.run()
  }

#endif
