import CryptoKit
import Darwin
import Foundation
import GitHubIntegration
import Security

// Verification-only host. No network, login, real PAT input or production deletion API.
private enum ProbeFailure: Error { case guardRejected, storeFailure }
private enum Phase: String, Codable, CaseIterable {
  case saveA = "save-a"
  case readA = "read-a"
  case replaceB = "replace-b"
  case readB = "read-b"
  case rebuiltReadB = "rebuilt-read-b"
  case cleanup
  case verifyAbsence = "verify-absence"
}

private protocol ProbeStore: Sendable {
  func load() async throws -> PersonalAccessToken?
  func save(_ token: PersonalAccessToken) async throws
  func removeOwnedItem() async throws
}

private protocol Journal: Sendable {
  func contains(_ marker: String) throws -> Bool
  func record(_ marker: String) throws
}

private struct LiveStore: ProbeStore {
  let store: GitHubPATDataProtectionStore
  let group: String
  let service: String
  func load() async throws -> PersonalAccessToken? { try await store.load() }
  func save(_ token: PersonalAccessToken) async throws { try await store.save(token) }
  func removeOwnedItem() async throws {
    let status = SecItemDelete(
      [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccessGroup: group, kSecAttrService: service, kSecAttrAccount: "pat",
        kSecUseDataProtectionKeychain: true, kSecAttrSynchronizable: false,
      ] as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw ProbeFailure.storeFailure
    }
  }
}

private struct Run: Codable {
  let runID: String
  let service: String
  let accessGroup: String
  let recoveryID: String?
}

private struct DiskJournal: Journal {
  let root: URL
  let run: Run
  func contains(_ marker: String) throws -> Bool {
    let url = root.appendingPathComponent(marker + ".json")
    guard FileManager.default.fileExists(atPath: url.path) else { return false }
    try Files.check(url, directory: false)
    let saved = try JSONDecoder().decode(Run.self, from: Data(contentsOf: url))
    return saved.runID == run.runID && saved.service == run.service
      && saved.accessGroup == run.accessGroup
  }
  func record(_ marker: String) throws {
    try Files.publish(try JSONEncoder().encode(run), root.appendingPathComponent(marker + ".json"))
  }
}

private enum Files {
  static func check(_ url: URL, directory: Bool) throws {
    var info = stat()
    guard lstat(url.path, &info) == 0, info.st_uid == getuid(),
      info.st_mode & S_IFMT == (directory ? S_IFDIR : S_IFREG),
      info.st_mode & 0o777 == (directory ? 0o700 : 0o600)
    else { throw ProbeFailure.guardRejected }
  }
  static func publish(_ data: Data, _ url: URL) throws {
    let descriptor = open(url.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
    guard descriptor >= 0 else { throw ProbeFailure.guardRejected }
    defer { close(descriptor) }
    try data.withUnsafeBytes { buffer in
      var offset = 0
      while offset < buffer.count {
        let count = write(
          descriptor, buffer.baseAddress!.advanced(by: offset), buffer.count - offset)
        guard count > 0 else { throw ProbeFailure.guardRejected }
        offset += count
      }
    }
    guard fsync(descriptor) == 0 else { throw ProbeFailure.guardRejected }
    let parent = open(url.deletingLastPathComponent().path, O_RDONLY | O_DIRECTORY)
    guard parent >= 0 else { throw ProbeFailure.guardRejected }
    defer { close(parent) }
    guard fsync(parent) == 0 else { throw ProbeFailure.guardRejected }
  }
}

private enum Probe {
  static func token(_ value: String) throws -> PersonalAccessToken {
    try PersonalAccessToken(rawValue: "nonsecret-pat-storage-example-" + value)
  }
  static func require(_ condition: Bool) throws {
    guard condition else { throw ProbeFailure.guardRejected }
  }
  static func owned(_ journal: any Journal) throws {
    try require(journal.contains("absence") && journal.contains("write-attempt"))
  }
  static func perform(_ phase: Phase, store: any ProbeStore, journal: any Journal) async throws {
    switch phase {
    case .saveA:
      try require(try await store.load() == nil)
      try journal.record("absence")
      try journal.record("write-attempt")
      try await store.save(token("A"))
      try require(try await store.load() == token("A"))
    case .readA:
      try owned(journal)
      try require(try await store.load() == token("A"))
    case .replaceB:
      try owned(journal)
      try require(try await store.load() == token("A"))
      try await store.save(token("B"))
      try require(try await store.load() == token("B"))
    case .readB, .rebuiltReadB:
      try owned(journal)
      try require(try await store.load() == token("B"))
    case .cleanup:
      try owned(journal)
      try await store.removeOwnedItem()
      try require(try await store.load() == nil)
    case .verifyAbsence:
      try owned(journal)
      try require(try await store.load() == nil)
    }
  }

