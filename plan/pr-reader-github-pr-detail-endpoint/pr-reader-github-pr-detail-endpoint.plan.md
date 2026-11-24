# PR Reader GitHub PR 詳情端點執行計畫

Topic `pr-reader-github-pr-detail-endpoint`，基線 `dev` `386af9e`，分支 `feat/pr-reader-github-pr-detail-endpoint`，PR 目標 `dev`。工作限獨立 feature worktree。主工作樹兩份既有實驗文件修改留在原工作樹。

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| Goal | 給定 PR 識別與已認證的 REST client，交付背景資料或既有 Reader failure。 |
| Non-Goal | 完整閱讀快照與 Reader UI。 |
| In-Scope | Reader REST target、端點、JSON 轉換、失敗映射、受控測試及 BC 能力記錄。 |
| Out-Of-Scope | 討論、reviews、checks、Changed Files、Unified Diff、GraphQL、公開 product、即時 GitHub 驗收、資料遷移及發布。 |
| ReadOnly | 其餘既有 tracked 檔，包括 Reader Core、PRContentSource、WebView bridge、PR Inbox、GitHubIntegration 與 RivetHTTPClient 正式程式碼，以及主工作樹既有實驗文件。 |
| Written | 四份 topic 規劃文件。新增 `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/` 的 `GitHubPullRequestDetailEndpoint.swift` 和 `GitHubPullRequestBackgroundSource.swift`，以及 `Tests/RivetPRReaderGitHubTests/` 的 `GitHubPullRequestDetailEndpointTests.swift` 和 `GitHubPullRequestBackgroundSourceTests.swift`。 |
| Deleted | 無。 |
| Modify | `Package.swift`、`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`、`docs/architecture/bounded-contexts/pr-reader.md`。 |
| TestCase | TC01–TC04。端點與 adapter 分別使用獨立預期值，另行驗證 SwiftPM target 隔離。 |

## 實作與驗收

先新增 SwiftPM Reader Infra 與測試 targets，再依技術規格完成端點及背景 adapter。同步現有精確 SwiftPM graph 檢查及 Reader BC 長期能力說明，尤其是 REST 背景讀取範圍、Core 隔離和 Reader 自己的失敗映射。

| ID | 驗收條件 |
| --- | --- |
| TC01 | 端點的 `method` 為 `.get`，完整 URL 為獨立字面值 `https://api.github.com/repos/Owner-1/Repo.name_2/pulls/42`，query 缺席。分別驗證 `owner` 與 `repository` 拒絕空字串、`.`、`..`、斜線、反斜線、百分比編碼、query 或 fragment 分隔字元、空白、換行及其他不允許字元。拒絕零與負數編號。 |
| TC02 | Adapter spy 攔截 `get`，核對完整 URL、三項現行 headers 及 `nil` body。無效識別零次呼叫，有效流程一次。驗證正常詳情、字串原樣、描述或作者的合法缺值、必要資料缺失或錯型態及無法解碼的 JSON。 |
| TC03 | 驗證 `401`、`404`、權限 `403`、`429`、服務或執行失敗，以及送出前與等待回應期間取消。原始 `403` 有三組必驗差異，只有 `Retry-After` 回 `.unavailable`，只有可辨識的次級限流 JSON 回 `.notReadable`，權限訊息搭配剩餘額度 `0` 回 `.unavailable`。 |
| TC04 | 既有精確 target 檢查確認 Reader Infra 與測試 targets 及其依賴，Core 維持隔離，REST 來源不納入候選 GraphQL SDL。執行下列 Swift 與 diff 檢查。 |

```sh
swift test --skip KeychainTokenStoreTests
scripts/check-swift-format.sh
swiftlint lint --strict
git diff --check
```

受控回應完成離線驗收。程式碼與文件可直接回退。

## 本機工具證據

| 工具 | 使用與交付 |
| --- | --- |
| Graphify | 沿用 pin `0.9.73`。目前無 `graphify-out/graph.json`，直接查受限原碼。後續若有可證明對應受查 revision 的既有 graph，可沿用。每次呼叫設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。 |
| PR Lens | 沿用 `0.11.0`。目前無 `.github/pr-lens.yml`。在 repo 外暫存目錄驗證和渲染實際受限 base/head diff。尚未提交時用含新增檔的實際 worktree diff。已有 overlay 則沿用，否則使用 `--no-config`。 |
| Archify | 以繁中 sequence 呈現識別、`makeURL()`、headers factory、`client.get(...)`、背景或 Reader failure，包含原始 `403` 與共用分類器分工。Viewer 英文。本機 deliver 為 `.build/topic-evidence/pr-reader-github-pr-detail-endpoint/archify/`。要求 showcase 9/9、零錯誤與警告、四尺寸 visual-check 及目視核對。以 `--repo-root` 產生相對路徑紀錄。 |
| Show Me | 交接採精簡 call tree 說明無效識別零次呼叫、有效識別一次 `get`、預設 `executeGet`，以及 headers factory、REST client 與 classifier 分工。 |
| Floorplan | 延續 2026-11-18 的 ignored map，基準 496 檔、60 節點。新 worktree 缺 seed 時，從既有 map 複製 `graph.json`、`architecture.json`、作者描述及 local ignore，保留自訂流程。完成 refresh、依 `NEXT` 補檔案卡片與關係、Recent work、build 及 `open.mjs`。若本機開啟受限，驗證靜態 HTML 並記錄預覽待驗證。 |

本機工具產物以相對路徑交接，失敗與待驗證項分別記錄。Swift 測試為產品驗收證據。

## 審閱與交付

四份規劃文件由獨立 Plan-Reviewer 審查。明示 `approved` 後才交 Implementer，接續 Tester 與獨立 Reviewer。若須改動公開 Reader 契約、放寬 REST 目的地或提前交付部分快照，停在 Human Check。

使用者已確認本 topic 在 staged diff 語意單一、範圍相符且無重大問題時，可以執行單一 commit、push 並開 Draft PR 至 `dev`。提交前依 git-commit-convention 核對完整 staged diff 和記錄建議 message。條件不成立時停在提交前交回 Human。條件成立時完成 Draft PR 並讀回遠端狀態，停在 Human Review。

- [技術規格](../../analysis/pr-reader-github-pr-detail-endpoint/technical-spec.md)
- [步驟帳本](pr-reader-github-pr-detail-endpoint.step.md)
