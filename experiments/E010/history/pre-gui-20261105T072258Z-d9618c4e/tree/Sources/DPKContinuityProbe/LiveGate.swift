import CryptoKit
import Foundation
import CoreFoundation

struct LiveContext {
  let root: URL; let namespace: String; let ticketID: String; let ticket: [String: Any]
}
struct LiveAuthorization {
  fileprivate let context: LiveContext
  fileprivate let group: String
  fileprivate let operation: Operation
  fileprivate let proofHash: String
  fileprivate let executableHash: String
  var root: URL { context.root }
  var namespace: String { context.namespace }
  var stage: String { context.ticket["stage"] as? String ?? "rejected" }
  var ticketID: String { context.ticketID }
  var action: Operation { operation }
  var accessGroup: String { group }
  var service: String { "local.rivet.experiments.E010.\(namespace)" }
  var account: String { "oauth-bundle" }
  var proofSHA256: String { proofHash }
  var executableSHA256: String { executableHash }
}

enum LiveGate {
  static func hash(_ bytes: Data) -> String { SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined() }
  static func date(_ value: Any?) throws -> Date {
    guard let value = value as? String else { throw ProbeError.guardRejected }
    let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let result = f.date(from: value) { return result }
    f.formatOptions = [.withInternetDateTime]
    guard let result = f.date(from: value) else { throw ProbeError.guardRejected }; return result
  }
  static func safe(_ root: URL, _ relative: String) throws -> URL {
    guard !relative.hasPrefix("/"), !relative.split(separator: "/").contains("..") else { throw ProbeError.guardRejected }
    var current = root
    for part in relative.split(separator: "/") {
      current.appendPathComponent(String(part))
      if (try? current.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true { throw ProbeError.guardRejected }
    }
    return current
  }
  static func object(_ root: URL, _ relative: String) throws -> ([String: Any], Data) {
    let raw = try Data(contentsOf: safe(root, relative))
    guard raw.last == 10, let value = try JSONSerialization.jsonObject(with: raw) as? [String: Any] else { throw ProbeError.guardRejected }
    return (value, raw)
  }
  static func write(_ root: URL, _ relative: String, _ value: [String: Any]) throws {
    let target = try safe(root, relative)
    try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    let raw = try CanonicalJSON.data(value)
    let fd = target.path.withCString { open($0, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600) }
    guard fd >= 0 else { throw ProbeError.guardRejected }
    let stream = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
    try stream.write(contentsOf: raw); try stream.synchronize(); try stream.close()
  }
  static func validateExperimentIdentity(_ root: URL, global: [String: Any]) throws {
    guard let namespace = global["namespace"] as? String,
      UUID(uuidString: namespace)?.uuidString.lowercased() == namespace,
      root.lastPathComponent == "rivet-E010-" + namespace,
      global["kind"] as? String == "E010-global",
      global["service"] as? String == "local.rivet.experiments.E010." + namespace,
      global["bundleIdentifier"] as? String == "local.rivet.dpkcontinuity." + namespace.replacingOccurrences(of: "-", with: ""),
      global["account"] as? String == "oauth-bundle" else { throw ProbeError.guardRejected }
  }
  static func validateMainConsent(_ root: URL, global: [String: Any], now: Date) throws {
    let (consent, raw) = try object(root, "main-consent.json")
    let start = try date(global["startUTC"])
    guard global["authorizationMode"] as? String == "main-package",
      global["mainConsentSHA256"] as? String == hash(raw),
      consent["kind"] as? String == "E010-main-package-consent", consent["authorizationMode"] as? String == "main-package",
      consent["namespace"] as? String == global["namespace"] as? String,
      consent["synthetic"] as? Bool == global["synthetic"] as? Bool, consent["approved"] as? Bool == true,
      consent["statement"] as? String == "確認批准整包，包含跨週留存、本人認證／跨日喚起，以及第7項故障殘留交接例外。",
      consent["approvedUTC"] as? String == "2026-11-04T08:56:05Z", consent["latestStartUTC"] as? String == "2026-11-05T08:56:05Z",
      consent["grantsValidUntilUTC"] as? String == "2026-11-15T08:56:05Z", consent["retentionRoot"] as? String == root.path,
      consent["maxMainSignedBuilds"] as? Int == 3, consent["maxCleanupSignedBuilds"] as? Int == 1,
      consent["actions"] as? [String] == ["preflight", "seed", "fresh", "expired", "p1-setup", "p1-read", "rebuild-setup", "rebuilt-read", "cleanup"],
      NSDictionary(dictionary: consent["sourceSHA256"] as? [String: String] ?? [:]).isEqual(to: global["sourceSHA256"] as? [String: String] ?? [:]),
      start >= (try date(consent["approvedUTC"])), start <= (try date(consent["latestStartUTC"])), start <= now,
      now < (try date(consent["grantsValidUntilUTC"])), now < (try date(global["globalDeadlineUTC"])) else { throw ProbeError.guardRejected }
    guard let grantHashes = global["grantSHA256"] as? [String: String] else { throw ProbeError.guardRejected }
    for kind in ["assets", "retention", "recovery"] {
      let (grant, bytes) = try object(root, "grants/\(kind).json")
      guard grantHashes[kind] == hash(bytes), grant["kind"] as? String == "human-grant", grant["scope"] as? String == kind,
        grant["namespace"] as? String == global["namespace"] as? String, grant["synthetic"] as? Bool == global["synthetic"] as? Bool,
        grant["approved"] as? Bool == true, grant["authorizationMode"] as? String == "main-package",
        grant["mainConsentSHA256"] as? String == hash(raw), grant["retentionRoot"] as? String == root.path,
        grant["validUntilUTC"] as? String == "2026-11-15T08:56:05Z",
        !(grant["statement"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        NSDictionary(dictionary: grant["sourceSHA256"] as? [String: String] ?? [:]).isEqual(to: global["sourceSHA256"] as? [String: String] ?? [:]) else { throw ProbeError.guardRejected }
      if kind == "recovery" { guard grant["residualItemAccepted"] as? Bool == true, !(grant["procedure"] as? String ?? "").isEmpty else { throw ProbeError.guardRejected } }
    }
  }
  static func validatePackageAction(_ gate: [String: Any], global: [String: Any], stage: String, previous: String, window: [String: Any], windowHash: String, now: Date) throws {
    guard gate["kind"] as? String == "package-action", gate["authorizationMode"] as? String == "main-package",
      gate["namespace"] as? String == global["namespace"] as? String, gate["synthetic"] as? Bool == global["synthetic"] as? Bool,
      gate["stage"] as? String == stage, gate["mainConsentSHA256"] as? String == global["mainConsentSHA256"] as? String,
      gate["previousReceiptSHA256"] as? String == previous, gate["windowSHA256"] as? String == windowHash,
      gate["humanReady"] == nil, gate["humanReadyStatement"] == nil, gate["wholeStageObserved"] == nil, gate["promptCount"] == nil,
      NSDictionary(dictionary: gate["sourceSHA256"] as? [String: String] ?? [:]).isEqual(to: global["sourceSHA256"] as? [String: String] ?? [:]),
      try date(gate["recordedUTC"]) >= date(window["startUTC"]), try date(gate["recordedUTC"]) <= now else { throw ProbeError.guardRejected }
  }
  static func validateMainWindowChain(_ root: URL, global: [String: Any], globalHash: String, number: Int, now: Date) throws {
    try validateMainConsent(root, global: global, now: now)
    let (anchor, anchorRaw) = try object(root, "anchor.json"); let anchorHash = hash(anchorRaw)
    let (anchorBinding, _) = try object(root, "anchor.binding.json")
    let (window, windowRaw) = try object(root, "windows/1.json"); let windowHash = hash(windowRaw)
    let (windowBinding, _) = try object(root, "windows/1.binding.json")
    guard anchor["kind"] as? String == "E010-anchor", anchor["p0ExpiryUTC"] == nil, anchor["certificateNotAfterUTC"] == nil,
      anchorBinding["anchorSHA256"] as? String == anchorHash, global["anchorSHA256"] as? String == anchorHash,
      global["window1SHA256"] as? String == windowHash, window["anchorSHA256"] as? String == anchorHash,
      window["globalSHA256"] == nil, windowBinding["windowSHA256"] as? String == windowHash,
      window["number"] as? Int == 1, window["namespace"] as? String == global["namespace"] as? String else { throw ProbeError.guardRejected }
    for key in ["namespace", "synthetic", "backend", "startUTC", "globalDeadlineUTC", "maxWindows", "hostBinding", "hostBindingSHA256", "sourceSHA256", "grantSHA256", "authorizationMode", "mainConsentSHA256", "bundleIdentifier", "service", "account", "fixture", "fixtureSHA256", "publicEvidenceDirectory"] {
      guard let left = anchor[key], let right = global[key], NSDictionary(dictionary: [key:left]).isEqual(to: [key:right]) else { throw ProbeError.guardRejected }
    }
    let start = try date(global["startUTC"])
    guard try date(window["startUTC"]) == start, abs(try date(window["cutoffUTC"]).timeIntervalSince(start)-1500)<0.01,
      abs(try date(window["deadlineUTC"]).timeIntervalSince(start)-1800)<0.01,
      abs(try date(global["globalDeadlineUTC"]).timeIntervalSince(start)-864000)<0.01 else { throw ProbeError.guardRejected }
    let (begin, beginRaw) = try object(root, "bootstrap/begin.machine.json")
    let (setup, setupRaw) = try object(root, "bootstrap/setup.ready.json")
    try validatePackageAction(setup, global: global, stage: "setup-only", previous: hash(beginRaw), window: window, windowHash: windowHash, now: now)
    guard setup["anchorSHA256"] as? String == anchorHash, try date(setup["recordedUTC"]) >= date(begin["endedUTC"]) else { throw ProbeError.guardRejected }
    let (proof, proofRaw) = try object(root, "bootstrap/actual-proof.json"); let (_, p0Raw) = try object(root, "proofs/p0.json")
    let (proofBinding, proofBindingRaw) = try object(root, "bootstrap/proof.binding.json")
    let (complete, completeRaw) = try object(root, "bootstrap/complete.json")
    let (machine, machineRaw) = try object(root, "bootstrap/setup.machine.json")
    let (seed, _) = try object(root, "bootstrap/seed.ready.json")
    try validatePackageAction(seed, global: global, stage: "seed-ready", previous: hash(machineRaw), window: window, windowHash: windowHash, now: now)
    guard proof["profileSignatureVerified"] as? Bool == true, proof["certificateInProfile"] as? Bool == true, proof["appleDevelopmentChainVerified"] as? Bool == true,
      proof["hostBindingSHA256"] as? String == global["hostBindingSHA256"] as? String,
      NSDictionary(dictionary: proof["sourceSHA256"] as? [String:String] ?? [:]).isEqual(to: global["sourceSHA256"] as? [String:String] ?? [:]),
      hash(proofRaw) == hash(p0Raw), global["actualSetupProofSHA256"] as? String == hash(proofRaw),
      global["setupProofBindingSHA256"] as? String == hash(proofBindingRaw), proofBinding["actualProofSHA256"] as? String == hash(proofRaw),
      proofBinding["anchorSHA256"] as? String == anchorHash, proofBinding["windowSHA256"] as? String == windowHash,
      proofBinding["setupReadySHA256"] as? String == hash(setupRaw), complete["globalSHA256"] as? String == globalHash,
      complete["anchorSHA256"] as? String == anchorHash, complete["windowSHA256"] as? String == windowHash,
      complete["actualProofSHA256"] as? String == hash(proofRaw), machine["completionSHA256"] as? String == hash(completeRaw),
      machine["globalSHA256"] as? String == globalHash, machine["completed"] as? Bool == true, machine["callAttempted"] as? Bool == false,
      seed["globalSHA256"] as? String == globalHash, try date(seed["recordedUTC"]) >= date(machine["endedUTC"]),
      try date(machine["endedUTC"]) < date(window["cutoffUTC"]),
      global["p0ExpiryUTC"] as? String == proof["profileExpiryUTC"] as? String,
      global["certificateNotAfterUTC"] as? String == proof["certificateNotAfterUTC"] as? String,
      try date(proof["profileExpiryUTC"]) <= date(global["globalDeadlineUTC"]).addingTimeInterval(-1800),
      try date(proof["certificateNotAfterUTC"]) >= date(global["globalDeadlineUTC"]).addingTimeInterval(2100) else { throw ProbeError.guardRejected }
    if number != 1 {
      let (later, laterRaw) = try object(root, "windows/\(number).json"); let (binding, _) = try object(root, "windows/\(number).binding.json")
      guard (2...3).contains(number), later["number"] as? Int == number, later["globalSHA256"] as? String == globalHash,
        binding["windowSHA256"] as? String == hash(laterRaw), later["mainConsentSHA256"] as? String == global["mainConsentSHA256"] as? String else { throw ProbeError.guardRejected }
      let prior = number == 2 ? "fresh" : "p1-read"
      let (event, eventRaw) = try object(root, "receipts/\(prior).machine.json"); let (retained, _) = try object(root, "retained-\(number-1).json")
      guard retained["globalSHA256"] as? String == globalHash, retained["machineReceiptSHA256"] as? String == hash(eventRaw),
        event["completed"] as? Bool == true, retained["state"] as? String == "retained-no-background-process" else { throw ProbeError.guardRejected }
      if number == 2 { guard now >= (try date(global["p0ExpiryUTC"])) else { throw ProbeError.guardRejected } }
    }
  }
  static func validateWindowChain(_ root: URL, global: [String: Any], globalHash: String, number: Int, now: Date) throws {
    try validateExperimentIdentity(root, global: global)
    if global["authorizationMode"] as? String == "main-package" {
      try validateMainWindowChain(root, global: global, globalHash: globalHash, number: number, now: now); return
    }
    guard global["authorizationMode"] == nil else { throw ProbeError.guardRejected }
    let (window, windowRaw) = try object(root, "windows/\(number).json")
    let (windowBinding, _) = try object(root, "windows/\(number).binding.json")
    let windowHash = hash(windowRaw)
    guard (1...3).contains(number), window["number"] as? Int == number,
      windowBinding["windowSHA256"] as? String == windowHash else { throw ProbeError.guardRejected }
    if number != 1 {
      guard window["globalSHA256"] as? String == globalHash else { throw ProbeError.guardRejected }
      return
    }
    let (anchor, anchorRaw) = try object(root, "anchor.json")
    let (anchorBinding, _) = try object(root, "anchor.binding.json")
    let anchorHash = hash(anchorRaw)
    guard anchor["kind"] as? String == "E010-anchor", global["kind"] as? String == "E010-global",
      anchor["p0ExpiryUTC"] == nil, anchor["certificateNotAfterUTC"] == nil,
      window["globalSHA256"] == nil, anchorBinding["anchorSHA256"] as? String == anchorHash,
      window["anchorSHA256"] as? String == anchorHash, global["anchorSHA256"] as? String == anchorHash,
      global["window1SHA256"] as? String == windowHash, window["namespace"] as? String == anchor["namespace"] as? String,
      window["synthetic"] as? Bool == anchor["synthetic"] as? Bool, window["beginReadySHA256"] as? String == anchor["beginReadySHA256"] as? String,
      anchor["maxWindows"] as? Int == 3 else { throw ProbeError.guardRejected }
    for key in ["namespace", "synthetic", "backend", "startUTC", "globalDeadlineUTC", "maxWindows", "hostBinding", "hostBindingSHA256", "sourceSHA256", "grantSHA256", "beginReadySHA256", "bundleIdentifier", "service", "account", "fixture", "fixtureSHA256", "publicEvidenceDirectory"] {
      guard let left = anchor[key], let right = global[key],
        NSDictionary(dictionary: [key: left]).isEqual(to: [key: right]) else { throw ProbeError.guardRejected }
    }
    let start = try date(anchor["startUTC"])
    guard try date(window["startUTC"]) == start,
      abs(try date(window["cutoffUTC"]).timeIntervalSince(start) - 1500) < 0.01,
      abs(try date(window["deadlineUTC"]).timeIntervalSince(start) - 1800) < 0.01,
      abs(try date(global["globalDeadlineUTC"]).timeIntervalSince(start) - 864000) < 0.01 else { throw ProbeError.guardRejected }
    let (_, beginRaw) = try object(root, "bootstrap/begin.ready.json")
    let (beginMachine, beginMachineRaw) = try object(root, "bootstrap/begin.machine.json")
    let (beginHuman, beginHumanRaw) = try object(root, "bootstrap/begin.human.json")
    let (setupReady, setupReadyRaw) = try object(root, "bootstrap/setup.ready.json")
    let (proof, proofRaw) = try object(root, "bootstrap/actual-proof.json")
    let (_, p0Raw) = try object(root, "proofs/p0.json")
    let (proofBinding, proofBindingRaw) = try object(root, "bootstrap/proof.binding.json")
    let (complete, completeRaw) = try object(root, "bootstrap/complete.json")
    let (machine, machineRaw) = try object(root, "bootstrap/setup.machine.json")
    let (human, humanRaw) = try object(root, "bootstrap/setup.human.json")
    let (ready, _) = try object(root, "bootstrap/seed.ready.json")
    guard anchor["beginReadySHA256"] as? String == hash(beginRaw),
      beginHuman["machineReceiptSHA256"] as? String == hash(beginMachineRaw), beginHuman["wholeStageObserved"] as? Bool == true,
      beginHuman["phaseIdentified"] as? Bool == true, beginHuman["namespace"] as? String == global["namespace"] as? String,
      beginHuman["stage"] as? String == "begin-anchor", try date(beginHuman["recordedUTC"]) >= date(beginMachine["endedUTC"]),
      setupReady["previousReceiptSHA256"] as? String == hash(beginMachineRaw), setupReady["previousHumanSHA256"] as? String == hash(beginHumanRaw),
      try date(setupReady["recordedUTC"]) >= date(beginHuman["recordedUTC"]), setupReady["humanReady"] as? Bool == true,
      setupReady["stage"] as? String == "setup-only", setupReady["anchorSHA256"] as? String == anchorHash, setupReady["windowSHA256"] as? String == windowHash,
      proof["profileSignatureVerified"] as? Bool == true, proof["certificateInProfile"] as? Bool == true, proof["appleDevelopmentChainVerified"] as? Bool == true,
      proof["hostBindingSHA256"] as? String == global["hostBindingSHA256"] as? String,
      NSDictionary(dictionary: proof["sourceSHA256"] as? [String: String] ?? [:]).isEqual(to: global["sourceSHA256"] as? [String: String] ?? [:]),
      proofBinding["anchorSHA256"] as? String == anchorHash, proofBinding["windowSHA256"] as? String == windowHash,
      proofBinding["setupReadySHA256"] as? String == hash(setupReadyRaw), proofBinding["actualProofSHA256"] as? String == hash(proofRaw),
      global["actualSetupProofSHA256"] as? String == hash(proofRaw), hash(p0Raw) == hash(proofRaw),
      global["setupProofBindingSHA256"] as? String == hash(proofBindingRaw),
      global["p0ExpiryUTC"] as? String == proof["profileExpiryUTC"] as? String,
      global["certificateNotAfterUTC"] as? String == proof["certificateNotAfterUTC"] as? String,
      complete["globalSHA256"] as? String == globalHash, complete["anchorSHA256"] as? String == anchorHash,
      complete["windowSHA256"] as? String == windowHash, complete["actualProofSHA256"] as? String == hash(proofRaw),
      machine["completionSHA256"] as? String == hash(completeRaw), machine["globalSHA256"] as? String == globalHash,
      machine["completed"] as? Bool == true, machine["callAttempted"] as? Bool == false,
      human["namespace"] as? String == global["namespace"] as? String, human["stage"] as? String == "setup-only",
      human["machineReceiptSHA256"] as? String == hash(machineRaw), human["wholeStageObserved"] as? Bool == true,
      human["phaseIdentified"] as? Bool == true, try date(human["recordedUTC"]) >= date(machine["endedUTC"]),
      try date(human["recordedUTC"]) <= now, ready["stage"] as? String == "seed-ready",
      ready["namespace"] as? String == global["namespace"] as? String, ready["globalSHA256"] as? String == globalHash,
      ready["anchorSHA256"] as? String == anchorHash, ready["windowSHA256"] as? String == windowHash,
      ready["previousReceiptSHA256"] as? String == hash(machineRaw), ready["previousHumanSHA256"] as? String == hash(humanRaw),
      ready["humanReady"] as? Bool == true, !(ready["humanReadyStatement"] as? String ?? "").isEmpty,
      try date(ready["recordedUTC"]) > date(human["recordedUTC"]), try date(ready["recordedUTC"]) <= now else { throw ProbeError.guardRejected }
  }
  static func context(_ root: URL, _ ticketID: String) throws -> LiveContext {
    guard UUID(uuidString: ticketID)?.uuidString.lowercased() == ticketID,
      root.lastPathComponent.hasPrefix("rivet-E010-"), !root.path.hasPrefix("/private/tmp/"),
      !root.path.hasPrefix("/tmp/"), !root.path.hasPrefix("/private/var/folders/") else { throw ProbeError.guardRejected }
    let namespace = String(root.lastPathComponent.dropFirst("rivet-E010-".count))
    guard UUID(uuidString: namespace)?.uuidString.lowercased() == namespace else { throw ProbeError.guardRejected }
    var ancestor = root
    while ancestor.path != "/" {
      if (try? ancestor.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true || FileManager.default.fileExists(atPath: ancestor.appendingPathComponent(".git").path) { throw ProbeError.guardRejected }
      ancestor.deleteLastPathComponent()
    }
    let attrs = try FileManager.default.attributesOfItem(atPath: root.path)
    guard (attrs[.ownerAccountID] as? NSNumber)?.uint32Value == getuid(),
      (attrs[.posixPermissions] as? NSNumber)?.intValue == 0o700 else { throw ProbeError.guardRejected }
    let (ticket, _) = try object(root, "tickets/\(ticketID).json")
    guard ticket["namespace"] as? String == namespace, ticket["synthetic"] as? Bool == false else { throw ProbeError.guardRejected }
    return LiveContext(root: root, namespace: namespace, ticketID: ticketID, ticket: ticket)
  }
  static func authorize(_ context: LiveContext, guiUser: Bool, bundle: Bundle = .main, now: Date = Date()) throws -> LiveAuthorization {
    let root = context.root; let ticket = context.ticket
    let (global, raw) = try object(root, "global.json"); let globalHash = hash(raw)
    let (binding, _) = try object(root, "global.binding.json")
    guard guiUser, getuid() != 0, global["synthetic"] as? Bool == false, global["backend"] as? String == "dpk",
      global["namespace"] as? String == context.namespace, global["maxWindows"] as? Int == 3,
      binding["globalSHA256"] as? String == globalHash, ticket["globalSHA256"] as? String == globalHash,
      let grantHashes = global["grantSHA256"] as? [String: String],
      let number = ticket["window"] as? Int, (1...3).contains(number),
      let stage = ticket["stage"] as? String, let operationName = ticket["operation"] as? String,
      let operation = Operation(rawValue: operationName), let executable = bundle.executableURL,
      let proofRelative = ticket["proofRelative"] as? String, proofRelative.hasPrefix("proofs/")
    else { throw ProbeError.guardRejected }
    let start = try date(global["startUTC"]); let deadline = try date(global["globalDeadlineUTC"])
    guard start <= now, abs(deadline.timeIntervalSince(start) - 864_000) < 0.01 else { throw ProbeError.guardRejected }
    for kind in ["assets", "retention", "recovery"] {
      let (grant, bytes) = try object(root, "grants/\(kind).json")
      guard hash(bytes) == grantHashes[kind], grant["kind"] as? String == "human-grant", grant["scope"] as? String == kind,
        grant["namespace"] as? String == context.namespace, grant["synthetic"] as? Bool == false,
        grant["approved"] as? Bool == true, grant["retentionRoot"] as? String == root.path,
        let statement = grant["statement"] as? String, !statement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        try date(grant["validUntilUTC"]) >= deadline, try date(grant["validUntilUTC"]) > now else { throw ProbeError.guardRejected }
      if kind == "recovery" && (grant["procedure"] as? String ?? "").isEmpty { throw ProbeError.guardRejected }
    }
    let (window, windowBytes) = try object(root, "windows/\(number).json")
    let (windowBinding, _) = try object(root, "windows/\(number).binding.json")
    let windowStart = try date(window["startUTC"])
    guard windowBinding["windowSHA256"] as? String == hash(windowBytes), ticket["windowSHA256"] as? String == hash(windowBytes),
      window["number"] as? Int == number,
      windowStart <= now, abs(try date(window["cutoffUTC"]).timeIntervalSince(windowStart) - 1500) < 0.01,
      abs(try date(window["deadlineUTC"]).timeIntervalSince(windowStart) - 1800) < 0.01 else { throw ProbeError.guardRejected }
    try validateWindowChain(root, global: global, globalHash: globalHash, number: number, now: now)
    let mainPackage = global["authorizationMode"] as? String == "main-package"
    if mainPackage { guard now < (try date(window["deadlineUTC"])), now < deadline else { throw ProbeError.guardRejected } }
    let cleanup = ticket["cleanup"] as? Bool == true
    if cleanup {
      guard operation == .cleanup else { throw ProbeError.guardRejected }
    } else {
      let cutoff = try date(window["cutoffUTC"])
      let abort = try safe(root, "abort.json")
      guard now < deadline, now < cutoff, !FileManager.default.fileExists(atPath: abort.path),
        let readyHash = ticket["readySHA256"] as? String else { throw ProbeError.guardRejected }
      let (ready, readyBytes) = try object(root, "gates/\(stage).json")
      guard hash(readyBytes) == readyHash else { throw ProbeError.guardRejected }
      if mainPackage {
        let order = ["preflight", "seed", "fresh", "expired", "p1-setup", "p1-read", "rebuild-setup", "rebuilt-read", "cleanup"]
        guard let index = order.firstIndex(of: stage), index > 0 else { throw ProbeError.guardRejected }
        let (previous, previousRaw) = try object(root, "receipts/\(order[index-1]).machine.json")
        try validatePackageAction(ready, global: global, stage: stage, previous: hash(previousRaw), window: window, windowHash: hash(windowBytes), now: now)
        guard ready["globalSHA256"] as? String == globalHash, try date(ready["recordedUTC"]) >= date(previous["endedUTC"]) else { throw ProbeError.guardRejected }
      } else {
        guard ready["namespace"] as? String == context.namespace, ready["stage"] as? String == stage, ready["synthetic"] as? Bool == false,
          ready["humanReady"] as? Bool == true, let statement = ready["humanReadyStatement"] as? String, !statement.isEmpty,
          try date(ready["recordedUTC"]) <= now else { throw ProbeError.guardRejected }
      }
      guard (stage == "seed" && operation == .seed) || (["fresh", "expired", "p1-read", "rebuilt-read"].contains(stage) && operation == .read) else { throw ProbeError.guardRejected }
    }
    let (proof, proofBytes) = try object(root, proofRelative); let proofHash = hash(proofBytes)
    let binaryHash = hash(try Data(contentsOf: executable))
    let profilePath = bundle.bundleURL.appendingPathComponent("Contents/embedded.provisionprofile")
    guard ticket["proofSHA256"] as? String == proofHash, proof["synthetic"] as? Bool == false,
      proof["executableSHA256"] as? String == binaryHash,
      hash(try Data(contentsOf: profilePath)) == proof["profileSHA256"] as? String,
      bundle.bundleIdentifier == global["bundleIdentifier"] as? String,
      bundle.bundleURL.standardizedFileURL == (try safe(root, "current/DPKContinuityProbe.app")).standardizedFileURL,
      let entitlements = proof["entitlements"] as? [String: Any], let group = entitlements["com.apple.application-identifier"] as? String,
      entitlements["keychain-access-groups"] as? [String] == [group], !group.contains("*"),
      group.hasSuffix("." + (bundle.bundleIdentifier ?? "")),
      try date(proof["certificateNotBeforeUTC"]) <= now, try date(proof["certificateNotAfterUTC"]) > now,
      try date(proof["certificateNotAfterUTC"]) >= deadline.addingTimeInterval(2100)
    else { throw ProbeError.guardRejected }
    let expiry = try date(proof["profileExpiryUTC"])
    if stage == "expired" {
      let originalExpiry = try date(global["p0ExpiryUTC"])
      guard operation == .read, !cleanup, now >= expiry, expiry == originalExpiry, proofRelative == "proofs/p0.json" else { throw ProbeError.guardRejected }
    } else { guard expiry > now else { throw ProbeError.guardRejected } }
    let fixtureBytes = try JSONSerialization.data(withJSONObject: global["fixture"] ?? [:])
    guard try JSONDecoder().decode(FakeBundle.self, from: fixtureBytes) == FakeBundle.a else { throw ProbeError.guardRejected }
    #if E010_REBUILT
      let marker = "rebuilt"
    #else
      let marker = "initial"
    #endif
    guard bundle.object(forInfoDictionaryKey: "E010BuildMarker") as? String == marker,
      proof["buildMarker"] as? String == marker else { throw ProbeError.guardRejected }
    try write(root, "consumed/\(context.ticketID).json", ["namespace": context.namespace, "ticket": context.ticketID])
    return LiveAuthorization(context: context, group: group, operation: operation, proofHash: proofHash, executableHash: binaryHash)
  }
}
