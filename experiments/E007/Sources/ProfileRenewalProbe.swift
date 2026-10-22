import AppKit
import CryptoKit
import Foundation
import Security
import SystemConfiguration

struct FakeBundle: Codable, Equatable {
  let accessToken: String
  let refreshToken: String
  let accessTokenExpiresAt: Date
  let refreshTokenExpiresAt: Date
  let tokenType: String
  let grantedScopes: String

  static let fixture = FakeBundle(
    accessToken: "fake-E007-access", refreshToken: "fake-E007-refresh",
    accessTokenExpiresAt: Date(timeIntervalSince1970: 2_000_000_120.125),
    refreshTokenExpiresAt: Date(timeIntervalSince1970: 2_000_008_640.5),
    tokenType: "bearer", grantedScopes: "repo read:user"
  )

  func comparisons() -> [String: Bool] {
    let expected = Self.fixture
    return [
      "accessToken": accessToken == expected.accessToken,
      "refreshToken": refreshToken == expected.refreshToken,
      "accessTokenExpiresAt": accessTokenExpiresAt == expected.accessTokenExpiresAt,
      "refreshTokenExpiresAt": refreshTokenExpiresAt == expected.refreshTokenExpiresAt,
      "tokenType": tokenType == expected.tokenType,
      "grantedScopes": grantedScopes == expected.grantedScopes,
    ]
  }
}

extension FakeBundle: CustomStringConvertible {
  var description: String { "FakeBundle(<redacted>)" }
}

extension FakeBundle: CustomDebugStringConvertible {
  var debugDescription: String { description }
}

extension FakeBundle: CustomReflectable {
  var customMirror: Mirror { Mirror(self, children: ["credential": "<redacted>"]) }
}

enum ProbeFailure: Error {
  case guardRejected, missing, invalidData, comparison
  case security(Int32)

  var classification: String {
    switch self {
    case .guardRejected: "guardRejected"
    case .missing: "missing"
    case .invalidData: "invalidData"
    case .comparison: "comparison"
    case .security(let status):
      switch status {
      case errSecAuthFailed, errSecUserCanceled: "accessDenied"
      case errSecInteractionNotAllowed: "interactionUnavailable"
      default: "securityFailure"
      }
    }
  }
}

