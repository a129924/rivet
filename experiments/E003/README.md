# E003：GitHub OAuth refresh exchange 與 rotation 相容性驗證

## 狀態與目的

**真實 OAuth 測量：未執行，四項結果均無法判定。** 本 README 記錄 runner 與局部證據；SwiftPM 測試、Archify 圖和 PR Lens 不能代替遠端實測。E002 的正向 code exchange、六欄 credential 與 `/user` 證據保持獨立，其 PKCE 反向與總體結論仍為「無法判定」。

目標是在一次新授權後，確認 GitHub.com OAuth App refresh token 可交換出新 token pair、建立既有 public `GitHubOAuthCredentialBundle`、維持相同 user ID，且舊 refresh token 重用得到 `bad_refresh_token`。[GitHub 官方授權文件](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#refreshing-an-access-token-with-a-refresh-token)

## 邊界與判準

| 案例 | 成功條件 | 真實狀態 |
| --- | --- | --- |
| T01 初始基準 | 新授權後初始 `/user` 為 HTTP 200，user ID 有效。 | 未執行 |
| T02 正向刷新 | 新 access／refresh token 非空且各自更換；六欄、正期限、bearer、scope 集合與 public bundle 相容。 | 未執行 |
| T03 新 token 使用 | 新 `/user` 為 HTTP 200，user ID 與 T01 相同。 | 未執行 |
| T04 舊 token 重用 | 唯一一次舊 refresh token 重用得到 `error=bad_refresh_token`，未取得新 token。 | 未執行 |

四項皆符合才記「成功」；有效前置與可判讀回應違反預期記「失敗」；App 設定、credentials、人工授權、網路或回應不足以歸因時記「無法判定」。T04 不以泛用 HTTP 錯誤或網路失敗冒充拒絕證據。T04 的前置是 T02 成功；T03 可判讀的失敗仍保留 T04 的唯一一次測量。

本次不測產品自動刷新、`OAuthTokenProvider`、Keychain、持久化、401 recovery、並行、真實到期、舊 access token、撤銷或 E002 PKCE 反向案例。`GitHubIntegration` 是 BC 外共用整合模組，本實驗沒有新增 BC 或 public API。

## Runner 與重現

`experiments/E003` 是獨立 SwiftPM package，僅以 root public `GitHubIntegration` product 建立既有 bundle。授權沿用 E002 的 127.0.0.1 動態 loopback、state、PKCE `S256` 與 `offline_access`；E003 在本地解析六欄，bundle 保存原始 scope 字串，集合比較才以逗號分隔。`offline_access` 不要求出現在一般 granted scope。

```sh
swift build --package-path experiments/E003
swift test --package-path experiments/E003
swift run --package-path experiments/E003 oauth-refresh-probe --client-id <Client-ID>
```

最後一條只在操作者已確認 E002 OAuth App、client ID／secret、callback 與網路後，由本機互動執行。secret 在 TTY 的隱藏提示輸入；不可放在命令列、shell 歷史、聊天或檔案。無 TTY 或參數不合法時 runner 以固定安全文字退出 2，不開瀏覽器。可選 `--timeout-seconds <1…180>` 縮短 callback 等待。

最多一次新授權、callback 等待 180 秒、一次正向 refresh、一次舊 refresh token 重用；每個 HTTP request 最多 30 秒，禁止 redirect 與自動重試。正向 refresh request 送出後若回應遺失，rotation 狀態未知並停止；若 T04 意外取得新 token，記失敗並停止使用。所有路徑關閉 listener／ephemeral session。遠端 rotation 無本機 rollback；程序結束不宣稱撤銷或安全抹除 credential。

secret、code、state、verifier、token、user ID、完整 URL 與原始 request／response／error 只留記憶體。stdout／stderr 僅有固定分類、HTTP status 與分項 verdict；若需保存實測證據，只保存遮蔽輸出與環境／日期／限制，不保存原始資料。browser／OS 留痕不在 runner 控制範圍。

## 局部驗證與圖

2026-10-08 在 feature worktree：`swift test --package-path experiments/E003` 通過 **29 個 Swift Testing tests**；局部 `swift format lint --strict --recursive` 通過，`swiftlint lint --strict` 對 11 個 Swift 檔案回報 0 violations。測試使用 mock／本地 loopback，不開 GitHub 授權瀏覽器或交換真實 token。TDD red 起點為尚無 E003 測量型別與 refresh 傳輸的編譯失敗；加入 E003 測量後轉為 green；T02 前已取消但誤標 rotation 未知的局部測試亦先 red 後 green。

[正式 v2 sequence 圖](diagrams/refresh-rotation-v2.html) 描述初始基準、refresh 與舊 token 重用；作者文字繁體中文，固定 Viewer UI／HTML lang 依工具 fallback 為英文。v2 `showcase` 驗證 9／9、0 errors／warnings；`deliver` 的 spec SHA-256 為 `a4b183915429b852d121163b286fd3df359e10e4cc0f37a002a31f352008d028`（3455 bytes），HTML SHA-256 為 `d9fd6d7182741809aed3b406d70a2ec1fff13e27cfa628f643eb1932e4f2ffe0`（704263 bytes）。[visual-check receipt](diagrams/refresh-rotation-v2.visual-check.json) 四種桌面尺寸 1440×900、1600×1000、1920×1080、2048×1320 均無 overflow，最小／最大明暗 captures 已保存；工具 `visualReview=pending`，獨立 Reviewer 已逐一檢視四張 capture 並判定可讀。正式僅保留 v2 圖；其布局已修正參與者過度集中與段落範圍。

Graphify 沒有可用的既存 graph，已改用有界的 `rg` 與來源檢查；未建圖、安裝或呼叫 provider。PR Lens 需等真實 base/head topic commit 才能在 repository 外建立本地變更圖，目前 pending。兩者均不構成程式或真實 OAuth 驗收。

HC-LIVE：App／credentials／人工授權尚待；HC-REVIEW：Draft PR 開立後交人類審查。上述未完成狀態不因局部測試或圖驗證通過而改寫。
