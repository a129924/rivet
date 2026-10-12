# GitHub authenticated GET foundation — Requirements

## Goal
在 BC 外的 GitHubIntegration 交付 internal GitHub.com authenticated GET execution。與 GraphQL 共用同一 OAuthTokenProvider instance；保存實際使用的完整 TokenSnapshot，以 BearerAuth 和 bare RivetHTTPClient 發送。首次 HTTP 401 才要求 replacement，最多重送原 GET 一次。

## In-Scope
- GET、固定 GitHub API 目的地、redirect 拒絕、raw HTTP response。
- 401-only recovery、完整 snapshot、一次 replay、取消優先、有限不含敏感資料的 technical failure。
- 不需真實 credential 的 interaction 與 transport 驗證。

## Out-Of-Scope / Non-Goal
其他 HTTP method、寫入 replay、endpoint catalog、DTO、BC Port 或 failure mapping、pagination、rate limit、一般 retry、cache、OAuth sign-in／PKCE／Keychain credential adapter、GraphQL 改動、generic HTTP authentication 改動、新 public capability、target 或 product。

## Acceptance
- 驗證目的地先於取 token；Authorization 不送往非 GitHub API 或 redirect 目標。
- 復原收到實際遭拒絕的完整 snapshot；重送保留原 URL、GET、body 與非 Authorization headers，最多兩次 execution。
- 第二次 401 為 authentication-required；403 與其他 status 不 recovery 且 raw response 原樣交付。
- Provider、transport 與取消維持各自語意；client 不建立 refresh state、version decision 或 single-flight。
- E002／E003 是 OAuth 有限依據，不構成本 GET 切片驗收。
