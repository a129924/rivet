# E001：GitHub OAuth 重導向可行性驗證需求

## 意圖與成功條件

使用者希望先驗證 OAuth 重導向 URL 能否正常返回本機，降低後續正式 Swift implementation 的不確定性。本次交付獨立 `experiments/E001/` Swift package 與 Markdown 紀錄；不修改產品 package、產品 API 或既定架構。

**實驗成功**僅指真實 GitHub OAuth App 授權經系統瀏覽器返回本機、收到非空 code 且 state 相符。本機模擬、build/test 通過或圖工具通過都不能代替真實授權成功。

**初次交付成功**指受限驗證工具、文件與自動化測試完成獨立審查，依使用者授權建立 topic commit、push 並開 Draft PR，交 human review；這不代表正式圖 gate 通過。PR #45 現為 Ready，此次只更新既有 PR，不重開 Draft。沒有 Client ID 或未完成真實授權時，README、ledger 與 PR 必須標示「真實可行性未驗證」。

## 已鎖定範圍

- Topic slug：`github-oauth-redirect-feasibility`；實驗 ID：`E001`。
- 在由 dev 建立的 feature worktree，使用 `chore/github-oauth-redirect-feasibility`；不得在 dev worktree 實作或寫入任何檔案。
- Swift 6、macOS 15+、Apple frameworks，獨立 package，不連結 root package。
- 獨立測試 GitHub OAuth App，註冊 callback `http://127.0.0.1/oauth/callback`；runner 僅綁定 IPv4 loopback，使用動態 port。
- 驗證 redirect/code/state，不交換 token，不取得 Client Secret，不實作產品登入、refresh、Keychain 或 token persistence。
- Graphify 僅 bounded navigation／來源 fallback；Archify 一張 sequence；PR Lens local bounded diff map。工具安裝、建圖、上傳、hosted canvas 或發布均不在範圍。
- 未驗證假設不得寫成長期架構真相。2026-10-07 真實成功已有遮蔽證據，此次只允許在 `docs/architecture/github-oauth-dual-client.md` 附加「E001 受限可行性依據」，連結 E001 README；不更動既定責任／產品 callback 決策。

## Markdown 紀錄

`experiments/E001/README.md` 記錄驗證什麼、為什麼、假設與成功條件、前置設定與重現指令、環境與日期、是否成功、遮蔽後結果證據、失敗原因與限制。初始實測狀態為「未執行」，其後只依實際證據記為成功、失敗或未完成；不保存 code/state、完整 callback query 或 authorization URL。

## Human Check 與授權

2026-10-07 使用者接受計畫，明示先建立 feature worktree 並只在該 worktree 實作；沒有重大問題時直接 commit by topic → push → open Draft PR → human review。此授權包含本 topic 的 bounded commit/push/Draft PR，commit 仍須依 staged diff 檢查語意邊界；不重新要求例行 commit 確認。

初次交付時 Client ID 尚未提供，真實授權以 deferred human-check 交付。2026-10-07 人類提供測試 App Client ID 並要求啟動；真實 browser callback code 非空、state 相符、process exit 0，人類亦確認成功頁，HC-LIVE 已完成。詳細遮蔽證據見 E001 README；PR review 與 Archify 殘留仍待處理，成功不擴張為 token 或產品登入驗證。

## 依據

- 使用者核准的 E001 最終計畫與 2026-10-07 execution 授權。
- Repository `README.md`、`docs/design-principles.md`、`docs/development-workflow.md`。
- GitHub OAuth App loopback redirect 官方說明：[Authorizing OAuth apps](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#loopback-redirect-urls)。實作前需確認動態 port 行為，官方規則不等於本機真實實測證據。

## PR #45 Review-Fix Amendment（待正式審查）

2026-10-07 使用者授權處理必要 review fix、commit/push、回覆並 resolve threads；非必要建議以證據說明後 resolve，不再要求例行確認。獨立 Reviewer triage 為 needs-rework，四項必要修正：正式 Archify desktop 驗收、真實成功的受限長期依據、圖卡過時狀態、測試 client Task 等待與 listener 啟動失敗的有限退出。

本次僅限四份契約、E001 README／diagrams、`experiments/E001/Tests/ProbeCoreTests/LoopbackProbeTests.swift` 與唯一 docs append。不修改 E001 runtime、產品、root package、其他 docs 或架構圖，不再次啟動真實 OAuth。既有真實成功與 Draft-only approval 保留；新 amendment 需獨立 Plan-Reviewer approved 才能實作。

圖修訂為使用者此次明確授權的新 bounded iteration，最多兩輪 focused correction。先前兩輪與四 viewport 失敗仍為歷史事實，不得追溯宣稱通過。新 iteration 耗盡仍失敗就是 blocker，不默刪圖或自行重開預算。
