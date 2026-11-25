# PR Reader 單一 PR 審閱紀錄讀取需求

## 目標

PR Reader 的套件內呼叫端提供 `ReaderPullRequestID` 及已認證的 `GitHubRestClient`，取得指定 GitHub.com PR 完整、有序的 `[ReaderReview]`，或收到單一 `PRReaderFailure`。完整空陣列代表該次讀取沒有審閱紀錄。

## 範圍與成功條件

- 讀取指定 PR 的所有審閱紀錄分頁，核對續頁歸屬，保留頁次、頁內順序及同一作者的多筆審閱。
- 每筆審閱保留 ID、原始正文、可取得的作者及五種既有狀態。合法缺少作者、`submitted_at` 或 `commit_id` 時，仍保留該筆審閱。
- 區分 PR 無法讀取、整次讀取無法完成及必要資料無法保真。任一頁或查核失敗時捨棄已累積紀錄。取消後忽略晚到的回應。

完整快照組裝、產品 App 與 UI、整體審閱結論、inline comments／threads、合併判定、寫入、持久化、遷移、新標頭組合與通用分頁框架皆在範圍外。

## 依據與驗收

以 PR #96 已合併的端點為基線。完整性以 GitHub 當次提供的分頁序列為準，各頁可能反映不同時間點。數字 repository 續頁依 GitHub 通用分頁文件及 Reader 既有先例納入受控 REST 驗收。 [PR #96](https://github.com/a129924/rivet/pull/96) · [GitHub Reviews API](https://docs.github.com/en/rest/pulls/reviews#list-reviews-for-a-pull-request) · [GitHub REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api#using-link-headers)

[技術規格](technical-spec.md) · [執行計畫與 RV01–RV05](../../plan/pr-reader-github-reviews-source/pr-reader-github-reviews-source.plan.md)
