import SwiftUI

public struct GitHubConnectionView: View {
  @Binding private var clientID: String
  @Binding private var clientSecret: String
  private let input: GitHubConnectionPresentation
  private let signIn: () -> Void
  private let cancel: () -> Void
  private let retry: () -> Void
  private let query: () -> Void

  public init(
    clientID: Binding<String>, clientSecret: Binding<String>, input: GitHubConnectionPresentation,
    signIn: @escaping () -> Void, cancel: @escaping () -> Void,
    retry: @escaping () -> Void, query: @escaping () -> Void
  ) {
    _clientID = clientID
    _clientSecret = clientSecret
    self.input = input
    self.signIn = signIn
    self.cancel = cancel
    self.retry = retry
    self.query = query
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("連接 GitHub").font(.largeTitle.bold())
      Text("使用你管理的個人 OAuth App。配置與連線僅保留於本次啟動。")
        .foregroundStyle(.secondary)
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
      HStack {
        Button("使用瀏覽器登入", action: signIn)
          .keyboardShortcut(.defaultAction)
          .disabled(!input.canStart || clientID.isEmpty || clientSecret.isEmpty)
        if input.canCancel { Button("取消", action: cancel).keyboardShortcut(.cancelAction) }
        if input.canRetry { Button("重試連線操作", action: retry) }
        if input.canQuery { Button("再次查詢", action: query) }
        if input.isBusy { ProgressView().controlSize(.small) }
      }
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
