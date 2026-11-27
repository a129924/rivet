# 整體 Review 送出需求

讓具有 GitHub 審閱寫入權限的套件內呼叫端，對指定 PR 與已審閱的 commit 送出一筆整體 Review。呼叫端需要區分 GitHub 已接受、明確拒絕與結果待核對，以免在確認遺失後重複送出。

- 支援 `APPROVE`、`REQUEST_CHANGES` 與 `COMMENT`，後兩者須提供正文。呼叫端必須指定已審閱的 commit SHA。
- 無效輸入在送出前回報。GitHub 回報成功時提供可核對的 Review ID 與狀態，收據不可讀時仍保留接受結果。
- 待核對時交由呼叫端先查閱 GitHub 紀錄。首版以受控測試驗收。
- 逐行留言、建立或送出 PENDING Review、編輯、撤回、合併、自動核對與 UI 另案處理。

[技術規格](technical-spec.md) · [執行計畫](../../plan/github-pull-request-review-submission/github-pull-request-review-submission.plan.md) · [GitHub REST](https://docs.github.com/en/rest/pulls/reviews#create-a-review-for-a-pull-request)
