# Login UI 元件化技術規格

- Topic：`rivet-login-ui-adoption`
- 日期：2026-11-17
- 基線：`1f31b35604adb5bb36326e52f9d6dbcff0cac763`
- 上游決策：Human 已接受需求與對話方案；本文件等待獨立 planning review。

## 鎖定責任與依賴

唯一公開 View 是 `RivetLoginView`。其他 View 為 internal，按互動責任分檔，不把 label／button／裝飾逐一公開。既有品牌、palette、圖示資源與樣式重用；保持 non-BC `RivetPresentation`，不新增 target、package、BC 或認證依賴。

Parent 是 phase 唯一權威；真正建 request、呼 service、管理認證 Task／cancellation 及更新 phase 的外層協調／Adapter 不在本 topic。E011 只提供 fake inputs／events，不 import 或呼叫真實登入 VO／service。

既有依賴由 phase、六個 intents、PAT helper、字級規則、品牌與資源滿足。PAT helper 只是 UI 編輯行為，不取代 `PersonalAccessToken`。

## 元件 composition

| 元件 | 輸入 | callbacks／事件 | owned state |
| --- | --- | --- | --- |
| `RivetLoginView` | phase、content、footer、bodyPointSize、canCreateToken | 統一轉發 `RivetLoginIntent` | 無認證／流程 state；穩定布局、區段選擇 |
| `LoginMethodSelection` | welcome 呈現內容及有效字級／樣式 | GitHub、PAT 選擇 callbacks | 主操作 keyboard／accessibility focus |
| `LoginOAuthSection` | waiting 或 browser failure、內容、有效字級／樣式 | cancel、retry、showTokenEntry callbacks | 區段焦點及可取消 phase-entry UI 工作 |
| `LoginPATForm` | tokenEntry 或 token failure、錯誤文字、內容、字級、canCreateToken | back、submit(String)、createToken callbacks | PAT 文字、Show／Hide、欄位焦點 |
| `LoginStatusNotice` | verifying／connected 的 title、message、announcement、字級／樣式 | 無業務事件 | accessibility focus 及可取消宣告工作 |

子元件只拿切片資料與具名 callbacks，不拿整個 DemoModel 或認證 model。Root 以既有 40:60 原生布局組合元件；元件內的小型排版 helper 可保留，不機械拆出每段 computed property。

## UI state 與生命週期

- 保留七態：welcome、tokenEntry、waitingForBrowser、verifyingAccount、verifyingToken、failure、connected。
- Waiting Cancel／Escape 發 `cancelSignIn`；browser failure 發 `retry`；token failure 保持可重填 form，送出仍發 `submitToken(String)`。
- Parent 決定取消完成、重試開始與結果，不由 View 自行改 phase。
- PAT form 在 tokenEntry 與 token-origin failure 間保留 identity。送出先取外圍 trim 值再立即清除；離開 form、消失或 E011 Reset 清除並隱藏。字級／文案更新、Show／Hide 不清文字；Create 不改編輯內容。
- 本地只拒絕 trim 後空值，保留內部空白，不驗 prefix／權限／到期。
- 沿用 13...21 pt 有限字級規則，非有限值回 13。字級變更不重建 form。
- Focus／accessibility／announcement 只屬 UI；每個 phase-entry 工作可取消，在每個 await 後確認仍屬目前 phase／有效視圖。快速切態、消失時舊工作不得把焦點拉回或發過期宣告。

## 公開介面

保留六個既有 intent 語義，新增 `case createPersonalAccessToken`。同次更新 exhaustive switch 與 E011 消費端；enum 新 case 有 source compatibility 影響，不能宣稱所有下游 switch 無須更新。

```swift
public init(
  phase: RivetLoginPhase,
  footer: String,
  bodyPointSize: CGFloat = 13,
  content: RivetLoginContent = .standard,
  canCreateToken: Bool = false,
  onIntent: @escaping (RivetLoginIntent) -> Void
)
```

新增參數有預設值且位於最後 callback 前，舊 label 呼叫與 trailing closure 語法維持可用。

```swift
public struct RivetLoginStatusContent: Equatable, Sendable {
  public let title: String
  public let message: String
  public let announcement: String

  public init(title: String, message: String, announcement: String)
}

public struct RivetLoginContent: Equatable, Sendable {
  public let waitingDescription: String
  public let waitingStatus: String
  public let waitingNote: String
  public let waitingCancelAccessibilityLabel: String
  public let verifyingAccount: RivetLoginStatusContent
  public let verifyingToken: RivetLoginStatusContent
  public let connected: RivetLoginStatusContent
  public let tokenFieldAccessibilityLabel: String
  public let createTokenUnavailableMessage: String

  public static let standard: RivetLoginContent

  public init(
    waitingDescription: String,
    waitingStatus: String,
    waitingNote: String,
    waitingCancelAccessibilityLabel: String,
    verifyingAccount: RivetLoginStatusContent,
    verifyingToken: RivetLoginStatusContent,
    connected: RivetLoginStatusContent,
    tokenFieldAccessibilityLabel: String,
    createTokenUnavailableMessage: String
  )
}
```

