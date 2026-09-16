import Foundation
import Security

public final class KeychainTokenStore: GitHubTokenStore {
  private let service: String
  private let account: String

  public init() {
    service = "com.rivet.github-integration"
    account = "github-access-token"
  }

  init(service: String, account: String) {
    self.service = service
    self.account = account
  }

  public func load() throws(TokenStoreError) -> GitHubAccessToken? {
    var query = baseQuery
    query[kSecMatchLimit] = kSecMatchLimitOne
    query[kSecReturnData] = true

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    switch status {
    case errSecSuccess:
      guard let data = result as? Data,
        let rawValue = String(data: data, encoding: .utf8)
      else {
        throw failure(for: .load)
      }

      return GitHubAccessToken(rawValue: rawValue)
    case errSecItemNotFound:
      return nil
    default:
      throw failure(for: .load)
    }
  }

  public func save(_ token: GitHubAccessToken) throws(TokenStoreError) {
    let attributes: [CFString: Any] = [
      kSecValueData: Data(token.rawValue.utf8)
    ]
    let updateStatus = SecItemUpdate(
      baseQuery as CFDictionary,
      attributes as CFDictionary
    )

    switch updateStatus {
    case errSecSuccess:
      return
    case errSecItemNotFound:
      var addQuery = baseQuery
      for (key, value) in attributes {
        addQuery[key] = value
      }

      guard SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess else {
        throw failure(for: .save)
      }
    default:
      throw failure(for: .save)
    }
  }

  public func delete() throws(TokenStoreError) {
    let status = SecItemDelete(baseQuery as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw failure(for: .delete)
    }
  }

  private var baseQuery: [CFString: Any] {
    [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: account,
      kSecAttrSynchronizable: false,
    ]
  }

  private func failure(for operation: TokenStoreOperation) -> TokenStoreError {
    TokenStoreError(
      operation: operation,
      underlyingError: KeychainStoreFailure.operationFailed
    )
  }
}

private enum KeychainStoreFailure: Error {
  case operationFailed
}
