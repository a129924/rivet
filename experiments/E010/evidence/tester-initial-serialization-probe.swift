import Foundation
@main enum SerializationProbe {
 static func main() throws {
  let value: [String: Any] = ["fields": [:], "callAttempted": false, "OSStatus": NSNull(), "stage": "cleanup"]
  FileHandle.standardOutput.write(try CanonicalJSON.data(value))
 }
}
