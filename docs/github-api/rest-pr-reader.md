# REST PR Reader

最後官方校驗：2026-09-03。

## Pull Request Detail

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /repos/{owner}/{repo}/pulls/{pull_number}` |
| 用途 | 取得單一 PR 的背景與 refs。 |
| 成功結果 | `200 OK` 與 PR response；conditional request 時 GitHub 另列 `304 Not Modified`。 |
| 重要欄位 | title、body（nullable）、user、state、draft（可能缺席）、head、base、mergeable、merged、commits、changed_files |
| 限制 | `mergeable` 可能暫時為 `null`；詳細 merge gating 應使用 GraphQL PR state。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [Get a pull request](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request)、[GitHub REST OpenAPI `pull-request` schema](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json)（`body` 為 nullable，`draft` 未列於 `required`） |

## Changed Files

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /repos/{owner}/{repo}/pulls/{pull_number}/files` |
| 用途 | 取得檔案清單與變更統計。 |
| 成功結果 | `200 OK` 與 changed-files list response。 |
| 重要欄位 | filename、status、additions、deletions、changes、sha、previous_filename、patch；`previous_filename` 與 `patch` 都可能缺席，不能當作必填字串。 |
| 分頁與上限 | `page`／`per_page`；依 response `Link` header 的 next URL 取得下一頁。此 endpoint 的回應最多 3,000 files。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [List pull requests files](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests-files)、[GitHub REST OpenAPI `diff-entry` schema](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json)（`previous_filename` 與 `patch` 未列於 `required`） |

## Unified Diff

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | 同 PR detail endpoint，Accept 為 `application/vnd.github.diff` |
| 用途 | 取得 raw unified diff，供 renderer parse 與呈現。 |
| 成功結果 | `200 OK` 與 unified diff response；conditional request 時 GitHub 另列 `304 Not Modified`。 |
| 注意事項 | GitHub 對同 endpoint 列出 `406 Unacceptable`。本 catalog 不推論該 status 的原因，亦不定義 failure mapping 或 fallback；parser／rendering 與後續處理是 PR Reader implementation topic 的責任。 |
| 認證／權限 | 同 Pull Request Detail，因使用相同 endpoint。 |
| 官方來源 | [Get a pull request media types](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request) |

## Sources

- [Get a pull request](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request)
- [List pull requests files](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests-files)
- [REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)
- [GitHub REST API description](https://github.com/github/rest-api-description/blob/main/descriptions/api.github.com/api.github.com.json)
