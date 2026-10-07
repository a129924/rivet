# E001：GitHub OAuth 重導向可行性驗證需求

## 意圖與成功條件

使用者希望先驗證 OAuth 重導向 URL 能否正常返回本機，降低後續正式 Swift implementation 的不確定性。本次交付獨立 `experiments/E001/` Swift package 與 Markdown 紀錄；不修改產品 package、產品 API 或既定架構。

**實驗成功**僅指真實 GitHub OAuth App 授權經系統瀏覽器返回本機、收到非空 code 且 state 相符。本機模擬、build/test 通過或圖工具通過都不能代替真實授權成功。

**本次交付成功**指受限驗證工具、文件與自動化測試完成獨立審查，依使用者授權建立 topic commit、push 並開 Draft PR，交 human review。沒有 Client ID 或未完成真實授權時，README、ledger 與 PR 必須標示「真實可行性未驗證」。

## 已鎖定範圍

- Topic slug：`github-oauth-redirect-feasibility`；實驗 ID：`E001`。
- 在由 dev 建立的 feature worktree，使用 `chore/github-oauth-redirect-feasibility`；不得在 dev worktree 實作或寫入任何檔案。
- Swift 6、macOS 15+、Apple frameworks，獨立 package，不連結 root package。
- 獨立測試 GitHub OAuth App，註冊 callback `http://127.0.0.1/oauth/callback`；runner 僅綁定 IPv4 loopback，使用動態 port。
- 驗證 redirect/code/state，不交換 token，不取得 Client Secret，不實作產品登入、refresh、Keychain 或 token persistence。
- Graphify 僅 bounded navigation／來源 fallback；Archify 一張 sequence；PR Lens local bounded diff map。工具安裝、建圖、上傳、hosted canvas 或發布均不在範圍。
- 暫時研究結論留在 E001 與本 topic；本次不得將未驗證假設寫入 `docs/` 成為長期架構真相。

## Markdown 紀錄

`experiments/E001/README.md` 記錄驗證什麼、為什麼、假設與成功條件、前置設定與重現指令、環境與日期、是否成功、遮蔽後結果證據、失敗原因與限制。初始實測狀態為「未執行」，其後只依實際證據記為成功、失敗或未完成；不保存 code/state、完整 callback query 或 authorization URL。

## Human Check 與授權

2026-10-07 使用者接受計畫，明示先建立 feature worktree 並只在該 worktree 實作；沒有重大問題時直接 commit by topic → push → open Draft PR → human review。此授權包含本 topic 的 bounded commit/push/Draft PR，commit 仍須依 staged diff 檢查語意邊界；不重新要求例行 commit 確認。

Client ID 尚未提供，GitHub App 註冊、登入與授權由人類完成。真實授權為 deferred human-check，不阻止獨立驗證工具實作、自動化測試與 Draft PR 交付。不得將 deferred 記為實測完成；重大 blocker 或 scope/contract drift 仍停止自動前進。

## 依據

- 使用者核准的 E001 最終計畫與 2026-10-07 execution 授權。
- Repository `README.md`、`docs/design-principles.md`、`docs/development-workflow.md`。
- GitHub OAuth App loopback redirect 官方說明：[Authorizing OAuth apps](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#loopback-redirect-urls)。實作前需確認動態 port 行為，官方規則不等於本機真實實測證據。