  static func sha(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  static func dictionary(_ url: URL) throws -> [String: Any] {
    try Files.check(url, directory: false)
    let data = try Data(contentsOf: url)
    try require(data.count <= 1_048_576)
    guard let value = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw ProbeFailure.guardRejected
    }
    return value
  }

  /// Admission completes before constructing LiveStore or making any Security call.
  static func admit(_ phase: Phase, run: Run, root: URL, journal: any Journal) throws {
    let sourceURL = root.appendingPathComponent("source.json")
    let source = try dictionary(sourceURL)
    let amendmentURL = root.appendingPathComponent("amendment.json")
    let controllerURL = root.appendingPathComponent("controller.py")
    let hasRecoveryTrace =
      run.recoveryID != nil || root.lastPathComponent.hasPrefix("recovery-")
      || FileManager.default.fileExists(atPath: amendmentURL.path)
      || FileManager.default.fileExists(atPath: controllerURL.path)
      || source["recoveryID"] != nil || source["recoveryPurpose"] != nil
    guard hasRecoveryTrace else {
      try require(phase != .verifyAbsence)
      return
    }
    try require(phase == .verifyAbsence)
    guard let recoveryID = run.recoveryID else { throw ProbeFailure.guardRejected }
    try require(UUID(uuidString: recoveryID)?.uuidString.lowercased() == recoveryID)
    try require(root.lastPathComponent == "recovery-" + recoveryID)
    try require(source["recoveryID"] as? String == recoveryID)
    try require(source["recoveryPurpose"] as? String == "verify-owned-absence")
    let amendment = try dictionary(amendmentURL)
    try require(amendment["purpose"] as? String == "verify-owned-absence")
    try require(amendment["recoveryID"] as? String == recoveryID)
    try require(amendment["originalRunID"] as? String == run.runID)
    try require(
      amendment["recoverySourceProofSHA256"] as? String == sha(Data(contentsOf: sourceURL)))
    try Files.check(controllerURL, directory: false)
    try require(amendment["controllerSHA256"] as? String == sha(Data(contentsOf: controllerURL)))
    let attempt = try dictionary(root.appendingPathComponent("verify-absence.attempt.json"))
    try require(attempt["runID"] as? String == run.runID)
    try require(attempt["phase"] as? String == phase.rawValue)
    try require(attempt["recoveryID"] as? String == recoveryID)
    try require(attempt["amendmentSHA256"] as? String == sha(Data(contentsOf: amendmentURL)))
    try require(attempt["controllerSHA256"] as? String == amendment["controllerSHA256"] as? String)
    try owned(journal)
  }

