# 單一 PR 的 GraphQL 審閱對話技術規格

## 套件入口與值型別

以 `RivetPRReaderGitHub` 的 `package` 級 `GitHubReviewThreadsSource.init(client:)` 注入 `any GitHubGraphQLServing`。`fetchReviewThreads(for: ReaderPullRequestID) async -> Outcome<[ReaderReviewThread], PRReaderFailure>` 交付完整結果。既有 core `ReaderInlineThread` 語意由套件內結果完整承接，目標與回覆指向保留在套件內型別。

| 值 | 必要欄位與選填 |
| --- | --- |
| Thread | `id`、`path`、file／line 目標、`isResolved`、`isOutdated`、有序留言。保留選填 `line`、`startLine`、`originalLine`、`originalStartLine`。 |
| 留言 | `id`、原始 Markdown `body`、選填作者登入名及 `replyToID`。 |

目標依 `subjectType` 的 `FILE`／`LINE` 判定。行層級即使未提供任何行號也能保留。空正文可交付。作者或回覆合法為 null 時保留缺值。識別與回覆 ID 按來源保留，允許回覆指向目前清單以外，不重建回覆樹。 [GitHub Thread 與 Comment](https://docs.github.com/en/graphql/reference/pulls#pullrequestreviewthread)

## 兩層查詢與完整性

1. 使用 `GitHubPullRequestDetailEndpoint.validateIdentity` 檢查輸入，再限制 `number` 為 `1...Int32.max`。以 GraphQL 變數傳遞識別與不透明游標。
2. 外層從 `repository(owner:name:) { pullRequest(number:) { reviewThreads(...) } }` 讀取每頁 50 個 threads，每個 thread 讀留言首批 20 則。傳入 `after` 前，核對帶回的 `nameWithOwner` 與 requested owner／repository 不區分大小寫相符、PR 編號相符，且 PR 的 repository node ID 與包覆它的 repository 相同。鎖定首個有效回應的 repository 與 PR node ID，後續外層頁面逐一核對。所有回應中的 thread 及留言也核對所屬 PR node ID。
3. 當前頁依序處理各 thread。留言有續頁時，以 `node(id:)` 的 `PullRequestReviewThread` selection 讀取每頁 20 則，核對 node 類型、thread ID 及 PR node ID。每則留言再核對 PR node ID。留言分組使用已核對的 thread connection。清完當前頁所有留言後續讀外層。
4. 每條 connection 獨立追蹤先前游標。`hasNextPage` 為真時，要求此頁非空且 `endCursor` 非空、尚未使用，照原游標值續查。為假時結束，允許終頁游標缺值。拒絕任何重複 thread ID，包含同頁與跨頁，並拒絕同一結果內任何重複留言 ID。依頁次及頁內原序交付。完整性以本次可核對序列為準，允許跨頁狀態在不同時間取得。 [GitHub 分頁](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)

## 失敗與取消

| 條件 | 失敗 |
| --- | --- |
| 無效輸入，且零請求 | `.notReadable`。若已取消，優先交付 `.unavailable`。 |
| `.authenticationRequired` 或明確 HTTP 401。可確認在外層定位缺少 repository 或 PR | `.notReadable`。外層無 errors 且已解碼定位結果為 null 時可確認缺席。 |
| 外層定位的結構化拒絕 | `.notReadable` 僅限所有 errors 均為 `FORBIDDEN` 或 `NOT_FOUND`，且原始完整 path 為 `["repository"]` 或 `["repository","pullRequest"]`。接受原始 `type` 或 `extensions.type`，兩者同在時須一致。 |
| 其餘 GraphQL errors、無法確認的部分回應或無根資料、裸 HTTP 403／其他無法確認 PR 拒絕的狀態、限流、傳輸、`.executionFailed`、續頁 node 缺席或類型不符、身分或游標矛盾、重複 ID | `.unavailable`。 |
| 已解碼且可證實必要資料無法保真，含 null 集合／元素、空白必要 ID 或路徑、未知目標 | `.contentNotRepresentable`。 |
| 取消 | `.unavailable`，優先於晚到成功或錯誤。每次請求前、await 返回後及交付前檢查。 |

沿用 client 的技術錯誤資訊，只使用結構化資訊辨識明確拒絕。每項失敗均捨棄已累積資料。 [GitHub 限流](https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api)

## 官方快照與產碼

從 GitHub Docs 公開的 `https://docs.github.com/public/fpt/schema.docs.graphql` 取得 GitHub.com 官方 SDL，以原始 bytes 替換 `Sources/BoundedContexts/PRReader/Infra/GitHub/GraphQL/Schema.graphqls`。記錄取得來源、日期及 SHA-256，並在驗收後將證據及重生步驟寫回 PR Reader BC 文件。舊 schema topic 帳本保留歷史。2026-11-26 已取得正式快照，取得入口、SHA-256 及離線重生程序記錄於 PR Reader 的長期契約。 [GitHub 公開 schema](https://docs.github.com/en/graphql/overview/public-schema)

將 Apollo CLI 固定於現有 Apollo runtime 的 `2.1.2`，使用該版封存檔的 CLI。配置以 `Schema.graphqls` 與 `ReviewThreads.graphql` 為輸入、以 `embeddedInTarget(name: "RivetPRReaderGitHub", accessModifier: .internal)` 與 `inSchemaModule` 產出 `Generated/` 下的 internal Swift。存入一套可重現的固定程序，對每個生成 Swift 檔案在開頭依固定順序加入 `// swift-format-ignore-file`、`// swiftlint:disable:next blanket_disable_command` 與 `// swiftlint:disable all`。將生成檔收尾統一為一個 LF，符合專案檔尾 hook。用同一程序離線重生至乾淨輸出目錄並比對。 [Apollo Codegen 設定](https://www.apollographql.com/docs/ios/code-generation/codegen-configuration)

將現有 `RivetPRReaderGitHub` 根目錄由 `Infra/GitHub/REST` 擴至 `Infra/GitHub`，加入直接 Apollo／ApolloAPI 依賴並排除 SDL、GraphQL 操作、codegen 設定。在 `RivetPRReaderGitHubTests` 加入 Apollo／ApolloAPI 供受控 session 使用。Human 已授權同步更新 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 `packageDeclaresTheLockedTargetGraph`，限 `RivetPRReaderGitHub` 的來源路徑，以及 `RivetPRReaderGitHub` 和其測試 target 的 Apollo／ApolloAPI 依賴預期。保留原本依據來源 target 依賴推導其測試 target 預期的檢查。利用測試專用的 `GitHubGraphQLServing` 和 Apollo session 提供真實解析及受控 transport，production client 不增設測試入口。 [執行計畫](../../plan/pr-reader-github-review-threads-source/pr-reader-github-review-threads-source.plan.md)
