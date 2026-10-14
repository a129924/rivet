/// 有限的本地準備失敗；不攜帶 credential 或 underlying error。
public enum GitHubClientPreparationError: Error, Sendable, Equatable {
  public enum CredentialLifecycleStage: Sendable {
    case restore
    case refresh
    case persist
  }

  case missingCredential
  case authenticationRequired
  case credentialLifecycle(stage: CredentialLifecycleStage)
  case invalidAuthorizationToken
}
