import Foundation
import Testing

@testable import GitHubIntegration

@Suite("Dual login runtime")
struct GitHubLoginServiceTests {
  @Test func patValidatesBeforeSaving() async throws {
    let trace = LoginTrace()
    let service = GitHubLoginService(
      coordinator: GitHubLoginCoordinator(),
      dependencies: .init(
        authorize: { throw LoginTestFailure.failed },
        validate: { _ in await trace.append("validate") },
        saveOAuth: { _ in await trace.append("oauth") },
        savePAT: { _ in await trace.append("pat") }))
    let result = await service.authenticate(.pat(try PersonalAccessToken(rawValue: "fixture")))
    #expect(result == .success)
    #expect(await trace.values == ["validate", "pat"])
  }
  @Test func oauthSavesCompleteBundleAndLeavesPATUntouched() async {
    let trace = LoginTrace()
    let saved = SavedLogin()
    let credential = Self.bundle()
    let service = GitHubLoginService(
      coordinator: GitHubLoginCoordinator(),
      dependencies: .init(
        authorize: {
          await trace.append("authorize")
          return credential
        },
        validate: { token in
          #expect(token == "oauth-access")
          await trace.append("validate")
        },
        saveOAuth: { value in
          await saved.store(value)
          await trace.append("oauth")
        },
        savePAT: { _ in Issue.record("PAT must be untouched") }))
    #expect(await service.authenticate(.oauth) == .success)
    #expect(await trace.values == ["authorize", "validate", "oauth"])
    let restored = await saved.credential
    #expect(restored?.refreshToken.rawValue == credential.refreshToken.rawValue)
    #expect(restored?.accessTokenExpiresAt == credential.accessTokenExpiresAt)
    #expect(restored?.refreshTokenExpiresAt == credential.refreshTokenExpiresAt)
    #expect(restored?.grantedScopes == credential.grantedScopes)
  }

  @Test(arguments: ["authorize", "validate", "save"])
  func failuresStayFinite(_ stage: String) async {
    let trace = LoginTrace()
    let service = GitHubLoginService(
      coordinator: GitHubLoginCoordinator(),
      dependencies: .init(
        authorize: {
          if stage == "authorize" { throw LoginTestFailure.failed }
          return Self.bundle()
        },
        validate: { _ in
          await trace.append("validate")
          if stage == "validate" { throw LoginTestFailure.failed }
        },
        saveOAuth: { _ in
          await trace.append("save")
          throw LoginTestFailure.failed
        }, savePAT: { _ in Issue.record("Wrong destination") }))
    #expect(await service.authenticate(.oauth) == .failure(.authenticationFailed))
    let expected =
      stage == "authorize" ? [] : stage == "validate" ? ["validate"] : ["validate", "save"]
    #expect(await trace.values == expected)
    // A failed attempt releases admission too.
    #expect(await service.authenticate(.oauth) == .failure(.authenticationFailed))
  }

  @Test func preCancelledDoesNoWork() async {
    let ready = LoginGate()
    let proceed = LoginGate()
    let service = Self.forbiddenService()
    let task = Task {
      await ready.open()
      await proceed.wait()
      return await service.authenticate(.oauth)
    }
    await ready.wait()
    task.cancel()
    await proceed.open()
    #expect(await task.value == .cancelled)
  }

  @Test(arguments: [false, true])
  func cancellationWaitsForOriginalAndBlocksOverlap(_ duringSave: Bool) async throws {
    let entered = LoginGate()
    let proceed = LoginGate()
    let saved = LoginTrace()
    let coordinator = GitHubLoginCoordinator()
    let dependencies = GitHubLoginDependencies(
      authorize: { Self.bundle() },
      validate: { _ in
        if !duringSave {
          await entered.open()
          await proceed.wait()
        }
      },
      saveOAuth: { _ in },
      savePAT: { _ in
        await saved.append("started")
        if duringSave {
          await entered.open()
          await proceed.wait()
        }
        await saved.append("saved")
      })
    let first = GitHubLoginService(coordinator: coordinator, dependencies: dependencies)
    let second = GitHubLoginService(coordinator: coordinator, dependencies: dependencies)
    let token = try PersonalAccessToken(rawValue: "fixture")
    let task = Task { await first.authenticate(.pat(token)) }
    await entered.wait()
    task.cancel()
    #expect(await second.authenticate(.pat(token)) == .failure(.authenticationFailed))
    await proceed.open()
    #expect(await task.value == .cancelled)
    #expect(await saved.values == (duringSave ? ["started", "saved"] : []))
    #expect(await second.authenticate(.pat(token)) == .success)
  }

