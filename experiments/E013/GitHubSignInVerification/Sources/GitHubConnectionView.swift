import SwiftUI

struct GitHubConnectionView: View {
  @Binding private var clientID: String
  @Binding private var clientSecret: String
  private let input: GitHubConnectionPresentation
  private let signIn: () -> Void
  private let manualSignIn: () -> Void
  private let copyAuthorizationURL: () -> Void
  private let cancel: () -> Void
  private let retry: () -> Void
  private let query: () -> Void

  init(
    clientID: Binding<String>, clientSecret: Binding<String>, input: GitHubConnectionPresentation,
    signIn: @escaping () -> Void, manualSignIn: @escaping () -> Void,
    copyAuthorizationURL: @escaping () -> Void, cancel: @escaping () -> Void,
    retry: @escaping () -> Void, query: @escaping () -> Void
  ) {
    _clientID = clientID
    _clientSecret = clientSecret
    self.input = input
    self.signIn = signIn
    self.manualSignIn = manualSignIn
    self.copyAuthorizationURL = copyAuthorizationURL
    self.cancel = cancel
    self.retry = retry
    self.query = query
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("GitHub 登入驗證").font(.largeTitle.bold())
      Text("獨立驗證 App；非 Rivet 正式產品登入 UI。使用真實 OAuth 與 GitHub API。")
      Text("使用你管理的個人 OAuth App。配置與連線僅保留於本次啟動。")
        .foregroundStyle(.secondary)
      if input.hasPreparedConfiguration {
        Text("開發端設定已準備；登入驗證者不需要提供 App 憑證。")
      }
      if input.showsConfigurationFields {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
          GridRow {
            Text("Client ID")
            TextField("OAuth App Client ID", text: $clientID)
          }
          GridRow {
            Text("Client Secret")
            SecureField("僅保留於記憶體", text: $clientSecret)
          }
        }
        .textFieldStyle(.roundedBorder).disabled(input.isBusy)
      }
      HStack {
        Button("使用瀏覽器登入", action: signIn)
          .keyboardShortcut(.defaultAction)
          .disabled(
            !input.canStart
              || (input.showsConfigurationFields && (clientID.isEmpty || clientSecret.isEmpty)))
        Button("準備手動登入", action: manualSignIn)
          .disabled(
            !input.canStart
              || (input.showsConfigurationFields && (clientID.isEmpty || clientSecret.isEmpty)))
        if input.canCancel { Button("取消", action: cancel).keyboardShortcut(.cancelAction) }
        if input.canRetry { Button("重試連線操作", action: retry) }
        if input.canQuery { Button("再次查詢", action: query) }
        if input.isBusy { ProgressView().controlSize(.small) }
      }
      if input.canCopyAuthorizationURL {
        Button("複製本次授權網址", action: copyAuthorizationURL)
        Text("貼到未登入 GitHub 的獨立瀏覽器或無痕視窗，以尚未授權此 App 的測試帳號操作。")
          .font(.caption)
      }
      Text("手動驗證每次啟動僅一輪，最多等待 300 秒；取消或失敗後停止。")
        .font(.caption).foregroundStyle(.secondary)
      Divider()
      Text(input.status).textSelection(.enabled).accessibilityIdentifier("connection-status")
      if let account = input.accountDescription {
        Text(account).font(.title3.monospaced()).textSelection(.enabled)
      }
      Text("Callback：http://127.0.0.1/oauth/callback；本機連接埠由系統分配。")
        .font(.caption).foregroundStyle(.secondary)
    }
    .padding(28).frame(minWidth: 600, minHeight: 360, alignment: .topLeading)
  }
}
