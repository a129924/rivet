import Foundation
import GitHubIntegration
import Observation
import RivetPresentation

struct SavedGitHubCredential {
  let clientID: String
  let bundle: GitHubOAuthCredentialBundle
}

@MainActor struct GitHubReadyConnection {
  let account: () async throws -> GitHubAccount
}

@MainActor protocol GitHubAuthorizationFlow: AnyObject {
  func run(onExchange: @escaping @MainActor () -> Void) async throws -> GitHubOAuthCredentialBundle
  func cancel() async
}

@MainActor struct GitHubConnectionDependencies {
  let loadConfiguration: () async throws -> GitHubOAuthAppConfiguration?
  let inspectCredential: () async throws -> SavedGitHubCredential?
  let saveConfiguration: (GitHubOAuthAppConfiguration) async throws -> Void
  let credentialStore: (String) -> any OAuthCredentialStore
  let makeFetcher: (GitHubOAuthAppConfiguration) throws -> any OAuthTokenFetcher
  let prepare: (OAuthTokenProvider) async throws -> GitHubReadyConnection
  let makeAuthorization: (GitHubOAuthAppConfiguration) -> any GitHubAuthorizationFlow
}

enum GitHubConnectionFailure: Error, Equatable {
  case operationInProgress, storageDenied, storageUnavailable, configurationRequired
  case identityMismatch, recoveryConfirmationRequired, invalidConfiguration, configurationSave
  case credentialSave, cancelled, denied, invalidCallback, expired, authorization, prepare, probe
  case authenticationRequired, stopped, hostConfiguration
}

@MainActor @Observable final class GitHubConnectionCoordinator {
  enum Phase: Equatable {
    case idle, configuration, authorization, waiting, exchanging, preparing, connected, failed
  }
  private(set) var phase: Phase = .idle
  private(set) var failure: GitHubConnectionFailure?
  private(set) var account: GitHubAccount?
  private(set) var trustedClientID: String?
  private(set) var needsRecoveryConfirmation = false
  private(set) var isBusy = false
  private let dependencies: GitHubConnectionDependencies
  private let expiryValidation: GitHubExpiryValidation?
  private var configuration: GitHubOAuthAppConfiguration?
  private var provider: OAuthTokenProvider?
  private var scope: GitHubReadyConnection?
  private var operationTask: Task<Void, Never>?
  private var authorization: (any GitHubAuthorizationFlow)?
  private var storageBlocked = false
  private var retired = false
  private var started = false

  init(
    dependencies: GitHubConnectionDependencies, expiryValidation: GitHubExpiryValidation? = nil
  ) {
    self.dependencies = dependencies
    self.expiryValidation = expiryValidation
  }

  func start() async {
    guard !started else { return }
    started = true
    await run { await self.loadConnection() }
  }

  func retry() async {
    await run {
      self.failure = nil
      if let provider = self.provider {
        guard await provider.disposition() == .notStopped else {
          await self.classifyLifecycleFailure(default: .prepare)
          return
        }
        await self.prepareAndProbe()
      } else {
        await self.loadConnection()
      }
    }
  }

  func connect(clientID: String, secret: String, confirmsRecovery: Bool) async {
    await run {
      guard !self.storageBlocked else {
        self.fail(.storageUnavailable)
        return
      }
      self.retireConnection()
      guard self.trustedClientID == nil || self.trustedClientID == clientID else {
        self.fail(.identityMismatch)
        return
      }
      guard !self.needsRecoveryConfirmation || confirmsRecovery else {
        self.fail(.recoveryConfirmationRequired)
        return
      }
      let configuration: GitHubOAuthAppConfiguration
      do {
        configuration = try GitHubOAuthAppConfiguration(clientID: clientID, clientSecret: secret)
      } catch {
        self.fail(.invalidConfiguration)
        return
      }
      do { try await self.dependencies.saveConfiguration(configuration) } catch {
        self.handleStorage(error, fallback: .configurationSave)
        return
      }
      self.configuration = configuration
      self.trustedClientID = clientID
      self.needsRecoveryConfirmation = false
      await self.authorize(configuration)
    }
  }

