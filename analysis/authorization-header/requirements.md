# AuthorizationHeader 需求

## 目的與成功條件

在既有 RivetHTTPClient product 交付 public、無狀態的 AuthorizationHeader，統一新 API 的 Bearer formatting 與 dictionary replacement。可以獨立使用與測試，不依賴 transport 或 credential lifecycle。

- 大小寫不敏感替換全部 Authorization 變體，輸出單一精確 `Authorization`。
- 無關 key 拼字與 value 原樣保留；不修改 input。
- 相同輸入產生相同 dictionary 內容；重複套用相同 token 為冪等操作，不承諾列舉順序。
- 無 I/O、logging、可變狀態或 token retention；非法輸入使用不帶 token 的 typed error。
- 新 API 的驗證與 formatting 有單一實作來源；既有 consumers 尚未整合，不宣稱全 repository 已共用規則。

## 已鎖定範圍

In-Scope：新元件、Swift Testing 單元測試、最小 architecture README 回寫、四份 planning artifacts、一張 Archify dataflow，以及 PR Lens／Graphify 的受限輔助流程。

Out-Of-Scope：BearerAuth、REST／GraphQL consumer、OAuthTokenProvider、HTTPHeaders、transport 的修改；token acquisition、refresh、expiry、JWT、persistence、retry；新 package、dependency、protocol、factory、DI、其他 authentication scheme 或通用 headers framework。

Graphify 目前無可用 graph，採 targeted source reads，不授權建圖。PR Lens 只在真實 bounded diff 存在後產生 external local artifacts；不能捏造 consumer edges。Archify 只描述元件 dataflow，不新增 system／BC boundary canvas。

## 人類確認與執行授權

使用者已確認完整元件交付、最小 public API、嚴格 RFC 6750 b64token、同步 typed throws、canonical key 與所有範圍限制，並接受加入上述輔助交付流程。

使用者另明確授權：建立 feature worktree → 在 feature 實作 → 依 topic commit → push → 開 Draft PR → human review。分支為 `feat/authorization-header`；不得寫入 dev worktree。後續 bounded commit 沿用此明確授權，不重複要求 commit 許可；仍須執行 staged diff 語意檢查、提出 message 並完成既有 gates。

目前沒有未鎖定的產品問題。授權不是獨立 Plan-Reviewer／Reviewer approval，也不是測試證據。

## 文件責任

設計見 [technical-spec](technical-spec.md)；寫入範圍與驗收見 [plan](../../plan/authorization-header/authorization-header.plan.md)；實際狀態見 [step ledger](../../plan/authorization-header/authorization-header.step.md)。真正完成實作後，才將已交付能力回寫 docs。
