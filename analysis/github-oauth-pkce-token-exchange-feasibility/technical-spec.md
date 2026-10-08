# E002 — Technical Spec

- Topic：`github-oauth-pkce-token-exchange-feasibility`
- 狀態：locked decisions 來自使用者批准的對話計畫；正式 planning gate approved（獨立 Plan-Reviewer，由 Dispatcher 轉交）。
- 配對文件：[requirements](requirements.md)、[plan](../../plan/github-oauth-pkce-token-exchange-feasibility/github-oauth-pkce-token-exchange-feasibility.plan.md)、[step](../../plan/github-oauth-pkce-token-exchange-feasibility/github-oauth-pkce-token-exchange-feasibility.step.md)。

## Runner 與接口

E002 在 `experiments/E002` 建獨立 SwiftPM executable、core 與 tests，Swift tools 6.0／language mode 6，macOS 15 起；root package 只作相對 local dependency，僅取 public `GitHubIntegration` product。不修改根 Package／產品 target，不公開 internal DTO，不與 OAuthTokenProvider、REST／GraphQL client 接線。

複製 E001 必要 listener 模式至 E002，E001 保持唯讀。callback 為 `http://127.0.0.1:<dynamic-port>/oauth/callback`，授權 request 與同次交換使用完全相同的 redirect_uri。每次生成獨立 state 與 32-byte 隨機、無 padding base64url verifier；challenge 為 SHA-256(verifier) 的 base64url。反向 verifier 必須格式合法並確認不匹配此次 challenge。

授權至 GitHub.com `https://github.com/login/oauth/authorize`，明示 client_id、redirect_uri、state、scope=offline_access、code_challenge、code_challenge_method=S256；不額外要求 repo／user。client ID 沿用 E001，只有使用者提供後才安排真實測量。不以回應 scope 含 offline_access 作成功條件。[官方授權文件](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)

callback 必須有符合預期、未重複的 state 與非空 code；state 缺漏／重複／不符或 code 缺漏／空字串均不得 exchange。有效 callback 後立即單次 POST `https://github.com/login/oauth/access_token`；form encoding client_id、client_secret、code、redirect_uri、code_verifier，要求 Accept: application/json。每 code 只 POST 一次，無 retry；PKCE 不免除 client_secret。

## Schema 與 API

本地 DTO 嚴格沿用既有 nonoptional 六欄與型別：access_token String、refresh_token String、expires_in Int、refresh_token_expires_in Int、token_type 既有 bearer enum、scope String。不補欄位或改型別；scope 可為空字串。

收到 token 回應時擷取 receivedAt；以 receivedAt 加兩個整數秒數轉 Date，再以 public initializer 建真正的 GitHubOAuthCredentialBundle。不呼叫產品 internal decoder，不把過期映射的 mock 結果誤記真實相容。

只要正向取得非空 access token，就執行唯一一次 `GET https://api.github.com/user`，即使其他 schema 欄位不相容。Bearer token 只在記憶體 request；API 成功要求 HTTP 200、JSON object、有效 id 與非空 login，只保存驗證布林，不保存 userinfo。不 refresh 或 retry。

## 兩次測量、判定與清理

先正向新授權／正確 verifier，再獨立記 exchange、schema、API。正向 exchange 成功後才做反向新授權；schema／API 的有效 failure 不妨礙反向測量。反向不用已消耗正向 code。

反向任何非空 access／refresh token 為失敗；檢查 OAuth error body，不能只看 HTTP status。通用 bad_verification_code 必須以正向 baseline、同 App／secret、相符 redirect、有效 state、新 code、立即單次交換排除混淆；無法排除即無法判定。不預設其他未核實 error code 為 PKCE 專屬訊號。[官方錯誤說明](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/troubleshooting-oauth-app-access-token-request-errors)

最多兩次真實授權；每次 callback 上限 180 秒，每個 HTTP request 上限 30 秒。正向 exchange 未成功、前置條件不足、人工拒絕、網路或 timeout 時停止，不新增反向授權、不擴大嘗試。API 有效 failure 與網路／timeout 分開；後者停止測量。各完成、取消或停止路徑均關閉 listener／session。

每軸成功／失敗／無法判定，總體全成功才成功；任一有效 failure 為總體失敗，其餘未完成記無法判定。runner 交付品質與真實 OAuth 實證分開，HC-LIVE pending 不等重大實作問題。

