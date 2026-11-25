# PR Reader 一般討論留言讀取計畫

## Current state

Topic 為 `pr-reader-github-conversation-comments-source`。草案查證基線 `612b97e` 已含 #91 的留言端點。#92 的 Changed Files source 使用原 PR 詳情核對數字 repository ID。已查證 GitHub `dev` 及 feature worktree 基線均為 `b0ad6974a33cc53112083eefad60504462593d66`，已納入 #93 Raw Unified Diff。#93 未改動詳情端點、#91／#92 來源或 `.standardREST` 的三項標頭值。若執行時發現範圍、契約或允許修改路徑與基線有衝突，重新 preflight。 [PR #91](https://github.com/a129924/rivet/pull/91) · [PR #92](https://github.com/a129924/rivet/pull/92) · [PR #93](https://github.com/a129924/rivet/pull/93)

依 `git-branch-naming` 與專案 `feat/<work-item>` 慣例，功能分支為 `feat/pr-reader-github-conversation-comments-source`。獨立工作樹相對於主工作樹位於 `../rivet.worktrees/agent-20261125-pr-reader-github-conversation-comments-source`，Git metadata 由原 repository 管理。

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| Goal | 套件內呼叫端提供已確認屬於 GitHub.com PR 的識別及已認證 client，取得完整、有序的一般留言，或單一 Reader failure。 |
| Non-Goal | 組裝完整 `PRContentSnapshot` 或提供產品 Reader UI。 |
| In-Scope | Reader Infra 套件內入口、既有端點與 client 接線、留言分頁、按需 PR 詳情查核、抽取 #92 的身分解碼與驗證、資料與失敗映射、受控驗證、BC 文件回寫。 |
| Out-Of-Scope | Review 摘要、inline comments／threads、Changed Files 行為變更、寫入、已讀、持久化、資料遷移與共用 REST／分頁框架擴充。 |
| ReadOnly | 其餘既有 tracked 檔案，含 `Package.swift`、Reader Core／`PRContentSource`、PR 詳情／#91／Changed Files 端點、Background Source、Raw Unified Diff、共用 REST client／headers／HTTP transport，以及主工作樹的既有 experiment 修改。 |
| Written | 在 `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/` 新增 `GitHubConversationCommentsSource.swift` 與 `GitHubPullRequestRepositoryIdentity.swift`，在 `Tests/RivetPRReaderGitHubTests/` 新增 `GitHubConversationCommentsSourceTests.swift`，並建立同 topic 的四份正式規劃文件。 |
| Deleted | 無。 |
| Modify | `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubPullRequestChangedFilesSource.swift` 僅抽取詳情身分 DTO 與核對條件。`Tests/RivetPRReaderGitHubTests/GitHubPullRequestChangedFilesSourceTests.swift` 僅補詳情 `401`、`403`、`404` 的失敗與停止續頁回歸。`docs/architecture/bounded-contexts/pr-reader.md` 更新一般留言區段，保留 #92 與 #93 的區段。 |
| TestCase | CC01 起始請求與投影、CC02 分頁、CC03 PR 詳情身分查核、CC04 完整交付與失敗、CC05 #92 與既有端點回歸。 |

在既有 Reader Infra 接上留言入口，依技術規格實作分頁及 failure。首次有效數字 `next` 用現有詳情端點查核，兩個 adapter 共用抽取的 DTO 與部分純解碼驗證。Changed Files 的請求與 Reader failure 仍由它自己的 adapter 負責。 [需求](../../analysis/pr-reader-github-conversation-comments-source/requirements.md) · [技術規格](../../analysis/pr-reader-github-conversation-comments-source/technical-spec.md)

## 驗收

- **CC01** 以 `Owner-1/Repo.name_2`、PR `42` 呼叫套件內入口。透過 REST client spy 用獨立字面值比對 `https://api.github.com/repos/Owner-1/Repo.name_2/issues/42/comments?page=1&per_page=100`、GET、`nil` body，以及 `Accept: application/vnd.github+json`、`User-Agent: Rivet`、`X-GitHub-Api-Version: 2026-03-10`。驗證精確留言 ID、原始 Markdown、有作者、缺席或 `null` 作者、成功空陣列，以及無效起始識別時零請求。
- **CC02** 核對具名兩頁的續頁目的地、頁內及跨頁順序。覆蓋合法無 `next`、錯 host／repo／PR、歧義或錯誤 query、跳頁、循環、`next`／`last` 矛盾。分頁失敗時透過 spy 確認未送出該頁。
- **CC03** 數字 repository ID `817` 的請求順序須與下列獨立字面值相符。詳情 GET 一次且無 query。第 2 頁再提供數字 `next` 時沿用首次確認 ID。逐筆核對 GET、CC01 的固定三項標頭及 `nil` body。分別覆蓋 `number`、`base.repo.id`、`base.repo.full_name` 的不符與畸形，另驗證詳情 `401`、`403`、`404`、拋錯、等待詳情時取消與後續數字 ID 改變。均回 `.unavailable`，且未送出未證實的續頁。具名分頁或只有數字 `last` 時詳情呼叫數為零。

  ```text
  https://api.github.com/repos/Owner-1/Repo.name_2/issues/42/comments?page=1&per_page=100
  https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42
  https://api.github.com/repos/Owner-1/Repo.name_2/issues/42/comments?page=2&per_page=100
  https://api.github.com/repos/Owner-1/Repo.name_2/issues/42/comments?page=3&per_page=100
  ```

