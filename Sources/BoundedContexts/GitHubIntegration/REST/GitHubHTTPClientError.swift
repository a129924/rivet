public enum GitHubHTTPClientError: Error, Sendable, Equatable {
  public enum CredentialLifecycleStage: Sendable {
    case restore
    case refresh
    case persist
  }

  case invalidRequest
  case authenticationRequired
  case credentialLifecycle(stage: CredentialLifecycleStage)
  case executionFailed
}
