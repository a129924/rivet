# GitHub API Endpoint Catalog — Technical Specification

## Locked Decisions

- Topic slug 固定為 `github-api-catalog`。
- 長期 API 參考資料位於 `docs/github-api/`；使用一個索引與六份 endpoint family 文件，不為每一條 endpoint 產生獨立檔案。
- 每個 operation 都必須有：產品狀態、API protocol、operation、必要輸入、主要輸出、分頁或上限、認證／權限注意事項、限制，以及指向該 operation 的官方來源。
- GitHub API 的 version、auth 實作與內部 mapping 不在本 topic 鎖定；參考文件只記錄官方 operation 的當前能力與限制。
- Review、merge、notification 寫入一律標為「後續寫入」，即使 GitHub 官方 API 已支援；非 MVP 但 catalog 保留的讀取 operation 標為「後續唯讀」。
- comment-level last-seen 是「可選本機狀態」；文件只描述 ownership 與 identity，不定義持久化技術或 schema。

## Document Map

| 文件 | API 範圍 |
| --- | --- |
| `README.md` | capability 索引、產品狀態、使用規則與共通限制 |
| `rest-inbox-discovery.md` | repository PR list、跨 repository 的直接 review request search |
| `rest-pr-reader.md` | PR detail、changed files、unified diff |
| `rest-discussion-reviews.md` | conversation comments、inline comments、reviews、提交 review |
| `graphql-pr-state.md` | files viewed、review threads、review/merge state |
| `graphql-write-actions.md` | viewed、thread resolution、merge mutations |
| `rest-notifications-local-state.md` | notification thread 與 local last-seen boundary |

## Content Rules

- endpoint path 使用 GitHub 官方 placeholder，例如 `{owner}`、`{repo}`、`{pull_number}`；GraphQL 使用正式 operation 或 field 名稱。
- REST 內容區分 Pull requests、Issues comments、Pull request review comments 與 Pull request reviews，避免把三種 comment 混為同一資源。
- `viewerViewedState` 是 GitHub API 的遠端 PR file 資料；本 catalog 不定義本機持久化、同步或 Rivet UI 的狀態採用規則。
- PR files 的 REST endpoint 記錄 3,000 files 上限；GraphQL connections 記錄 cursor 分頁，REST list endpoints 使用官方 query 名稱 `page` 與 `per_page`。Notifications 的 `per_page` 上限為 50。
- 只在官方 reference 已確認時列出 qualifier、enum、欄位或 token 限制；否則標為不採用或待未來 topic 驗證。

## File Impact Contract

### ReadOnly

- `README.md`、`docs/design-principles.md`、`docs/product.md`
- `docs/architecture/README.md` 與三份 Bounded Context 文件
- 既有 `analysis/` 與 `plan/` artifacts
- GitHub 官方 REST／GraphQL reference

### Written

- `analysis/github-api-catalog/requirements.md`
- `analysis/github-api-catalog/technical-spec.md`
- `plan/github-api-catalog/github-api-catalog.plan.md`
- `plan/github-api-catalog/github-api-catalog.step.md`
- `docs/github-api/` 及其七份 catalog Markdown 文件

### Modify / Deleted

無。不得修改或刪除既有 tracked files。
