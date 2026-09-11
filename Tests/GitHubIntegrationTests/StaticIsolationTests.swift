import Foundation
import GitHubIntegration
import Testing

@Suite("GitHubIntegration static isolation")
struct StaticIsolationTests {
  @Test
  func packageDeclaresTheLockedTargetGraph() throws {
    let package = try packageDescription()
    let products = try namedItems(in: package, named: "products")
    let targets = try namedItems(in: package, named: "targets")

    #expect(Set(products.keys) == ["GitHubIntegration", "RivetPRInbox"])
    #expect(
      Set(targets.keys)
        == [
          "GitHubIntegration",
          "GitHubIntegrationTests",
          "RivetPRInbox",
          "RivetPRInboxTests",
        ]
    )

    let integrationProduct = try #require(products["GitHubIntegration"])
    #expect(targetNames(in: integrationProduct) == ["GitHubIntegration"])

    let integrationTarget = try #require(targets["GitHubIntegration"])
    #expect(integrationTarget["type"] as? String == "regular")
    #expect(
      integrationTarget["path"] as? String
        == "Sources/BoundedContexts/GitHubIntegration"
    )
    #expect(rawDependencies(in: integrationTarget).isEmpty)

    let integrationTests = try #require(targets["GitHubIntegrationTests"])
    #expect(integrationTests["type"] as? String == "test")
    #expect(dependencyNames(in: integrationTests) == ["GitHubIntegration"])
  }

  @Test
  func dependencyExtractionRecognizesAllPackageDescriptionDependencyForms() {
    let target =
      [
        "dependencies": [
          ["byName": ["ByNameDependency", NSNull()]],
          ["target": ["TargetDependency", NSNull()]],
          ["product": ["ProductDependency", "Package", NSNull(), NSNull()]],
        ]
      ] as [String: Any]

    #expect(
      Set(dependencyNames(in: target))
        == ["ByNameDependency", "TargetDependency", "ProductDependency"]
    )
  }

  @Test
  func importRootExtractionRecognizesAttributesAndScopedImports() throws {
    let source = """
      import Foundation
      @_implementationOnly import Security.Cryptography
      @preconcurrency import struct ApolloAPI.Selection
      @_exported import class RivetHTTPClient.HTTPClient
      """

    #expect(
      try importedModuleRoots(in: source)
        == ["Foundation", "Security", "ApolloAPI", "RivetHTTPClient"]
    )
  }

  @Test
  func targetContainsOnlyTheLockedSourceFilesAndNoForbiddenImports() throws {
    let sourceDirectory =
      repositoryRoot
      .appendingPathComponent("Sources/BoundedContexts/GitHubIntegration")

    let expectedPaths: Set = [
      "Contracts/CredentialTypes.swift",
      "Contracts/GitHubTokenStore.swift",
      "Contracts/GitHubTokenProvider.swift",
      "Providers/TokenStoreGitHubTokenProvider.swift",
    ]

    let actualPaths = try sourcePaths(in: sourceDirectory)
    #expect(actualPaths == expectedPaths)

    for path in actualPaths {
      let sourceFile = sourceDirectory.appendingPathComponent(path)
      let source = try String(contentsOf: sourceFile, encoding: .utf8)

      let forbiddenImports: Set = ["RivetHTTPClient", "Security", "Keychain", "Apollo"]
      #expect(try importedModuleRoots(in: source).isDisjoint(with: forbiddenImports))
    }
  }

  @Test
  func tokenStoreOperationIsSendable() {
    assertSendable(TokenStoreOperation.load)
  }
}

private let repositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()

private func packageDescription() throws -> [String: Any] {
  let scratchDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("rivet-package-graph-\(UUID().uuidString)")
  defer { try? FileManager.default.removeItem(at: scratchDirectory) }

  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = [
    "swift",
    "package",
    "--scratch-path",
    scratchDirectory.path,
    "dump-package",
  ]
  process.currentDirectoryURL = repositoryRoot

  let output = Pipe()
  process.standardOutput = output
  process.standardError = Pipe()
  try process.run()
  process.waitUntilExit()

  guard process.terminationStatus == 0 else {
    throw PackageDescriptionError.commandFailed(process.terminationStatus)
  }

  let data = output.fileHandleForReading.readDataToEndOfFile()
  return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
}

private func namedItems(
  in package: [String: Any],
  named key: String
) throws -> [String: [String: Any]] {
  let items = try #require(package[key] as? [[String: Any]])
  return try Dictionary(
    uniqueKeysWithValues: items.map { item in
      let name = try #require(item["name"] as? String)
      return (name, item)
    }
  )
}

private func targetNames(in product: [String: Any]) -> [String] {
  product["targets"] as? [String] ?? []
}

private func dependencyNames(in target: [String: Any]) -> [String] {
  rawDependencies(in: target).compactMap { dependency in
    ["byName", "target", "product"].lazy.compactMap { representation in
      (dependency[representation] as? [Any])?.first as? String
    }.first
  }
}

private func rawDependencies(in target: [String: Any]) -> [[String: Any]] {
  target["dependencies"] as? [[String: Any]] ?? []
}

private func importedModuleRoots(in source: String) throws -> Set<String> {
  let expression =
    #"(?m)^[\t ]*(?:@[_A-Za-z][_A-Za-z0-9]*(?:\([^\r\n)]*\))?[\t ]+)*"#
    + #"import[\t ]+(?:(?:typealias|struct|class|enum|protocol|let|var|func)[\t ]+)?"#
    + #"([_A-Za-z][_A-Za-z0-9]*)(?:\.[_A-Za-z][_A-Za-z0-9]*)*"#
  let expressionMatcher = try NSRegularExpression(pattern: expression)
  let sourceRange = NSRange(source.startIndex..., in: source)

  return Set(
    expressionMatcher.matches(in: source, range: sourceRange).compactMap { match in
      guard let moduleRange = Range(match.range(at: 1), in: source) else {
        return nil
      }
      return String(source[moduleRange])
    }
  )
}

private func sourcePaths(in directory: URL) throws -> Set<String> {
  let enumerator = try #require(
    FileManager.default.enumerator(
      at: directory,
      includingPropertiesForKeys: [.isRegularFileKey]
    )
  )

  return Set(
    enumerator.compactMap { element in
      guard let url = element as? URL else {
        return nil
      }

      let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
      guard values?.isRegularFile == true, url.pathExtension == "swift" else {
        return nil
      }

      return url.path.replacingOccurrences(of: directory.path + "/", with: "")
    }
  )
}

private func assertSendable<Value: Sendable>(_ value: Value) {}

private enum PackageDescriptionError: Error {
  case commandFailed(Int32)
}
