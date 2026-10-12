# GitHub OAuth refresh 失敗分類技術契約

## Public API

新增 public OAuthTokenRefreshError: Error, Sendable，cases 為 credentialRejected、clientConfiguration、knownTechnicalFailure、rotationIndeterminate、cancelled(stage: CancellationStage)。CancellationStage 為 public、Sendable，cases beforeRequest／afterRequestStarted。

OAuthTokenFetcher.refresh 改為 async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle，更新所有 conformers。OAuthTokenProviderError 新增 authenticationRequired；refresh(underlying:) 保留為 technical failure surface。GraphQL 將 authenticationRequired 映射為既有 authenticationRequired，其餘 refresh 映射 credentialLifecycle(stage: .refresh)，並更新 typed cancellation 辨識。

## Internal HTTP adapter

GitHubOAuthHTTPTokenFetcher 注入 bare HTTPClient、clientID／clientSecret 與 clock；helpers 留在同檔，不新增泛化 abstraction。Root Package.swift 接上小寫 packages/RivetHTTPClient local dependency／product；不修改 generic package source。

正式 construction 使用 ephemeral URLSession，停用 redirect、cookie、cache；request／resource timeout 30 秒，無 application retry。固定既有 GitHub.com token URL，POST application/x-www-form-urlencoded，client_id、client_secret、grant_type=refresh_token、refresh_token 正確編碼，Accept: application/json。

成功限 2xx、無 OAuth error、六欄完整、access／refresh token 非空、期限為正且可安全映射的整數、token_type 為 bearer；scope 可空。沿用 DTO mapping，以收到 response 的 clock 計算到期时间，不改 public bundle constructor。failure／diagnostics 不保存 raw body、token、secret 或原始 transport error。

## Failure／state contract

| 證據 | Fetcher failure／Provider state |
| --- | --- |
| 2xx／4xx 純 error body，明確 bad_refresh_token | credentialRejected；authenticationRequired terminal |
| 2xx／4xx 可信純 error body，明確 incorrect_client_credentials，或送出前缺少 App 設定 | clientConfiguration；refresh nonterminal，保留 bundle |
| 可確定尚未開始 transport 的技術失敗 | knownTechnicalFailure；refresh nonterminal |
| timeout、network failure、5xx、未知 code、malformed／mixed response、其他證據不足回應 | rotationIndeterminate；refresh terminal |
| 送出前取消 | cancelled(beforeRequest)，非 terminal |
| transport 開始後拋取消，且無可信 response | cancelled(afterRequestStarted)；當次取消，cache 非取消 refresh(rotationIndeterminate) terminal |
| 有效 rotation 後 persist 失敗 | 原 persist terminal policy |
| 兩次成功 rotation／persist 後 access token 仍過期 | 既有本地 refresh exhaustion，nonterminal；保留最後 bundle，後續可再 refresh |

分類優先序：先排除 5xx／malformed／error 與 token 欄位混合回應，這些一律 rotationIndeterminate，即使含已知 OAuth code；只有 2xx／4xx 的可信純 error body 才分類 bad_refresh_token／incorrect_client_credentials。3xx 與其他證據不足 status 亦為 indeterminate。HTTP 401／403 單獨不足以判定重新授權。afterRequestStarted 不證明遠端收到 request；未知 error-only JSON 不證明未 rotation。Terminal 保留 store，兩入口先檢查終止錯誤，不再 restore／fetch／save、不交付舊 snapshot。恢復只由外部保存新授權 bundle 後建立新 provider，本 topic 不交付登入 API。

## Cancellation precedence

某 caller 取消不取消 shared refresh。已有可信 response 時先解析，bad_refresh_token／incorrect_client_credentials 仍決定 provider 狀態；有效 pair 仍 persist 再 publish，不用 Task.isCancelled 覆蓋 response。只有 transport 取消且沒有可信 response 才採 afterRequestStarted／indeterminate cache。GraphQL 在 caller await boundary 保持 cancellation 優先，未取消 waiter 取得 shared task 的實際結果。

## 保留與 supersede

保留 expiry-first、single-flight、version／stale recovery、persist-before-publish、persist failure terminal、401-only 最多重送一次、不預檢 refreshTokenExpiresAt、兩次 expired-rotation exhaustion 上限與 nonterminal 例外。新 topic supersede 原 any Error fetcher signature，以及所有 fetch failure 一概允許再次 refresh 的 blanket policy；不改歷史 topic artifacts。

## 工具與圖表

責任圖由 architecture-canvas 更新既有 scene／index。Archify 新增 lifecycle v7，保留 v1–v6，完成 showcase validation／deliver／visual evidence 後才更新 canonical links。作者繁中；Viewer 固定 UI／html lang fallback 英文，不發布 artifact.cafe。

Graphify：repo 無 usable graph，採 bounded source fallback，不 build；如提供既有 graph則驗 revision／freshness，query budget 1500，重要 edges source verify，每 CLI 設 GRAPHIFY_NO_AUTO_REFRESH=1，不安裝／extract／改設定。

PR Lens：固定 0.11.0，只用真實 bounded diff／必要 unchanged neighbors／file refs，repo 外 per-topic scratch，validate／render、讀 manifest，不 install／analyze／server／upload／publish。目前 config absent 使用 --no-config；若已有 config唯讀套用。記真實 commit SHAs；dirty diff 另記 actual SHA／hash，不捏造 head commit。
