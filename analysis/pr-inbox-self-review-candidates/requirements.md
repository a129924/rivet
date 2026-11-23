# PR Inbox 自查候選需求

首版讓單人開發者集中找出自己開啟、尚未關閉的 GitHub.com PR，並於合併前逐一自查。清單收錄條件為 PR 作者是目前 OAuth 帳號且 PR 仍開啟，包含符合條件的 Draft。自查完成狀態留待後續定義。

沿用既有 `PRInboxFacade.refresh()` 與 `Outcome<[InboxItem], PRInboxFailure>`，以唯讀且無 UI 的入口取得清單。另一位作者的 PR 即使指派目前帳號審閱，也不納入自查候選。

在既有 feature worktree 更新 [Draft PR #78](https://github.com/a129924/rivet/pull/78)。E019 的直接指派問題、程式、測試、判準與結果照原版本保存。新版真實驗證獨立記為 E020，使用 [mlops-async#72](https://github.com/a129924/mlops-async/pull/72) 作候選正例。規劃時該 PR 為開啟，作者為 `a129924`。受測 OAuth bundle 的帳號仍須當次核對。
