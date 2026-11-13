# OAuth／PAT 雙登入契約技術規格

- Topic：`github-dual-login-contract`
- 狀態：規劃與成果審查已 approved；先前 inventory 暫停及文件回修為歷史。執行／發布／Human review 現行狀態以配對 step 帳本為準。
- 配對：[需求](requirements.md)、[執行計畫](../../plan/github-dual-login-contract/github-dual-login-contract.plan.md)、[帳本](../../plan/github-dual-login-contract/github-dual-login-contract.step.md)。

## Locked Decisions

沿用 GitHubIntegration 與 GitHubIntegrationTests，不新增 target。應用層僅描述 caller 責任。OAuth request 無配置 payload；success 無 payload。帳號、session、token capability、provider／clients 與真實登入均延後。共同入口 async、nonthrowing、Sendable，結果使用本功能自己的 LoginOutcome，不共用其他 BC failure。

## 公開介面

以下是宣告規格，initializer 由實作補入本地驗證 body；其餘公開面不擴張。

```swift
public enum PATInputError: Error, Equatable, Sendable {
    case empty
}

public struct PersonalAccessToken: Equatable, Sendable {
    public let rawValue: String
    public init(rawValue: String) throws(PATInputError)
}

public enum LoginRequest: Equatable, Sendable {
    case oauth
    case pat(PersonalAccessToken)
}

public enum LoginFailure: Error, Equatable, Sendable {
    case authenticationFailed
}

public enum LoginOutcome: Equatable, Sendable {
    case success
    case failure(LoginFailure)
    case cancelled
}

public protocol LoginAuthenticating: Sendable {
    func authenticate(_ request: LoginRequest) async -> LoginOutcome
}
```

PersonalAccessToken 與 LoginRequest 另公開符合 CustomStringConvertible、CustomDebugStringConvertible、CustomReflectable；相應 properties 為 public。除此之外不增加 factory、driver、type erasure 或 convenience public API。

## VO 與結果語義

- PAT initializer 使用 Foundation 的 whitespacesAndNewlines trim，保存 trim 後 rawValue；空字串或純空白拋 PATInputError.empty，不提供繞過驗證的其他公開 initializer。
- 保留所有內部字元，包括內部空白；不驗 prefix、權限、到期或遠端有效性。
- OAuth case 只有啟動 intent；未來 concrete service 建立時由 composition root 提供配置。本輪沒有該正式 concrete service。
- authenticationFailed 是「本次登入未能完成」的有限語義，不宣稱 credential 無效。failure 不含原始 error、HTTP response、URL、token 或任意 message。
- PAT 建構失敗是獨立 typed initializer error，不形成非法 LoginRequest，也不呼叫登入服務。
- 結果不交付帳號、session、token、credential、provider 或 ready clients。無 payload 只有 success；failure 仍攜帶 LoginFailure。

## 敏感診斷

PAT 與外層 LoginRequest 的 description、debugDescription、customMirror 僅輸出固定型別／登入方式及 redacted 標記；Mirror 不暴露 PAT 子值。不可輸出原值、片段、長度或雜湊。明確讀取 rawValue 仍可取得資料；此遮蔽不保證 debugger、process memory 或使用者自行記錄 rawValue 的防護。不更改既有 UI intent 或 GitHubAccessToken 診斷行為。

## 非同步與取消

- 預先取消的 Task 直接回 cancelled，不啟動受控登入工作。
- 執行中取消須傳遞至受控工作，待原工作 settled 後回 cancelled；不讓 detached／遺留工作假裝已完成。
- conformer 發布結果前最後同步檢查若觀察到取消，取消優先於受控 success／failure；其後不再 await。檢查與 return 之間的新取消屬既定競態邊界，已回傳結果不追溯修改。
- Protocol 無法強迫任意 conformer 遵守；本輪以測試替身證明預期義務，不新增 production cancellation manager 或登入 runtime。

## 依賴、文件與圖

公開值不依賴 Presentation、PR Inbox／Reader 或驗證 App。既有 OAuth runtime、GitHubAccessTokenProvider、GitHubClientScope 皆只讀。最小 caller 為接受 any LoginAuthenticating 的測試 helper；真實登入 UI 只在文件描述 OAuth intent→oauth、PAT intent→validated PAT→pat 的對應。

新增長期文件與 Archify sequence，只描述本地 PAT 拒絕、共同受控呼叫和結果／取消；不得畫成正式登入或 session 已接通。作者內容繁中，omit meta.locale，如實揭露固定 Viewer UI／html lang fallback English。JSON、HTML、receipts、截圖與 hashes 的驗收以執行計畫為準。

本輪 additive public contracts 不需 migration；rollback 以移除本 topic 新增程式、測試與文件入口評估，不碰既有 OAuth 資料。正式產品接線另立範圍，不預先保證未來 session ABI。

## Bounded source inventory 維護

實作回歸指出 StaticIsolationTests.targetContainsOnlyTheLockedSourceFilesAndNoForbiddenImports 的 expectedPaths 尚未包含新契約。僅允許在 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的該 Set 加入 `"Contracts/LoginAuthentication.swift"` 一條；不改 actualPaths 計算、equality assertion、forbidden import 檢查、其他 expectedPaths 或其他 test。此項使既定 source inventory 與已授權新增檔一致，不新增需求或架構。