上列是介面宣告規格，不是可直接編譯的完整 struct 實作。Failure 維持 `RivetLoginFailure(message:origin:)`，不新增錯誤型別／轉譯。

Content 覆蓋原 View 的 waiting、verification、connected、PAT accessibility label 與停用提示展示硬字串。其餘既有產品適用 label 沿用。正式 `.standard` 不含 simulated、Demo Controls、example-only，不宣稱憑證保存或 session 已建立。Verification 標題用 `Verifying account…`／`Verifying token…`；connected title／announcement 為 `Sign-in completed.`，message 為 `This sign-in attempt completed successfully.`。它僅表達本次登入完成。

`canCreateToken == true` 才發新增 intent，View 不內嵌 URL、不開 browser；停用 help／accessibility hint 共用 `createTokenUnavailableMessage`。Root 不另外建立 demo mode。E011 自行提供展示 content、fake callbacks，預設保持建立入口停用。

## 文件層的接線對應契約

已核對既有實碼 `Sources/BoundedContexts/GitHubIntegration/Contracts/LoginAuthentication.swift` 與 `docs/architecture/github-dual-login-contract.md`。以下只記錄對應，不新增 production mapper／Adapter，不讓 E011 呼叫真 VO／service。

| UI intent／phase 或 Outcome | 既有 VO／未來外層責任 | 限制 |
| --- | --- | --- |
| `.beginGitHubSignIn` | 未來建立 `LoginRequest.oauth`，呼 `authenticate(_:)` | request 不帶 OAuth 配置，配置屬 service 組裝 |
| `.submitToken(String)` | 未來 `try PersonalAccessToken(rawValue:)` 後形成 `LoginRequest.pat(token)` | init 只 trim 外圍，空值 throws `PATInputError.empty`；本地接受不代表遠端有效 |
| `.showTokenEntry`／`.backToWelcome` | parent 提供 `.tokenEntry`／`.welcome` | 純 UI 切換，沒有登入 request |
| `.cancelSignIn` | 未來外層傳遞取消並等原工作 settled | 沒有 cancel request case，本次只有 callback |
| `.retry` | 未來外層依原嘗試脈絡決定新工作 | intent 無 request payload，Outcome 不含原登入方式 |
| `.createPersonalAccessToken` | 未來外層處理建立入口 | 不對應 LoginRequest，本次不開 browser |
| `LoginOutcome.success` | 未來外層可提供 `.connected` | 無 payload，不建立或交付 account／session／provider／clients |
| `.failure(.authenticationFailed)` | 未來外層可提供 `.failure(RivetLoginFailure)` | origin 從嘗試脈絡取得，message 由外層提供安全文案；Outcome 無原始 error／任意訊息，失敗不證明憑證無效 |
| `.cancelled` | 未來外層依取消完成與 UI 脈絡更新 phase | 沒有唯一內建 UI phase 對應，View 不推測 |
| `.waitingForBrowser`／`.verifyingAccount`／`.verifyingToken` | 未來外層依工作進度提供 | Outcome 無中間狀態，不能單憑最終 Outcome 推導 |

既有 `LoginAuthenticating: Sendable` 唯一 requirement 為 `authenticate(_ request: LoginRequest) async -> LoginOutcome`，不拋錯；結果僅 success、failure(LoginFailure)、cancelled，LoginFailure 目前僅 authenticationFailed。取消義務由未來 conformer／外層遵守，不在本 topic 實作；既有 OAuth Scope 仍只接受具體 OAuth provider，不推論 PAT 可取得 Scope。

## 長期說明與證據

長期 UI 文件記錄上述對應及元件責任，校正相關入口的舊 pending 摘要；既有 GitHubIntegration 契約不改。採用程度／方式／來源關係分開記錄；舊 Human 接受不當作新二進位驗收。Native Human VoiceOver／最終 UI 接受可以 pending 交付 Draft，但必須明記未驗，不能升格為已接受。

- [需求與 audit](requirements.md)
- [執行計畫](../../plan/rivet-login-ui-adoption/rivet-login-ui-adoption.plan.md)
- [帳本](../../plan/rivet-login-ui-adoption/rivet-login-ui-adoption.step.md)
