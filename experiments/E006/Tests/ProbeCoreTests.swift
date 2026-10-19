import Foundation

@main enum CoreTests {
  static func main() throws {
    let backend = MemoryStore()
    let core = ProbeCore(store: backend)
    let initial = try core.perform(.saveReadA)
    precondition(initial.fields.count == 6 && initial.fields.values.allSatisfy { $0 })
    precondition(backend.operations == ["save", "load"])
    _ = try core.perform(.readA)
    precondition(backend.operations == ["save", "load", "load"])
    let cleared = try core.perform(.deleteReadAbsent)
    precondition(cleared.absent == true)
    do { _ = try core.perform(.readA); preconditionFailure("missing must fail") }
    catch ProbeError.missing { }
    backend.data = Data("invalid".utf8)
    do { _ = try core.perform(.readA); preconditionFailure("malformed must fail") }
    catch ProbeError.invalidData { }
    backend.failure = .security(operation: "load", status: -25293)
    do { _ = try core.perform(.readA); preconditionFailure("denied must fail") }
    catch ProbeError.security(_, let status) { precondition(status == -25293) }
    precondition(!String(describing: FakeBundle.a).contains("fake-access"))
    precondition(!String(reflecting: FakeBundle.a).contains("fake-refresh"))
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("E006-gate-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: root) }
    do { _ = try LiveGate.safe(root, "../escape"); preconditionFailure("unsafe path accepted") }
    catch ProbeError.guardRejected { }
    let link = root.appendingPathComponent("link")
    try FileManager.default.createSymbolicLink(at: link, withDestinationURL: root)
    do { _ = try LiveGate.safe(root, "link/file"); preconditionFailure("symlink accepted") }
    catch ProbeError.guardRejected { }
    do {
      _ = try LiveGate.authorize(root: root, namespace: UUID().uuidString.lowercased(), phase: 1,
        operation: .saveReadA, executable: root, bundle: .main, guiUser: false)
      preconditionFailure("GUI guard accepted")
    } catch ProbeError.guardRejected { }
    print("synthetic=true; six-field, read-only, delete-absent, missing, invalid, denied, redaction, GUI/path guards: passed")
  }
}
