import AppKit
import Foundation
import GitHubIntegration
import Observation

struct GitHubAuthorizationPresenter: Sendable {
  let present: @Sendable (URL) async throws -> Void
}

struct GitHubConnectionDependencies: Sendable {
  var authorize:
    @Sendable (GitHubOAuthAppConfiguration, GitHubAuthorizationPresenter) async throws ->
      GitHubOAuthCredentialBundle
  var makeFetcher: @Sendable (GitHubOAuthAppConfiguration) throws -> any OAuthTokenFetcher
  var prepare: @Sendable (OAuthTokenProvider) async throws -> GitHubClientScope
  var probe: @Sendable (GitHubClientScope) async throws -> GitHubAccountIdentity

  var openBrowser: @MainActor @Sendable (URL) -> Bool = { NSWorkspace.shared.open($0) }
  var copyAuthorizationURL: @MainActor @Sendable (URL) -> Bool = { url in
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setData(Data(), forType: .init("org.nspasteboard.ConcealedType"))
    return NSPasteboard.general.setString(url.absoluteString, forType: .string)
  }

  static var live: Self {
    Self(
      authorize: { configuration, presenter in
        let relay = GitHubLoopbackCallbackRelay()
        defer { relay.cancel() }
        let redirect = try await relay.start()
        let session = try GitHubOAuth.makeAuthorizationSession(
          configuration: configuration, redirectURI: redirect)
        return try await withThrowingTaskGroup(of: GitHubOAuthCredentialBundle.self) { group in
          group.addTask {
            try await presenter.present(session.authorizationURL)
            while true {
              try Task.checkCancellation()
              let callback = try await relay.next()
              do {
                return try await session.complete(callbackURL: callback)
              } catch GitHubOAuthAuthorizationError.invalidCallback { continue }
            }
          }
          group.addTask {
            try await Task.sleep(for: .seconds(300))
            await session.cancel()
            throw GitHubConnectionFailure.timeout
          }
          defer { group.cancelAll() }
          return try await group.next()!
        }
      },
      makeFetcher: { try GitHubOAuth.makeTokenFetcher(configuration: $0) },
      prepare: { try await GitHubClientScope.prepare(provider: $0) },
      probe: { try await GitHubAccountProbe.read(using: $0) })
  }

  static var disabled: Self {
    Self(
      authorize: { _, _ in throw GitHubConnectionFailure.unavailable },
      makeFetcher: { _ in throw GitHubConnectionFailure.unavailable },
      prepare: { _ in throw GitHubConnectionFailure.unavailable },
      probe: { _ in throw GitHubConnectionFailure.unavailable })
  }
}

enum GitHubConnectionFailure: Error { case browser, timeout, unavailable }

@MainActor @Observable
final class GitHubConnectionCoordinator {
  var clientID = ""
  var clientSecret = ""
  private(set) var status = "尚未連線"
  private(set) var identity: GitHubAccountIdentity?
  private(set) var isBusy = false
  private let dependencies: GitHubConnectionDependencies
  private let preparedConfiguration: GitHubOAuthAppConfiguration?
  private let allowsManualConfiguration: Bool
  private var provider: OAuthTokenProvider?
  private var scope: GitHubClientScope?
  private var operation: Task<Void, Never>?
  private var pendingAuthorizationURL: URL?
  private var manualAttemptStarted = false

  init(
    dependencies: GitHubConnectionDependencies,
    configuration: GitHubOAuthAppConfiguration? = nil, allowsManualConfiguration: Bool = true
  ) {
    self.dependencies = dependencies
    self.preparedConfiguration = configuration
    self.allowsManualConfiguration = allowsManualConfiguration
    if !allowsManualConfiguration {
      status =
        configuration == nil
        ? "開發端設定尚未準備；尚未啟動授權。"
        : "開發端設定已準備；尚未啟動授權。"
    }
  }

  var presentation: GitHubConnectionPresentation {
    GitHubConnectionPresentation(
      status: status, isBusy: isBusy, canRetry: provider != nil && !manualAttemptStarted,
      canQuery: scope != nil && !manualAttemptStarted,
      canStart: !manualAttemptStarted
        && (preparedConfiguration != nil || allowsManualConfiguration),
      canCopyAuthorizationURL: pendingAuthorizationURL != nil,
      hasPreparedConfiguration: preparedConfiguration != nil,
      showsConfigurationFields: allowsManualConfiguration && preparedConfiguration == nil,
      accountDescription: identity.map { "\($0.login) · ID \($0.id)" })
  }

  func signIn() { startSignIn(manually: false) }

  func startManualSignIn() { startSignIn(manually: true) }

  func copyAuthorizationURL() {
    guard isBusy, let url = pendingAuthorizationURL else { return }
    if !dependencies.copyAuthorizationURL(url) {
      status = "複製授權網址失敗；本輪停止。"
      operation?.cancel()
      pendingAuthorizationURL = nil
    }
  }

