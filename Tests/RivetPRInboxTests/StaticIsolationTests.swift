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
    #expect(!manifest.contains("RivetHTTPClient"))
  }

  @Test
  func targetSourceDoesNotImportExternalIntegrationOrNetworkDependencies() throws {
    let sourceDirectory = repositoryRoot.appendingPathComponent("Sources/BoundedContexts/PRInbox")
    let sourceFiles = try FileManager.default.contentsOfDirectory(
      at: sourceDirectory,
      includingPropertiesForKeys: nil
    )
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
