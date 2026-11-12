import Foundation
import GitHubIntegration
import Testing

@testable import GitHubConnectionVerification

@Suite("Verification-local lifecycle observation")
struct VerificationLifecycleObservationTests {
  @Test(arguments: [
    OAuthTokenRefreshError.credentialRejected, .rotationIndeterminate,
    .cancelled(stage: .afterRequestStarted), .clientConfiguration,
    .knownTechnicalFailure, .cancelled(stage: .beforeRequest),
  ])
  func classifiesActualFailureWithoutIO(_ failure: OAuthTokenRefreshError) async {
    let observation = VerificationLifecycleObservation()
    let store = ObservedTestStore()
    let fetcher = ObservedTestFetcher(failure: failure)
    let provider = OAuthTokenProvider(
      store: VerificationObservedCredentialStore(base: store, observation: observation),
      fetcher: VerificationObservedTokenFetcher(base: fetcher, observation: observation),
      now: { observationDate })
    #expect(observation.disposition() == .notStopped)
    #expect(await store.counts() == [0, 0])
    do { _ = try await provider.snapshot() } catch {}
    let expected: VerificationLifecycleObservation.Disposition
    switch failure {
    case .credentialRejected: expected = .authenticationRequired
    case .rotationIndeterminate, .cancelled(stage: .afterRequestStarted): expected = .stopped
    default: expected = .notStopped
    }
    for _ in 0..<10 { #expect(observation.disposition() == expected) }
    #expect(await store.counts() == [1, 0])
    #expect(await fetcher.count() == 1)
  }

  @Test func acceptedRotationSaveFailureStopsAndPreservesOriginalError() async {
    let observation = VerificationLifecycleObservation()
    let store = ObservedTestStore(failSave: true)
    let fetcher = ObservedTestFetcher(failure: nil)
    let provider = OAuthTokenProvider(
      store: VerificationObservedCredentialStore(base: store, observation: observation),
      fetcher: VerificationObservedTokenFetcher(base: fetcher, observation: observation),
      now: { observationDate })
    do {
      _ = try await provider.snapshot()
      Issue.record("Expected accepted rotation persistence failure")
    } catch {
      guard case .persist(let underlying) = error else {
        Issue.record("Wrong provider error stage")
        return
      }
      #expect(underlying is ObservationTestFailure)
    }
    #expect(observation.disposition() == .stopped)
    #expect(await store.counts() == [1, 1])
    #expect(await fetcher.count() == 1)
  }

  @Test func initialSaveFailureAndSuccessfulPriorSaveDoNotPoisonNextGeneration() async {
    let observation = VerificationLifecycleObservation()
    let store = VerificationObservedCredentialStore(
      base: ObservedTestStore(failSave: true), observation: observation)
    do { try await store.save(observationBundle(expired: false)) } catch {}
    #expect(observation.disposition() == .notStopped)
    observation.refreshBegan()
    observation.refreshAccepted()
    observation.saveSucceeded()
    observation.saveFailed()
    #expect(observation.disposition() == .notStopped)
    observation.refreshBegan()
    observation.refreshFailed(.rotationIndeterminate)
    #expect(observation.disposition() == .stopped)
    #expect(VerificationLifecycleObservation().disposition() == .notStopped)
  }

  @Test func secondAcceptedRotationFailureIsStillTerminal() async {
    let observation = VerificationLifecycleObservation()
    let store = ObservedTestStore(failSecondSave: true)
    let fetcher = ObservedTestFetcher(failure: nil, expiredRotation: true)
    let provider = OAuthTokenProvider(
      store: VerificationObservedCredentialStore(base: store, observation: observation),
      fetcher: VerificationObservedTokenFetcher(base: fetcher, observation: observation),
      now: { observationDate })
    do { _ = try await provider.snapshot() } catch {}
    #expect(observation.disposition() == .stopped)
    #expect(await fetcher.count() == 2)
    #expect(await store.counts() == [1, 2])
  }

  @Test func expiredRotationLimitRemainsNonterminal() async {
    let observation = VerificationLifecycleObservation()
    let store = ObservedTestStore()
    let fetcher = ObservedTestFetcher(failure: nil, expiredRotation: true)
    let provider = OAuthTokenProvider(
      store: VerificationObservedCredentialStore(base: store, observation: observation),
      fetcher: VerificationObservedTokenFetcher(base: fetcher, observation: observation),
      now: { observationDate })
    do { _ = try await provider.snapshot() } catch {}
    #expect(observation.disposition() == .notStopped)
    #expect(await fetcher.count() == 2)
    #expect(await store.counts() == [1, 2])
  }
}

private let observationDate = Date(timeIntervalSince1970: 1_800_000_000)
private enum ObservationTestFailure: Error { case failed }
private func observationBundle(expired: Bool) -> GitHubOAuthCredentialBundle {
  .init(
    accessToken: .init(rawValue: "fake-access"), refreshToken: .init(rawValue: "fake-refresh"),
    accessTokenExpiresAt: observationDate.addingTimeInterval(expired ? 0 : 60),
    refreshTokenExpiresAt: observationDate.addingTimeInterval(600), tokenType: .bearer,
    grantedScopes: "")
}
private actor ObservedTestStore: OAuthCredentialStore {
  private var loads = 0
  private var saves = 0
  let failSave: Bool
  let failSecondSave: Bool
  init(failSave: Bool = false, failSecondSave: Bool = false) {
    self.failSave = failSave
    self.failSecondSave = failSecondSave
  }
  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    loads += 1
    return observationBundle(expired: true)
  }
  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    saves += 1
    if failSave || (failSecondSave && saves == 2) { throw ObservationTestFailure.failed }
  }
  func counts() -> [Int] { [loads, saves] }
}
private actor ObservedTestFetcher: OAuthTokenFetcher {
  let failure: OAuthTokenRefreshError?
  let expiredRotation: Bool
  private var calls = 0
  init(failure: OAuthTokenRefreshError?, expiredRotation: Bool = false) {
    self.failure = failure
    self.expiredRotation = expiredRotation
  }
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    calls += 1
    if let failure { throw failure }
    return observationBundle(expired: expiredRotation)
  }
  func count() -> Int { calls }
}
