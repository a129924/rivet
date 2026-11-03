import Foundation

// Pure producer invokes the same serializer used by App receipts, with no App/Security import.
@main enum ReceiptProducer {
  static func main() throws {
    let fields = FakeBundle.a.comparisons()
    let value: [String: Any]
    switch CommandLine.arguments.dropFirst().first {
    case "no-call":
      value = ["stage": "expired", "callAttempted": false, "OSStatus": NSNull(), "promptCount": NSNull(), "fields": [:]]
    case "six-fields":
      value = ["stage": "fresh", "callAttempted": true, "OSStatus": Int32(0), "fields": fields, "completed": true]
    case "cleanup":
      value = ["stage": "cleanup", "callAttempted": true, "OSStatus": Int32(0), "fields": [:], "absent": true]
    case "unicode":
      value = ["OSStatus": Int32(-25308), "z": ["é", "中", "😀", "\"\\/\n\t\u{0001}"], "é": "a", "中": "b", "\u{e000}": "c", "\u{10000}": "d", "😀": "e"]
    default: throw ProbeError.guardRejected
    }
    FileHandle.standardOutput.write(try CanonicalJSON.data(value))
  }
}
