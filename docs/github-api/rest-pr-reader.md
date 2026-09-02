# REST PR Reader

最後官方校驗：2026-09-02。

## Pull Request Detail

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /repos/{owner}/{repo}/pulls/{pull_number}` |
| 用途 | 取得單一 PR 的背景與 refs。 |
| 重要欄位 | title、body、user、state、draft、head、base、mergeable、merged、commits、changed_files |
| 限制 | `mergeable` 可能暫時為 `null`；詳細 merge gating 應使用 GraphQL PR state。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [Get a pull request](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request) |

## Changed Files

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | `GET /repos/{owner}/{repo}/pulls/{pull_number}/files` |
| 用途 | 取得檔案清單與變更統計。 |
| 重要欄位 | filename、status、additions、deletions、changes、sha、previous_filename、patch |
| 分頁與上限 | page/per-page；此 endpoint 的回應最多 3,000 files。 |
| 認證／權限 | Fine-grained PAT、GitHub App user 或 installation token 需 `Pull requests` repository permission（read）；只取 public resource 時可不認證。 |
| 官方來源 | [List pull requests files](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests-files) |

## Unified Diff

| 項目 | 定義 |
| --- | --- |
| 狀態 | MVP 唯讀 |
| Operation | 同 PR detail endpoint，Accept 為 `application/vnd.github.diff` |
| 用途 | 取得 raw unified diff，供 renderer parse 與呈現。 |
| 注意事項 | diff 是外部表示；parser/rendering 是 PR Reader implementation topic 的責任。 |
| 認證／權限 | 同 Pull Request Detail，因使用相同 endpoint。 |
| 官方來源 | [Get a pull request media types](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request) |

## Sources

- [Get a pull request](https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request)
- [List pull requests files](https://docs.github.com/en/rest/pulls/pulls#list-pull-requests-files)
- [REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)
