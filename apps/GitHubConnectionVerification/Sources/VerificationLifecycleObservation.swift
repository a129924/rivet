import GitHubIntegration
import Synchronization

/// One instance belongs to one provider generation. This observes wrapper outcomes only.
/// It is deliberately not a copy of the provider's internal state machine.
final class VerificationLifecycleObservation: Sendable {
  enum Disposition: Sendable { case notStopped, authenticationRequired, stopped }
  private struct State {
    var disposition: Disposition = .notStopped
    var acceptedRefreshAwaitingSave = false
  }
  private let state = Mutex(State())

  func disposition() -> Disposition { state.withLock { $0.disposition } }
  func refreshBegan() {
    state.withLock { $0.acceptedRefreshAwaitingSave = false }
  }
  func refreshAccepted() {
    state.withLock { $0.acceptedRefreshAwaitingSave = true }
  }
  func refreshFailed(_ error: OAuthTokenRefreshError) {
    state.withLock {
      $0.acceptedRefreshAwaitingSave = false
      guard $0.disposition == .notStopped else { return }
      switch error {
      case .credentialRejected: $0.disposition = .authenticationRequired
      case .rotationIndeterminate, .cancelled(stage: .afterRequestStarted):
        $0.disposition = .stopped
      case .knownTechnicalFailure, .clientConfiguration, .cancelled(stage: .beforeRequest):
        break
      }
    }
  }
  func saveSucceeded() {
    state.withLock { $0.acceptedRefreshAwaitingSave = false }
  }
  func saveFailed() {
    state.withLock {
      // An initial grant save does not mean this provider accepted a refresh.
      guard $0.acceptedRefreshAwaitingSave else { return }
      $0.acceptedRefreshAwaitingSave = false
      if $0.disposition == .notStopped { $0.disposition = .stopped }
    }
  }
}

struct VerificationObservedTokenFetcher: OAuthTokenFetcher {
  let base: any OAuthTokenFetcher
  let observation: VerificationLifecycleObservation
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    observation.refreshBegan()
    do {
      let result = try await base.refresh(credential)
      observation.refreshAccepted()
      return result
    } catch {
      observation.refreshFailed(error)
      throw error
    }
  }
}

struct VerificationObservedCredentialStore: OAuthCredentialStore {
  let base: any OAuthCredentialStore
  let observation: VerificationLifecycleObservation
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    try await base.load()
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    do {
      try await base.save(credential)
      observation.saveSucceeded()
    } catch {
      observation.saveFailed()
      throw error
    }
  }
}
