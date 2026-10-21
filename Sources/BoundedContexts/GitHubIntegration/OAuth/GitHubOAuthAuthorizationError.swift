public enum GitHubOAuthAuthorizationError: Error, Sendable, Equatable {
  case clientConfiguration
  case invalidCallback
  case denied
  case expiredSession
  case cancelled
  case alreadyCompleted
  case exchangeRejected
  case transport
  case invalidTokenResponse
}
