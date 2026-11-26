# PR Reader 行內留言來源選擇需求

Topic 為 `pr-reader-github-inline-review-source-selection`，Primary BC 為 PR Reader。原查證基線 `97e3db8` 含 [GraphQL 審閱對話 #102](https://github.com/a129924/rivet/pull/102) 與 [REST 行內審閱留言 #100](https://github.com/a129924/rivet/pull/100)。執行基線為本機及遠端 `dev` 的 `10610d0`，已包含 Checks。

## 使用情境與結果

套件內呼叫端持有指定 PR 的 `ReaderPullRequestID` 及兩個已就緒的 GitHub clients，需要一份供後續快照組裝使用的行內留言。優先採用 GraphQL 的完整審閱 threads。只有 GraphQL 回 `.unavailable` 且呼叫端仍有效時，才從 REST 取得同一 PR 的完整平面留言。任一來源的完整空結果都是成功。 [Rivet 來源選擇規則](../../docs/github-api/rest-discussion-reviews.md)

GraphQL 結果保留分組、各層原序、thread 狀態與既有欄位。REST 結果保留頁次、原序及既有欄位，以成功 case 辨識其平面形態與 thread 狀態缺席。每次只交付一個來源的完整資料或一個 Reader 失敗。GraphQL 的 `.notReadable` 或 `.contentNotRepresentable` 直接返回。切換後的 REST 失敗原樣返回。觀察到呼叫端取消時回 `.unavailable`，停止尚未啟動的 REST 或捨棄晚到結果。 [Reader 失敗契約](../../docs/architecture/bounded-contexts/pr-reader.md#failure-contract)

## 驗收與範圍

`IS01–IS06` 涵蓋 GraphQL 優先、REST 保真、重疊與部分資料隔離、整次失敗、取消及原來源離線回歸。統一由新套件內入口驅動兩個既有來源，以受控回應驗證。完整快照、公開契約、其他來源、Facade／UI／App、真實 GitHub 驗收、寫入及持久化另屬後續工作。

Human 已確認對話版計畫並授權獨立 feature worktree 實作。驗收與獨立審查無重大問題時，依 topic 做單一 commit、推送及開啟以 `dev` 為目標的 Draft PR，再交 Human Review。 [技術規格](technical-spec.md) · [執行計畫](../../plan/pr-reader-github-inline-review-source-selection/pr-reader-github-inline-review-source-selection.plan.md)
