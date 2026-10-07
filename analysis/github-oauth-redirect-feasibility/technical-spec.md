# E001：GitHub OAuth 重導向技術規格

## Locked Decisions

獨立 Swift 6 package，minimum macOS 15，僅使用 Apple frameworks。實驗 executable 名稱 `oauth-redirect-probe`；不新增 root product/target、產品 API 或 BC dependency。不重開產品 callback architecture 或 token lifecycle 決策。

## CLI 與流程

```sh
swift run --package-path experiments/E001 oauth-redirect-probe \
  --client-id <Client-ID> --timeout-seconds 180
```

- `--client-id` 必填且非空；`--timeout-seconds` 為正整數，預設 180 秒。未知／無效參數不開瀏覽器。
- 先建立只綁定 `127.0.0.1` 的 listener，取得動態 port，再以 Security framework 的密碼學安全亂數產生 32 bytes，編碼為 64 字元 hexadecimal state，組成 GitHub authorization URL 和實際 redirect URI `http://127.0.0.1:<port>/oauth/callback`。
- listener 啟動上限 10 秒；逾時回報 failure。listener ready 後才以系統瀏覽器開啟授權頁，瀏覽器開啟失敗回報 failure。
- 僅處理指定 callback；驗證非空 code 與匹配 state，不交換 token。測試注入的模擬 callback 必須與真實授權結果清楚區分。
- code 缺漏／空值、state 缺漏／不符、重複參數、GitHub error、listener／瀏覽器啟動失敗或逾時均不算成功。
- 終結結果僅一次；清理 listener、timer 與 connections。SIGINT 同樣清理資源。
- 結束碼：成功 `0`、執行失敗 `1`、無效 CLI `2`、SIGINT `130`。

## HTTP 與資料邊界

只接受 loopback HTTP 的 `GET /oauth/callback`，解析 query 不以原始字串切割取代 URL parsing。其他路徑回覆 404，指定 callback 的其他 method 回覆 405；兩者只關閉該 connection，probe 繼續等待合法 callback，不終結為 OAuth 成功或失敗。每條 connection 的 HTTP header 讀取上限為 8 KiB、讀取等待上限為 5 秒，避免不完整 HTTP request 無限佔用 connection。以必要的代表測試確認限制與清理，不擴張為通用 HTTP server。

瀏覽器 callback response 與終端輸出只包含安全結果，不反射 query 或敏感值。code/state 僅在記憶體處理；不輸出、不寫入紀錄或持久化；不得保存完整 callback query 或 authorization URL。不取得 Client Secret。

## 工具契約

### Graphify

Pinned graphifyy `0.9.73`，每次 CLI invocation（含 version/help）必須設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。既有 graph 若可用，先確認 revision/source locations，用 budget 1500 bounded query，再對重要關係回讀 source。此次未發現可用 graph，採 targeted source reads；不執行 extract、semantic/provider work、watcher、hooks、MCP、安裝或全域合併，不寫 version stamp。

### Archify

在 `experiments/E001/diagrams/` 產生 `oauth-redirect-flow.json` 與 `oauth-redirect-flow.html`，僅一張 sequence：runner/listener、系統瀏覽器、GitHub、callback、code/state 結果判定。作者內容繁體中文；不設定 unsupported locale，明示固定 Viewer UI 與 HTML lang 的 English fallback；static/classic、showcase，無自行發布。

遵守 schema/example → candidate-first；每次修改後 validate，最終需全 9 artifact checks、0 composition errors、0 warnings。初次 iteration 最多兩輪 focused correction，已耗盡且四 desktop containment failed；這是歷史 needs-rework，不因 Draft-only approval 成為通過。此次 PR review-fix 由使用者另授權一個新 bounded iteration，最多兩輪 focused correction；仍失敗回報 blocker，不默刪圖或自行重開預算。通過後 deliver，保留 spec/artifact SHA-256、byte receipts 並凍結候選。visual-check 檢查 1440×900、1600×1000、1920×1080、2048×1320，保存 light/dark captures；獨立 Reviewer 視覺確認。自動 receipt 的 `visualReview: pending` 與 skipped 不算視覺通過。

