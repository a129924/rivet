import Foundation

final class MemoryStore: ExperimentStore {
  var raw: Data?; var adds = 0; var reads = 0; var deletes = 0
  var failure: ProbeError?
  func add(_ data: Data) throws { adds += 1; if let failure { throw failure }; guard raw == nil else { throw ProbeError.security("add", -25299) }; raw = data }
  func load() throws -> Data? { reads += 1; if let failure { throw failure }; return raw }
  func delete() throws { deletes += 1; if let failure { throw failure }; raw = nil }
}
@main enum CoreTests {
  static func main() {
    do {
      let memory = MemoryStore(); let core = ProbeCore(store: memory)
      let seeded = try core.perform(.seed)
      guard seeded.fields.count == 6 && seeded.fields.values.allSatisfy({ $0 }) else { throw ProbeError.comparison }
      let original = memory.raw
      _ = try core.perform(.read)
      guard memory.adds == 1 && memory.reads == 2 && memory.raw == original else { throw ProbeError.comparison }
      do { _ = try core.perform(.seed); throw ProbeError.comparison } catch ProbeError.security(_, -25299) {}
      let clean = try core.perform(.cleanup)
      guard clean.absent == true && memory.deletes == 1 else { throw ProbeError.comparison }
      memory.raw = Data("invalid".utf8)
      do { _ = try core.perform(.read); throw ProbeError.comparison } catch ProbeError.invalidData {}
      memory.failure = .security("load", -25308)
      do { _ = try core.perform(.read); throw ProbeError.comparison } catch ProbeError.security(_, -25308) {}
      guard ProbeError.security("load", -25308).classification == "interactionUnavailable",
        ProbeError.security("load", -34018).classification == "missingEntitlement",
        !String(reflecting: FakeBundle.a).contains("fake-access") else { throw ProbeError.comparison }
      let a = try CanonicalJSON.data(["z": "階段", "a": 1])
      let b = try CanonicalJSON.data(["a": 1, "z": "階段"])
      guard a.last == 10 && a == b else { throw ProbeError.comparison }
      print("PASS: six fields, no rewrite, duplicate add, exact cleanup, invalid/technical errors, redaction, canonical LF (7 scenarios)")
    } catch {
      print("FAIL: pure core scenario: \((error as? ProbeError)?.classification ?? "testFailure")")
      exit(1)
    }
  }
}
