/// Refresh failures contain classification only, never credentials or raw responses.
public enum OAuthTokenRefreshError: Error, Sendable {
  case credentialRejected
  case clientConfiguration
  case knownTechnicalFailure
  case rotationIndeterminate
  case cancelled(stage: CancellationStage)

  public enum CancellationStage: Sendable {
    case beforeRequest
    case afterRequestStarted
  }
}
