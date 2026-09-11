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
  func importRootExtractionRecognizesAccessLevelImports() throws {
    let source = """
      private import Security
      fileprivate import Keychain
      internal import ApolloAPI
      package import RivetHTTPClient
      public import Foundation
      """

    #expect(
      try importedModuleRoots(in: source)
        == ["Security", "Keychain", "ApolloAPI", "RivetHTTPClient", "Foundation"]
    )
  }

  @Test
  func importRootExtractionRecognizesEscapedModuleIdentifiers() throws {
    let source = """
      @_implementationOnly import `Security`.Cryptography
      @preconcurrency import struct `ApolloAPI`.Selection
      public import /* reason */ `Foundation`
      """

    #expect(
      try importedModuleRoots(in: source)
        == ["Security", "ApolloAPI", "Foundation"]
    )
  }

  @Test
  func escapedForbiddenModuleImportsAreDetected() throws {
    let source = "@_implementationOnly import `ApolloAPI`"
    let forbiddenImports: Set = ["ApolloAPI"]

    #expect(
      try !importedModuleRoots(in: source).isDisjoint(with: forbiddenImports)
    )
  }

  @Test
  func importRootExtractionRecognizesImportsAfterSemicolons() throws {
    let source = """
      import Foundation; import Security
      @_implementationOnly import struct ApolloAPI.Selection; import RivetHTTPClient
      """

    #expect(
      try importedModuleRoots(in: source)
        == ["Foundation", "Security", "ApolloAPI", "RivetHTTPClient"]
    )
  }

  @Test
  func importRootExtractionRecognizesBlockCommentsAtImportBoundaries() throws {
    let source = """
      /* detail */ import Security
      import /* reason */ ApolloAPI
      // import RivetHTTPClient
      /* import Keychain */
      """

    #expect(
      try importedModuleRoots(in: source)
        == ["Security", "ApolloAPI"]
    )
  }

  @Test
  func importRootExtractionIgnoresSemicolonDelimitedImportsInsideComments() throws {
    let source = """
      // ; import RivetHTTPClient
      /* ; import Keychain */
      /*
       * ; import Security
       */
      import Foundation
      """

    #expect(try importedModuleRoots(in: source) == ["Foundation"])
  }

  @Test
  func importRootExtractionIgnoresSemicolonDelimitedImportsInsideStringLiterals() throws {
    let source = """
      let example = \"; import RivetHTTPClient\"
      import Foundation
      """

    #expect(try importedModuleRoots(in: source) == ["Foundation"])
  }

  @Test
  func importRootExtractionIgnoresSemicolonDelimitedImportsInsideNestedBlockComments() throws {
    let source = """
      /* outer /* ; import RivetHTTPClient */ still outer */
      import Foundation
      """

    #expect(try importedModuleRoots(in: source) == ["Foundation"])
  }

  @Test
  func importRootExtractionRecognizesImportsAfterMultilineBlockComments() throws {
    let source = """
      import /*
        multiline detail
      */ Security
      """

    #expect(try importedModuleRoots(in: source) == ["Security"])
  }

  @Test
  func importRootExtractionRecognizesImportsAfterStarPrefixedBlockComments() throws {
    let source = """
      import /*
       * reason
       */ ApolloAPI
      """

    #expect(try importedModuleRoots(in: source) == ["ApolloAPI"])
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

      let forbiddenImports: Set = ["RivetHTTPClient", "Security", "Keychain", "ApolloAPI"]
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
  let trivia = #"[\t \r\n]"#
  let expression =
    #"(?m)(?:^|;)"#
    + trivia + #"*"#
    + #"(?:@[_A-Za-z][_A-Za-z0-9]*(?:\([^\r\n)]*\))?"#
    + trivia + #"+)*"#
    + #"(?:(?:private|fileprivate|internal|package|public)"#
    + trivia + #"+)?"#
    + #"import"#
    + trivia + #"+"#
    + #"(?:(?:typealias|struct|class|enum|protocol|let|var|func)"#
    + trivia + #"+)?"#
    + #"`?([_A-Za-z][_A-Za-z0-9]*)`?(?:\.`?[_A-Za-z][_A-Za-z0-9]*`?)*"#
  let expressionMatcher = try NSRegularExpression(pattern: expression)
  let sourceWithoutTrivia = sourceWithCommentsAndStringLiteralsReplaced(in: source)
  let sourceRange = NSRange(sourceWithoutTrivia.startIndex..., in: sourceWithoutTrivia)

  return Set(
    expressionMatcher.matches(in: sourceWithoutTrivia, range: sourceRange).compactMap { match in
      guard let moduleRange = Range(match.range(at: 1), in: sourceWithoutTrivia) else {
        return nil
      }
      return String(sourceWithoutTrivia[moduleRange])
    }
  )
}

