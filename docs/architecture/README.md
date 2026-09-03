# Rivet 架構規範

本文件記錄未來實作必須遵守的架構不變量。Rivet 目前是 architecture baseline；除已鎖定的 PR Reader WebView diff declaration-only modules，以及其單一架構圖的 artifact-local viewer 可近用性補強外，不建立產品功能。

## 架構方向

Rivet 未來採用 monorepo 與輕量 DDD。

核心的 compile-time dependency 方向如下：

```text
Presentation → Facade → UseCase → Port
```

Adapter 符合 Port，並隔離 Outside；Adapter 不加入核心的 compile-time dependency 方向。PR Reader WebView diff 的 runtime render request 則是：

```text
Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output
```

## Layer Responsibilities

- **Outside**：GitHub API、OAuth、Keychain、網路、WebView runtime 等外部世界。
- **Adapter**：符合 Port，隔離外部協定、資料與錯誤的轉換邊界。
- **Port**：由內部擁有的依賴契約。
- **UseCase**：應用與業務流程。
- **Facade**：提供 Presentation 使用的穩定入口。
- **Presentation**：原生 UI 與 WebView renderer。

## Outcome 與 Failure Contract

- 所有正式 layer 與 Bounded Context 邊界使用 `Outcome` 作為成功／失敗契約。
- 每個 Bounded Context 擁有自己的 failure contract；不得洩漏、重用或混入其他 Bounded Context 的 failure contract。
- `InfraUnknownError` 用於標準化無法安全分類的外部 infrastructure failure。
- `InfraUnknownError` 應在 Adapter 邊界產生或正規化；其他層只能傳遞，或補充自身語意。
- 純資料轉換與保證不失敗的 private helper，未來不強制使用 `Outcome`。

## 已確認的 Bounded Context Map

- **PR Inbox**：定義目前明確要求使用者 review 的 open PR 與其排序；不負責單一 PR 的閱讀資料或 UI selection。
- **PR Reader**：提供單一 PR 的背景、討論、checks、檔案與 diff 閱讀資料；不決定 Inbox membership。
- **GitHub Integration**：Supporting BC，隔離 GitHub 身分、外部資料、DTO、HTTP 狀態與 infrastructure failure。
- **Presentation Session**：擁有目前選取的 PR 與切換狀態；它屬於 Presentation，不屬於任何 Bounded Context。
- PR Inbox 與 PR Reader 不直接依賴彼此；兩者各自透過內部 Port 取得 GitHub Integration 提供的資料。

## PR Reader WebView Diff Pipeline

PR Reader 的 WebView diff rendering 已鎖定為 declaration-only pipeline。render 主路徑為 `Swift snapshot → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output`；UseCase 擁有四個 stage Port 的協調責任，也是 Output Port 唯一 caller。Adapter 僅宣告 Swift／WebView 的輸入與通知邊界，不加入或反向轉送 render 主路徑。

公開 render outcome 區分 `invalid-input`、`parse-error`、`render-error` 與 `output-error`。`viewed` 的持久化權威仍是 Swift：WebView 只發送包含 PR、snapshot 與 snapshot-local file identity 的 best-effort `void` 單向 notification，不等待 acknowledgement、不 retry、不承諾可靠傳輸，也不修改 snapshot。具體 Adapter、parser、renderer、Output、DOM 與 Swift bridge 均尚未定義。

- [PR Reader WebView Diff Pipeline](diagrams/pr-reader-webview-diff-rendering/index.html)：Swift／WebView 邊界、編譯期依賴、宣告的 Ports 與 ownership；此 canvas 不表達 runtime render dataflow。其 [重建與失敗回復規則](diagrams/pr-reader-webview-diff-rendering/BUILD.md) 明確區分兩次單檔 atomic rename 與可驗證的 backup/restore policy，不宣稱雙檔原子交付。
- [PR Reader WebView Diff Dataflow](diagrams/pr-reader-webview-diff-rendering/diff-render-flow.html)：以同一組既定契約表達 runtime render dataflow；不新增 concrete implementation 或資料契約。

## 文件導覽

- [設計原則](../design-principles.md)：Rivet 的產品取捨與工作方法。
- [Bounded Context](bounded-contexts/)：每個 BC 的長期責任與邊界。
- [Bounded Context Map](diagrams/bounded-context-map/index.html)：BC、Presentation Session 與外部邊界的互動式全景圖。
- [GitHub Integration 與 HTTP Client 邊界](diagrams/github-integration-http-client-boundary/index.html)：預定 transport foundation 在 Integration Adapter 與 Outside 之間的 ownership 與依賴邊界。
- [HTTP Client package 結構](diagrams/http-client-package-structure/index.html)：預定 HTTPClient、Requester、Transport、TokenProvider 與 Foundation URLSession 的 declaration-only 結構。
- [Repository Knowledge Map](diagrams/repository-knowledge-map/index.html)：公開讀者與 agent 如何從入口、文件、analysis、plan 走向下一個 BC 切片。
- [Topic Lifecycle](diagrams/topic-lifecycle/index.html)：正式 topic 從分析、計畫、受限實作到回寫與 human review 的可互動流程圖。

## 尚未定義的項目

Rivet 仍是 architecture baseline。除已鎖定的 PR Reader WebView diff pipeline contract 外，本階段不定義 `Outcome` 的程式碼型別、泛型、case 名稱、payload schema，也不定義其餘 module、package、target 或實作細節。這些決策將隨著一次一個 Bounded Context 的實作 topic 處理。