enum ProbeFiles {
  static func nowString() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: Date())
  }

  static func sha(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  static func date(_ value: Any?) throws -> Date {
    guard let text = value as? String else { throw ProbeFailure.guardRejected }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let result = formatter.date(from: text) { return result }
    formatter.formatOptions = [.withInternetDateTime]
    guard let result = formatter.date(from: text) else { throw ProbeFailure.guardRejected }
    return result
  }

  static func validateTime(
    start: Date, cutoff: Date, deadline: Date, now: Date, phase: Int
  ) throws {
    guard (1...3).contains(phase), start <= now,
      abs(cutoff.timeIntervalSince(start) - 2100) < 0.01,
      abs(deadline.timeIntervalSince(start) - 2700) < 0.01,
      phase == 3 || now < cutoff
    else { throw ProbeFailure.guardRejected }
  }

  static func safe(_ root: URL, _ relative: String) throws -> URL {
    guard !relative.hasPrefix("/"), !relative.split(separator: "/").contains("..") else {
      throw ProbeFailure.guardRejected
    }
    var current = root
    for part in relative.split(separator: "/") {
      current.appendPathComponent(String(part))
      if (try? current.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true {
        throw ProbeFailure.guardRejected
      }
    }
    return current
  }

  static func object(_ root: URL, _ relative: String) throws -> ([String: Any], Data) {
    let data = try Data(contentsOf: safe(root, relative))
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw ProbeFailure.guardRejected
    }
    return (object, data)
  }

  static func writeExclusive(_ root: URL, _ relative: String, _ value: [String: Any]) throws {
    let url = try safe(root, relative)
    let data = try JSONSerialization.data(
      withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
    let descriptor = url.path.withCString {
      open($0, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
    }
    guard descriptor >= 0 else { throw ProbeFailure.guardRejected }
    let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    try handle.write(contentsOf: data)
    try handle.write(contentsOf: Data([10]))
    try handle.close()
  }
}

struct Permit {
  let root: URL
  let namespace: String
  let phase: Int
  let group: String
  let profileHash: String
  let binaryHash: String
  let windowHash: String

  static func authorize(root: URL, namespace: String, phase: Int) throws -> Permit {
    let now = Date()
    let bundle = Bundle.main
    let attributes = try FileManager.default.attributesOfItem(atPath: root.path)
    var consoleUID: uid_t = 0
    var consoleGID: gid_t = 0
    let console = SCDynamicStoreCopyConsoleUser(nil, &consoleUID, &consoleGID) as String?
    guard getuid() != 0, consoleUID == getuid(), console != nil, console != "loginwindow",
      UUID(uuidString: namespace)?.uuidString.lowercased() == namespace,
      root.lastPathComponent == "rivet-E007-\(namespace)",
      (try root.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])).isDirectory == true,
      (try root.resourceValues(forKeys: [.isSymbolicLinkKey])).isSymbolicLink != true,
      (attributes[.ownerAccountID] as? NSNumber)?.uint32Value == getuid(),
      (attributes[.posixPermissions] as? NSNumber)?.intValue == 0o700,
      (1...3).contains(phase)
    else { throw ProbeFailure.guardRejected }

    let (window, windowData) = try ProbeFiles.object(root, "window.json")
    let (permit, _) = try ProbeFiles.object(root, "private/permit-\(phase).json")
    let start = try ProbeFiles.date(window["startUTC"])
    let cutoff = try ProbeFiles.date(window["cutoffUTC"])
    let deadline = try ProbeFiles.date(window["deadlineUTC"])
    try ProbeFiles.validateTime(
      start: start, cutoff: cutoff, deadline: deadline, now: now, phase: phase)

    let expectedID = "local.rivet.renewalprobe." + namespace.replacingOccurrences(of: "-", with: "")
    let current = try ProbeFiles.safe(root, "current/ProfileRenewalProbe.app")
    guard window["namespace"] as? String == namespace,
      window["kind"] as? String == "setup-window",
      window["synthetic"] as? Bool == false,
      window["observationMode"] as? String == "human-only",
      let ready = window["humanReadyStatement"] as? String, !ready.isEmpty,
      let freeTeam = window["freePersonalTeamStatement"] as? String, !freeTeam.isEmpty,
      permit["namespace"] as? String == namespace, permit["phase"] as? Int == phase,
      permit["operation"] as? String == (phase == 1 ? "save" : phase == 2 ? "read" : "cleanup"),
      permit["windowSHA256"] as? String == ProbeFiles.sha(windowData),
      let phaseReady = permit["humanReadyStatement"] as? String, !phaseReady.isEmpty,
      try ProbeFiles.date(permit["createdUTC"]) <= now,
      bundle.bundleIdentifier == expectedID, permit["bundleID"] as? String == expectedID,
      bundle.bundleURL.standardizedFileURL == current.standardizedFileURL,
      let executable = bundle.executableURL, let group = permit["group"] as? String,
      group.hasSuffix("." + expectedID), !group.contains("*"),
      let profileHash = permit["profileSHA256"] as? String,
      let binaryHash = permit["executableSHA256"] as? String,
      ProbeFiles.sha(try Data(contentsOf: executable)) == binaryHash,
      ProbeFiles.sha(
        try Data(
          contentsOf: bundle.bundleURL.appendingPathComponent("Contents/embedded.provisionprofile"))
      )
        == profileHash
    else { throw ProbeFailure.guardRejected }

    if phase == 2 {
      let (human, humanData) = try ProbeFiles.object(root, "receipts/phase-1.human.json")
      let (_, machineData) = try ProbeFiles.object(root, "receipts/phase-1.machine.json")
      guard permit["initialProfileSHA256"] as? String != profileHash,
        permit["previousHumanSHA256"] as? String == ProbeFiles.sha(humanData),
        human["namespace"] as? String == namespace, human["phase"] as? Int == 1,
        human["wholeStageObserved"] as? Bool == true,
        human["machineReceiptSHA256"] as? String == ProbeFiles.sha(machineData),
        let count = human["promptCount"] as? NSNumber,
        CFGetTypeID(count) != CFBooleanGetTypeID(), (0...1).contains(count.intValue),
        count.doubleValue == Double(count.intValue)
      else { throw ProbeFailure.guardRejected }
    }
    return Permit(
      root: root, namespace: namespace, phase: phase, group: group,
      profileHash: profileHash, binaryHash: binaryHash, windowHash: ProbeFiles.sha(windowData))
  }
}

protocol ProbeStore {
  func add(_ data: Data) throws
  func load() throws -> Data?
  func delete() throws
}

final class ProbeCore {
  let store: any ProbeStore
  private(set) var readAttempted = false

  init(store: any ProbeStore) { self.store = store }

