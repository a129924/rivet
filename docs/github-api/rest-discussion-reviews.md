# REST Discussion & Reviews

最後官方校驗：2026-09-02。

## PR Conversation Comments

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /repos/{owner}/{repo}/issues/{issue_number}/comments` |
| 用途 | 取得 PR 的 issue-level comments；PR 同時也是 Issue。 |
| 重要欄位 | id、body、user、created_at、updated_at、html_url |
| 分頁 | page/per-page。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Issues` 或 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [List issue comments](https://docs.github.com/en/rest/issues/comments#list-issue-comments) |

Rivet catalog composition rule：完整 PR discussion 視圖在需要時組合此 issue-level resource、下列 inline review comments 與 GraphQL review threads；本規則不將單一 endpoint 描述為完整 conversation。

## Inline Review Comments

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /repos/{owner}/{repo}/pulls/{pull_number}/comments` |
| 用途 | 取得 diff 上的 review comments。 |
| 重要欄位 | id、pull_request_review_id、path、line、side、start_line、start_side、commit_id、original_commit_id、body、in_reply_to_id |
| 注意事項 | Rivet mapping 可使用 GitHub comment `id` 作 identity；thread grouping、resolved 與 outdated 見 GraphQL 文件。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [List review comments on a pull request](https://docs.github.com/en/rest/pulls/comments#list-review-comments-on-a-pull-request) |

## Review Summary

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /repos/{owner}/{repo}/pulls/{pull_number}/reviews` |
| 用途 | 取得 PR reviews 的時序與結果。 |
| 重要欄位 | id、user、body、state、commit_id、submitted_at |
| Review state | `APPROVED`、`CHANGES_REQUESTED`、`COMMENTED`、`DISMISSED`、`PENDING`。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [List reviews for a pull request](https://docs.github.com/en/rest/pulls/reviews#list-reviews-for-a-pull-request) |

## Submit Review

| 項目 | 定義 |
| --- | --- |
| 狀態 | 後續寫入 |
| Operation | `POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews` |
| 用途 | 提交整體 review。 |
| 重要輸入 | `event`：`APPROVE`、`REQUEST_CHANGES` 或 `COMMENT`；可帶 `body` 與 comments。 |
| 注意事項 | 不屬目前 MVP，亦不在本 topic 實作。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（write）。 |
| 官方來源 | [Create a review for a pull request](https://docs.github.com/en/rest/pulls/reviews#create-a-review-for-a-pull-request) |

## Sources

- [List issue comments](https://docs.github.com/en/rest/issues/comments#list-issue-comments)
- [List review comments on a pull request](https://docs.github.com/en/rest/pulls/comments#list-review-comments-on-a-pull-request)
- [List reviews for a pull request](https://docs.github.com/en/rest/pulls/reviews#list-reviews-for-a-pull-request)
- [Create a review for a pull request](https://docs.github.com/en/rest/pulls/reviews#create-a-review-for-a-pull-request)
