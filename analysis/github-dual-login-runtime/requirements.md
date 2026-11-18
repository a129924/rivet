# OAuth／PAT 正式登入 Runtime 需求

Topic：`github-dual-login-runtime`。狀態：Human 已接受對話計畫；正式 R02 已由獨立 Plan-Reviewer approved；TC08 與 Human 最終接受仍 pending。

## Goal 與成功條件

應用組裝端透過既有 `LoginAuthenticating.authenticate(_:)`，使用 OAuth 或 PAT 完成 GitHub.com 帳號遠端驗證、對應憑證持久化與有限結果回傳。`.success` 無 payload，必須同時具備驗證通過及保存成功依據；保存後可依相同儲存設定讀回。

## 鎖定決策

- Q1：採正式 `GitHubPATDataProtectionStore`，不新增 legacy 適配、不移除 legacy、不遷移或刪既有 token。
- Q2：OAuth／PAT 分開保存並保留另一方式憑證；不新增目前啟用方式紀錄。
- Q3：同邏輯儲存目標整次登入互斥；重疊請求立即回 `.failure(.authenticationFailed)`，取消仍優先。
- 沿用 `LoginRequest`、PAT VO、`LoginOutcome` 及既有取消契約，不擴充 success payload。
- 責任維持既有 non-BC `GitHubIntegration`；登入 UI 接線安排下一 topic。

## In-Scope

正式共同服務、必要 OAuth browser／callback 通道、共用帳號 probe、正式 OAuth／PAT stores 組裝、取消與提交競態、重疊登入拒絕、獨立驗證入口與長期契約。

## Out-Of-Scope／Non-Goal

登入畫面接線、session／clients 交接、啟動恢復、refresh／401 擴充、登出、帳號切換、多帳號、GitHub Enterprise、跨程序協調、新 BC 或應用層 target。不新增 PAT store、active-mode 紀錄、跨 store transaction、migration 或 delete 能力。必要驗證 target 僅供本 topic，與 production 隔離且可移除。

## Acceptance Criteria

1. OAuth／PAT 皆經既有共同 Protocol 執行；驗證成功後才開始對應保存。
2. OAuth 保存完整 bundle；PAT 使用正式 DPK store；另一 store 不改變。
3. 授權、網路、無效帳號回應及保存失敗皆回有限 failure。
4. 預先取消零工作；執行中傳遞取消並等待原工作 settled；回傳前最後同步檢查取消，之後不得 suspension。
5. 保存成功後才觀察取消可回 `.cancelled`，保留已完成副作用，不補償刪除或回寫。
6. 同目標所有 service instances 共用協調器；收尾完成前仍拒絕重疊登入。
7. 自動測試、真實整合與 Human 觀察分別記錄；診斷遮蔽憑證及授權資料。

## 既有能力與證據界線

PAT 已由 PR #73／merge `cd76cd3`／tag `v0.1.66-github-pat-dpk-storage` 採用。P07 approved 僅支持 `5465d3c` 指定環境的儲存能力；合併版不冒充新 live，原圖與 topic Human pending 保留。既有儲存 live 不代替本 topic 登入 runtime 驗收；不重跑舊 storage matrix、不挪用其他 topic 已耗用 OAuth 額度。

參考：[PAT 儲存契約](../../docs/architecture/github-pat-dpk-storage.md)、[P07](../../plan/github-pat-dpk-storage/evidence/live-review.md)、[技術規格](technical-spec.md)、[執行計畫](../../plan/github-dual-login-runtime/github-dual-login-runtime.plan.md)。
