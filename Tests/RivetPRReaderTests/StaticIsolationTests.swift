import Foundation
import Testing

@Suite("RivetPRReader static isolation")
struct RivetPRReaderStaticIsolationTests {
  @Test
  func manifestDeclaresLockedReaderTargetConfiguration() throws {
    let manifest = try String(
      contentsOf: repositoryRoot.appendingPathComponent("Package.swift"),
      encoding: .utf8
    )

    #expect(manifest.contains(".library(name: \"RivetPRReader\", targets: [\"RivetPRReader\"])"))
    #expect(manifest.contains("name: \"RivetPRReader\""))
    #expect(manifest.contains("path: \"Sources/BoundedContexts/PRReader/Core\""))
    #expect(manifest.contains("name: \"RivetPRReaderTests\""))
  }

  @Test
  func coreDoesNotImportForbiddenDependencies() throws {
    let core = repositoryRoot.appendingPathComponent("Sources/BoundedContexts/PRReader/Core")
    let files = try #require(
      FileManager.default.enumerator(at: core, includingPropertiesForKeys: [.isRegularFileKey])
    )
    .compactMap { $0 as? URL }
    .filter { $0.pathExtension == "swift" }

    let forbidden = [
      "import RivetPRInbox", "import GitHubIntegration", "import RivetHTTPClient",
      "import Foundation", "URLSession", "WebKit",
    ]
    for file in files {
      let source = try String(contentsOf: file, encoding: .utf8)
      for token in forbidden {
        #expect(!source.contains(token))
      }
    }
  }
}

private let repositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()
