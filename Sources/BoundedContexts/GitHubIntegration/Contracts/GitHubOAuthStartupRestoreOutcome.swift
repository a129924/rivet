/// 本地啟動還原結果；ready 不保證遠端身分或權限。
public enum GitHubOAuthStartupRestoreOutcome: Sendable {
  case ready(GitHubClientScope)
  case notConfigured
  case notSignedIn
  case authenticationRequired
  case failed(GitHubOAuthStartupRestoreFailure)
  case cancelled
  case busy
}

/// 有限技術原因，不持有任意 underlying error 或秘密。
public enum GitHubOAuthStartupRestoreFailure: Sendable {
  case configurationStore(GitHubOAuthDataProtectionStoreError)
  case configurationLoad
  case fetcherCreation
  case preparation(GitHubClientPreparationError)
  case preparationFailed
}