  @Test func cancellationDuringAuthorizationWaitsForCleanup() async {
    let entered = LoginGate()
    let cleanup = LoginGate()
    let coordinator = GitHubLoginCoordinator()
    let service = GitHubLoginService(
      coordinator: coordinator,
      dependencies: .init(
        authorize: {
          await entered.open()
          await cleanup.wait()
          try Task.checkCancellation()
          return Self.bundle()
        },
        validate: { _ in Issue.record("No validation after cancellation") },
        saveOAuth: { _ in Issue.record("No save after cancellation") },
        savePAT: { _ in Issue.record("Wrong destination") }))
    let task = Task { await service.authenticate(.oauth) }
    await entered.wait()
    task.cancel()
    #expect(await service.authenticate(.oauth) == .failure(.authenticationFailed))
    await cleanup.open()
    #expect(await task.value == .cancelled)
  }

  @Test(arguments: [false, true])
  func patFailureNeverTouchesOAuth(_ saveFails: Bool) async throws {
    let trace = LoginTrace()
    let service = GitHubLoginService(
      coordinator: GitHubLoginCoordinator(),
      dependencies: .init(
        authorize: {
          Issue.record("No OAuth")
          throw LoginTestFailure.failed
        },
        validate: { _ in if !saveFails { throw LoginTestFailure.failed } },
        saveOAuth: { _ in Issue.record("No OAuth save") },
        savePAT: { _ in
          await trace.append("save")
          throw LoginTestFailure.failed
        }))
    #expect(
      await service.authenticate(.pat(try PersonalAccessToken(rawValue: "fixture")))
        == .failure(.authenticationFailed))
    #expect(await trace.values == (saveFails ? ["save"] : []))
  }

  private static func forbiddenService() -> GitHubLoginService {
    GitHubLoginService(
      coordinator: GitHubLoginCoordinator(),
      dependencies: .init(
        authorize: {
          Issue.record("Unexpected authorization")
          throw LoginTestFailure.failed
        },
        validate: { _ in Issue.record("Unexpected probe") },
        saveOAuth: { _ in Issue.record("Unexpected save") },
        savePAT: { _ in Issue.record("Unexpected save") }))
  }

  static func bundle() -> GitHubOAuthCredentialBundle {
    GitHubOAuthCredentialBundle(
      accessToken: .init(rawValue: "oauth-access"), refreshToken: .init(rawValue: "oauth-refresh"),
      accessTokenExpiresAt: Date(timeIntervalSince1970: 1000),
      refreshTokenExpiresAt: Date(timeIntervalSince1970: 2000),
      tokenType: .bearer, grantedScopes: "repo")
  }
}

actor LoginGate {
  private var opened = false
  private var waiters: [CheckedContinuation<Void, Never>] = []

  func wait() async {
    guard !opened else { return }
    await withCheckedContinuation { waiters.append($0) }
  }

  func open() {
    opened = true
    let pending = waiters
    waiters.removeAll()
    for waiter in pending { waiter.resume() }
  }
}

actor SavedLogin {
  var credential: GitHubOAuthCredentialBundle?
  func store(_ value: GitHubOAuthCredentialBundle) { credential = value }
}

actor LoginTrace {
  var values: [String] = []
  func append(_ value: String) { values.append(value) }
}

enum LoginTestFailure: Error { case failed }
