import Foundation

/// Shared by the host and the offline checks. Normalize both sides, then confirm
/// the same filesystem object; matching text or matching content alone is insufficient.
enum E016PathIdentity {
  static func normalized(_ url: URL) -> URL {
    url.standardizedFileURL.resolvingSymlinksInPath().standardizedFileURL
  }

  static func matches(_ actual: URL, expected: String) throws -> Bool {
    let left = normalized(actual)
    let right = normalized(URL(fileURLWithPath: expected))
    guard left.path == right.path else { return false }
    let manager = FileManager.default
    let leftAttributes = try manager.attributesOfItem(atPath: left.path)
    let rightAttributes = try manager.attributesOfItem(atPath: right.path)
    guard let leftDevice = leftAttributes[.systemNumber] as? NSNumber,
      let rightDevice = rightAttributes[.systemNumber] as? NSNumber,
      let leftInode = leftAttributes[.systemFileNumber] as? NSNumber,
      let rightInode = rightAttributes[.systemFileNumber] as? NSNumber
    else { return false }
    return leftDevice == rightDevice && leftInode == rightInode
  }
}
