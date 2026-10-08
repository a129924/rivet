# E003 — Technical Spec

- Topic：`github-oauth-refresh-rotation-feasibility`。
- Locked decisions 來自使用者接受的 E003 對話計畫；2026-10-08 獨立 Plan-Reviewer 明示 `approved`，無 required fix。
- 配對文件：[requirements](requirements.md)、[plan](../../plan/github-oauth-refresh-rotation-feasibility/github-oauth-refresh-rotation-feasibility.plan.md)、[step](../../plan/github-oauth-refresh-rotation-feasibility/github-oauth-refresh-rotation-feasibility.step.md)。

## 獨立 runner 與資料流

在 `experiments/E003` 建 Swift 6／macOS 15+ 獨立 SwiftPM executable、core 與局部測試；以 root package 相對依賴只取 public `GitHubIntegration` product。不修改 root package／Sources／Tests，不依賴 E002 internal DTO，也不接線 `OAuthTokenProvider`。採 E002 的 IPv4 loopback 動態 port、`/oauth/callback`、state 驗證、PKCE `S256`、隱藏 secret 輸入與受限 HTTP 模式；E002 保持唯讀。

先確認 E002 App、client credentials、callback 與本機環境可用。新授權請求 `offline_access`；callback code／state 有效後交換初始 credential。以初始 access token 呼叫一次 `GET https://api.github.com/user`，僅在記憶體保存有效 user ID 供比較。再向 `POST https://github.com/login/oauth/access_token` 以 `Accept: application/json` 提交 `client_id`、`client_secret`、`grant_type=refresh_token`、初始 `refresh_token`；取得 response 後記接收時間。成功解析後以新 access token 呼叫一次 `/user`，最後只重用舊 refresh token 一次。使用相同 App／secret 及初始有效前置，避免把設定錯誤當作 rotation 訊號。[GitHub 官方授權文件](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#refreshing-an-access-token-with-a-refresh-token)

E003 local DTO 嚴格解析六欄：token 為 String、期限為 Int、type 限 bearer、scope 為 String。檢查新舊 pair 各自不同、非空、期限正值；以接收時間加期限建 public `GitHubOAuthCredentialBundle`。scope 可為空；以逗號分隔後的集合比較初始與刷新後值，不將 `offline_access` 當作 granted scope。public bundle 保存服務端原始 scope 字串。此證據是本地解析與 public initializer 相容，不冒稱執行產品 internal decoder。

T04 只接受可解析 `error=bad_refresh_token` 且不含新 token 的 response；HTTP status 自身不足。其他可判讀且違反預期的回應依分項判失敗，無法確認的網路／回應依無法判定處理。若 T02 refresh request 送出後 response 遺失，rotation 狀態未知，立即停止，不重試。若 T04 意外取得 token，記失敗並停止使用該 token。

## 上限、敏感資料與局部驗證

真實執行最多一次新授權、callback 最多等 180 秒、一次正向 refresh、一次舊 token 重用，不自動重試。每個 HTTP request 採 E002 的有限 timeout 與 redirect 禁止模式。前置失敗、取消或無法判讀的關鍵 response 停止後續依賴步驟並清理 listener／session。程序結束釋放記憶體，不宣稱安全抹除或遠端撤銷。

secret 僅由本機 TTY 隱藏輸入，不放 argv、shell、聊天或檔案，不讀既存 secret。使用 ephemeral HTTP session 並關閉持久 cache／cookie。code、state、verifier、token、user ID、完整 URL、原始 request／response／error 僅留記憶體；stdout／stderr／README 僅含固定有限分類、HTTP status、欄位有效性、token 更換與身分相同布林。不宣稱 browser／OS 留痕受 runner 控制。

局部模擬測試須覆蓋六欄缺失／型別與期限、bearer、空 scope、到期映射與 public bundle、token 非空／更換、scope 集合、兩次 `/user` 身分比較、`bad_refresh_token` 與非該 error 的分類、response 遺失停止、單次請求上限、遮蔽輸出。測試不得開瀏覽器或接觸 GitHub；真實結果另記成功／失敗／無法判定。

## 圖與導航工具

Archify 僅一張繁體中文 refresh／rotation sequence，置於 E003 diagrams；static/classic、`meta.quality_profile=showcase`，不自行發布。依 matching schema/common/example 建候選，每次編修後 validate；最終九項 artifact checks、零 composition errors／warnings 後凍結，deliver 記 spec／HTML SHA-256 與 byte counts。visual-check 檢查 1440×900、1600×1000、1920×1080、2048×1320 無 overflow，保留最小／最大 light／dark captures，獨立 Reviewer 實看；`visualReview=pending` 不是通過。繁體中文作者內容省略不支援的 locale，固定 Viewer UI／HTML lang fallback 英文。

Graphify 只查既存可用 graph：每次 pinned CLI invocation 設 `GRAPHIFY_NO_AUTO_REFRESH=1`，先核 revision／source、budget 1500 bounded query，再讀相關 source；沒有 graph 時以 `rg`／targeted reads 查證，不 extract／build／install／provider／upload／改設定。

PR Lens 等真實且不同的 base/head commit 存在後，從 bounded `git diff --find-renames` 與必要 source 建 repo 外 local change map，含 unchanged neighbours 與 file refs；只用 pinned 0.11.0 validate／render，讀 manifest。有現存 repo config 才讀取套用，否則 `--no-config`。沒有 provenance 時 pending 並直接 review diff；不在 repo 建 `.pr-lens`、不 upload／publish 或透過該工具操作 PR。

## PR #48 長期依據回寫 amendment（R02 approved；R03 append 完成）

只在 `docs/architecture/github-oauth-dual-client.md` 的既有 E001／E002 受限依據後附加一小節「E003 受限 refresh／rotation 相容性依據」。以 [E003 README](../../experiments/E003/README.md) 為遮蔽證據來源，記 2026-10-08 一次新授權、T01 初始 `/user` HTTP 200、T02 refresh HTTP 200／新 token pair／六欄 public bundle 相容、T03 新 `/user` HTTP 200 且 user ID 相同、T04 舊 refresh token 重用的 HTTP 200 body `bad_refresh_token` 且無新 token，以及 runner exit 0／overall 成功。只留有限結果，不複製 token、secret、code、state、verifier、user ID 或原始回應。

該小節明示：證據只支持本次 GitHub OAuth App／帳號的 refresh exchange、bundle 相容、同一身分與舊 token 拒絕；不證明產品 `OAuthTokenProvider` 自動刷新、Keychain／持久化、並行、到期行為、遠端 revoke，亦不改 E002 反向 PKCE 的「無法判定」。保持既有責任／產品 architecture 決策、原有段落與 diagrams 原樣。R02 獨立 Plan-Reviewer 已明示最終 `approved`、required fixes 無；R03 已只作 docs append，原 bytes 保留，未改圖。R04 Tester 仍須檢查 append-only、相對連結、敏感值與 diff allowlist，R05 獨立 Reviewer 仍須審查語意及限制；本 amendment 不再次執行真實 OAuth。

R03 的增量 allowlist 僅四份 topic planning artifacts 與 `docs/architecture/github-oauth-dual-client.md` 的唯一 append；E003 README 僅供讀取／連結。PR #48 其他 threads 已在 feature worktree 修正 E003 source／tests、同步 README 並新增 E003 `.delivery.json`；目前局部 32 tests 與 strict format／lint 通過，仍須各自獨立 Tester／Reviewer 驗證，不視為 R03 docs gate 的產出。R04 針對 R03 前後增量查 append-only，不能用整個 PR diff 混算 docs 限界。
