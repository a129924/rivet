public struct GitHubAccessToken: Equatable, Sendable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public enum TokenStoreOperation: Sendable {
  case load
  case save
  case delete
}

public struct TokenStoreError: Error, Sendable {
  public let operation: TokenStoreOperation
  public let underlyingError: any Error & Sendable

  public init(operation: TokenStoreOperation, underlyingError: any Error & Sendable) {
    self.operation = operation
    self.underlyingError = underlyingError
  }
}

public enum GitHubCredentialError: Error, Sendable {
  case missingCredential
  case tokenStore(TokenStoreError)
  case tokenAcquisition(any Error & Sendable)
}
