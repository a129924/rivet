internal enum GitHubGraphQLClientError: Error, Sendable, Equatable {
  internal enum CredentialLifecycleStage: Sendable {
    case restore
    case refresh
    case persist
  }

  case authenticationRequired
  case credentialLifecycle(stage: CredentialLifecycleStage)
  case httpStatus(Int)
  case executionFailed
}
