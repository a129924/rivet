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

    let forbiddenImports: Set = [
      "RivetPRInbox", "GitHubIntegration", "RivetHTTPClient", "Foundation", "WebKit",
    ]
    for file in files {
      let source = try String(contentsOf: file, encoding: .utf8)

      #expect(Set(importedModuleRoots(in: source)).isDisjoint(with: forbiddenImports))
      #expect(!source.contains("URLSession"))
    }
  }

  @Test
  func importRootExtractionRecognizesAccessLevelAndScopedImports() {
    let source = """
      private import RivetPRInbox
      public import struct GitHubIntegration.TokenSnapshot
      """

    #expect(importedModuleRoots(in: source) == ["RivetPRInbox", "GitHubIntegration"])
  }

  @Test
  func importRootExtractionRecognizesCommentTriviaAndIgnoresCommentContents() {
    let source = """
      /* outer /* import IgnoredModule */ comment */
      private /* access */ import /* module */ RivetHTTPClient
      // import AnotherIgnoredModule
      import Testing
      """

    #expect(importedModuleRoots(in: source) == ["RivetHTTPClient", "Testing"])
  }

  @Test
  func importRootExtractionRecognizesSpecialWhitespace() {
    let source =
      "import\u{000C}RivetPRInbox\nimport\u{000B}GitHubIntegration\nimport\u{00A0}WebKit"

    #expect(importedModuleRoots(in: source) == ["RivetPRInbox", "GitHubIntegration", "WebKit"])
  }

  @Test
  func importRootExtractionIgnoresOrdinaryStringLiterals() {
    let source = """
      let example = "; import RivetPRInbox"
      import Testing
      """

    #expect(importedModuleRoots(in: source) == ["Testing"])
  }

  @Test
  func importRootExtractionIgnoresMultilineAndRawStringLiterals() {
    let source = ##"""
      let multiline = """
        ; import GitHubIntegration
        """
      let raw = #"; import WebKit"#
      import Testing
      """##

    #expect(importedModuleRoots(in: source) == ["Testing"])
  }

  @Test
  func importRootExtractionIgnoresRegexLiteralsWithoutMaskingDivision() {
    let source = #"""
      let ordinary = /; import RivetHTTPClient/
      let ratio = 6 / 2
      import Testing
      """#

    #expect(importedModuleRoots(in: source) == ["Testing"])
  }

  @Test
  func returnIntroducesRegexLiteral() {
    let source = #"""
      func regex() -> Regex<Substring> {
        return /import Foundation/
      }
      import Testing
      """#

    #expect(importedModuleRoots(in: source) == ["Testing"])
  }

  @Test
  func identifierDivisionDoesNotMaskImports() {
    let source = """
      let ratio = value / import Foundation / other
      import Testing
      """

    #expect(importedModuleRoots(in: source) == ["Foundation", "Testing"])
  }

  @Test
  func numericDivisionDoesNotMaskImports() {
    let source = """
      let ratio = 6 / import WebKit / 2
      import Testing
      """

    #expect(importedModuleRoots(in: source) == ["WebKit", "Testing"])
  }

  @Test
  func importRootExtractionIgnoresRawRegexLiterals() {
    let source = ##"""
      let raw = #/; import GitHubIntegration/#
      import Testing
      """##

    #expect(importedModuleRoots(in: source) == ["Testing"])
  }

  @Test
  func escapedQuotesDoNotEndStringLiteralMaskingEarly() {
    let source = ##"""
      let ordinary = "escaped \"; import RivetPRInbox"
      let raw = #"escaped \#"#; import GitHubIntegration"#
      import Testing
      """##

    #expect(importedModuleRoots(in: source) == ["Testing"])
  }

  @Test
  func escapedRawRegexDelimiterDoesNotEndMaskingEarly() {
    let source = ##"""
      let regex = #/escaped \/#; import WebKit/#
      import Testing
      """##

    #expect(importedModuleRoots(in: source) == ["Testing"])
  }

  @Test
  func escapedSlashDoesNotEndBareRegexMaskingEarly() {
    let source = #"""
      let regex = /escaped \/; import RivetHTTPClient/
      import Testing
      """#

    #expect(importedModuleRoots(in: source) == ["Testing"])
  }

  @Test
  func slashInsideCharacterClassDoesNotEndBareRegexMaskingEarly() {
    let source = #"""
      let regex = /[a/b]; import RivetPRInbox/
      import Testing
      """#

    #expect(importedModuleRoots(in: source) == ["Testing"])
  }
}

private func importedModuleRoots(in source: String) -> [String] {
  let sanitizedSource = sourceWithCommentsAndStringLiteralsReplaced(in: source)
  let tokens = swiftIdentifierTokens(in: sanitizedSource)
  let scopedImportKinds: Set = [
    "typealias", "struct", "class", "enum", "protocol", "let", "var", "func", "operator",
  ]
  var roots: [String] = []

  for index in tokens.indices where tokens[index] == "import" {
    var rootIndex = tokens.index(after: index)
    guard rootIndex < tokens.endIndex else { continue }

    if scopedImportKinds.contains(tokens[rootIndex]) {
      rootIndex = tokens.index(after: rootIndex)
    }
    if rootIndex < tokens.endIndex {
      roots.append(tokens[rootIndex])
    }
  }

  return roots
}

private func swiftIdentifierTokens(in source: String) -> [String] {
  let scalars = Array(source.unicodeScalars)
  var tokens: [String] = []
  var index = 0

  while index < scalars.count {
    guard isIdentifierHead(scalars[index]) else {
      index += 1
      continue
    }

    let start = index
    index += 1
    while index < scalars.count, isIdentifierContinuation(scalars[index]) {
      index += 1
    }
    tokens.append(String(String.UnicodeScalarView(scalars[start..<index])))
  }

  return tokens
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

    if let hashCount = rawRegexHashCount(in: source, at: index) {
      let (replacement, nextIndex) = rawRegexLiteralReplacement(
        in: source,
        startingAt: index,
        hashCount: hashCount
      )
      sanitized += replacement
      index = nextIndex
      continue
    }

    if let (replacement, nextIndex) = ordinaryRegexLiteralReplacement(
      in: source,
      startingAt: index
    ) {
      sanitized += replacement
      index = nextIndex
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

private func rawRegexHashCount(in source: String, at candidate: String.Index) -> Int? {
  var probe = candidate
  var hashCount = 0

  while probe < source.endIndex, source[probe] == "#" {
    hashCount += 1
    probe = source.index(after: probe)
  }

  return hashCount > 0 && probe < source.endIndex && source[probe] == "/" ? hashCount : nil
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
    let isClosingDelimiter: Bool
    if hashCount == 0 {
      isClosingDelimiter =
        sourceContains(closingDelimiter, in: source, at: probe)
        && precedingBackslashCount.isMultiple(of: 2)
    } else {
      isClosingDelimiter =
        sourceContains(closingDelimiter, in: source, at: probe)
        && !rawStringQuoteIsEscaped(in: source, at: probe, hashCount: hashCount)
    }
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

private func rawStringQuoteIsEscaped(
  in source: String,
  at quote: String.Index,
  hashCount: Int
) -> Bool {
  guard
    hashCount > 0,
    let firstHash = source.index(
      quote,
      offsetBy: -hashCount,
      limitedBy: source.startIndex
    ),
    firstHash > source.startIndex
  else {
    return false
  }

  let escape = source.index(before: firstHash)
  guard source[escape] == "\\" else {
    return false
  }

  return source[firstHash..<quote].allSatisfy { $0 == "#" }
}

private func rawRegexLiteralReplacement(
  in source: String,
  startingAt start: String.Index,
  hashCount: Int
) -> (String, String.Index) {
  let openingDelimiter = String(repeating: "#", count: hashCount) + "/"
  let closingDelimiter = "/" + String(repeating: "#", count: hashCount)
  var replacement = String(repeating: " ", count: openingDelimiter.count)
  var probe = source.index(start, offsetBy: openingDelimiter.count)
  var precedingBackslashCount = 0

  while probe < source.endIndex {
    let isClosingDelimiter =
      sourceContains(closingDelimiter, in: source, at: probe)
      && precedingBackslashCount.isMultiple(of: 2)
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

private func ordinaryRegexLiteralReplacement(
  in source: String,
  startingAt start: String.Index
) -> (String, String.Index)? {
  guard source[start] == "/", bareRegexCanStart(in: source, at: start) else {
    return nil
  }

  var replacement = " "
  var probe = source.index(after: start)
  var precedingBackslashCount = 0
  var isInsideCharacterClass = false

  while probe < source.endIndex {
    let character = source[probe]
    if character.isNewline {
      return nil
    }

    let isEscaped = !precedingBackslashCount.isMultiple(of: 2)
    if character == "[", !isEscaped {
      isInsideCharacterClass = true
    } else if character == "]", !isEscaped {
      isInsideCharacterClass = false
    } else if character == "/", !isEscaped, !isInsideCharacterClass {
      replacement.append(" ")
      return (replacement, source.index(after: probe))
    }

    replacement.append(" ")
    precedingBackslashCount = character == "\\" ? precedingBackslashCount + 1 : 0
    probe = source.index(after: probe)
  }

  return nil
}

private func bareRegexCanStart(in source: String, at start: String.Index) -> Bool {
  var probe = start
  let expressionPrefixCharacters = "=([{,:;!?&|+-*%^~<>"
  let expressionIntroducingKeywords: Set = ["return", "throw", "try", "await", "yield"]

  while probe > source.startIndex {
    let previous = source.index(before: probe)
    let character = source[previous]
    if character.isNewline {
      return true
    }
    if character.isWhitespace {
      probe = previous
      continue
    }
    if expressionPrefixCharacters.contains(character) {
      return true
    }

    guard character.unicodeScalars.allSatisfy(isIdentifierContinuation) else {
      return false
    }

    var identifierStart = previous
    while identifierStart > source.startIndex {
      let candidate = source.index(before: identifierStart)
      guard source[candidate].unicodeScalars.allSatisfy(isIdentifierContinuation) else {
        break
      }
      identifierStart = candidate
    }

    return expressionIntroducingKeywords.contains(String(source[identifierStart...previous]))
  }

  return true
}

private func isIdentifierHead(_ scalar: Unicode.Scalar) -> Bool {
  scalar == "_" || scalar.properties.isAlphabetic
}

private func isIdentifierContinuation(_ scalar: Unicode.Scalar) -> Bool {
  isIdentifierHead(scalar) || scalar.properties.numericType != nil
}

private let repositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()
