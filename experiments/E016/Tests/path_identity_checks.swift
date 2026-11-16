import Foundation

@main
struct PathIdentityChecks {
  static func main() throws {
    let manager = FileManager.default
    let name = "e016-offline-path-\(UUID().uuidString)"
    let temporary = URL(fileURLWithPath: "/tmp", isDirectory: true).appendingPathComponent(name)
    try manager.createDirectory(at: temporary, withIntermediateDirectories: false)
    defer { try? manager.removeItem(at: temporary) }
    let privateAlias = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
      .appendingPathComponent(name)
    let first = temporary.appendingPathComponent("First.app", isDirectory: true)
    let second = temporary.appendingPathComponent("Second.app", isDirectory: true)
    try manager.createDirectory(at: first, withIntermediateDirectories: false)
    try manager.createDirectory(at: second, withIntermediateDirectories: false)
    let firstExecutable = first.appendingPathComponent("probe")
    let secondExecutable = second.appendingPathComponent("probe")
    try Data("same synthetic content".utf8).write(to: firstExecutable)
    try Data("same synthetic content".utf8).write(to: secondExecutable)
    let bundleAlias = privateAlias.appendingPathComponent("First.app")
    let executableAlias = bundleAlias.appendingPathComponent("probe")
    guard try E016PathIdentity.matches(first, expected: bundleAlias.path),
      try E016PathIdentity.matches(firstExecutable, expected: executableAlias.path),
      try E016PathIdentity.matches(executableAlias, expected: firstExecutable.path),
      try !E016PathIdentity.matches(first, expected: second.path),
      try !E016PathIdentity.matches(firstExecutable, expected: secondExecutable.path)
    else { throw NSError(domain: "E016OfflinePathChecks", code: 1) }
    print("E016 pure Foundation path checks passed (alias and distinct-object cases).")
  }
}
