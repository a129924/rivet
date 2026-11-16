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
    }
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
      let receipt: [String: Any] = [
        "runID": run.runID, "phase": phase.rawValue, "outcome": outcome,
        "processID": Int(getpid()), "processInstance": UUID().uuidString.lowercased(),
        "processStartSeconds": processInfo.pbi_start_tvsec,
        "processStartMicroseconds": processInfo.pbi_start_tvusec,
        "binarySHA256": SHA256.hash(data: try Data(contentsOf: binary)).map {
          String(format: "%02x", $0)
        }.joined(),
        "buildVariant": variant,
      ]
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
  func load() -> PersonalAccessToken? { value }
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
  static func rejected(_ phase: Phase, _ store: FakeStore, _ journal: FakeJournal) async -> Bool {
    do {
      try await Probe.perform(phase, store: store, journal: journal)
      return false
    } catch { return true }
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
      print("{\"mode\":\"fake-only\",\"checks\":7,\"passed\":true}")
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
