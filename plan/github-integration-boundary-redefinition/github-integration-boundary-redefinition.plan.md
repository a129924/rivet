# GithubIntegration Boundary Redefinition

## Goal

完成 `GithubIntegration` 由 Supporting BC 重新定義為 shared GitHub-specific integration module 的正式 planning artifacts，並在 planning review 後交付受限的文件與 architecture-canvas boundary correction。

## Non-Goal

不實作 runtime module、package、target、public API、GitHub adapter、authentication、schema、REST／GraphQL policy、retry／rate-limit policy、dependency rewiring 或 domain behavior；不處理 PR #17 的 code、review comment、merge 或 release。

## In-Scope

- 產出本 topic 四份 planning artifacts，記錄 inventory、分類、target boundary、風險與驗收。
- 將 PR #17／`github-integration-auth-boundary` 的 Supporting BC 架構決定標示為 superseded，僅保留為 traceability；其 pending gates 不構成本 topic 前置條件或 blocker。
- 在 planning review 通過後，修正 active architecture documentation 與 Bounded Context Map，使其表達 BC-local adapter → `GithubIntegration` → GitHub API 的方向。
- 圖表以 architecture-canvas 製作、繁體中文作者內容、validate/build 驗證，且不得發布 artifact.cafe。

## Out-Of-Scope

- 新增 `GithubIntegration` runtime source、SwiftPM manifest／target、concrete client、DTO、GraphQL operation、REST endpoint 或 authentication implementation。
- 對 `RivetHTTPClient`、PR Inbox、PR Reader source、package／build configuration、測試、schema 或現有 API 進行任何修改。
- 集中 Pull Request、Review、Repository、Issue 或 Workflow 語意到 global `GithubService`，或建立 shared domain model。

## ReadOnly

- `RivetHTTPClient`、根 manifest、所有 runtime source、測試、build configuration 與 PR Reader GraphQL schema snapshot。
- `docs/github-api/` 的 capability-reference content，惟 catalog introduction 例外。
- PR #17／`github-integration-auth-boundary` 的既有 artifacts 與相關歷史資料；僅作 supersession traceability。

## Written

- `analysis/github-integration-boundary-redefinition/requirements.md`
- `analysis/github-integration-boundary-redefinition/technical-spec.md`
- `plan/github-integration-boundary-redefinition/github-integration-boundary-redefinition.plan.md`
- `plan/github-integration-boundary-redefinition/github-integration-boundary-redefinition.step.md`

## Modify

僅在 documentation delivery 時修改 active long-lived architecture documentation、PR Inbox／PR Reader BC boundary wording、`docs/github-api/README.md` 的 catalog introduction，以及 Bounded Context Map scene／generated artifact；`docs/github-api/` 其餘 catalog content 維持 ReadOnly。具體範圍依 technical spec 的 Documentation Delivery Contract。不得修改 runtime 或歷史 artifacts。

## Deleted

無。舊 Supporting BC 決定與 PR #17 保留可追溯紀錄；本 topic 不對其 pending gates 或其他歷史狀態執行操作。

## Implementation

1. 由 Plan-Creator 建立四份同 slug artifacts，並由獨立 Plan-Reviewer 檢查 scope 與 contract consistency。
2. Implementer 僅進行 documentation 與 architecture-canvas boundary correction：`GithubIntegration` 只承擔 shared GitHub technical mechanisms；各 BC Infrastructure Adapter 擁有 GitHub DTO／node translation、failure mapping 與 business meaning。
3. Tester 執行受限驗證：architecture-canvas validate/build 與 `git diff --check`。
4. Reviewer 驗證文件、canvas、dependency assertions 與 scope isolation；任何 scope／contract／workflow drift 均退回對應 owner。
5. Human 在 Reviewer verdict 後進行終端交付 review；此 review 不以 PR #17 pending gates 為前置條件。

## TestCase

- TC-01：四份 artifacts 存在、使用 `github-integration-boundary-redefinition` slug，且 Goal、Non-Goal、scope matrix、inventory、分類與終端 human review 一致。
- TC-02：文件不再將 `GithubIntegration` 表示為 Supporting BC，並對 PR #17／舊 topic 保有 explicit supersession traceability。
- TC-03：canvas 清楚呈現 BC Infrastructure Adapter → `GithubIntegration` → GitHub API；不呈現 `GithubIntegration` → BC 或 Domain／UseCase／Application Port → `GithubIntegration`。
- TC-04：canvas 通過 architecture-canvas validate/build，作者內容為繁體中文，且未發布至 artifact.cafe。
- TC-05：allowed-path review 確認沒有 runtime source、package／target、adapter、schema、authentication flow 或 REST／GraphQL policy 變更。
- TC-06：`git diff --check` 通過；文件不將 `RivetHTTPClient` 表示為 `GithubIntegration` implementation，亦不宣稱未實作 API。

## Assumptions

- `GithubIntegration` 為此正式 topic 所鎖定的 future shared-module boundary 名稱；本 topic 不決定其檔案路徑或 runtime type 名稱。
- PR #17／舊 topic 僅作 supersession traceability；其 pending gates 不影響本 topic 的 routing、delivery 或終端 human review。
