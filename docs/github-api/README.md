# GitHub PR API Catalog

本目錄是 Rivet 後續 GitHub Integration 實作的外部 API 參考。它不定義 Swift contract、BC data model 或 authentication 實作；那些決策必須留給對應的 implementation topic。

最後官方校驗：2026-09-02（GitHub.com）。

## 產品狀態

- **MVP 唯讀**：符合目前 PR Inbox 與 PR Reader 的產品範圍；本文件只確認 GitHub 官方可提供的資料。
- **後續寫入**：GitHub 已有 API，但產品規範明確延後，不能由本 catalog 視為實作授權。
- **可選本機狀態**：GitHub 沒有等價 viewer state；是否保存、如何保存均留給未來 topic。

## Capability Index

| 能力 | 狀態 | 主文件 |
| --- | --- | --- |
| 指定 repository 的 open PR 列表 | MVP 唯讀 | [REST Inbox](rest-inbox-discovery.md) |
| 跨 repository、直接要求我 review 的 PR | MVP 唯讀 | [REST Inbox](rest-inbox-discovery.md) |
| 我建立的 open PR | MVP 唯讀 | [REST Inbox](rest-inbox-discovery.md) |
| PR 基本資訊、changed files、unified diff | MVP 唯讀 | [REST PR Reader](rest-pr-reader.md) |
| PR conversation、inline comments、reviews | MVP 唯讀 | [REST Discussion & Reviews](rest-discussion-reviews.md) |
| Files Viewed 與變更後失效 | 後續寫入 | [GraphQL PR State](graphql-pr-state.md) |
| Review threads、resolved 與 outdated | MVP 唯讀 | [GraphQL PR State](graphql-pr-state.md) |
| Approve、request changes、resolve/unresolve、merge | 後續寫入 | [REST Discussion & Reviews](rest-discussion-reviews.md)、[GraphQL Write Actions](graphql-write-actions.md) |
| Mergeable、merge state、review decision | MVP 唯讀 | [GraphQL PR State](graphql-pr-state.md) |
| GitHub notification thread | 後續寫入 | [REST Notifications & Local State](rest-notifications-local-state.md) |
| App 內的 comment-level last-seen | 可選本機狀態 | [REST Notifications & Local State](rest-notifications-local-state.md) |

## 共通規則

- REST list endpoints 使用 page/per-page 與 Link header；GraphQL connection 使用 cursor 與 `pageInfo`。不要假設單頁結果完整。
- GitHub REST 的 API version、Accept header 與 token 細節屬 Integration Adapter 的未來實作決策；文件只保留 endpoint 特有的 media type 與限制。
- `viewerViewedState` 是 GitHub API 回傳的遠端 PR file 資料；既有 Swift viewed persistence 是 WebView snapshot-local state。兩者是否同步、Rivet UI 最終採用哪個狀態，留待後續 implementation topic 決定。
- 原稿中的 `review-involves:@me` 未在本次官方 search qualifier 參考中確認，因此不列為可採用 query。

## Official Sources

- [REST Pull requests](https://docs.github.com/en/rest/pulls/pulls)
- [REST Search](https://docs.github.com/en/rest/search/search)
- [Search qualifiers](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/filtering-and-searching-issues-and-pull-requests)
- [GraphQL Pull requests](https://docs.github.com/en/graphql/reference/pulls)
- [GraphQL endpoint and request method](https://docs.github.com/en/graphql/guides/introduction-to-graphql#discovering-the-graphql-api)
