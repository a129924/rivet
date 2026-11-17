import Foundation

/// Share this coordinator whenever login services share either credential destination.
/// It coordinates complete attempts in this process, not external writers or providers.
public actor GitHubLoginCoordinator {
  private var busy = false

  public init() {}

  func acquire() -> Bool {
    guard !busy else { return false }
    busy = true
    return true
  }

  func release() { busy = false }
}

/// GitHub.com login. Success means account validation and the corresponding save finished.
/// The caller must exclude other processes/providers writing these destinations.
public struct GitHubLoginService: LoginAuthenticating, CustomReflectable {
  public var customMirror: Mirror { Mirror(self, children: [:]) }
  private let coordinator: GitHubLoginCoordinator
  private let dependencies: GitHubLoginDependencies

  public init(
    configuration: GitHubOAuthAppConfiguration,
    oauthStores: GitHubOAuthDataProtectionStores,
    patStore: GitHubPATDataProtectionStore,
    coordinator: GitHubLoginCoordinator
  ) {
    let oauthStore = oauthStores.credentialStore(clientID: configuration.clientID)
    self.init(
      coordinator: coordinator,
      dependencies: GitHubLoginDependencies(
        authorize: { try await GitHubLoginOAuthFlow.authorize(configuration: configuration) },
        validate: { try await GitHubLoginAccountProbe().validate(token: $0) },
        saveOAuth: { try await oauthStore.save($0) },
        savePAT: { try await patStore.save($0) }))
  }

  init(coordinator: GitHubLoginCoordinator, dependencies: GitHubLoginDependencies) {
    self.coordinator = coordinator
    self.dependencies = dependencies
  }

  public func authenticate(_ request: LoginRequest) async -> LoginOutcome {
    guard !Task.isCancelled else { return .cancelled }
    guard await coordinator.acquire() else {
      return Task.isCancelled ? .cancelled : .failure(.authenticationFailed)
    }
    let worker = Task { await execute(request) }
    let result = await withTaskCancellationHandler {
      await worker.value
    } onCancel: {
      worker.cancel()
    }
    await coordinator.release()
    // This must remain the last check, with no subsequent suspension.
    return Task.isCancelled ? .cancelled : result
  }

  private func execute(_ request: LoginRequest) async -> LoginOutcome {
    do {
      try Task.checkCancellation()
      switch request {
      case .oauth:
        let credential = try await dependencies.authorize()
        try Task.checkCancellation()
        try await dependencies.validate(credential.accessToken.rawValue)
        try Task.checkCancellation()
        try await dependencies.saveOAuth(credential)
      case .pat(let token):
        try await dependencies.validate(token.rawValue)
        try Task.checkCancellation()
        try await dependencies.savePAT(token)
      }
      return Task.isCancelled ? .cancelled : .success
    } catch {
      return Task.isCancelled || error is CancellationError
        ? .cancelled : .failure(.authenticationFailed)
    }
  }
}

struct GitHubLoginDependencies: Sendable {
  let authorize: @Sendable () async throws -> GitHubOAuthCredentialBundle
  let validate: @Sendable (String) async throws -> Void
  let saveOAuth: @Sendable (GitHubOAuthCredentialBundle) async throws -> Void
  let savePAT: @Sendable (PersonalAccessToken) async throws -> Void
}
