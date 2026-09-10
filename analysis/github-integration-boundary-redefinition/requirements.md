# GithubIntegration Boundary Redefinition：需求

## Goal

將 `GithubIntegration` 鎖定為 Bounded Context（BC）外的 shared GitHub-specific integration module，而非 Supporting BC。完成本決定的現況盤點、正式 planning artifacts，以及後續 documentation 與 architecture-canvas boundary correction 的受限契約。

## 背景與已鎖定決定

- `GithubIntegration` 集中多個 BC 可共用的 GitHub raw transport、authentication、共通 request headers／API version mechanism、GitHub error technical classification 與 shared configuration；它不擁有任何 BC 的 domain meaning 或 shared BC failure contract。
- 此決定 supersede PR #17／`github-integration-auth-boundary` 將 GitHub Integration 定義為 Supporting BC 的架構決定。該 PR 與其 pending gates 僅保留為 supersession traceability，不構成本 topic documentation delivery 的前置條件、blocker 或 human gate。
- `RivetHTTPClient` 是已存在的 generic、GitHub-unaware technical HTTP foundation；本 topic 不改變它。

## In-Scope

- 建立本 topic 的 requirements、technical spec、plan 與 step ledger。
- 盤點目前 GitHub-related assets、依賴方向與舊說法，並以 KEEP／MOVE／SPLIT／REMOVE 分類記錄。
- 在通過 planning review 後，更正長期架構文件與保留的 Bounded Context Map，並退役舊 Supporting BC 主文件及其 authorization boundary canvas。
- 將 GitHub REST／GraphQL raw transport、authentication mechanism、共通 request headers／API version、pagination、rate-limit、retry、GitHub error technical classification 與 shared configuration，記錄為 shared module 的責任類別；endpoint-specific media type、DTO translation 與 technical classification 到 BC failure contract 的 mapping 仍屬各 BC Infra，且不把這些類別誤記為既有 runtime API。

## Non-Goal

- 不建立 runtime module、SwiftPM package／target、public API、adapter、auth flow、schema、REST／GraphQL policy 或 compatibility layer。
- 不搬移 GitHub DTO、改變 BC Port、改寫 dependency、改變 domain behavior，或處理 PR #17 的 code、review comments、commit、push、merge 與 release。
- 不建立集中式、承載 Pull Request／Issue／Review／Workflow 語意的 `GithubService`。

## 成功條件

- 四份 artifacts 使用一致 slug，且完整記錄目標、非目標、inventory、分類、風險、驗收與 human boundary。
- active 長期架構文件與保留圖表明確表達：BC Infrastructure Adapter 可以依賴 `GithubIntegration`；Domain、UseCase、Application Port 不得依賴它；它也不得依賴任何 BC。舊 Supporting BC 主文件與 authorization boundary canvas 不再作為 active architecture truth。
- GitHub DTO／GraphQL node 的 translation、GitHub error technical classification 到 BC failure contract 的 mapping 與 BC business meaning，仍只屬各 BC Infrastructure Adapter；不得形成 shared BC failure contract。
- 圖表以繁體中文、architecture-canvas 驗證後交付，且不發布至 artifact.cafe。

## Human Review Boundary

Human review 位於獨立 Reviewer 完成 documentation delivery verification 之後。此終端 boundary 僅供人類確認交付結果，不授權 runtime implementation，亦不改變 PR #17 作為 superseded 歷史紀錄的定位。