  func reauthorize() async {
    await run {
      guard !self.storageBlocked else {
        self.fail(.storageUnavailable)
        return
      }
      self.retireConnection()
      guard let configuration = self.configuration else {
        self.phase = .configuration
        self.fail(.configurationRequired)
        return
      }
      await self.authorize(configuration)
    }
  }

  // UI cancellation never releases the operation handle. Only actual task settlement does that.
  func cancelOperation() { operationTask?.cancel() }

  func cancelAuthorization() async {
    guard phase == .waiting else { return }
    await authorization?.cancel()
  }

  private func run(_ work: @escaping @MainActor () async -> Void) async {
    guard operationTask == nil else {
      failure = .operationInProgress
      return
    }
    isBusy = true
    failure = nil
    let task = Task { @MainActor in await work() }
    operationTask = task
    await task.value
    expiryValidation?.exportReceipt(accountConfirmed: account != nil)
    operationTask = nil
    isBusy = false
  }

  private func loadConnection() async {
    account = nil
    storageBlocked = false
    var loadedConfiguration: GitHubOAuthAppConfiguration?
    var credential: SavedGitHubCredential?
    var corrupt = false
    do {
      loadedConfiguration = try await dependencies.loadConfiguration()
    } catch GitHubOAuthStoreError.corrupt { corrupt = true } catch {
      handleStorage(error, fallback: .storageUnavailable)
      return
    }
    do {
      credential = try await dependencies.inspectCredential()
    } catch GitHubOAuthStoreError.corrupt {
      corrupt = true
    } catch {
      handleStorage(error, fallback: .storageUnavailable)
      return
    }
    if let credential { expiryValidation?.restored(credential.bundle) }
    trustedClientID = credential?.clientID ?? loadedConfiguration?.clientID
    needsRecoveryConfirmation = corrupt && trustedClientID == nil
    if let loadedConfiguration, loadedConfiguration.clientID == trustedClientID {
      configuration = loadedConfiguration
    } else {
      configuration = nil
    }
    guard let configuration else {
      phase = .configuration
      return
    }
    guard let credential, credential.clientID == configuration.clientID, !retired else {
      phase = .authorization
      return
    }
    if provider == nil {
      expiryValidation?.arm(credential.bundle)
      do { provider = try makeProvider(configuration) } catch {
        fail(.invalidConfiguration)
        return
      }
    }
    await prepareAndProbe()
  }

  private func retireConnection() {
    expiryValidation?.endAttempt()
    retired = true
    provider = nil
    scope = nil
    account = nil
    failure = nil
  }

  private func authorize(_ configuration: GitHubOAuthAppConfiguration) async {
    let flow = dependencies.makeAuthorization(configuration)
    authorization = flow
    phase = .waiting
    defer { authorization = nil }
    let bundle: GitHubOAuthCredentialBundle
    do {
      bundle = try await flow.run { [weak self] in self?.phase = .exchanging }
    } catch {
      switch error {
      case GitHubOAuthError.cancelled: fail(.cancelled)
      case GitHubOAuthError.denied: fail(.denied)
      case GitHubOAuthError.invalidCallback: fail(.invalidCallback)
      case GitHubOAuthError.expiredSession: fail(.expired)
      default: fail(.authorization)
      }
      return
    }
    do { try await dependencies.credentialStore(configuration.clientID).save(bundle) } catch {
      handleStorage(error, fallback: .credentialSave)
      return
    }
    do { provider = try makeProvider(configuration) } catch {
      fail(.invalidConfiguration)
      return
    }
    retired = false
    await prepareAndProbe()
  }

  private func makeProvider(
    _ configuration: GitHubOAuthAppConfiguration
  ) throws -> OAuthTokenProvider {
    OAuthTokenProvider(
      store: dependencies.credentialStore(configuration.clientID),
      fetcher: try dependencies.makeFetcher(configuration),
      now: { [expiryValidation] in expiryValidation?.now() ?? Date() })
  }

