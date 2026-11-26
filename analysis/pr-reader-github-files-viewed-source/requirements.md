# 讀取單一 PR 的 Files Viewed 狀態｜需求

Topic 為 `pr-reader-github-files-viewed-source`。Primary BC 為 PR Reader。Human 已確認對話版執行計畫，並授權在獨立 feature worktree 實作和依條件交付。草案查證基線為 `5127b5dcbcf38d0034739bb00ba530420612b570`。執行基線為 `dev` 的 `41fdb0e30e2ecc4edc68e4ac944ace32ffe2592d`，已納入獨立的審閱與合併狀態讀取。 [原查證基線](https://github.com/a129924/rivet/commit/5127b5dcbcf38d0034739bb00ba530420612b570) · [執行基線](https://github.com/a129924/rivet/commit/41fdb0e30e2ecc4edc68e4ac944ace32ffe2592d) · [PR #105](https://github.com/a129924/rivet/pull/105)

## 目標

持有指定 PR 識別與可讀取其 repo 的 GitHub GraphQL client 的 Reader 呼叫端，可以在套件內取得完整、有序的變更檔案清單。每筆檔案保留原始路徑、變更類型、增刪數與目前 GitHub viewer 的逐檔閱讀狀態。三種狀態分別表示尚未檢視、已檢視、上次檢視後又有新變更。 [Rivet API Catalog](../../docs/github-api/graphql-pr-state.md#changed-files-and-viewed-state) · [GitHub FileViewedState](https://docs.github.com/en/graphql/reference/pulls#fileviewedstate)

## 驗收條件

1. 正式入口交付檔案頁次及頁內原序。檔案路徑在本次結果內唯一。零筆可確認時回傳成功空清單。
2. 每個檔案交付六種已知變更之一、原始路徑、增刪數和可區分的 viewed 三態。
3. 跨頁核對 PR、head、游標及筆數。任一頁無法取得或無法確認完整時，回傳單一 Reader 失敗並捨棄所有累積結果。
4. 可確認的 PR 缺席或存取拒絕回 `.notReadable`。取消及完整性無法確認回 `.unavailable`。已解碼的必要檔案內容或狀態無法保真映射時回 `.contentNotRepresentable`。 [PR Reader 失敗契約](../../docs/architecture/bounded-contexts/pr-reader.md#failure-contract)

## 範圍

讀取透過既有 GitHub.com GraphQL client 與 Bearer 認證，並由 Reader Infra 擁有逐檔資料、狀態映射與失敗契約。驗收點為套件內來源入口。標記／取消已讀、本機同步、持久化、UI／WebView、完整快照組裝、REST fallback、逐檔 patch 或 raw unified diff 均在本次範圍外。

[技術規格](technical-spec.md) · [執行計畫](../../plan/pr-reader-github-files-viewed-source/pr-reader-github-files-viewed-source.plan.md)
