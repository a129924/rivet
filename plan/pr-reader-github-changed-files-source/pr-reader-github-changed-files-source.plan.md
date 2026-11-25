# 單一 PR 的變更檔案執行計畫

採用獨立 feature worktree 與 `feat/pr-reader-github-changed-files-source`，基線為 `dev` `d8e2ffe`。使用者已接受對話規格並授權實作。若驗證與獨立審查無重大問題，授權一個 topic commit、push 與開啟以 `dev` 為 base 的 Draft PR，交還 Human review。

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 套件內唯讀入口、REST 請求與續頁核對、檔案投影、Reader failure 與受控測試。 |
| Out-Of-Scope | 公開 Port 擴充、UI、raw diff、逐檔補抓 patch、部分成功、Inbox、OAuth、通用分頁及持久化。 |
| ReadOnly | Written 與 Modify 以外的既有 tracked 檔案，含 #84、#89、Reader Core、GitHubIntegration、`Package.swift` 與既有測試。 |
| Written | `Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubPullRequestChangedFilesSource.swift`、`Tests/RivetPRReaderGitHubTests/GitHubPullRequestChangedFilesSourceTests.swift` 及四份同 slug planning artifacts。 |
| Deleted | 無。 |
| Modify | 驗證後回寫 `docs/architecture/bounded-contexts/pr-reader.md`。 |
| Goal | 一次取得依來源排序、識別唯一且含可取得 metadata 與 patch 的完整檔案清單，或收到單一 Reader failure。 |
| Non-Goal | 完整 `PRContentSnapshot` 與跨頁固定 PR 版本。 |
| TestCase | CF01–CF05。 |

## 驗收

- CF01 以受控 REST client 驗證單頁、空清單、多頁順序、路徑識別、所有可映射狀態、增刪統計與 optional 缺值。
- CF02 核對標頭、GET 目的地及次序，驗證名稱與數字 ID 續頁、一次詳情核對、異常續頁不發出請求、短非終頁、空續頁、超量單頁、100 檔終頁、`last` 結構和一致性、只有數字 ID `last` 時沒有額外請求。收據以受控回應為準，線上 Link 路徑格式未驗證。
- CF03 驗證 2,999 檔成功與 3,000 檔有無 next 都失敗，包括同頁含無法投影項目及不超過 30 個檔案頁請求。
- CF04 驗證各階段取消、認證與權限、限流、傳輸、詳情核對、無效資料、空路徑及重複識別。核對首請求的 `.invalidRequest` 回 `.notReadable`，以及續頁和詳情請求回 `.unavailable`。任何失敗只回一個 failure。
- CF05 執行 `swift test --filter RivetPRReaderGitHubTests`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、`git diff --check`。Swift 測試包含既有 #84 與 #89 回歸。

## 本機交接

- Graphify 0.9.73 只查有 revision 可追溯的既有圖，各 CLI 設 `GRAPHIFY_NO_AUTO_REFRESH=1`。缺圖時以 `rg` 與原碼核對。
- PR Lens 0.11.0 依實際 base、head、限域 diff 與原碼手寫 graph JSON，納入未追蹤的 topic 新檔。另記工作樹差異、範圍及 diff 摘要或雜湊。在 repo 外 validate、render 及核對 manifest。有適用的既存 overlay 時套用，否則 render 使用 `--no-config`。工具拒絕時記錄原因並直接核對實際 diff。產物限本機。
- Archify 於 ignored `.build/topic-evidence/pr-reader-github-changed-files-source/archify/` 交付繁中 sequence 與英文 viewer。使用 showcase validate、deliver，要求 9/9、零錯誤與零警告。以 `visual-check --repo-root` 檢查四種桌面尺寸，交付相對路徑收據及目視結果。
- Show Me 以技術規格的呼叫樹交接並對照實作。
- Floorplan 從既有 ignored 資料複用種子至 feature worktree，refresh、依 NEXT 完成本 topic、更新 Recent work、build 並本機顯示。預覽受限時檢查靜態 HTML 並記錄限制。

[需求](../../analysis/pr-reader-github-changed-files-source/requirements.md) · [技術規格](../../analysis/pr-reader-github-changed-files-source/technical-spec.md) · [步驟帳本](pr-reader-github-changed-files-source.step.md)