  static func run() async {
    guard CommandLine.arguments.count == 5, CommandLine.arguments[1] == "--root",
      CommandLine.arguments[3] == "--phase", let phase = Phase(rawValue: CommandLine.arguments[4])
    else {
      fputs("probe: invalid-input\n", stderr)
      exit(1)
    }
    do {
      let root = URL(fileURLWithPath: CommandLine.arguments[2]).resolvingSymlinksInPath()
      try Files.check(root, directory: true)
      let runURL = root.appendingPathComponent("run.json")
      try Files.check(runURL, directory: false)
      let run = try JSONDecoder().decode(Run.self, from: Data(contentsOf: runURL))
      try require(UUID(uuidString: run.runID)?.uuidString.lowercased() == run.runID)
      try require(run.service == "local.rivet.github.pat.validation." + run.runID)
      let journal = DiskJournal(root: root, run: run)
      try admit(phase, run: run, root: root, journal: journal)
      let store = LiveStore(
        store: try GitHubPATDataProtectionStore(accessGroup: run.accessGroup, service: run.service),
        group: run.accessGroup, service: run.service)
      let receiptURL = root.appendingPathComponent(phase.rawValue + ".host.json")
      try require(!FileManager.default.fileExists(atPath: receiptURL.path))
      var outcome = "completed"
      do { try await perform(phase, store: store, journal: journal) } catch { outcome = "failed" }
      #if PAT_STORAGE_REBUILT
        let variant = "rebuilt"
      #else
        let variant = "debug"
      #endif
      var processInfo = proc_bsdinfo()
      let processInfoSize = Int32(MemoryLayout<proc_bsdinfo>.size)
      try require(
        proc_pidinfo(getpid(), PROC_PIDTBSDINFO, 0, &processInfo, processInfoSize)
          == processInfoSize)
      let binary = Bundle.main.executableURL!
      var receipt: [String: Any] = [
        "runID": run.runID, "phase": phase.rawValue, "outcome": outcome,
        "processID": Int(getpid()), "processInstance": UUID().uuidString.lowercased(),
        "processStartSeconds": processInfo.pbi_start_tvsec,
        "processStartMicroseconds": processInfo.pbi_start_tvusec,
        "binarySHA256": SHA256.hash(data: try Data(contentsOf: binary)).map {
          String(format: "%02x", $0)
        }.joined(),
        "buildVariant": variant,
      ]
      if let recoveryID = run.recoveryID { receipt["recoveryID"] = recoveryID }
      try Files.publish(
        try JSONSerialization.data(withJSONObject: receipt, options: [.sortedKeys]), receiptURL)
      if outcome != "completed" { exit(1) }
    } catch {
      fputs("probe: guard-or-storage-failure\n", stderr)
      exit(1)
    }
  }
}

private actor FakeStore: ProbeStore {
  var value: PersonalAccessToken?
  var writes = 0
  var deletes = 0
  var rejectSave = false
  var rejectLoad = false
  func load() throws -> PersonalAccessToken? {
    if rejectLoad { throw ProbeFailure.storeFailure }
    return value
  }
  func save(_ token: PersonalAccessToken) throws {
    if rejectSave { throw ProbeFailure.storeFailure }
    writes += 1
    value = token
  }
  func removeOwnedItem() {
    deletes += 1
    value = nil
  }
  func failSaving() { rejectSave = true }
  func failLoading() { rejectLoad = true }
}

private final class FakeJournal: Journal, @unchecked Sendable {
  private let lock = NSLock()
  private var markers: Set<String> = []
  var failAttempt = false
  func contains(_ marker: String) -> Bool { lock.withLock { markers.contains(marker) } }
  func record(_ marker: String) throws {
    try lock.withLock {
      if failAttempt && marker == "write-attempt" { throw ProbeFailure.guardRejected }
      guard markers.insert(marker).inserted else { throw ProbeFailure.guardRejected }
    }
  }
}

private enum SelfTests {
  struct AdmissionFixture {
    let root: URL
    let run: Run
    let journal: FakeJournal
  }
  static func rejected(_ phase: Phase, _ store: FakeStore, _ journal: FakeJournal) async -> Bool {
    do {
      try await Probe.perform(phase, store: store, journal: journal)
      return false
    } catch { return true }
  }
  static func absenceChecks() async throws -> Int {
    let store = FakeStore()
    let journal = FakeJournal()
    try Probe.require(await rejected(.verifyAbsence, store, journal))
    try journal.record("absence")
    try journal.record("write-attempt")
    try await Probe.perform(.verifyAbsence, store: store, journal: journal)
    try Probe.require(await store.writes == 0)
    try Probe.require(await store.deletes == 0)
    try await store.save(Probe.token("A"))
    try Probe.require(await rejected(.verifyAbsence, store, journal))
    try Probe.require(await store.writes == 1)
    try Probe.require(await store.deletes == 0)
    let unavailable = FakeStore()
    await unavailable.failLoading()
    try Probe.require(await rejected(.verifyAbsence, unavailable, journal))
    try Probe.require(await unavailable.writes == 0)
    try Probe.require(await unavailable.deletes == 0)
    return 6
  }

