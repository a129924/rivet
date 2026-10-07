# E001：GitHub OAuth 重導向可行性驗證

## 驗證什麼、為什麼

驗證獨立 GitHub OAuth App 授權能經系統瀏覽器重導向至本機 IPv4 loopback listener，收到非空 `code` 且 `state` 相符，降低後續正式 Swift implementation 的不確定性。本 package 使用 Swift 6、macOS 15+ 與 Apple frameworks，不連結 Rivet 產品 package。

**實驗成功條件**：真實 GitHub 授權返回、code 非空、state 相符、程序結束碼 `0`。本機模擬 callback、build/test 或圖驗證通過均不能代替真實實測。本次不交換 token，不取得 Client Secret，不驗證 refresh、Keychain 或產品登入，也不鎖定產品 callback 架構。

## 如何重現

1. 在 GitHub 註冊獨立測試 **OAuth App**，Authorization callback URL 設為 `http://127.0.0.1/oauth/callback`；提供該 App 的 Client ID。不要提供 Client Secret。
2. 在 feature worktree 根目錄執行：

   ```sh
   swift run --package-path experiments/E001 oauth-redirect-probe \
     --client-id <Client-ID> --timeout-seconds 180
   ```

3. 在系統瀏覽器親自完成登入與授權。Runner 先綁定 `127.0.0.1` 的動態 port，listener 就緒後以 Security framework 產生 32 bytes 隨機 state，再開啟授權頁。
4. 依終端安全結果記錄實測狀態。不要複製完整 authorization URL、callback query、code 或 state 到檔案、PR 或聊天。

