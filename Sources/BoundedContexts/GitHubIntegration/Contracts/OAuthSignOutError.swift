public enum OAuthSignOutError: Error, Sendable {
  case unsupportedStore
  case clear(underlying: any Error & Sendable)
}
