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
  var service: String { "local.rivet.experiments.E008.\(namespace)" }
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
  static func context(_ root: URL, _ ticketID: String) throws -> LiveContext {
    guard UUID(uuidString: ticketID)?.uuidString.lowercased() == ticketID,
      root.lastPathComponent.hasPrefix("rivet-E008-"), !root.path.hasPrefix("/private/tmp/"),
      !root.path.hasPrefix("/tmp/"), !root.path.hasPrefix("/private/var/folders/") else { throw ProbeError.guardRejected }
    let namespace = String(root.lastPathComponent.dropFirst("rivet-E008-".count))
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
      window["globalSHA256"] as? String == globalHash, window["number"] as? Int == number,
      windowStart <= now, abs(try date(window["cutoffUTC"]).timeIntervalSince(windowStart) - 1500) < 0.01,
      abs(try date(window["deadlineUTC"]).timeIntervalSince(windowStart) - 1800) < 0.01 else { throw ProbeError.guardRejected }
    let cleanup = ticket["cleanup"] as? Bool == true
    if cleanup {
      guard operation == .cleanup else { throw ProbeError.guardRejected }
    } else {
      let cutoff = try date(window["cutoffUTC"])
      let abort = try safe(root, "abort.json")
      guard now < deadline, now < cutoff, !FileManager.default.fileExists(atPath: abort.path),
        let readyHash = ticket["readySHA256"] as? String else { throw ProbeError.guardRejected }
      let (ready, readyBytes) = try object(root, "gates/\(stage).json")
      guard hash(readyBytes) == readyHash, ready["namespace"] as? String == context.namespace,
        ready["stage"] as? String == stage, ready["synthetic"] as? Bool == false, ready["humanReady"] as? Bool == true,
        let statement = ready["humanReadyStatement"] as? String, !statement.isEmpty,
        try date(ready["recordedUTC"]) <= now else { throw ProbeError.guardRejected }
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
    #if E008_REBUILT
      let marker = "rebuilt"
    #else
      let marker = "initial"
    #endif
    guard bundle.object(forInfoDictionaryKey: "E008BuildMarker") as? String == marker,
      proof["buildMarker"] as? String == marker else { throw ProbeError.guardRejected }
    try write(root, "consumed/\(context.ticketID).json", ["namespace": context.namespace, "ticket": context.ticketID])
    return LiveAuthorization(context: context, group: group, operation: operation, proofHash: proofHash, executableHash: binaryHash)
  }
}