  static func admissionFixture(_ mutation: String) throws -> AdmissionFixture {
    let parent = FileManager.default.temporaryDirectory.appendingPathComponent(
      "rivet-pat-admission-" + UUID().uuidString.lowercased())
    try FileManager.default.createDirectory(
      at: parent, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    let recoveryID = UUID().uuidString.lowercased()
    let plainRoot = ["normal", "only-source-trace", "only-marker-trace"].contains(mutation)
    let root = parent.appendingPathComponent(plainRoot ? "normal" : "recovery-" + recoveryID)
    try FileManager.default.createDirectory(
      at: root, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    let runID = "00000000-0000-4000-8000-000000000001"
    let missingRunID = plainRoot || ["missing-run-id", "only-root-trace"].contains(mutation)
    let run = Run(
      runID: runID, service: "local.rivet.github.pat.validation." + runID,
      accessGroup: "test.group", recoveryID: missingRunID ? nil : recoveryID)
    let journal = FakeJournal()
    if mutation != "unowned" {
      try journal.record("absence")
      try journal.record("write-attempt")
    }
    var source: [String: Any] = [
      "recoveryID": recoveryID, "recoveryPurpose": "verify-owned-absence",
    ]
    if ["normal", "only-marker-trace", "only-root-trace"].contains(mutation) { source = [:] }
    if mutation == "wrong-source-id" { source["recoveryID"] = "wrong" }
    if mutation == "wrong-source-purpose" { source["recoveryPurpose"] = "wrong" }
    let sourceData = try JSONSerialization.data(withJSONObject: source, options: [.sortedKeys])
    try Files.publish(sourceData, root.appendingPathComponent("source.json"))
    if ["normal", "only-source-trace", "only-root-trace"].contains(mutation) {
      return AdmissionFixture(root: root, run: run, journal: journal)
    }
    let controller = Data("nonexecuted fake-only controller".utf8)
    try Files.publish(
      mutation == "wrong-controller" ? Data("changed".utf8) : controller,
      root.appendingPathComponent("controller.py"))
    let amendment: [String: Any] = [
      "purpose": "verify-owned-absence",
      "recoveryID": mutation == "wrong-marker-id" ? "wrong" : recoveryID,
      "originalRunID": runID, "controllerSHA256": Probe.sha(controller),
      "recoverySourceProofSHA256": Probe.sha(sourceData),
    ]
    let amendmentData = try JSONSerialization.data(
      withJSONObject: amendment, options: [.sortedKeys])
    if mutation != "missing-marker" {
      try Files.publish(amendmentData, root.appendingPathComponent("amendment.json"))
    }
    var attempt: [String: Any] = [
      "phase": "verify-absence", "runID": runID, "recoveryID": recoveryID,
      "amendmentSHA256": mutation == "wrong-amendment-hash" ? "wrong" : Probe.sha(amendmentData),
      "controllerSHA256": Probe.sha(controller),
    ]
    if mutation == "missing-attempt-id" { attempt.removeValue(forKey: "recoveryID") }
    if mutation == "wrong-attempt-id" { attempt["recoveryID"] = "wrong" }
    try Files.publish(
      try JSONSerialization.data(withJSONObject: attempt, options: [.sortedKeys]),
      root.appendingPathComponent("verify-absence.attempt.json"))
    return AdmissionFixture(root: root, run: run, journal: journal)
  }

  static func admissionRejected(_ phase: Phase, run: Run, root: URL, journal: FakeJournal) -> Bool {
    do {
      try Probe.admit(phase, run: run, root: root, journal: journal)
      return false
    } catch { return true }
  }

  static func admissionChecks() throws -> Int {
    var checks = 0
    for mutation in [
      "valid", "missing-run-id", "missing-marker", "wrong-marker-id", "missing-attempt-id",
      "wrong-attempt-id", "wrong-amendment-hash", "wrong-controller", "wrong-source-id",
      "wrong-source-purpose", "unowned", "only-root-trace", "only-source-trace",
      "only-marker-trace",
    ] {
      let fixture = try admissionFixture(mutation)
      let root = fixture.root
      let run = fixture.run
      let journal = fixture.journal
      defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
      try Probe.require(
        admissionRejected(.verifyAbsence, run: run, root: root, journal: journal)
          == (mutation != "valid"))
      checks += 1
      for phase in Phase.allCases where phase != .verifyAbsence {
        try Probe.require(admissionRejected(phase, run: run, root: root, journal: journal))
        checks += 1
      }
    }
    let fixture = try admissionFixture("normal")
    let root = fixture.root
    let run = fixture.run
    let journal = fixture.journal
    defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
    try Probe.require(admissionRejected(.verifyAbsence, run: run, root: root, journal: journal))
    try Probe.admit(.saveA, run: run, root: root, journal: journal)
    return checks + 2
  }

  static func run() async {
    do {
      let store = FakeStore()
      let journal = FakeJournal()
      try Probe.require(await rejected(.cleanup, store, journal))
      try Probe.require(await store.deletes == 0)
      for phase in Phase.allCases { try await Probe.perform(phase, store: store, journal: journal) }
      let writes = await store.writes
      let deletes = await store.deletes
      try Probe.require(writes == 2 && deletes == 1)
      let failedStore = FakeStore()
      let failedJournal = FakeJournal()
      await failedStore.failSaving()
      try Probe.require(await rejected(.saveA, failedStore, failedJournal))
      try Probe.owned(failedJournal)
      try await Probe.perform(.cleanup, store: failedStore, journal: failedJournal)
      let blockedStore = FakeStore()
      let blockedJournal = FakeJournal()
      blockedJournal.failAttempt = true
      try Probe.require(await rejected(.saveA, blockedStore, blockedJournal))
      try Probe.require(await blockedStore.writes == 0)
      try Probe.require(await rejected(.cleanup, blockedStore, blockedJournal))
      let checks = 7 + (try await absenceChecks()) + (try admissionChecks())
      print("{\"mode\":\"fake-only\",\"checks\":\(checks),\"passed\":true}")
    } catch {
      print("{\"mode\":\"fake-only\",\"passed\":false}")
      exit(1)
    }
  }
}

if CommandLine.arguments.dropFirst().elementsEqual(["--self-test"]) {
  await SelfTests.run()
} else {
  await Probe.run()
}
