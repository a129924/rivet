# 既有 Bearer Authorization 入口共用規則：需求

## Mission 與成功條件

將既有同步 Request Authorization 與 Apollo GraphQL Authorization 統一經由 `BearerAuth`，底層共用 `AuthorizationHeader` 的 Token 驗證、Bearer formatting 與 Authorization replacement。相同 Token 與等價 Headers 必須產生一致的 HTTP Authorization 語意；非法 Token 必須在該 Request 送出前失敗。

- 合法 Token 產生單一 Authorization，保留其他 Headers 與 Request 資料；重複套用具 idempotency，原始輸入不變。
- Token 文法、formatting 與 replacement 各有單一實作來源。
- 非法 Token 回報明確且不含 Token 的錯誤，不因本地驗證失敗啟動 recovery。
- 保留 `BearerAuth` diagnostics／reflection redaction，以及 GraphQL snapshot、取消、HTTP 分類、401 recovery 與既有 retry 行為。

## 範圍與已確認決策

本次包含 `BearerAuth` 初始化契約、新 Headers overload、既有 Request overload 的委派、GraphQL 接入與錯誤映射、必要測試及長期契約文件。

1. `BearerAuth.init(token:) throws(AuthorizationHeaderError)`；接受 source-breaking 變更。`RequestAuthorization.applying` 維持 nonthrowing。
2. 新增 public、nonthrowing `BearerAuth.applying(to headers: [String: String]) -> [String: String]`。同步 Request 與 GraphQL 入口均經此 overload。
3. 一致性按 HTTP 語意驗收；保留 `HTTPHeaders` 的 lowercase storage 與 Foundation Header representation。
4. 僅 `GitHubGraphQLHTTPInterceptor.swift` 新增 `RivetHTTPClient` import；新增 token-free internal `.invalidAuthorizationToken`。
5. `AuthorizationHeader` public API、Token 文法與錯誤維持不變，replacement 使用唯一 internal nonthrowing helper。

上述設計已由人類確認，不因落檔重新開啟決策。同步 initializer 的相容性變更須記錄於長期文件。

## 排除範圍與回退

REST Client、Token acquisition／refresh／expiration／persistence、401 recovery 或取消策略重新設計、其他認證方案、統一 Client／Transport，以及新增 BC、Protocol、Factory、Middleware Framework 或 public validated-token type 均不在本次範圍。

本次沿用 BC 外既有 `RivetHTTPClient` 與 `GitHubIntegration` 責任；無持久化資料遷移，回退以本 topic 的變更為單位。

## 依據與追溯

既有 `analysis/authorization-header/technical-spec.md` 將 consumer migration 留給後續 topic；現有 `AuthorizationHeader` 為 public throwing 純轉換，`RequestAuthorization` 為同步 nonthrowing protocol，GraphQL 僅對 `.httpStatus(401)` recovery。本次執行設計見 [technical-spec.md](technical-spec.md)，受限執行與驗收見 [plan](../../plan/bearer-authorization-shared-rules/bearer-authorization-shared-rules.plan.md)。