- **CC04** 覆蓋首頁與後續頁的必要資料異常、權限拒絕、`410`、限流、傳輸或服務失敗及取消。涵蓋已有累積留言後的失敗，每案只交付單一 Reader failure。
- **CC05** 為 #92 加入詳情 `401`、非限流 `403`、`404` 回歸，確認仍回 `.notReadable`，且未送出未驗續頁。執行 `swift test --filter RivetPRReaderGitHubTests`，涵蓋新 source、詳情及 #91 端點、Changed Files 端點及 source，再執行 `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh` 與 `git diff --check`。對未追蹤新增檔補做等效空白檢查，核對完整差異符合九欄契約。

此留言端點的實際線上 `Link` 形狀尚未採樣。兩種路徑及失敗情境以受控 REST 回應驗收。

## 本機交接與驗證

| Skill | 交付 |
| --- | --- |
| Graphify `0.9.73` | 僅查詢可追溯到受查 revision 的既有圖。每次呼叫設 `GRAPHIFY_NO_AUTO_REFRESH=1` 並以原碼覆核。無適用的 `graphify-out/graph.json` 時，以 `rg` 和原碼核對接線。 |
| Archify | 在 ignored `.build/topic-evidence/pr-reader-github-conversation-comments-source/archify/` 交付繁中 sequence，Viewer 使用英文。依實作呈現首頁、具名續頁、數字 `next` 所需的 PR 詳情 GET、共用解碼器與失敗分支。以 showcase validate／deliver 驗證 9/9、零錯誤和警告，保存相對路徑 receipt。用 `visual-check --repo-root` 檢查四種桌面尺寸並目視核對。交付留在本機。 |
| PR Lens `0.11.0` | 在 repo 外本機暫存目錄對實際 topic worktree 差異執行 `validate` 和 `render`。納入未追蹤新增檔，記錄真實 base／head 與未提交 worktree 證據。核對 manifest、實際 diff、#92 驗證抽取及兩個 adapter 的失敗映射。將詳情、#91 和共用 REST 的相鄰行為納入對照。有適用 overlay 即沿用，否則使用 `--no-config`。工具無法處理時直接檢查完整 diff 並記錄限制。 |
| Show Me | 以下列預期呼叫樹交接。實作後對照原碼核實端點、client、共用驗證及失敗分支。 |
| Floorplan | 使用前次查得的主工作樹 ignored map 作 seed，基線 `4955cff`、536 檔、62 節點。帶入 topic worktree 後 refresh，依 `NEXT` 補描述與關係，新增 Recent work，build 後核對描述及連線。用 `open.mjs` 本機預覽。預覽受限時核對靜態 HTML 並記錄預覽狀態。 |

```text
GitHubConversationCommentsSource.fetchConversationComments(for:)
├─ #91 makeURL(page: 1) → REST client.get(.standardREST, nil)
├─ 檢查取消、HTTP 回應、留言投影及 Link
│  ├─ 首個有效數字 next → PR 詳情 makeURL() → REST client.get
│  │  └─ 200 → GitHubPullRequestRepositoryIdentity.verifiedRepositoryID
│  │     └─ 核對 number、base.repo.full_name、base.repo.id，於本次 fetch 重用
│  └─ 合法 next → #91 makeURL(page:) → REST client.get
└─ 完整有序留言清單或單一 PRReaderFailure

GitHubPullRequestChangedFilesSource.verifiedRepositoryID(for:matching:)
└─ 既有 PR 詳情 makeURL() 與 get 分類 → 同一共用解碼及核對
```

五項工具的產物與證據留在本機，tracked 設定為唯讀。產品驗收以 CC01–CC05 為準。

## Dispatch 與 Stop condition

獨立 Plan-Reviewer 審查已落地的四份正式檔案並明示 `approved` 後，依序交 Implementer、Tester、獨立 Reviewer。以步驟帳本保留各階段的實際證據。若須改變公開 Reader 契約、放寬分頁目的地、交付部分結果或改變 Changed Files 行為，停在 Human Check。 [步驟帳本](pr-reader-github-conversation-comments-source.step.md)

Human 已批准 processed-plan，並授權在獨立 feature worktree 實作。若產品驗證及獨立審查無重大問題，且 staged diff 語意單一並符合本 topic，已授權一個 topic commit、push 功能分支及開啟以 `dev` 為目標的 Draft PR。提交前依 `git-commit-convention` 檢查 staged diff 的語意邊界並記錄 commit message。條件未達成時停在提交前。Draft PR 建立後讀回遠端狀態，停在 Human Review。
