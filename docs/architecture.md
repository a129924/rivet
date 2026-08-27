# Rivet 架構規範

本文件記錄未來實作必須遵守的架構不變量。Rivet 目前是 architecture baseline，不建立程式碼、抽象層或產品功能。

## 架構方向

Rivet 未來採用 monorepo 與輕量 DDD。

正式依賴與資料流方向如下：

```text
Outside → Adapter ↔ Port → UseCase → Facade → Presentation
```

## Layer Responsibilities

- **Outside**：GitHub API、OAuth、Keychain、網路、WebView runtime 等外部世界。
- **Adapter**：外部協定、資料與錯誤的轉換邊界。
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

互動式地圖位於 [Bounded Context Map](diagrams/bounded-context-map/index.html)。

## 尚未定義的項目

本階段不定義 `Outcome` 的程式碼型別、泛型、case 名稱、payload schema，也不定義 module、package、target 或實作細節。這些決策將隨著一次一個 Bounded Context 的實作 topic 處理。
