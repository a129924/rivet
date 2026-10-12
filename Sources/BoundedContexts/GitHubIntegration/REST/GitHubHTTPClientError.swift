internal enum GitHubHTTPClientError: Error, Sendable, Equatable {
  internal enum CredentialLifecycleStage: Sendable {
    case restore
    case refresh
    case persist
  }

  case invalidRequest
  case authenticationRequired
  case credentialLifecycle(stage: CredentialLifecycleStage)
  case executionFailed
}
