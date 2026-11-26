# 單一 PR 的 GraphQL 審閱對話需求

Topic 為 `pr-reader-github-review-threads-source`。Primary BC 為 PR Reader。規劃與獨立工作樹基線為本機 `dev` 的 `1fcdb2c274e2d0fde5c88e4225e20942650167c3`，已納入 PR #100 的 REST 行內審閱留言來源。本題有獨立的範圍與驗收。 [PR #100](https://github.com/a129924/rivet/pull/100)

## 使用情境與結果

套件內呼叫端持有 `ReaderPullRequestID` 及已就緒且可讀目標 PR 的 GraphQL client。需要取得指定 GitHub.com PR 的有序審閱 threads、每個 thread 的完整留言、留言歸屬與 thread 原始狀態。外層 thread 清單與每個 thread 的留言都可能有續頁。

成功時單次交付完整結果。保留 GitHub 的分組、原序、識別、檔案路徑、檔案或行層級目標、可用行號、`isResolved`、`isOutdated`、原始 Markdown、可用作者及回覆指向。允許合法缺值、空正文及可證實的空清單。隨讀取進行，各頁可反映不同時間點。 [GitHub Review Thread](https://docs.github.com/en/graphql/reference/pulls#pullrequestreviewthread) · [GitHub 分頁](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api)

## 驗收條件

- **RT01 保真與入口。** 由一般套件內 caller import 讀取。可逐筆核對 thread ID、檔案路徑、兩種狀態、目標、行號、留言與原始 Markdown。合法缺值保留，完整空清單成功。
- **RT02 兩層分頁。** 受控回應涵蓋外層兩頁、至少兩個 thread 各自的留言續頁。驗證各層請求、順序、分組及歸屬。
- **RT03 單一失敗。** 指向其他 PR 或 thread、游標無法前進或循環、無法證明完整的部分回應及任一層後頁失敗均只回單一 Reader failure。可確認的 PR 不可讀回 `.notReadable`，限流、取消、傳輸、解碼來源不明及完整性問題回 `.unavailable`，已確認的資料保真問題回 `.contentNotRepresentable`。 [PR Reader 失敗契約](../../docs/architecture/bounded-contexts/pr-reader.md#failure-contract)
- **RT04 重現與回歸。** 官方 SDL、查詢與生成 Swift 可離線重生。用受控 GraphQL 回應驗收，同時執行相鄰 Reader 與 GitHubIntegration 回歸。

## 範圍與確認

GraphQL adapter、operations、schema 與資料映射屬 Reader Infra。後續 topic 處理 REST fallback、來源去重、完整快照與接線。Facade／UI、公開及跨 BC 介面、`PRContentSource`、寫入、持久化及 live 驗收均在本題範圍外。

Human 已選定固定 GitHub 官方公開 SDL 快照、沿用現有 GraphQL client 的錯誤資訊，並核准對話版計畫及在獨立工作樹實作。條件式交付授權與停點見執行計畫。 [技術規格](technical-spec.md) · [執行計畫](../../plan/pr-reader-github-review-threads-source/pr-reader-github-review-threads-source.plan.md)