private func sourceWithCommentsAndStringLiteralsReplaced(in source: String) -> String {
  var sanitized = ""
  var index = source.startIndex

  while index < source.endIndex {
    if sourceContains("//", in: source, at: index) {
      repeat {
        sanitized.append(sanitizedPlaceholder(for: source[index]))
        index = source.index(after: index)
      } while index < source.endIndex && !source[index].isNewline
      continue
    }

    if sourceContains("/*", in: source, at: index) {
      var depth = 0

      repeat {
        if sourceContains("/*", in: source, at: index) {
          depth += 1
          sanitized += "  "
          index = source.index(index, offsetBy: 2)
        } else if sourceContains("*/", in: source, at: index) {
          depth -= 1
          sanitized += "  "
          index = source.index(index, offsetBy: 2)
        } else {
          sanitized.append(sanitizedPlaceholder(for: source[index]))
          index = source.index(after: index)
        }
      } while index < source.endIndex && depth > 0
      continue
    }

    if let hashCount = rawStringHashCount(in: source, at: index) {
      let (replacement, nextIndex) = stringLiteralReplacement(
        in: source,
        startingAt: index,
        hashCount: hashCount
      )
      sanitized += replacement
      index = nextIndex
      continue
    }

    sanitized.append(source[index])
    index = source.index(after: index)
  }

  return sanitized
}

private func sourceContains(
  _ literal: String,
  in source: String,
  at candidate: String.Index
) -> Bool {
  source[candidate...].hasPrefix(literal)
}

private func sanitizedPlaceholder(for character: Character) -> Character {
  character.isNewline ? character : " "
}

private func rawStringHashCount(in source: String, at candidate: String.Index) -> Int? {
  var probe = candidate
  var hashCount = 0

  while probe < source.endIndex, source[probe] == "#" {
    hashCount += 1
    probe = source.index(after: probe)
  }

  return probe < source.endIndex && source[probe] == "\"" ? hashCount : nil
}

private func stringLiteralReplacement(
  in source: String,
  startingAt start: String.Index,
  hashCount: Int
) -> (String, String.Index) {
  let quoteStart = source.index(start, offsetBy: hashCount)
  let isMultiline = sourceContains("\"\"\"", in: source, at: quoteStart)
  let openingLength = hashCount + (isMultiline ? 3 : 1)
  var replacement = String(repeating: " ", count: openingLength)
  var probe = source.index(start, offsetBy: openingLength)
  let closingQuotes = isMultiline ? "\"\"\"" : "\""
  let closingDelimiter = closingQuotes + String(repeating: "#", count: hashCount)
  var precedingBackslashCount = 0

  while probe < source.endIndex {
    let isClosingDelimiter =
      sourceContains(closingDelimiter, in: source, at: probe)
      && (hashCount > 0 || precedingBackslashCount.isMultiple(of: 2))
    if isClosingDelimiter {
      replacement += String(repeating: " ", count: closingDelimiter.count)
      return (replacement, source.index(probe, offsetBy: closingDelimiter.count))
    }

    let character = source[probe]
    replacement.append(sanitizedPlaceholder(for: character))
    precedingBackslashCount = character == "\\" ? precedingBackslashCount + 1 : 0
    probe = source.index(after: probe)
  }

  return (replacement, probe)
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
