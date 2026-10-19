import CoreFoundation
import CryptoKit
import Foundation

struct LiveAuthorization {
  fileprivate let namespace: String
  fileprivate let accessGroup: String
  fileprivate let operation: Operation
  fileprivate let phase: Int
  fileprivate let proofSHA256: String
  fileprivate let executableSHA256: String
  fileprivate let scratch: URL
  fileprivate let startedUTC: String

  var service: String { "local.rivet.experiments.E006.\(namespace)" }
  var account: String { "oauth-bundle" }
  var group: String { accessGroup }
  var action: Operation { operation }
  var phaseNumber: Int { phase }
  var proofHash: String { proofSHA256 }
  var binaryHash: String { executableSHA256 }
  var root: URL { scratch }
  var started: String { startedUTC }
}

enum LiveGate {
  static func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
  static func date(_ value: Any?) throws -> Date {
    guard let value = value as? String else { throw ProbeError.guardRejected }
    let format = ISO8601DateFormatter()
    format.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let parsed = format.date(from: value) { return parsed }
    format.formatOptions = [.withInternetDateTime]
    guard let parsed = format.date(from: value) else { throw ProbeError.guardRejected }
    return parsed
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
    let data = try Data(contentsOf: safe(root, relative))
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw ProbeError.guardRejected }
    return (json, data)
  }
  static func authorize(root: URL, namespace: String, phase: Int, operation: Operation,
                        executable: URL, bundle: Bundle, guiUser: Bool, now: Date = Date()) throws -> LiveAuthorization {
    let resources = try root.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
    let attributes = try FileManager.default.attributesOfItem(atPath: root.path)
    guard guiUser, getuid() != 0, resources.isDirectory == true, resources.isSymbolicLink != true,
      (attributes[.ownerAccountID] as? NSNumber)?.uint32Value == getuid(),
      (attributes[.posixPermissions] as? NSNumber)?.intValue == 0o700,
      UUID(uuidString: namespace)?.uuidString.lowercased() == namespace,
      root.lastPathComponent == "rivet-E006-\(namespace)", (1...4).contains(phase),
      ((phase == 1 && operation == .saveReadA) || ((phase == 2 || phase == 3) && operation == .readA)
        || (phase == 4 && operation == .deleteReadAbsent)) else { throw ProbeError.guardRejected }
    let (run, _) = try object(root, "run.json")
    let (proof, proofData) = try object(root, "preflight.json")
    let hash = digest(try Data(contentsOf: executable))
    let expected: Any? = phase == 4 && [run["firstHash"] as? String, run["secondHash"] as? String].contains(hash) ? hash : (phase == 3 ? run["secondHash"] : run["firstHash"])
    let started = try date(run["startUTC"])
    let cutoff = try date(run["cutoffUTC"])
    let deadline = try date(run["deadlineUTC"])
    let cleanupRequest = try safe(root, "cleanup-request.json")
    let abortPath = try safe(root, "control/abort.json")
    let emergency = phase == 4 && FileManager.default.fileExists(atPath: cleanupRequest.path)
    // Cleanup may run after cutoff/deadline; it never permits save/read measurement.
    guard run["namespace"] as? String == namespace, run["observationMode"] as? String == "human-only",
      run["backend"] as? String == "dpk", run["synthetic"] as? Bool == false,
      run["proofSHA256"] as? String == digest(proofData),
      proof["namespace"] as? String == namespace, proof["kind"] as? String == "live",
      proof["synthetic"] as? Bool == false, proof["backend"] as? String == "dpk",
      proof["firstHash"] as? String == run["firstHash"] as? String,
      proof["secondHash"] as? String == run["secondHash"] as? String,
      run["firstHash"] as? String != run["secondHash"] as? String,
      started <= now, abs(cutoff.timeIntervalSince(started) - 1500) < 0.01,
      abs(deadline.timeIntervalSince(started) - 1800) < 0.01,
      try date(proof["expiresUTC"]) >= started.addingTimeInterval(2100),
      try date(proof["measurementStartUTC"]) == started,
      expected as? String == hash,
      bundle.bundleIdentifier == proof["bundleIdentifier"] as? String,
      bundle.bundleURL.standardizedFileURL == (try safe(root, "current/DPKProbe.app")).standardizedFileURL,
      (phase == 4 || (now < cutoff && !FileManager.default.fileExists(atPath: abortPath.path))),
      emergency || now < deadline else { throw ProbeError.guardRejected }
    guard let group = proof["accessGroup"] as? String,
      let entitlements = proof["entitlements"] as? [String: Any],
      entitlements["com.apple.application-identifier"] as? String == group,
      entitlements["keychain-access-groups"] as? [String] == [group], !group.contains("*") else { throw ProbeError.guardRejected }
    let profile = bundle.bundleURL.appendingPathComponent("Contents/embedded.provisionprofile")
    guard digest(try Data(contentsOf: profile)) == proof["profileSHA256"] as? String else { throw ProbeError.guardRejected }
    // Proof is a local cooperation gate. The coordinator revalidates installed signature,
    // certificate, profile and DR before every launch; this process rechecks immutable bytes.
    if emergency {
      let (request, _) = try object(root, "cleanup-request.json")
      guard request["namespace"] as? String == namespace, request["proofSHA256"] as? String == digest(proofData),
        request["mayHaveWritten"] as? Bool == true else { throw ProbeError.guardRejected }
    } else {
      let (gate, _) = try object(root, "control/gate-\(phase).json")
      let (previous, previousBytes) = try object(root, "receipts/phase-\(phase-1).machine.json")
      let (human, _) = try object(root, "receipts/phase-\(phase-1).human.json")
      let previousHash = digest(previousBytes)
      guard gate["namespace"] as? String == namespace, gate["phase"] as? Int == phase,
        gate["observationMode"] as? String == "human-only", gate["synthetic"] as? Bool != true,
        gate["humanReady"] as? Bool == true, gate["desktopConnected"] as? Bool != true,
        let statement = gate["humanReadyStatement"] as? String, !statement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        gate["previousReceiptSHA256"] as? String == previousHash,
        try date(gate["recordedUTC"]) >= date(previous["endedUTC"]), try date(gate["recordedUTC"]) <= now,
        human["namespace"] as? String == namespace, human["phase"] as? Int == phase-1,
        human["observationMode"] as? String == "human-only", human["synthetic"] as? Bool != true,
        human["wholeStageObserved"] as? Bool == true, human["phaseIdentified"] as? Bool == true,
        human["machineReceiptSHA256"] as? String == previousHash,
        let count = human["promptCount"] as? NSNumber, CFGetTypeID(count) != CFBooleanGetTypeID(),
        count.doubleValue == Double(count.intValue), count.intValue >= 0,
        let actions = human["actions"] as? [String], let purposes = human["purposes"] as? [String],
        actions.count == count.intValue, purposes.count == count.intValue,
        (actions + purposes).allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw ProbeError.guardRejected }
    }
    let marker = bundle.object(forInfoDictionaryKey: "E006BuildMarker") as? String
    #if E006_REBUILT
      let compiledMarker = "rebuilt"
    #else
      let compiledMarker = "initial"
    #endif
    guard marker == compiledMarker,
      (hash == run["secondHash"] as? String ? marker == "rebuilt" : marker == "initial") else { throw ProbeError.guardRejected }
    return LiveAuthorization(namespace: namespace, accessGroup: group, operation: operation, phase: phase,
      proofSHA256: digest(proofData), executableSHA256: hash, scratch: root,
      startedUTC: ISO8601DateFormatter().string(from: now))
  }
}
