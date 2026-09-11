import Foundation
import Testing

@Suite("GitHubIntegration static isolation")
struct StaticIsolationTests {
  @Test
  func manifestDeclaresTheLockedSingleTargetConfiguration() throws {
    let manifest = try String(
      contentsOf: repositoryRoot.appendingPathComponent("Package.swift"),
      encoding: .utf8
    )

    #expect(
      manifest.contains(
        ".library(name: \"GitHubIntegration\", targets: [\"GitHubIntegration\"])"
      )
    )
    #expect(manifest.contains("name: \"GitHubIntegration\""))
    #expect(manifest.contains("path: \"Sources/BoundedContexts/GitHubIntegration\""))
    #expect(manifest.contains("name: \"GitHubIntegrationTests\""))
  }

  @Test
  func targetContainsOnlyTheLockedSourceFilesAndNoForbiddenImports() throws {
    let sourceDirectory =
      repositoryRoot
      .appendingPathComponent("Sources/BoundedContexts/GitHubIntegration")

    let expectedPaths = [
      "Contracts/CredentialTypes.swift",
      "Contracts/GitHubTokenStore.swift",
      "Contracts/GitHubTokenProvider.swift",
      "Providers/TokenStoreGitHubTokenProvider.swift",
    ]

    for path in expectedPaths {
      let sourceFile = sourceDirectory.appendingPathComponent(path)
      let source = try String(contentsOf: sourceFile, encoding: .utf8)

      #expect(!source.contains("import RivetHTTPClient"))
      #expect(!source.contains("import Security"))
      #expect(!source.contains("import Keychain"))
      #expect(!source.contains("import Apollo"))
    }
  }
}

private let repositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()
