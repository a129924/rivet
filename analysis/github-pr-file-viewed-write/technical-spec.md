# GitHub PR 檔案已讀寫入技術規格

## 套件入口

- 新增 SwiftPM target `RivetPRWriteGitHub`，依賴 `GitHubIntegration`、`Apollo` 和 `ApolloAPI`。依賴由寫入端指向既有技術能力。SwiftPM product 集合維持現狀。新增 `RivetPRWriteGitHubTests`，依賴寫入 target 和上述三項依賴。排除 `GraphQL/Codegen` 下的非 Swift 產碼輸入。
- `PRFileViewedWriter`、`init(client:)` 和 `setViewed(_:)` 採 `package` 可見性。建構子接受已就緒的 `any GitHubGraphQLServing`。入口為 async，接受操作專屬的 `Request`，由 `pullRequestID: String`、`path: String` 及 `Action` 的 `mark`／`unmark` 組成。回傳 `Sendable` 的操作專屬 `Outcome`，表達已接受、未送出（無效輸入或送出前取消）、明確拒絕或待核對。Apollo 型別留在 target 內。
- 驗證 PR node ID 非空且不含空白或控制字元。驗證檔案路徑非空且不含 NUL。將兩者視為原始字串，維持 UTF-8 字面值。PR ID 作不透明值，以精確的 UTF-8 比對收據。路徑無 trim、URL 編碼或解碼、Unicode 正規化。遠端歸屬與文件版本由呼叫端核對。
- 在進入 `perform` 前檢查取消。有效且未取消的動作最多進入 `perform` 一次，直接提交 `markFileAsViewed` 或 `unmarkFileAsViewed`，以 `pullRequestId`、`path` 帶入呼叫端值，只讀取收據的 `pullRequest.id`。沿用現有 Bearer interceptor 和 client 在明確 HTTP `401` 下最多一次的認證復原及重送。Adapter 無新增標頭、額外查詢、重送或協定切換。 [GitHubGraphQLClient](../../Sources/BoundedContexts/GitHubIntegration/GraphQL/GitHubGraphQLClient.swift) · [GitHubGraphQLServing](../../Sources/BoundedContexts/GitHubIntegration/GraphQL/GitHubGraphQLServing.swift)

## 結果核對

| 條件 | 結果 |
| --- | --- |
| 無效輸入或進入 `perform` 前取消 | 未送出，回傳對應原因。 |
| `pullRequest.id` 與請求精確相符，且所有 GraphQL errors 的 path 都與必要收據欄位無關 | GitHub 已接受。 |
| Mutation payload 缺席，且所有 GraphQL errors 都位於該 mutation 的根 field，並一致帶有同一結構化理由 `FORBIDDEN`、`UNAUTHORIZED` 或 `NOT_FOUND` | 明確拒絕。 |
| Client 交付明確終止的認證錯誤 `authenticationRequired`／`invalidAuthorizationToken` 或 HTTP `401` | 明確拒絕。 |
| 其餘無法證明操作結果的回應或錯誤 | 結果待核對。包括空 payload、PR 不符、無足夠證據的 HTTP 狀態、逾時、斷線與進入 `perform` 後僅收到取消。 |

必要收據欄位的完整路徑是 `[mutation 欄位, pullRequest, id]`。GraphQL error 沒有可用 path，或其 path 與必要路徑互為前綴、相等或延伸時，收據無法核對。若 response 同時給出互相矛盾的資料和拒絕訊號，回待核對。拒絕證據依結構化欄位及操作路徑比對。錯誤訊息文字、原始回應與底層錯誤不作為套件結果的一部分。既有 client 可在發現取消時捨棄晚到的回應。Adapter 已收到且可核對的收據仍照收據判定。

## 離線產碼

- 把 `PullRequestFileViewedWrite.graphql` 與 `apollo-codegen-config.json` 放在寫入 target 的 `GraphQL/Codegen/`。Config 獨立明列 operation 檔案，schema namespace 採 `PRWriteGitHubGraphQL`，嵌入 `RivetPRWriteGitHub` 並採 `internal`，operations in schema module，無 test mocks。
- 以已解析的 Apollo iOS `2.1.2` CLI，在暫存的 `Codegen/` 重現輸入。將現有 Reader 的固定 `Schema.graphqls` 唯讀複製至該暫存目錄，SHA-256 為 `a70103efc655a6b81afa69cdbce8b27d90d8202270b19ea54130e95c650047b7`。從該處執行 config，output 為相對 config 的 `../Generated`。產碼沿用 Reader 的 SwiftFormat／SwiftLint 抑制檔頭及結尾 LF 規則。提交全量 Swift 輸出於寫入 target 的 `GraphQL/Generated/`。以同一流程重生後預期逐檔一致。 [Reader 離線產碼](../../docs/architecture/bounded-contexts/pr-reader.md#graphql-schema-再生成)

[需求](requirements.md) · [執行計畫](../../plan/github-pr-file-viewed-write/github-pr-file-viewed-write.plan.md)
