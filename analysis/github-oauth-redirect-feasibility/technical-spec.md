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

遵守 schema/example → candidate-first；每次修改後 validate，最終需全 9 artifact checks、0 composition errors、0 warnings。最多兩輪 focused correction，仍失敗如實交還診斷，不假稱通過。通過後 deliver，保留 spec/artifact SHA-256、byte receipts 並凍結候選。visual-check 檢查 1440×900、1600×1000、1920×1080、2048×1320，保存 light/dark captures；獨立 Reviewer 視覺確認。自動 receipt 的 `visualReview: pending` 與 skipped 不算視覺通過。

### PR Lens

Pinned CLI `0.11.0`，僅 local validate/render。獨立 Reviewer 從實際 `git diff --find-renames <base>...<head>`、真實且不同的 base/head commit SHA 與必要來源建立 change map；含 file refs 與 `delta: unchanged` 鄰接元件。

圖與渲染寫到 `$TMPDIR/github-oauth-redirect-feasibility/pr-lens/`，不得在 repository 建立 `.pr-lens/` 或修改 config。若存在既有 `.github/pr-lens.yml` 僅讀取套用，否則 `--no-config`。缺少 commit provenance 時先 pending，直接 diff review；不得為工具自行 commit。工具不可用就如實記錄並 fallback，不安裝或升級，不 upload／attach／publish PR Lens assets。

## 驗證與限制

必要 callback cases、listener 動態 port／loopback、逾時清理、CLI exit behavior 與有限 HTTP 讀取的代表測試。測試只驗證獨立 package，不因無關範圍擴張 root suite。本機測試通過後由 Reviewer 檢查未觸及 ReadOnly paths、未洩漏敏感值、工具 receipts 與真實授權狀態。

未提供 Client ID；真實 OAuth App 註冊、登入與授權未執行。Draft PR 可交付工具，但必須明示真實可行性未驗證。實測成功也只證明此次 redirect/code/state 流程，不證明 token、refresh 或產品整合。
