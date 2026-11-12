import SwiftUI

struct GitHubConnectionView: View {
  private let presentation: GitHubConnectionPresentation
  private let onConnect: (String, String, Bool) -> Void
  private let onCancel: () -> Void
  private let onRetry: () -> Void
  private let onReauthorize: () -> Void
  @State private var clientID = ""
  @State private var secret = ""
  @State private var confirmsRecovery = false

  init(
    presentation: GitHubConnectionPresentation,
    onConnect: @escaping (String, String, Bool) -> Void,
    onCancel: @escaping () -> Void, onRetry: @escaping () -> Void,
    onReauthorize: @escaping () -> Void
  ) {
    self.presentation = presentation
    self.onConnect = onConnect
    self.onCancel = onCancel
    self.onRetry = onRetry
    self.onReauthorize = onReauthorize
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Label("GitHub 持續連線驗證", systemImage: "person.crop.circle.badge.checkmark")
        .font(.title2)
      Text("驗證用途，非 Rivet 正式產品").font(.headline)
      Text(presentation.title).font(.headline)
      Text(presentation.detail).foregroundStyle(.secondary)
      if let account = presentation.account {
        Text(account).font(.title3).textSelection(.enabled)
      }
      if presentation.showsConfiguration { configurationFields }
      HStack {
        if presentation.isBusy { ProgressView().controlSize(.small) }
        if presentation.canCancel {
          Button("取消等待", action: onCancel).keyboardShortcut(.cancelAction)
        }
        if presentation.canRetry { Button("重試", action: onRetry).disabled(presentation.isBusy) }
        if presentation.canReauthorize {
          Button("重新授權", action: onReauthorize).disabled(presentation.isBusy)
        }
      }
    }
    .padding(24)
    .frame(minWidth: 440, idealWidth: 500, minHeight: 300, alignment: .topLeading)
    .onAppear { clientID = presentation.clientID }
    .onChange(of: presentation.clientID) { _, value in clientID = value }
    .onDisappear { secret = "" }
  }

  private var configurationFields: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("使用你自己的 GitHub OAuth App 設定。")
      TextField("Client ID", text: $clientID).disabled(presentation.locksClientID)
      SecureField("Client secret", text: $secret)
      if presentation.requiresRecoveryConfirmation {
        Toggle("我確認這是原先使用的 OAuth App", isOn: $confirmsRecovery)
      }
      Button("儲存並登入") {
        let submittedSecret = secret
        secret = ""
        onConnect(clientID, submittedSecret, confirmsRecovery)
      }
      .keyboardShortcut(.defaultAction)
      .disabled(
        clientID.isEmpty || secret.isEmpty
          || (presentation.requiresRecoveryConfirmation && !confirmsRecovery))
    }
    .textFieldStyle(.roundedBorder)
    .disabled(presentation.isBusy)
  }
}
