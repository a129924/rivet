# E003：GitHub OAuth refresh exchange 與 rotation 相容性驗證

## 狀態與目的

**真實 OAuth 測量：2026-10-08 單次執行，T01–T04 均成功。** 本 README 區分遠端實測與 runner 的局部證據；SwiftPM 測試、Archify 圖和 PR Lens 不能代替遠端實測。E002 的正向 code exchange、六欄 credential 與 `/user` 證據保持獨立，其 PKCE 反向與總體結論仍為「無法判定」。

目標是在一次新授權後，確認 GitHub.com OAuth App refresh token 可交換出新 token pair、建立既有 public `GitHubOAuthCredentialBundle`、維持相同 user ID，且舊 refresh token 重用得到 `bad_refresh_token`。[GitHub 官方授權文件](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#refreshing-an-access-token-with-a-refresh-token)

## 邊界與判準

| 案例 | 成功條件 | 真實狀態 |
| --- | --- | --- |
| T01 初始基準 | 新授權後初始 `/user` 為 HTTP 200，user ID 有效。 | 成功，HTTP 200 |
| T02 正向刷新 | 新 access／refresh token 非空且各自更換；六欄、正期限、bearer、scope 集合與 public bundle 相容。 | 成功，HTTP 200 |
| T03 新 token 使用 | 新 `/user` 為 HTTP 200，user ID 與 T01 相同。 | 成功，HTTP 200 |
| T04 舊 token 重用 | 唯一一次舊 refresh token 重用得到 `error=bad_refresh_token`，未取得新 token。 | 成功，HTTP 200 內含明確 OAuth error |

初始 exchange 未完成時，T01 的 HTTP status 留「未取得」；正向 refresh 若回可解析 OAuth error，T02 記「失敗」。T01／T03 的 `/user` 若只有泛用非 200 HTTP 狀態或不可解析 body，記「無法判定」；HTTP 200 且可解析但 user shape 無效，記「失敗」。

四項皆符合才記「成功」；有效前置與可判讀回應違反預期記「失敗」；App 設定、credentials、人工授權、網路或回應不足以歸因時記「無法判定」。T02 request 送出前的取消記為 interrupted；送出後回應遺失或不可解析時，rotation 狀態未知，記為無法判定並停止。T04 不以泛用 HTTP 錯誤或網路失敗冒充拒絕證據；可解析的其他非空 OAuth `error` 明確不符舊 token 拒絕判準，記為失敗；無法解析或缺乏錯誤證據仍為無法判定。T04 的前置是 T02 成功；T03 可判讀的失敗或非取消的網路失敗仍保留 T04 的唯一一次測量，取消則停止。

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

## 2026-10-08 真實執行證據

操作者在 feature worktree 使用已建置的 E003 runner、E002 OAuth App 的 Client ID、本機 TTY 隱藏輸入的 secret，完成一次瀏覽器授權。命令採 `--timeout-seconds 180`；runner exit code 為 `0`。外層腳本記錄開始 `2026-10-08T03:58:33Z`、結束 `2026-10-08T03:58:45Z`；這是程序外層時間，並非各 HTTP 事件的時間戳。此次沒有自動重試。

以下為 runner 的完整遮蔽 stdout（461 bytes，SHA-256 `8c3d86d2030a7e0b681529a73ce957aa350dbe55322c36ecdb10d8d50adbc2ca`）：

```text
最多一次新授權、一次正向 refresh、一次舊 refresh token 重用；結果只輸出遮蔽分類。按 Ctrl-C 中止。
T01=成功, http=200, reason=初始六欄相容且 API 200、user ID 有效
T02=成功, http=200, reason=新 token pair、六欄、scope 與 public bundle 相容
T03=成功, http=200, reason=新 access token 的 user ID 一致
T04=成功, http=200, reason=舊 refresh token 回傳 bad_refresh_token 且無新 token
overall=成功
```

T04 的 HTTP 200 是 OAuth response 的 transport status；成功判準依 body 中的明確 `bad_refresh_token` 且沒有新 token，不以 status 200 本身推論。此結果只支持本次 App／帳號的一次 refresh exchange、public bundle 相容與舊 refresh token 拒絕。App 全域 expiring-token 設定沒有另行查證；E002 反向 PKCE 的「無法判定」維持獨立。產品自動刷新、持久化、並行與遠端 revoke 仍不在本次驗證範圍。

## 局部驗證與圖

2026-10-08 在 feature worktree：`swift test --package-path experiments/E003` 通過 **42 個 Swift Testing tests**；局部 `swift format lint --strict --recursive` 通過，`swiftlint lint --strict` 對 Sources／Tests 的 10 個 Swift 檔案回報 0 violations。測試使用 mock／本地 loopback，不開 GitHub 授權瀏覽器或交換真實 token。TDD red 起點為尚無 E003 測量型別與 refresh 傳輸的編譯失敗；加入 E003 測量後轉為 green；T02 前已取消但誤標 rotation 未知的局部測試亦先 red 後 green；PR review 指出的可解析 OAuth error 與 T01 HTTP status 歸屬另以回歸測試先 red 後 green；T04 可解析其他 OAuth error 的分類也以 HTTP 200／400 案例先 red 後 green；先前 preflight cancellation 與不可解析 refresh 回應新增三個先 red 後 green 的回歸測試；本輪 `/user` 證據不足分類新增四個回歸測試，其中三個先 red 後 green，一個保護既有可判讀失敗行為；本輪 T03 網路失敗繼續 T04 的測試先 red 後 green，取消停止的測試保護既有邊界。

[正式 v2 sequence 圖](diagrams/refresh-rotation-v2.html) 描述初始基準、refresh 與舊 token 重用；作者文字繁體中文，固定 Viewer UI／HTML lang 依工具 fallback 為英文。v2 `showcase` 驗證 9／9、0 errors／warnings；[deliver receipt](diagrams/refresh-rotation-v2.delivery.json) 已提交，其 spec SHA-256 為 `a4b183915429b852d121163b286fd3df359e10e4cc0f37a002a31f352008d028`（3455 bytes），HTML SHA-256 為 `d9fd6d7182741809aed3b406d70a2ec1fff13e27cfa628f643eb1932e4f2ffe0`（704263 bytes）。[visual-check receipt](diagrams/refresh-rotation-v2.visual-check.json) 四種桌面尺寸 1440×900、1600×1000、1920×1080、2048×1320 均無 overflow，最小／最大明暗 captures 已保存；工具 `visualReview=pending`，獨立 Reviewer 已逐一檢視四張 capture 並判定可讀。正式僅保留 v2 圖；其布局已修正參與者過度集中與段落範圍。

Graphify 沒有可用的既存 graph，已改用有界的 `rg` 與來源檢查；未建圖、安裝或呼叫 provider。PR Lens 已依真實 base/head topic commit 在 repository 外建立本地變更圖，使用 pinned 0.11.0 validate／render 並經獨立 Reviewer 核對。兩者均不構成程式或真實 OAuth 驗收。

HC-LIVE：本次單次人工授權與遠端測量已完成；HC-REVIEW：PR #48 已標記 Ready for review，仍待人類審查。局部測試或圖驗證不擴大真實實驗的結論邊界。
