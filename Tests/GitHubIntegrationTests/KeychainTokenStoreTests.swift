import Foundation
import Security
import Testing
@testable import GitHubIntegration

@Suite("Keychain GitHub token store")
struct KeychainTokenStoreTests {
  @Test
  func emptyStoreLoadsNoToken() throws {
    try withIsolatedStore { store, _ in
      let loadedToken = try store.load()

      #expect(loadedToken == nil)
    }
  }

  @Test
  func savedTokenLoadsUnchanged() throws {
    try withIsolatedStore { store, identity in
      let token = GitHubAccessToken(rawValue: "keychain-test-token")

      try store.save(token)

      let loadedToken = try store.load()
      let savedData = try storedData(for: identity)

      #expect(loadedToken?.rawValue == token.rawValue)
      #expect(savedData == Data(token.rawValue.utf8))
    }
  }

  @Test
  func laterSaveReplacesThePreviousToken() throws {
    try withIsolatedStore { store, _ in
      try store.save(GitHubAccessToken(rawValue: "first-keychain-test-token"))
      try store.save(GitHubAccessToken(rawValue: "replacement-keychain-test-token"))

      let loadedToken = try store.load()

      #expect(loadedToken?.rawValue == "replacement-keychain-test-token")
    }
  }

  @Test
  func deleteClearsTheSavedToken() throws {
    try withIsolatedStore { store, _ in
      try store.save(GitHubAccessToken(rawValue: "keychain-test-token"))

      try store.delete()

      let loadedToken = try store.load()

      #expect(loadedToken == nil)
    }
  }

  @Test
  func deletingAnEmptyStoreKeepsItEmpty() throws {
    try withIsolatedStore { store, _ in
      try store.delete()
      try store.delete()

      let loadedToken = try store.load()

      #expect(loadedToken == nil)
    }
  }

  @Test
  func aNewStoreWithTheSameIdentityLoadsTheSavedToken() throws {
    try withIsolatedStore { store, identity in
      let token = GitHubAccessToken(rawValue: "keychain-test-token")
      try store.save(token)

      let reloadedStore = KeychainTokenStore(
        service: identity.service,
        account: identity.account
      )
      let loadedToken = try reloadedStore.load()

      #expect(loadedToken?.rawValue == token.rawValue)
    }
  }

  @Test
  func invalidUTF8IsATokenStoreFailureRatherThanAMissingCredential() throws {
    try withIsolatedStore { store, identity in
      try addItem(for: identity, valueData: Data([0xFF]))
      let provider = TokenStoreGitHubTokenProvider(store: store)

      do {
        _ = try provider.token()
        Issue.record("Expected a token-store failure")
      } catch let error as GitHubCredentialError {
        guard case .tokenStore(let storeError) = error else {
          Issue.record("Expected a token-store failure")
          return
        }

        #expect(storeError.operation == .load)
      }
    }
  }
}

private struct TestKeychainIdentity {
  let service: String
  let account = "github-access-token"

  var baseQuery: [CFString: Any] {
    [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: account,
      kSecAttrSynchronizable: false,
    ]
  }
}

private func withIsolatedStore(
  _ body: (KeychainTokenStore, TestKeychainIdentity) throws -> Void
) throws {
  let identity = TestKeychainIdentity(
    service: "com.rivet.github-integration.tests.\(UUID().uuidString)"
  )
  try removeItem(for: identity)
  defer {
    do {
      try removeItem(for: identity)
    } catch {
      Issue.record("Keychain fixture cleanup failed")
    }
  }

  try body(
    KeychainTokenStore(service: identity.service, account: identity.account),
    identity
  )
}

private func addItem(
  for identity: TestKeychainIdentity,
  valueData: Data
) throws {
  var query = identity.baseQuery
  query[kSecValueData] = valueData

  try requireSuccess(SecItemAdd(query as CFDictionary, nil))
}

private func storedData(for identity: TestKeychainIdentity) throws -> Data {
  var query = identity.baseQuery
  query[kSecMatchLimit] = kSecMatchLimitOne
  query[kSecReturnData] = true

  var result: CFTypeRef?
  try requireSuccess(SecItemCopyMatching(query as CFDictionary, &result))

  guard let data = result as? Data else {
    throw TestKeychainFailure.operationFailed
  }

  return data
}

private func removeItem(for identity: TestKeychainIdentity) throws {
  let status = SecItemDelete(identity.baseQuery as CFDictionary)

  guard status == errSecSuccess || status == errSecItemNotFound else {
    throw TestKeychainFailure.operationFailed
  }
}

private func requireSuccess(_ status: OSStatus) throws {
  guard status == errSecSuccess else {
    throw TestKeychainFailure.operationFailed
  }
}

private enum TestKeychainFailure: Error {
  case operationFailed
}