  func perform(phase: Int) throws -> [String: Any] {
    guard (1...3).contains(phase) else { throw ProbeFailure.guardRejected }
    if phase == 3 {
      try store.delete()
      readAttempted = true
      guard try store.load() == nil else { throw ProbeFailure.comparison }
      return ["absent": true]
    }
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    if phase == 1 { try store.add(encoder.encode(FakeBundle.fixture)) }
    readAttempted = true
    guard let data = try store.load() else { throw ProbeFailure.missing }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    let value: FakeBundle
    do { value = try decoder.decode(FakeBundle.self, from: data) } catch {
      throw ProbeFailure.invalidData
    }
    let fields = value.comparisons()
    guard fields.count == 6, fields.values.allSatisfy({ $0 }) else { throw ProbeFailure.comparison }
    return ["fields": fields]
  }
}

final class DataProtectionStore: ProbeStore {
  private let permit: Permit
  init(permit: Permit) { self.permit = permit }

  private var query: [CFString: Any] {
    [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: "local.rivet.experiments.E007.\(permit.namespace)",
      kSecAttrAccount: "oauth-bundle", kSecAttrAccessGroup: permit.group,
      kSecUseDataProtectionKeychain: true, kSecAttrSynchronizable: false,
    ]
  }

  func add(_ data: Data) throws {
    guard permit.phase == 1 else { throw ProbeFailure.guardRejected }
    var request = query
    request[kSecValueData] = data
    request[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let status = SecItemAdd(request as CFDictionary, nil)
    guard status == errSecSuccess else { throw ProbeFailure.security(status) }
  }

  func load() throws -> Data? {
    var request = query
    request[kSecReturnData] = true
    request[kSecMatchLimit] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(request as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw ProbeFailure.security(status) }
    guard let data = result as? Data else { throw ProbeFailure.invalidData }
    return data
  }

  func delete() throws {
    guard permit.phase == 3 else { throw ProbeFailure.guardRejected }
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw ProbeFailure.security(status)
    }
  }
}

#if !E007_TESTING
  @main
  enum ProbeMain {
    @MainActor static func main() {
      let application = NSApplication.shared
      let delegate = ProbeDelegate()
      application.delegate = delegate
      application.setActivationPolicy(.regular)
      application.run()
      withExtendedLifetime(delegate) {}
    }
  }

  @MainActor
  final class ProbeDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
      let label = NSTextField(labelWithString: "E007 隔離假憑證：驗證前提")
      label.frame = NSRect(x: 20, y: 25, width: 500, height: 40)
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 540, height: 100),
        styleMask: [.titled], backing: .buffered, defer: false)
      window.title = "E007 profile 更新驗證"
      window.contentView?.addSubview(label)
      window.center()
      window.makeKeyAndOrderFront(nil)
      self.window = window
      NSApp.activate(ignoringOtherApps: true)
      DispatchQueue.main.async { self.performOnce() }
    }

    private func performOnce() {
      var permit: Permit?
      var operation: ProbeCore?
      var receipt: [String: Any] = [:]
      do {
        let args = Array(CommandLine.arguments.dropFirst())
        guard args.count == 6, args[0] == "--root", args[2] == "--namespace",
          args[4] == "--phase", let phase = Int(args[5])
        else { throw ProbeFailure.guardRejected }
        let authorization = try Permit.authorize(
          root: URL(fileURLWithPath: args[1]),
          namespace: args[3], phase: phase)
        permit = authorization
        try ProbeFiles.writeExclusive(
          authorization.root, "private/process-\(phase).json",
          ["pid": getpid(), "phase": phase])
        receipt = [
          "namespace": authorization.namespace, "phase": phase,
          "startedUTC": ProbeFiles.nowString(),
          "synthetic": false, "observationMode": "human-only", "promptCount": NSNull(),
          "profileSHA256": authorization.profileHash, "executableSHA256": authorization.binaryHash,
          "windowSHA256": authorization.windowHash,
        ]
        let selectedOperation = ProbeCore(store: DataProtectionStore(permit: authorization))
        operation = selectedOperation
        let result = try selectedOperation.perform(phase: phase)
        receipt.merge(result) { _, new in new }
        receipt["completed"] = true
      } catch {
        let failure = error as? ProbeFailure
        receipt["completed"] = false
        receipt["error"] = failure?.classification ?? "guardRejected"
        if case .security(let status)? = failure { receipt["status"] = status }
      }
      receipt["readAttempted"] = operation?.readAttempted ?? false
      receipt["endedUTC"] = ProbeFiles.nowString()
      if let permit {
        let name = permit.phase == 3 ? "cleanup.machine.json" : "phase-\(permit.phase).machine.json"
        try? ProbeFiles.writeExclusive(permit.root, "receipts/\(name)", receipt)
      }
      NSApp.terminate(nil)
    }
  }
#endif
