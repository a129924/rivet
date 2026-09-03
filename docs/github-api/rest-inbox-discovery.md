# REST Inbox Discovery

最後官方校驗：2026-09-02。

## Repository Pull Request List

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續唯讀 |
| Operation | `GET /repos/{owner}/{repo}/pulls` |
| 用途 | 取得指定 repository 的 PR；預設只回傳 open PR。 |
| 重要 query | `state`, `head`, `base`, `sort`, `direction`, `per_page`, `page` |
| 重要欄位 | number、title、body、user、head、base、state、draft、`_links` |
| 分頁 | `per_page` 最大 100；依 Link header 取下一頁。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [List pull requests](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests) |

此 endpoint 適合 repository 範圍瀏覽，不決定「等待我 review」的 Inbox membership。

## Cross-Repository Review Requests

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /search/issues` |
| 必要 query | `q=is:pr is:open user-review-requested:@me` |
| 用途 | 尋找直接要求目前使用者 review 的 open PR。 |
| 重要欄位 | items 中的 number、title、state、user、repository_url、pull_request、updated_at |
| 分頁與上限 | `per_page` 最大 100，使用 `page` 取得後續頁，並依 Link header 的 next URL traversal。單一 Search query 最多提供 1,000 筆結果。Search API 另有 rate-limit 限制，實作時必須處理 `incomplete_results` 與分頁；超過上限時的切分 query 或不完整結果 UX 留給未來 implementation topic 決定。 |
| 認證／權限 | 此 catalog 固定使用代表目前使用者的 `@me`，因此必須以有效 token 呼叫；查詢 private resources 時 token 另須具有 repository access。多資源查詢只回傳 token 可存取的資源。 |
| 官方來源 | [Search issues and pull requests](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests)、[REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)、[search access errors](https://docs.github.com/en/rest/search/search#access-errors-or-missing-search-results) |

`review-requested:USERNAME` 用於指定使用者；`user-review-requested:@me` 是「直接要求我 review」的明確 qualifier。team review request 不是本 MVP Inbox 的既定 membership 規則。

## Sources

- [List pull requests](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests)
- [Search issues and pull requests](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests)
- [Filtering and searching issues and pull requests](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/filtering-and-searching-issues-and-pull-requests)