  private func prepareAndProbe() async {
    guard let provider else {
      fail(.authenticationRequired)
      return
    }
    phase = .preparing
    failure = nil
    account = nil
    if scope == nil {
      do { scope = try await dependencies.prepare(provider) } catch {
        await classifyLifecycleFailure(default: .prepare)
        return
      }
    }
    do {
      account = try await scope?.account()
      phase = .connected
      failure = nil
    } catch { await classifyLifecycleFailure(default: .probe) }
  }

  private func classifyLifecycleFailure(default fallback: GitHubConnectionFailure) async {
    guard let provider else {
      fail(fallback)
      return
    }
    switch await provider.disposition() {
    case .notStopped: fail(fallback)
    case .authenticationRequired: fail(.authenticationRequired)
    case .stopped: fail(.stopped)
    }
  }

  private func handleStorage(_ error: any Error, fallback: GitHubConnectionFailure) {
    switch error {
    case GitHubConnectionFailure.hostConfiguration:
      storageBlocked = true
      fail(.hostConfiguration)
    case GitHubOAuthStoreError.denied:
      storageBlocked = true
      fail(.storageDenied)
    case GitHubOAuthStoreError.unavailable:
      storageBlocked = true
      fail(.storageUnavailable)
    case GitHubOAuthStoreError.identityMismatch: fail(.identityMismatch)
    default: fail(fallback)
    }
  }

  private func fail(_ failure: GitHubConnectionFailure) {
    self.failure = failure
    account = nil
    phase = .failed
  }

  var presentation: GitHubConnectionPresentation {
    GitHubConnectionPresentation(
      title: account == nil ? "連線 GitHub" : "已連線 GitHub",
      detail: detail,
      account: account.map { "\($0.login) · \($0.id)" }, clientID: trustedClientID ?? "",
      locksClientID: trustedClientID != nil,
      showsConfiguration: !storageBlocked && (configuration == nil || phase == .failed),
      requiresRecoveryConfirmation: needsRecoveryConfirmation, isBusy: isBusy,
      canCancel: phase == .waiting,
      canRetry: !isBusy && phase == .failed && failure != .authenticationRequired
        && failure != .stopped,
      canReauthorize: !isBusy && configuration != nil && !storageBlocked)
  }

  private var detail: String {
    if let failure {
      switch failure {
      case .operationInProgress: return "前一項工作仍在完成，請稍後再試。"
      case .storageDenied: return "無法取得憑證授權。請允許存取後按重試。"
      case .storageUnavailable: return "憑證目前無法存取，請確認系統狀態後重試。"
      case .identityMismatch: return "請使用原 GitHub OAuth App 的 Client ID 與 secret。"
      case .recoveryConfirmationRequired: return "請確認輸入的是原先使用的 OAuth App。"
      case .invalidConfiguration, .configurationRequired:
        return "請輸入原 OAuth App 的 Client ID 與 secret。"
      case .configurationSave: return "設定保存失敗，尚未開始授權，請重試。"
      case .credentialSave: return "連線憑證保存失敗，請重新授權。"
      case .cancelled: return "已取消登入，可再次授權。"
      case .denied: return "GitHub 授權遭拒，可再次授權。"
      case .invalidCallback: return "授權回應無效，請重新授權。"
      case .expired: return "登入等待已逾時，請重新授權。"
      case .authorization: return "授權未完成，請確認設定與網路後重新授權。"
      case .prepare: return "連線暫時未就緒，可重試或修復原 App 設定。"
      case .probe: return "目前無法取得 GitHub 帳號結果，請重試。"
      case .authenticationRequired, .stopped: return "此連線已停止，請重新授權。"
      case .hostConfiguration: return "請先完成 Rivet 的開發簽章與有效 profile 設定。"
      }
    }
    switch phase {
    case .idle: return "準備還原連線。"
    case .configuration: return "設定自己的 OAuth App 後開始登入。"
    case .authorization: return "設定已保存，請按重新授權。"
    case .waiting: return "請在瀏覽器完成 GitHub 授權。"
    case .exchanging: return "正在完成授權與保存憑證。"
    case .preparing: return "正在還原連線並取得帳號結果。"
    case .connected: return "已取得目前 GitHub 帳號結果。"
    case .failed: return "連線尚未完成。"
    }
  }
}
