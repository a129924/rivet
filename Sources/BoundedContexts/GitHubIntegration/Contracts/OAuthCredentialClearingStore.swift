/// Optional local deletion capability. Missing credentials are an idempotent success.
public protocol OAuthCredentialClearingStore: OAuthCredentialStore {
  func clear() async throws(any Error & Sendable)
}