  private func startSignIn(manually: Bool) {
    guard !isBusy, !manualAttemptStarted else { return }
    let configuration: GitHubOAuthAppConfiguration
    if let preparedConfiguration {
      configuration = preparedConfiguration
    } else if allowsManualConfiguration {
      do { configuration = try .init(clientID: clientID, clientSecret: clientSecret) } catch {
        status = "請輸入有效的 Client ID 與 Client Secret。"
        return
      }
    } else {
      status = "開發端設定尚未準備；尚未啟動授權。"
      return
    }
    if manually { manualAttemptStarted = true }
    provider = nil
    scope = nil
    identity = nil
    begin {
      self.status = manually ? "正在準備手動授權…" : "瀏覽器授權與交換中…"
      let presenter = GitHubAuthorizationPresenter { url in
        try await self.presentAuthorization(url, manually: manually)
      }
      let credential = try await self.dependencies.authorize(configuration, presenter)
      try Task.checkCancellation()
      let store = InMemoryOAuthCredentialStore()
      await store.save(credential)
      try Task.checkCancellation()
      self.provider = OAuthTokenProvider(
        store: store, fetcher: try self.dependencies.makeFetcher(configuration))
      try await self.prepareAndRead()
    }
  }

  func retry() {
    guard !isBusy, !manualAttemptStarted, provider != nil else { return }
    identity = nil
    begin { try await self.prepareAndRead() }
  }

  func query() {
    guard !isBusy, !manualAttemptStarted, scope != nil else { return }
    identity = nil
    begin { try await self.prepareAndRead() }
  }

  func cancel() {
    guard isBusy else { return }
    status = "正在取消，等待工作結束…"
    pendingAuthorizationURL = nil
    operation?.cancel()
  }

  private func presentAuthorization(_ url: URL, manually: Bool) throws {
    try Task.checkCancellation()
    if manually {
      pendingAuthorizationURL = url
      status = "等待手動開啟本次授權網址；300 秒內完成，逾時停止。"
    } else if !dependencies.openBrowser(url) {
      throw GitHubConnectionFailure.browser
    }
  }

  func waitUntilSettled() async { await operation?.value }

  private func begin(_ work: @escaping @MainActor () async throws -> Void) {
    isBusy = true
    operation = Task {
      defer {
        self.pendingAuthorizationURL = nil
        self.isBusy = false
        self.operation = nil
      }
      do { try await work() } catch {
        self.identity = nil
        self.status = self.message(for: error)
      }
    }
  }

  private func prepareAndRead() async throws {
    guard let provider else { throw GitHubConnectionFailure.unavailable }
    if scope == nil {
      status = "準備連線中…"
      let ready = try await dependencies.prepare(provider)
      try Task.checkCancellation()
      scope = ready
    }
    guard let scope else { throw GitHubConnectionFailure.unavailable }
    status = "讀取 GitHub 帳號中…"
    let identity = try await dependencies.probe(scope)
    try Task.checkCancellation()
    self.identity = identity
    status = "GitHub API 查詢成功；連線僅保留於本次啟動。"
  }

  private func message(for error: any Error) -> String {
    if Task.isCancelled || error is CancellationError { return "已取消；可重新開始。" }
    if let error = error as? GitHubOAuthAuthorizationError {
      return oauthMessage(error)
    }
    if let error = error as? GitHubConnectionFailure { return failureMessage(error) }
    if let error = error as? GitHubAccountProbeError { return probeMessage(error) }
    if let error = error as? GitHubClientPreparationError {
      switch error {
      case .authenticationRequired, .missingCredential: return "連線需要重新授權。"
      default: return "連線準備失敗；可重試或重新授權。"
      }
    }
    return "連線或 API 操作失敗；可重試或重新授權。"
  }
  private func oauthMessage(_ error: GitHubOAuthAuthorizationError) -> String {
    switch error {
    case .denied: return "你已拒絕 GitHub 授權；可重新開始。"
    case .expiredSession: return "授權已逾時；請重新開始。"
    case .cancelled: return "已取消；可重新開始。"
    case .clientConfiguration: return "OAuth App 配置無效；請檢查後重新登入。"
    case .invalidTokenResponse: return "GitHub 未回傳符合契約的完整憑證；請重新登入。"
    default: return "GitHub 授權或交換失敗；請檢查配置與網路後重新開始。"
    }
  }

  private func failureMessage(_ error: GitHubConnectionFailure) -> String {
    switch error {
    case .browser: return "無法開啟瀏覽器；請重新開始。"
    case .timeout: return "授權已逾時；請重新開始。"
    case .unavailable: return "連線操作目前無法使用。"
    }
  }

  private func probeMessage(_ error: GitHubAccountProbeError) -> String {
    switch error {
    case .http(let status): return "GitHub API 回傳 HTTP \(status)；可重試。"
    case .invalidResponse: return "GitHub API 回應格式無效；可重試。"
    }
  }

}
