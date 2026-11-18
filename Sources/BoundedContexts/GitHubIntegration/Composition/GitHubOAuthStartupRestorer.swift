import Foundation

/// 呼叫端必須為單一連線保留唯一 owner，不以新 instance 繞過 terminal 狀態。
/// 初始化不讀取 Keychain 或發送網路請求；還原不清除憑證或啟動登入。
public actor GitHubOAuthStartupRestorer {
  private let configurationStore: any GitHubOAuthAppConfigurationStore
  private let makeCredentialStore: @Sendable (String) -> any OAuthCredentialStore
  private let makeTokenFetcher:
    @Sendable (GitHubOAuthAppConfiguration) throws -> any OAuthTokenFetcher
  private let prepareScope: @Sendable (OAuthTokenProvider) async throws -> GitHubClientScope
  private var provider: OAuthTokenProvider?
  private var inFlight: Task<GitHubOAuthStartupRestoreOutcome, Never>?

  public init(stores: GitHubOAuthDataProtectionStores) {
    configurationStore = stores.configurationStore
    makeCredentialStore = { stores.credentialStore(clientID: $0) }
    makeTokenFetcher = { try GitHubOAuth.makeTokenFetcher(configuration: $0) }
    prepareScope = { try await GitHubClientScope.prepare(provider: $0) }
  }

  public init(
    configurationStore: any GitHubOAuthAppConfigurationStore,
    makeCredentialStore: @escaping @Sendable (String) -> any OAuthCredentialStore,
    makeTokenFetcher:
      @escaping @Sendable (GitHubOAuthAppConfiguration) throws -> any OAuthTokenFetcher = {
        try GitHubOAuth.makeTokenFetcher(configuration: $0)
      }
  ) {
    self.configurationStore = configurationStore
    self.makeCredentialStore = makeCredentialStore
    self.makeTokenFetcher = makeTokenFetcher
    prepareScope = { try await GitHubClientScope.prepare(provider: $0) }
  }

  // 受控 client execution 使用既有 internal 組裝 seam，不擴張 public transport API。
  init(
    configurationStore: any GitHubOAuthAppConfigurationStore,
    makeCredentialStore: @escaping @Sendable (String) -> any OAuthCredentialStore,
    makeTokenFetcher:
      @escaping @Sendable (GitHubOAuthAppConfiguration) throws -> any OAuthTokenFetcher,
    prepareScope: @escaping @Sendable (OAuthTokenProvider) async throws -> GitHubClientScope
  ) {
    self.configurationStore = configurationStore
    self.makeCredentialStore = makeCredentialStore
    self.makeTokenFetcher = makeTokenFetcher
    self.prepareScope = prepareScope
  }

  /// 每次只 prepare 一次。取消仍等原工作 settled，期間新需求回 busy。
  public func restore() async -> GitHubOAuthStartupRestoreOutcome {
    if Task.isCancelled { return .cancelled }
    guard inFlight == nil else { return .busy }
    let task = Task { await runRestore() }
    inFlight = task
    let outcome = await withTaskCancellationHandler {
      await task.value
    } onCancel: {
      task.cancel()
    }
    inFlight = nil
    return Task.isCancelled ? .cancelled : outcome
  }

  private func runRestore() async -> GitHubOAuthStartupRestoreOutcome {
    if Task.isCancelled { return .cancelled }
    if provider == nil, let incomplete = await assembleProvider() { return incomplete }
    guard let provider else { return .failed(.preparationFailed) }
    do {
      let scope = try await prepareScope(provider)
      return Task.isCancelled ? .cancelled : .ready(scope)
    } catch {
      if isCancellation(error) { return .cancelled }
      guard let preparation = error as? GitHubClientPreparationError else {
        return .failed(.preparationFailed)
      }
      switch preparation {
      case .missingCredential: return .notSignedIn
      case .authenticationRequired: return .authenticationRequired
      default: return .failed(.preparation(preparation))
      }
    }
  }

  private func assembleProvider() async -> GitHubOAuthStartupRestoreOutcome? {
    let configuration: GitHubOAuthAppConfiguration?
    do {
      configuration = try await configurationStore.load()
    } catch {
      if isCancellation(error) { return .cancelled }
      if let known = error as? GitHubOAuthDataProtectionStoreError {
        return .failed(.configurationStore(known))
      }
      return .failed(.configurationLoad)
    }
    if Task.isCancelled { return .cancelled }
    guard let configuration else { return .notConfigured }
    let fetcher: any OAuthTokenFetcher
    do {
      fetcher = try makeTokenFetcher(configuration)
    } catch {
      return isCancellation(error) ? .cancelled : .failed(.fetcherCreation)
    }
    if Task.isCancelled { return .cancelled }
    provider = OAuthTokenProvider(
      store: makeCredentialStore(configuration.clientID), fetcher: fetcher)
    return nil
  }

  private func isCancellation(_ error: any Error) -> Bool {
    Task.isCancelled || error is CancellationError
      || (error as? URLError)?.code == .cancelled
  }
}
