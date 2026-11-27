# GitHub PR 檔案已讀寫入需求

Topic 為 `github-pr-file-viewed-write`。Human 核准 Viewed、Thread、Merge 的對話版計畫與交付順序。本輪先在獨立工作樹交付 Viewed。已認證的套件內呼叫端能對指定 PR 中一個已核對的檔案明確標記或取消已讀，並取得 GitHub 已確認、未送出、明確拒絕或結果待核對的回報。 [技術規格](technical-spec.md) · [執行計畫](../../plan/github-pr-file-viewed-write/github-pr-file-viewed-write.plan.md)

## 驗收

- 呼叫端負責取得已核對的 PR node ID 與檔案原始路徑。已知檔案清單換版時先重新核對。現有 Files Viewed 查詢提供逐檔三態，套件介面沒有交付 PR node ID。Adapter 直接執行呼叫端選擇的動作，原樣傳送路徑。 [PR Reader 的 Files Viewed 契約](../../docs/architecture/bounded-contexts/pr-reader.md#github-graphql-files-viewed-讀取)
- 無效輸入與送出前取消均回報零次 mutation。兩種有效動作各送對應 GraphQL mutation。同一 PR 的有效收據確認 GitHub 接受操作。若呼叫端需要確認當下逐檔三態，由既有 Files Viewed 讀取。 [GitHub markFileAsViewed](https://docs.github.com/en/graphql/reference/pulls#markfileasviewed) · [GitHub unmarkFileAsViewed](https://docs.github.com/en/graphql/reference/pulls#unmarkfileasviewed)
- 明確遭拒與結果待核對有不同的回報。送出後收據空缺、目標不符或中斷且無足夠證據時回待核對，由呼叫端決定後續讀取。這兩個 mutation 只接受 PR ID 與路徑作為目標，前置核對到寫入之間仍可能換版。

## 交付邊界

Viewed 建立獨立套件內寫入 target 和離線產碼入口。Thread 與 Merge 各待前一組整合至 `dev` 後開始實作。產品 UI、WebView、本機同步、批次寫入及真人遠端寫入驗收均在本輪範圍外。PR Reader 維持唯讀，既有憑證、REST review submission 及 GraphQL transport 契約沿用。 [Rivet 設計原則](../../docs/design-principles.md) · [PR Reader](../../docs/architecture/bounded-contexts/pr-reader.md)