## 敏感資料邊界

secret 僅由 runner 啟動後的本機 TTY 隱藏輸入，不放 argv、shell 指令、聊天或檔案；不讀取既存 secret。使用 ephemeral session，停用持久 cache／cookie storage。code、state、verifier、token、secret、userinfo、完整 URL、request／response body、未遮蔽 error 不落盤、不 log。所有 error 只輸出有限遮蔽分類，mock 檢查 stdout／stderr 與證據不含敏感值。

程序結束時釋放記憶體資料，不宣稱安全抹除。runner only 邊界不涵蓋 browser／OS 留痕，後者未驗證。自動驗證限 stub／mock，不隱式開瀏覽器或交換真實 token。

## 受限圖表與導航工具

Archify 僅 E002 一張 sequence，包含正向與使用新授權的反向分支；static、classic，作者繁中，省略 unsupported meta.locale，記固定 Viewer UI／html lang fallback 英文。讀 matching schema／common schema／一個 example 後下一步寫 candidate，不先讀 renderer 或計畫座標；meta.quality_profile=showcase，每次修改與交接前 validate 須九項全通過、零 errors／warnings。

最終 validate 後凍結，再 deliver 記 spec／HTML SHA-256 與 byte count。最多兩輪 focused repair；兩次連續未改善最佳 error count 或預算用盡即停，不能重啟預算。凍結 HTML 執行 repo-relative visual-check：1440×900、1600×1000、1920×1080、2048×1320，scrollWidth／Height 不超 viewport；最小／最大 light／dark captures 與 sidecars。visualReview=pending 須獨立 Reviewer 實看，非零／skipped 不冒稱通過。圖問題與 OAuth 實證分開；不發布 artifact.cafe、不 preview、不增 UI scope。

Graphify pinned 0.9.73；每 CLI 包含 help／version 都設 GRAPHIFY_NO_AUTO_REFRESH=1。僅可用既存 graph 作 budget 1500 bounded query，查 revision／source，重要關係再 source 驗證。現無 graph 用 targeted source fallback，記缺口、不阻本體；不 extract／build／cache／stamp／install／config／hooks／provider／uploads／watchers。

PR Lens pinned 0.11.0，只 local validate／render。第一個已授權且受審 topic commit 形成真實不同 base／head 後，才能建立 map；provenance.repo／base／head 必須真實，不能假 head／借無關 commit。以 git diff --find-renames 與必要 unchanged neighbors／fileRefs author repo 外 scratch graph，validate／render 並讀 manifest。已有 config 僅 read，否則 --no-config。不 npx／install／auth／provider／push／upload／PR 訊息／server／config edit／repo .pr-lens。失敗採 direct diff 並記未完成。

## A001：追加圖修復預算

2026-10-07 — 原兩輪預算已用盡且失敗，不重設原計數；人類另批准最多兩輪追加，獨立計數已用 1／2（累計 3／4），上限四輪。A001 獨立 Plan-Reviewer approved／無 required fix；A05 成果 Reviewer approved，v3 為正式入口，來源／artifact matching receipts 與四 captures 已獨立驗收；所有圖檔保持凍結。

追加輪次採新的 v3、v4 spec／HTML／receipt／capture 路徑；既有 v1／v2 candidate、trusted HTML、receipts、captures 與 hashes 均保留、不覆寫。v1 原始 spec／delivery receipt 曾被覆蓋的 provenance 缺口不可追造或冒稱恢復。Implementer 先記原證據 hash，再以新版本修復，每輪從 candidate 修改到 validate／deliver／visual-check／診斷交接算一輪，任一失敗不重啟預算。

驗收完全不變：meta.quality_profile=showcase、九項檢查全數通過、零 errors／warnings；最終 spec 凍結並 deliver 留 SHA-256／byte count；四 desktop viewport 1440×900、1600×1000、1920×1080、2048×1320 無 overflow，最小／最大 light／dark captures；獨立 Reviewer 必須實看，visualReview=pending 不算通過。不改 renderer／gate，不隱藏 overflow、不裁切、不以縮小字體偽造通過。

仍沿用原 no-progress 規則：兩次連續未改善最佳 objective error count 即停止；追加兩輪用盡仍未達標也停止 human-check。記每輪診斷與 error count／containment 結果，不自行延長或豁免。圖修復不重跑真實 OAuth、不改 runner，HC-LIVE 0／2 不變。