GitHub 的 [loopback redirect 官方說明](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#loopback-redirect-urls) 允許 runtime 使用不同 port；本次註冊無顯式 port 的 callback，runtime 使用 `http://127.0.0.1:<動態 port>/oauth/callback`。官方規則支援此方式；2026-10-07 已完成一次真實 App／系統瀏覽器 redirect 實測，結果見下節。

`--client-id` 必填且非空；`--timeout-seconds` 為正整數，預設 `180`。未知、重複或無效 CLI 參數不開瀏覽器。listener 啟動上限 `10` 秒，每條 connection header 讀取上限 `8 KiB`、等待上限 `5` 秒。按 Ctrl-C 可中止並清理資源。

| 結束碼 | 結果 |
| --- | --- |
| `0` | code 非空且 state 相符；未交換 token。 |
| `1` | callback／state／授權錯誤、listener／瀏覽器啟動失敗或逾時。 |
| `2` | 無效 CLI 參數。 |
| `130` | SIGINT 中止。 |

只接受 `GET /oauth/callback`。其他路徑回 `404`，callback 的其他 method 回 `405`，關閉該 connection 後繼續等待；code/state 缺漏、空值、不符、重複 query 參數或 GitHub error 都不能算成功。終結一次後清理 listener、timer 與 connections；callback 頁面與終端不反射敏感 query，response 使用 `Cache-Control: no-store`。

## 是否成功

| 項目 | 狀態與證據 |
| --- | --- |
| 真實 OAuth 可行性 | **成功**：2026-10-07 使用人類提供的測試 OAuth App Client ID，系統瀏覽器返回非空 code、state 相符，程序 exit 0；人類亦確認 callback 頁顯示相同安全成功訊息。未交換 token。 |
| 本機自動化 | 獨立 Tester 的 `swift build --package-path experiments/E001` 與 `swift test --package-path experiments/E001` 均 exit 0；15 tests、3 suites 於 1.008 秒通過。全部使用 browser stub／模擬 callback，不是真實授權。 |
| Swift 格式與 lint | E001 recursive `swift format` 與 `swiftlint lint --strict --no-cache`：9 個 Swift 檔案、0 violations。 |
| Archify 結構 | sequence showcase `9/9`、0 errors、0 warnings；final deliver 通過。 |
| Archify 桌面 containment | **failed**：四個尺寸皆有垂直 overflow；`1440×900` 的 scrollHeight 為 `1645`，`2048×1320` 為 `1773`。captures 已保存；獨立 Reviewer 已親看最小 light／最大 dark，確認視覺 gate needs-rework，分類為不阻 Draft 的殘留。達兩輪 focused correction 上限，未繼續修圖，未宣稱整體圖驗收通過。 |
| Graphify | 前序唯讀檢查確認 pinned `0.9.73`；未找到可用既有 graph，採限定來源查讀，不建圖或刷新。 |
| PR Lens | 獨立 Reviewer 的 initial local map validate/render exit 0；actual base `622abf6` → head `77be780`，1 static light SVG，manifest head 相符。最終證據 commit 後需刷新外部 map；不上傳資產。 |

環境：2026-10-07，macOS `26.5.2`（`25F84`）、Xcode `26.6`（`17F113`）、Apple Swift `6.3.3`，arm64。真實實測成功結果於 2026-10-07 11:14:21（Asia/Taipei）／03:14:21 UTC 觀測；code_present=true、state_matches=true、exit_code=0。

## 自動化驗證

```sh
swift build --package-path experiments/E001
swift test --package-path experiments/E001
swift format lint --strict --recursive \
  experiments/E001/Package.swift experiments/E001/Sources experiments/E001/Tests
swiftlint lint --strict --no-cache \
  experiments/E001/Package.swift experiments/E001/Sources experiments/E001/Tests
```

核心案例：成功／缺少／空 code/state、state 不符、GitHub error、重複參數與 URL decoding、CLI 缺漏／未知／重複／非正整數值、32-byte 隨機 state、本機動態 port、404／405 後繼續等待、逾時／瀏覽器失敗、SIGINT 終結一次、不完整／超量 header connection 清理、成功後 listener 關閉與安全 response。

TDD 證據：首先以尚未實作的 callback stub 執行 `swift test --package-path experiments/E001 --filter CallbackTests`，合法 code/state 被判為 `.invalidCallback`，1 個測試失敗；實作判定後 10 個測試通過；補上真實 loopback runtime 與受限 HTTP cases 後，15 個測試通過。測試用的 code/state 是合成資料，不是真實授權結果。

## 獨立 Tester 證據

2026-10-07 在 feature worktree 複核：

- `swift build --package-path experiments/E001`：exit `0`。
- `swift test --package-path experiments/E001`：exit `0`，15 tests／3 suites 通過，涵蓋 callback 判定、loopback 動態 port、404／405 後繼續等待、逾時、browser failure、interrupt 單次終結與 HTTP 有限讀取／清理。
- 實際 executable 的四組合成無效 CLI（缺參數、unknown option、timeout 0、重複 client ID）：均 exit `2`，只輸出固定 usage，未反射輸入值、未開啟瀏覽器。
- 外部暫存 harness 保留 executable 原始 RunLoop／DispatchSource SIGINT 程式碼，只將 `NSWorkspace.open` 替換為 browser stub；使用已建置 ProbeCore objects 連結。1 秒 timeout exit `1`，送出 SIGINT exit `130`，安全結果輸出均無合成 Client ID。這是入口控制流程驗證，不是實際 GUI 開啟或 GitHub 授權；暫存 harness 已清理，實作未修改。
- `git diff --check` 通過；root `Package.swift`、產品 `Sources/`／`Tests/`、`docs/` 與 `.vscode/` 對基線無 tracked diff。feature 新檔只在 E001 與本 topic；`.build/` 被既有 ignore 排除。dev worktree 唯一狀態為原有 `.vscode/launch.json`，本次未寫入 dev。
- topic／E001 可交付文字檔未發現本機絕對路徑 marker。delivery receipt 的規格／HTML SHA-256 和 bytes 完全相符，visual receipt 也指向相同 HTML；四張 captures 與 contact sheet 存在。
- 已檢視最小 light 與最大 dark 截圖：流程下半部超出首屏，與四尺寸 overflowY receipt 一致。未修改、rerender 或重啟圖修正；圖視覺 gate 不算通過，由獨立 Reviewer 分類。

交付前 Tester 分列結論（歷史結果；後續真實實測見下節）：核心自動化 **approved**；Archify desktop 驗收 **needs-rework**；真實 GitHub 授權仍 **未執行／未驗證**。Tester 不決定 topic／Draft PR gate。

## 流程圖與限制

[OAuth sequence 圖](diagrams/oauth-redirect-flow.html)、[規格](diagrams/oauth-redirect-flow.json)、[delivery receipt](diagrams/oauth-redirect-flow.delivery.json)、[desktop receipt](diagrams/oauth-redirect-flow.visual-check.json)、[light/dark contact sheet](diagrams/oauth-redirect-flow.visual-check.html)。規格已凍結，圖採 static/classic；作者內容繁體中文，Archify 固定 Viewer UI 與 HTML lang 使用 English fallback。

Delivery receipt 的規格 SHA-256 為 `55f81f859f7b01a144e65df17cf8c87abe45e3ba259c196d3dc3ae187d14db19`（2564 bytes），HTML SHA-256 為 `0757306592a67ad92337cbb8d58e9155f81c25a6fb18fa61cb3f759e91b6f08a`（700053 bytes）。結構通過與 desktop failure 分開記錄，不能以 deliver 通過推定視覺通過。

真實實測後只更新「成功／失敗／未完成」、環境日期、code 是否存在、state 是否相符及安全失敗分類。實測成功也僅證明此次 redirect/code/state 流程。Desktop 圖缺陷已由獨立 Reviewer 分類為 nonblocking Draft residual，正式視覺驗收仍 needs-rework，待人類 review；正式 planning 與九欄位執行契約見 `plan/github-oauth-redirect-feasibility/`，不得以輔助工具狀態改寫 OAuth 實驗結果。

## 交付前獨立 Reviewer 結論（歷史）

2026-10-07 — correctness／scope review 未發現重大程式問題；serial queue、單次終結、listener／timer／connections 清理、有限 HTTP 讀取及 callback／CLI 的安全輸出符合 E001 契約。僅新增 E001 與同 topic artifacts，未修改 root package、產品 API 或 docs。依獨立 Tester 核心證據，**bounded Draft delivery approved**，可依已授權流程建立 topic commit 與 Draft PR，並交 human review。

Reviewer 已親看 1440×900 light 與 2048×1320 dark 截圖；流程與結論超出首屏，四尺寸 containment failure 為真實殘留，**正式 Archify 視覺 gate 仍 needs-rework**。此輔助圖缺陷不影響 runner 或核心 callback 證據，因此不阻 Draft；本結論不是完整 topic approval，不改寫凍結 receipts，也不宣稱真實 OAuth 成功。真實 App／GUI／授權仍未驗證。

## PR Lens 與 Graphify 交付證據

獨立 Reviewer 使用 PR Lens CLI `0.11.0`，依真實 base `622abf662d73afd7e887c7684630663fcaae4a6f` 與 topic commit `77be7808220e26232b7a2a5e910f8831c9651589` 的 bounded diff，製作 local 概念變更圖；`validate` 與 `render --theme light --no-config` 均 exit `0`。圖呈現新增 runner／ProbeCore／tests、既有系統 browser 與未變更 root package；root 沒有 E001 dependency，不新增或推論產品 compile 關係。

外部暫存的 topic-relative 目錄 `github-oauth-redirect-feasibility/pr-lens/` 保存 `graph.json`、`review-receipt.json`、`rendered/manifest.json`、`rendered/drawn.graph.json` 與 `rendered/e001-context-light-29d63bbc70d0c5e20cfeca9a4e4002d0.svg`。manifest 確認 actual head；SVG 為 1304×388、9555 bytes；JSON 保留 11 file refs，static SVG 沒有可點的檔案連結。這是 comprehension map，不能代替 correctness review、真實授權或正式圖視覺驗收。最終 docs-only 交付證據 commit 後刷新外部 map 至最終 head，不再寫 repo 造成遞迴 commit。

Graphify 每次 CLI 設 `GRAPHIFY_NO_AUTO_REFRESH=1`；pinned version `0.9.73`。沒有既有 graph，採 bounded source reads，不建圖、安裝、刷新 skills 或修改 hooks/config。工具產物不 commit／upload／attach／publish，Draft PR 由已授權的交付流程建立。

## Draft PR 與人類 review

[Draft PR #45](https://github.com/a129924/rivet/pull/45) 指向 `dev`，實作 commit 為 `77be7808220e26232b7a2a5e910f8831c9651589`；全部既有 pre-commit hooks 通過。交付證據以同 topic docs-only commit 同步，外部 PR Lens map 隨後對齊最終 head。

目前等待 PR 人類 review。真實 OAuth redirect/code/state 已於 2026-10-07 驗證成功；Archify desktop containment 仍 needs-rework。本 Draft 不代表完整 topic 或產品登入完成，不自動 merge 或移除 worktree。

## 真實 OAuth 人工驗證結果

- 觀測時間：2026-10-07 11:14:21（Asia/Taipei），即 03:14:21 UTC。
- 執行版本：實作 commit `77be7808220e26232b7a2a5e910f8831c9651589`，啟動時 branch HEAD 為 `51dca1eab42cc3748c3ad39e687139dd617f6c8f`；後者僅新增交付文件，runtime 程式未變更。
- 命令：`experiments/E001/.build/debug/oauth-redirect-probe --client-id <Client-ID> --timeout-seconds 180`，從 feature worktree 執行；使用人類提供的真實測試 App Client ID，不是 browser stub。
- 程式先開啟系統瀏覽器並等待，隨後輸出「OAuth 重導向驗證成功：收到非空 code，state 相符。未交換 token。」；process exit code 為 `0`。
- 人類亦回報 callback 頁顯示同一成功訊息；code_present=true、state_matches=true。這是終結結果證據，沒有保存 code、state、完整 callback query 或 authorization URL。
- 結論：本次 GitHub OAuth App → 系統瀏覽器 → IPv4 loopback callback 的 redirect/code/state 流程驗證成功。沒有交換 access token，不能推論 token acquisition、refresh、Keychain 或正式 app 整合已驗證。
- 限制：實際動態 port 與瀏覽器品牌／版本未記錄，不以推測補值；重現仍須使用自己的測試 App 設定。Archify desktop 殘留與 PR human review 不因本次成功自動通過。
