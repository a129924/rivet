import Foundation
import Testing

@Suite("RivetPRInbox static isolation")
struct StaticIsolationTests {
  @Test
  func rootManifestDeclaresOnlyTheLockedPRInboxTargetConfiguration() throws {
    let manifest = try String(
      contentsOf: repositoryRoot.appendingPathComponent("Package.swift"),
      encoding: .utf8
    )

    #expect(manifest.contains(".library(name: \"RivetPRInbox\", targets: [\"RivetPRInbox\"])"))
    #expect(manifest.contains("name: \"RivetPRInbox\""))
    #expect(manifest.contains("path: \"Sources/BoundedContexts/PRInbox\""))
    #expect(manifest.contains("name: \"RivetPRInboxTests\""))
    let package = try packageDescription()
    let targets = try #require(package["targets"] as? [[String: Any]])
    let inbox = try #require(targets.first { $0["name"] as? String == "RivetPRInbox" })
    let dependencies = try #require(inbox["dependencies"] as? [Any])
    #expect(dependencies.isEmpty)
  }

  @Test
  func targetSourceDoesNotImportExternalIntegrationOrNetworkDependencies() throws {
    let sourceDirectory = repositoryRoot.appendingPathComponent("Sources/BoundedContexts/PRInbox")
    let sourceFiles = try #require(
      FileManager.default.enumerator(
        at: sourceDirectory,
        includingPropertiesForKeys: [.isRegularFileKey]
      )
    )
    .compactMap { $0 as? URL }
    .filter { $0.pathExtension == "swift" }

    for sourceFile in sourceFiles {
      let source = try String(contentsOf: sourceFile, encoding: .utf8)

      #expect(!source.contains("import RivetHTTPClient"))
      #expect(!source.contains("import GitHub"))
      #expect(!source.contains("import Foundation"))
      #expect(!source.contains("URLSession"))
    }
  }
}

private let repositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private func packageDescription() throws -> [String: Any] {
  let scratchDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("rivet-pr-inbox-package-graph-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: scratchDirectory) }
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["swift", "package", "--scratch-path", scratchDirectory.path, "dump-package"]
  process.currentDirectoryURL = repositoryRoot
  let output = Pipe()
  process.standardOutput = output
  process.standardError = FileHandle.nullDevice
  try process.run()
  let data = output.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()
  try #require(process.terminationStatus == 0)
  return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
}
