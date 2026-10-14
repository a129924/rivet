public enum GitHubGraphQLClientError: Error, Sendable, Equatable {
  public enum CredentialLifecycleStage: Sendable {
    case restore
    case refresh
    case persist
  }

  case invalidAuthorizationToken
  case authenticationRequired
  case credentialLifecycle(stage: CredentialLifecycleStage)
  case httpStatus(Int)
  case executionFailed
}
