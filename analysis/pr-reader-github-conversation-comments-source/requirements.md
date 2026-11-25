# PR Reader 一般討論留言讀取需求

## 目標

Topic `pr-reader-github-conversation-comments-source` 交付一個 PR Reader 套件內入口。呼叫端已確認 PR 身分並持有該 GitHub.com PR 的 `ReaderPullRequestID` 及已認證的 REST client。入口傳回指定 PR 完整、有序的一般討論留言，或一個可區分原因的 Reader failure。後續完整快照組裝可直接採用成功的清單。 [PR Reader 契約](../../docs/architecture/bounded-contexts/pr-reader.md)

## 範圍

- 使用 #91 的一般討論留言端點，驗證後續頁仍屬同一 PR，保留頁次與頁內順序。首次遇到需查核的數字 repository 路徑時，採用 #92 的原 PR 詳情查核方式。 [PR #91](https://github.com/a129924/rivet/pull/91) · [PR #92](https://github.com/a129924/rivet/pull/92)
- 保留每筆留言識別、原始 Markdown 與可用作者。缺席或 `null` 的作者保留缺值。
- 完整空清單回成功 `[]`。無法存取、讀取未完成與必要資料無法保真表達分別使用既有 Reader failure。
- Review 摘要、inline comments／threads、Changed Files 行為變更、Raw Unified Diff、完整快照、Reader UI、寫入、已讀、持久化、資料遷移與共用標頭或分頁框架擴充均在本 topic 範圍外。

## 驗收

1. 從套件內入口讀取指定 PR，可逐筆核對留言 `id`、原始 Markdown `body` 與可用 `author`。合法缺作者仍交付。
2. 多頁結果維持來源順序。只在分頁全部完成時交付成功，包含合法空清單。
3. 留言頁無法存取時回 `.notReadable`。取消、無法證明分頁歸屬或暫時無法完成讀取時回 `.unavailable`。
4. 任一頁的必要留言資料無法保真映射時回 `.contentNotRepresentable`。任何失敗均捨棄已取得的部分清單。 [Reader failure 契約](../../docs/architecture/bounded-contexts/pr-reader.md#failure-contract)
5. 抽取 #92 的詳情身分解碼與比對後，Changed Files 的既有輸出、失敗映射及續頁行為保持一致。

完整性以走完本次 GitHub 分頁為準。讀取期間的新增或刪除可能讓各頁反映不同時間點。GitHub 文件展示數字 repository 路徑，留言端點的實際線上 `Link` 形狀尚未採樣。驗收使用受控回應覆蓋具名與數字兩種路徑。 [GitHub REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api#using-link-headers)

## 授權與依據

Human 已核准此 topic 的 processed-plan，並授權在獨立 feature worktree 實作。條件式交付授權與停止點見執行計畫。 [技術規格](technical-spec.md) · [執行計畫](../../plan/pr-reader-github-conversation-comments-source/pr-reader-github-conversation-comments-source.plan.md)
