import Foundation
import Testing

extension StaticIsolationTests {
  @Test
  func keychainAdapterUsesTheCommonLegacyBaseQueryForEveryOperation() throws {
    let adapterPath =
      repositoryRoot
      .appendingPathComponent("Sources/BoundedContexts/GitHubIntegration/Stores")
      .appendingPathComponent("KeychainTokenStore.swift")

    let source = try String(contentsOf: adapterPath, encoding: .utf8)

    for requiredSnippet in [
      "private var baseQuery: [CFString: Any]",
      "kSecClass: kSecClassGenericPassword",
      "kSecAttrService: service",
      "kSecAttrAccount: account",
      "kSecAttrSynchronizable: false",
      "var query = baseQuery",
      "SecItemCopyMatching(query as CFDictionary, &result)",
      "SecItemUpdate(\n      baseQuery as CFDictionary,",
      "var addQuery = baseQuery",
      "SecItemAdd(addQuery as CFDictionary, nil)",
      "SecItemDelete(baseQuery as CFDictionary)",
      "underlyingError: KeychainStoreFailure.operationFailed",
      "private enum KeychainStoreFailure: Error {\n  case operationFailed\n}",
    ] {
      #expect(source.contains(requiredSnippet))
    }

    for forbiddenMarker in [
      "OAuth",
      "Authorization",
      "Bearer",
      "URLSession",
      "HTTP",
      "kSecUseDataProtectionKeychain",
      "kSecAttrAccessible",
      "kSecAttrAccessGroup",
      "KeychainSharing",
      "AppGroup",
      "DEVELOPMENT_TEAM",
      "xcodebuild",
      "codesign",
      "XCTest",
      "Automatic Signing",
      "OSStatus",
      "print(",
      "Logger",
    ] {
      #expect(!source.contains(forbiddenMarker))
    }
  }
}

private let repositoryRoot = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()