### PR Lens

Pinned CLI `0.11.0`，僅 local validate/render。獨立 Reviewer 從實際 `git diff --find-renames <base>...<head>`、真實且不同的 base/head commit SHA 與必要來源建立 change map；含 file refs 與 `delta: unchanged` 鄰接元件。

圖與渲染寫到 `$TMPDIR/github-oauth-redirect-feasibility/pr-lens/`，不得在 repository 建立 `.pr-lens/` 或修改 config。若存在既有 `.github/pr-lens.yml` 僅讀取套用，否則 `--no-config`。缺少 commit provenance 時先 pending，直接 diff review；不得為工具自行 commit。工具不可用就如實記錄並 fallback，不安裝或升級，不 upload／attach／publish PR Lens assets。

## 驗證與限制

必要 callback cases、listener 動態 port／loopback、逾時清理、CLI exit behavior 與有限 HTTP 讀取的代表測試。測試只驗證獨立 package，不因無關範圍擴張 root suite。本機測試通過後由 Reviewer 檢查未觸及 ReadOnly paths、未洩漏敏感值、工具 receipts 與真實授權狀態。

2026-10-07 人類提供測試 App Client ID，要求啟動 E001 並確認成功頁；真實 callback code 非空、state 相符、process exit 0，證據記於 E001 README。PR 的實測狀態依此更新為成功；此結果只證明此次 redirect/code/state 流程，不證明 token、refresh 或產品整合。Archify 視覺殘留不受影響。

## PR Review-Fix 技術限制（新 amendment 待審）

- **Archify revision**：從現有 frozen JSON 複製新 candidate，再修改圖卡真實成功狀態及 diagnosed composition；不修改 frozen HTML 手工修畫面。每次候選修改後 validate，最終 showcase 9 checks、0 errors／0 warnings → deliver → 四個 desktop containment／captures → 獨立 visual review 才算正式 acceptance。新 accepted JSON／HTML／receipts 取代 canonical revision 時記錄新 SHA-256／bytes，舊 hash、失敗與兩輪紀錄保留於 Git／ledger。不得偽造 receipts、以 overflow hidden／裁切／縮字／internal scroller 隱藏問題，或修改 runtime／安裝工具。已有 candidate 與前兩輪 failed repairs，只有未解除診斷需要時可 bounded read matching renderer，不做全 renderer／全 repo 調查。
- **圖內容**：以 2026-10-07 已有真實 callback `code_present=true`、`state_matches=true`、process exit `0` 的 README 證據取代「尚未執行」圖卡；不新增敏感值、不擴張為 token／refresh／產品驗證。
- **長期依據**：只在 `docs/architecture/github-oauth-dual-client.md` append「E001 受限可行性依據」，連結 `../../experiments/E001/README.md`；記錄日期、上述遮蔽結果與實驗限制，明示本次未交換 token、未鎖定產品 callback architecture。不改其餘長期結論、其他 docs 或架構圖。
- **測試 helper**：只修 `experiments/E001/Tests/ProbeCoreTests/LoopbackProbeTests.swift`，將 browser callback 啟動的 client Task 保留並 await／join，使所有 HTTP／response assertions 和錯誤記錄在 test 返回前完成。listener 啟動失敗時 helper 必須有限退出並完成或取消／join client work，不可永久等待未發生的 browser callback；必要有限性測試使用既有 injection，不新增 runtime API／hook、不再次真實授權。
- **再驗證**：只執行 E001 相關 test／build 與既有局部 lint、path hygiene，驗證 client Task 成功、錯誤及 listener-start failure 有限完成。Tester 與獨立 Reviewer 分開；既有 OAuth 真實成功不可替代本次圖或測試審查。
