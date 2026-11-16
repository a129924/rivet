import Foundation
import GitHubIntegration
import Testing

@Suite("受控 OAuth／PAT 登入契約")
struct LoginAuthenticationContractTests {
  @Test(arguments: ["", " ", "\t\n\r ", "\u{2003}\n"])
  func emptyPATIsRejected(input: String) {
    #expect(throws: PATInputError.empty) {
      try PersonalAccessToken(rawValue: input)
    }
  }

  @Test
  func patPreservesInternalCharactersWithoutPrefixValidation() throws {
    let token = try PersonalAccessToken(rawValue: " \tcustom token\nvalue\r\n")
    #expect(token.rawValue == "custom token\nvalue")
    #expect(token == (try PersonalAccessToken(rawValue: "custom token\nvalue")))
    requireSendable(token)
    requireSendable(PATInputError.empty)
  }

  @Test
  func publicExistentialCallerAcceptsBothRequestsAndControlledOutcomes() async throws {
    for request in try requests() {
      requireSendable(request)
      for outcome in [LoginOutcome.success, .failure(.authenticationFailed), .cancelled] {
        let service: any LoginAuthenticating = ImmediateControlledAuthenticator(outcome: outcome)
        #expect(await call(service, request: request) == outcome)
        requireSendable(service)
        requireSendable(outcome)
      }
    }
  }

  @Test
  func diagnosticsRedactPATAndOuterRequest() throws {
    let sentinel = "SENTINEL_private_74b9"
    let token = try PersonalAccessToken(rawValue: sentinel)
    let request = LoginRequest.pat(token)
    for value in [token as Any, request as Any] {
      var dumped = ""
      dump(value, to: &dumped)
      for diagnostic in [String(describing: value), String(reflecting: value), dumped] {
        #expect(!diagnostic.contains(sentinel))
        #expect(!diagnostic.contains("74b9"))
        #expect(!diagnostic.contains(String(sentinel.count)))
        #expect(diagnostic.contains("redacted"))
      }
      #expect(Mirror(reflecting: value).children.isEmpty)
    }
    #expect(String(describing: request).contains("pat"))
    #expect(String(describing: LoginRequest.oauth).contains("oauth"))
    #expect(Mirror(reflecting: LoginRequest.oauth).children.isEmpty)
  }

  @Test
  func preCancelledTaskDoesNotStartWork() async throws {
    for request in try requests() {
      let entry = PublicationGate()
      let work = ControlledLoginWork()
      let service = WaitingControlledAuthenticator(work: work)
      let task = Task {
        await entry.wait()
        return await call(service, request: request)
      }
      task.cancel()
      await entry.open()
      #expect(await task.value == .cancelled)
      #expect(await work.started == false)
    }
  }

  @Test
  func cancellationPropagatesAndWaitsForOriginalWorkToSettle() async throws {
    for request in try requests() {
      let work = ControlledLoginWork()
      let cancellation = CancellationObservation()
      let service = WaitingControlledAuthenticator(work: work, cancellation: cancellation)
      let task = Task { await call(service, request: request) }
      await work.waitUntilStarted()
      task.cancel()
      #expect(cancellation.observed)
      #expect(await work.settled == false)
      await work.finish(.success)
      #expect(await task.value == .cancelled)
      #expect(await work.settled)
      #expect(await work.observedCancellation)
    }
  }

  @Test
  func cancellationWinsOverReadySuccessAndFailure() async throws {
    for request in try requests() {
      for outcome in [LoginOutcome.success, .failure(.authenticationFailed)] {
        let publication = PublicationGate()
        let service = ReadyControlledAuthenticator(outcome: outcome, publication: publication)
        let task = Task { await call(service, request: request) }
        await publication.waitUntilEntered()
        task.cancel()
        await publication.open()
        #expect(await task.value == .cancelled)
      }
    }
  }

  @Test
  func cancellationAfterReturnDoesNotRewriteResult() async throws {
    for request in try requests() {
      let task = Task {
        await call(ImmediateControlledAuthenticator(outcome: .success), request: request)
      }
      #expect(await task.value == .success)
      task.cancel()
      #expect(await task.value == .success)
    }
  }
}

private func requests() throws -> [LoginRequest] {
  [.oauth, .pat(try PersonalAccessToken(rawValue: "controlled-test-token"))]
}

private func call(_ service: any LoginAuthenticating, request: LoginRequest) async -> LoginOutcome {
  await service.authenticate(request)
}

private func requireSendable<Value: Sendable>(_ value: Value) {}

// All conformers below return controlled results; none performs GitHub authentication.
private struct ImmediateControlledAuthenticator: LoginAuthenticating {
  let outcome: LoginOutcome

  func authenticate(_ request: LoginRequest) async -> LoginOutcome {
    Task.isCancelled ? .cancelled : outcome
  }
}

private struct WaitingControlledAuthenticator: LoginAuthenticating {
  let work: ControlledLoginWork
  var cancellation = CancellationObservation()

  func authenticate(_ request: LoginRequest) async -> LoginOutcome {
    guard !Task.isCancelled else { return .cancelled }
    let outcome = await withTaskCancellationHandler {
      await work.run()
    } onCancel: {
      cancellation.record()
    }
    return Task.isCancelled ? .cancelled : outcome
  }
}

private struct ReadyControlledAuthenticator: LoginAuthenticating {
  let outcome: LoginOutcome
  let publication: PublicationGate

  func authenticate(_ request: LoginRequest) async -> LoginOutcome {
    guard !Task.isCancelled else { return .cancelled }
    // The controlled result is already available before this publication barrier.
    await publication.wait()
    return Task.isCancelled ? .cancelled : outcome
  }
}

private final class CancellationObservation: @unchecked Sendable {
  private let lock = NSLock()
  private var value = false

  var observed: Bool { lock.withLock { value } }
  func record() { lock.withLock { value = true } }
}

private actor ControlledLoginWork {
  private(set) var started = false
  private(set) var settled = false
  private(set) var observedCancellation = false
  private var result: CheckedContinuation<LoginOutcome, Never>?
  private var observers: [CheckedContinuation<Void, Never>] = []

  func run() async -> LoginOutcome {
    let outcome = await withCheckedContinuation { continuation in
      result = continuation
      started = true
      for observer in observers { observer.resume() }
      observers.removeAll()
    }
    observedCancellation = Task.isCancelled
    settled = true
    return outcome
  }

  func waitUntilStarted() async {
    guard !started else { return }
    await withCheckedContinuation { observers.append($0) }
  }

  func finish(_ outcome: LoginOutcome) {
    result?.resume(returning: outcome)
    result = nil
  }
}

private actor PublicationGate {
  private var opened = false
  private var entered = false
  private var waiters: [CheckedContinuation<Void, Never>] = []
  private var observers: [CheckedContinuation<Void, Never>] = []

  func wait() async {
    entered = true
    for observer in observers { observer.resume() }
    observers.removeAll()
    guard !opened else { return }
    await withCheckedContinuation { waiters.append($0) }
  }

  func waitUntilEntered() async {
    guard !entered else { return }
    await withCheckedContinuation { observers.append($0) }
  }

  func open() {
    opened = true
    for waiter in waiters { waiter.resume() }
    waiters.removeAll()
  }
}
