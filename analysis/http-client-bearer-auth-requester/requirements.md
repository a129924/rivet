# HTTP Client Bearer Auth Requester：需求

## Goal

在 `RivetHTTPClient` 提供 GitHub-free、同步且無副作用的 Bearer request transformation。呼叫端先套用 authorization，再將轉換後的 request 交給既有 bare `Requester` 發送；既有 HTTP execution pipeline 與 typed-throws surface 維持不變。

建議 branch 名稱為 `feat/http-client-bearer-auth-requester`。此為命名建議；本 topic 不定義或執行 Git 操作。

## Non-Goal

- 不建立 authenticated requester、authentication flow 或 credential lifecycle。
- 不使用或修改 `AuthFlow`、既有 `Auth` protocol 或 `AuthRequester`。
- 不處理 token acquisition、OAuth、PAT、Keychain、refresh、401 recovery、retry 或 request replay。
- 不引入 GitHub 型別、token-source protocol、token provider bridge、`BearerRequester`、untyped `throws`，或與 `GitHubAccessTokenProvider`／`GitHubCredentialError` 的相容性設計。
- 不修改 `Requester`、`HTTPClient`、`Transport`、URLSession 或它們既有的 typed-throws surface。
- 不修改 architecture／Bounded Context 文件或產生圖；只有實作後證實長期 architecture truth 改變時，才由獨立 topic／明確授權處理 writeback。

## In-Scope

- 新增 GitHub-free `RequestAuthorization` contract 與 `BearerAuth` implementation。
- `BearerAuth` 以 `String` token 初始化，產生含 `Authorization: Bearer <token>` 的新 `HTTPRequest`。
- 使用既有大小寫不敏感 `HTTPHeaders.authorization` setter 覆寫既有 Authorization value，並保留 URL、method、body 與所有其他 headers。
- 呼叫端明確執行 `auth.applying(to: request)` 後，再將回傳值交給既有 `requester.execute(...)`；發送責任不移轉。
- 新增指定的 request transformation tests，並以既有完整 package test suite 驗證 bare request execution 無回歸。

## Out-Of-Scope

- 任何 Bearer-specific token acquisition failure、transport delegation failure、network side effect 或 typed-throws 測試。
- Bearer 以外的 authentication scheme、endpoint、DTO、BC failure mapping、GitHub API client adoption。
- logs、diagnostics、public metadata 或 error payload 中保存／包裝 token；本 topic 不新增這些 surface。
- 任一未列於本 topic implementation manifest 的 source、test、manifest、package target、adapter、documentation 或 diagram path。

## Success Criteria

- external caller 可用 `any RequestAuthorization` 對 `HTTPRequest` 套用 `BearerAuth`，並取得新的 request value。
- 回傳 request 的 Authorization 值精確為 `Bearer <token>`；大小寫不同的既有 Authorization value 僅被該值取代一次。
- 輸入 request 保持不變；轉換後的 URL、method、body 與非 Authorization headers 不變。
- 既有 bare `Requester`／HTTP execution 行為不會自動取得或加入 authorization header，且既有 typed-throws contract 不變。
- token 不出現在本 topic 新增的 log、diagnostics、public metadata 或 error payload；`BearerAuth` 本身不建立這些 surface。

## Swift Implementation Artifact Manifest

### ReadOnly

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPRequest.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/HTTPHeaders.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Requester.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/HTTPClient.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/Transport.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/Auth.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/AuthRequester.swift`

這些 existing references 僅供理解與 regression verification；不可因本 topic 寫入或調適。

### Written

- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/RequestAuthorization.swift`
- `packages/RivetHTTPClient/Sources/RivetHTTPClient/Request/BearerAuth.swift`
- `packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Request/BearerAuthTests.swift`

### Modify

無。

### Deleted

無。

## TestCase

- TC-01：Bearer header 被注入；不同大小寫的既有 Authorization header 被覆寫。
- TC-02：輸入 request 不變；輸出 request 保留 URL、method、body 與其他 headers。
- TC-03：透過 `any RequestAuthorization` existential 使用 `BearerAuth` 時，得到相同的 transformation 行為。
- TC-04：執行既有完整 `RivetHTTPClient` test suite，確認 bare request execution 無回歸。
