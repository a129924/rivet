# PR Reader 單一 PR 審閱紀錄讀取計畫

## Current state

Topic 為 `pr-reader-github-reviews-source`。獨立工作樹相對於主工作樹位於 `../rivet.worktrees/agent-20261125-pr-reader-github-reviews-source`。遠端 `dev` 與獨立工作樹的基線均為 `38f65400958d39db4fd3e803f71402b8745c6174`，已合併 Reviews Endpoint。依 `git-branch-naming` 與 #92–#96 的 `feat/<work-item>` 慣例，分支 `feat/pr-reader-github-reviews-source` 已通過 `git check-ref-format --branch`。主工作樹有兩份既有實驗文件修改。基線若有變動，先重查依賴契約。 [PR #96](https://github.com/a129924/rivet/pull/96)

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 套件內讀取入口、REST 請求、分頁與來源核對、資料及失敗映射、受控驗收、BC 契約回寫及五項本機審閱交付。 |
| Out-Of-Scope | Inline comments、review threads、合併判定、寫入、持久化、遷移、新標頭組合與通用分頁框架。 |
| ReadOnly | 其餘 tracked 檔案，含 Reader Core、`PRContentSource`、既有 REST 端點、Changed Files source、`GitHubIntegration`、`Package.swift`、工具設定及主工作樹既有修改。 |
| Written | Tracked 新增 `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubPullRequestReviewsSource.swift`、同目錄的 `GitHubPullRequestPageLinks.swift`、`Tests/RivetPRReaderGitHubTests/GitHubPullRequestReviewsSourceTests.swift`，以及下列四份規劃文件。本機審閱產物詳見交付表，留在 ignored 路徑或 repo 外暫存目錄。 |
| Deleted | 無。 |
| Modify | `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubConversationCommentsSource.swift` 僅擷取並接入共用 Link 解析器，保留留言行為。驗收後更新 `docs/architecture/bounded-contexts/pr-reader.md` 的審閱紀錄契約。 |
| Goal | 套件內呼叫端給定 PR 識別與已認證 client，取得完整、有序的 `[ReaderReview]` 或單一 `PRReaderFailure`。 |
| Non-Goal | 組裝完整快照、計算整體 `reviewDecision` 或接入產品 UI。 |
| TestCase | RV01 請求與投影、RV02 具名分頁、RV03 數字續頁核對、RV04 失敗與取消、RV05 回歸與差異。 |

四份規劃文件使用相同 slug：

- `analysis/pr-reader-github-reviews-source/requirements.md`
- `analysis/pr-reader-github-reviews-source/technical-spec.md`
- `plan/pr-reader-github-reviews-source/pr-reader-github-reviews-source.plan.md`
- `plan/pr-reader-github-reviews-source/pr-reader-github-reviews-source.step.md`

## 產品驗收

- **RV01** 由套件內入口用獨立期望值核對首頁 URL、GET、三個標準標頭與 `nil` body。驗證空陣列、五種狀態、精確 ID、原始 Markdown、空正文、缺席及 `null` 作者、缺少提交欄位的 `PENDING`，以及同一作者的多筆紀錄。
- **RV02** 驗證具名續頁的請求、頁內與跨頁順序及合法末頁。覆蓋錯 host、repo、PR、query、重複或矛盾 Link、跳頁與循環，確認未發出錯誤續頁請求。
- **RV03** 核對首頁 → 原 PR 詳情 → 具名續頁的請求順序，逐筆核對 GET、標頭與 body。同次讀取只查一次詳情，並涵蓋僅有數字 `last`、詳情失敗、身分不符及後續數字 ID 不符。
- **RV04** 驗證無效識別零請求、首頁及後續頁失敗映射、未知狀態及壞資料。覆蓋取消後 client 才交付的回應，以及累積資料後才發生的失敗。每案只交付單一 failure。
- **RV05** 執行 `swift test --filter RivetPRReaderGitHubTests`，涵蓋一般留言與既有 Reader REST 回歸。執行 `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、`git diff --check`，並核對含未追蹤新增檔的完整差異與空白。

產品驗收使用受控 REST 回應。數字 repository 路徑的案例依 GitHub 通用分頁文件與 Reader 既有先例。 [技術規格](../../analysis/pr-reader-github-reviews-source/technical-spec.md) · [GitHub REST 分頁](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api#using-link-headers)

## 本機審閱交付

| 工具 | 產物與核對 |
| --- | --- |
| Archify | 使用繁中內容與固定英文 viewer 產生 sequence，呈現首頁、具名續頁、數字續頁查核、資料投影與失敗收尾。存於 ignored `.build/topic-evidence/pr-reader-github-reviews-source/archify/`。由 showcase validate／deliver 核對 9/9、零錯誤與零警告，以 `visual-check --repo-root` 查四種桌面尺寸並目視核對亮暗畫面，保存相對路徑收據。 |
| PR Lens `0.11.0` | 於 repo 外暫存目錄對獨立工作樹的實際 base 與差異執行 `validate` 與 light theme `render`。納入允許的未追蹤新增檔。核對 manifest、實際差異及相鄰契約。沿用適用既有 overlay，否則用 `--no-config`。獲授權提交後以實際 base／head 檢查。工具不足時直接核對完整差異並記錄限制。 |
| Graphify `0.9.73` | 設定 `GRAPHIFY_NO_AUTO_REFRESH=1`，僅對可追溯至受查 revision 的既有圖做限定查詢，以原碼覆核。查無適用圖時以 `rg` 與原碼完成核對。 |
| Show Me | 以計畫所列的預期呼叫樹交接。Tester 於實作後對照入口、端點、client、歸屬查核與 failure，記錄實際接線差異。 |
| Floorplan | 以既有 ignored 地圖作 seed，基線 `4955cff`、536 檔、62 節點。僅在獨立工作樹 refresh，保留筆記與自訂 flows，依 `NEXT` 補齊說明。Recent work 限本 topic。build 後核對說明覆蓋率 100% 與連線，以 `open.mjs` 預覽。預覽受限時核對靜態 HTML 並記錄限制。 |

預期的 Show Me 呼叫樹：

```text
GitHubPullRequestReviewsSource.fetchReviews(for:)
├─ ReviewsEndpoint.makeURL(page:) → REST client.get(.standardREST, nil)
├─ 200 → ReaderReview 投影 → GitHubPullRequestPageLinks
│  ├─ 首次數字 next → 原 PR 詳情 GET → GitHubPullRequestRepositoryIdentity
│  └─ 合法 next → ReviewsEndpoint.makeURL(page:) → 下一次 GET
└─ 交付完整有序清單，或映射單一 PRReaderFailure
```

工具產物限本機。`.step.md` 記錄證據、替代檢查與未驗項。產品驗收以 RV01–RV05 為準。

## Dispatch 與 Stop condition

四份規劃文件由獨立 Plan-Reviewer 審查並明示 `approved` 後，依序交 Implementer、Tester、獨立 Reviewer。若需改變 Core、公開契約、續頁信任範圍或完整交付語意，停在 Human Check。

Human 已批准 processed-plan 與獨立工作樹實作，並在產品驗證及獨立成果審查無重大問題、staged diff 符合本 topic 語意邊界時授權一個 topic commit、推送功能分支並開啟以 `dev` 為目標的 Draft PR。提交前依 `git-commit-convention` 檢查 staged diff、提出並記錄 commit message。Human 已確認條件成立即可提交。條件不成立時停在提交前。Draft PR 建立及讀回後交還 Human Review。 [步驟帳本](pr-reader-github-reviews-source.step.md)
