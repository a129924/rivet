# GitHub API Endpoint Catalog — Technical Specification

## Locked Decisions

- Topic slug 固定為 `github-api-catalog`。
- 長期 API 參考資料位於 `docs/github-api/`；使用一個索引與六份 endpoint family 文件，不為每一條 endpoint 產生獨立檔案。
- 每個 operation 都必須有：產品狀態、API protocol、operation、必要輸入、主要輸出（含適用的成功 status 與空 response body）、分頁或上限、認證／權限注意事項、限制，以及指向該 operation 的官方來源。
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
| `graphql-pr-state.md` | checks、files viewed、review threads、review/merge state |
| `graphql-write-actions.md` | viewed、thread resolution、merge mutations |
| `rest-notifications-local-state.md` | notification thread 與 local last-seen boundary |

## Content Rules

- endpoint path 使用 GitHub 官方 placeholder，例如 `{owner}`、`{repo}`、`{pull_number}`；GraphQL 使用正式 operation 或 field 名稱。
- REST 內容區分 Pull requests、Issues comments、Pull request review comments 與 Pull request reviews，避免把三種 comment 混為同一資源。
- `viewerViewedState` 是 GitHub API 的遠端 PR file 資料；本 catalog 不定義本機持久化、同步或 Rivet UI 的狀態採用規則。
- PR files 的 REST endpoint 記錄 3,000 files 上限；GraphQL connections 記錄 cursor 分頁，REST list endpoints 使用官方 query 名稱 `page` 與 `per_page`。Notifications 的 `per_page` 上限為 50。
- GraphQL PR state query 必須明示 PR 的定位路徑與 `owner`、`name`、`number` 輸入；Checks 採 `PullRequest.statusCheckRollup`，並記錄其 `contexts` connection 的輸出與 cursor 分頁；`files` 亦須明示同樣的 traversal。
- 只在取得 `reviewThreads` 時以 GraphQL thread comments 作 inline content source；REST inline comments 是不取得 thread 時的替代 source，兩者不得串接為重複 feed。
- 寫入 operation 除 token／repository access 外，必須記錄可由官方欄位或 endpoint reference 支持的 capability／permission gate、成功 payload，以及適用的 SHA 行為。
- Checks 的 union output、巢狀 GraphQL connection、inline review comment 定位、outdated comment 原始位置、notification conditional polling 與 merge method gate，都必須記錄必要欄位或輸入；不得以 aggregate state 或泛稱的 cursor 取代。
- Read／write operation 的 response 與 nested content source 必須記錄可供後續 Adapter 讀取的主要欄位；GraphQL pagination 必須明示 window、`hasNextPage`、`endCursor` 與後續 `after` 的關係。
- REST Search 必須使用官方必填 query parameter 名稱；mutation 官方來源必須能分別追溯 operation payload 與 input。
- REST list／search operation 的 pagination 必須記錄實際後續頁參數及 Link header traversal；條件必填的 inline comment 定位欄位不得標為單純 optional。
- API schema 的 nullability、REST response required set 與官方 HTTP status 必須如實記錄；原因推論、failure mapping 與 fallback 仍留給後續 implementation topic。已標示 closing-down 的定位欄位不得作為新整合的首選。
- REST root response metadata 與 nested output 的 nullable／可能缺席 contract 都必須列入後續 Adapter 可讀取的主要輸出；不得將官方 schema 未指定的成因當作 API 事實。
- GraphQL nested comment node 的 nullable fields 必須逐一記錄；REST component 名稱本身不等同於 schema 的 nullable 宣告。
- REST nullable 必須區分 schema 的 `nullable` 與未列於 `required` 的可能缺席；不得把後者或 component 名稱推論成 nullable。Submit Review 的 `comments` input 只列該 operation 官方定義欄位，不暗示 `in_reply_to` 支援。
- REST inline review comment 的 `original_position` 與 `in_reply_to_id` 必須依 `pull-request-review-comment` required set 標記為可能缺席；不得將可能缺席改寫為 nullable 或推論其原因。
- 巢狀 GraphQL connection 必須逐層記錄其自身的 `hasNextPage`、`endCursor` 與下一次同層 `after`；可選本機 last-seen identity 必須保留 API source，且不得把 REST 與 GraphQL identifier 的對應當作既定事實。
- Mutation payload 的資源欄位與 REST list response 的欄位若在官方 schema 明示 nullable，必須逐一標記；不得僅以「成功結果」或一般重要欄位掩蓋其 nullable contract。
- GraphQL mutation 的 operation field 與其 payload resource field 若皆未標 non-null，必須逐層標記 nullable；不得只記錄 payload 的內層資源欄位。
- GraphQL connection field 若未標 non-null，必須在讀取其 `nodes` 或 `pageInfo` 前記錄外層 nullable；REST field 未列於 required set 時則標為可能缺席。Query parameter 的官方預設值與 filter 語意亦必須保留，但產品是否採用特定 filter 留給後續 topic 決定。
- GraphQL pagination 的 `endCursor` 與 connection nodes list／element 若未標 non-null，必須逐層記錄 nullable；只在 `hasNextPage` 為 true 且 cursor 存在時才建構下一頁的 `after`。
- Checks 與 changed-files connection 的 nodes list／element 均須明確標示 nullable；只有非 null node 才可選取 `__typename` 的 union fragment 或 changed-file 欄位。
- Review-thread connection 的 nodes list／element 均須明確標示 nullable；只有非 null node 才可讀取 review thread 欄位，並再依各欄位自己的 contract 判空。
- 外層 `reviewThreads` 與每個巢狀 `comments` connection 都必須各自記錄 1–100 window、自己的 `hasNextPage`／`endCursor` 與同層 `after`；REST GET operation 則必須記錄正常 `200 OK` response，適用時另記錄官方列出的 conditional `304 Not Modified`。
- REST inline review comment 的 `line`、`side` 與 `original_line` 未列於 required set 時，必須標記為可能缺席並與 nullable 區分；所有 REST list operation 均須記錄 Link header traversal。
- REST changed-files 與 notifications list 的 operation metadata 必須明列依 response `Link` header 的 next URL 取得下一頁；只列 `page`／`per_page` 不足以滿足 list traversal contract。
- Capability Index 的每一列只能對應一個產品狀態；REST changed-files 與 GraphQL Files Viewed state 必須分列，避免將後續唯讀 GraphQL state 誤列為 MVP。
- Cross-repository Issues Search 的 `issue-search-result-item.user` 必須標為 nullable，並直接連結 GitHub REST OpenAPI schema；不得把其他 REST response 的 `user` contract 類推為相同結果。
- Repository PR list 與 PR detail 必須各自標記 `head.repo` 為 nullable，並直接連結各自的 GitHub REST OpenAPI schema；不得以外層 `head` 存在推論其巢狀 repository 必定存在。
- 只在官方 reference 已確認時列出 qualifier、enum、欄位或 token 限制；否則標為不採用或待未來 topic 驗證。

## File Impact Contract

### ReadOnly

- `docs/design-principles.md`、`docs/product.md`
- `docs/architecture/README.md` 與三份 Bounded Context 文件
- 既有 `analysis/` 與 `plan/` artifacts
- GitHub 官方 REST／GraphQL reference

### Written

- `analysis/github-api-catalog/requirements.md`
- `analysis/github-api-catalog/technical-spec.md`
- `plan/github-api-catalog/github-api-catalog.plan.md`
- `plan/github-api-catalog/github-api-catalog.step.md`
- `docs/github-api/` 及其七份 catalog Markdown 文件

### Modify

- `README.md`：新增 GitHub PR API catalog 的 first-read 文件導覽。

### Deleted

無。
