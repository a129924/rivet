# 按需讀取 GitHub 未讀通知｜執行計畫

Topic 為 `github-unread-notifications-source`，分支為 `feat/github-unread-notifications-source`，工作樹為 `../rivet.worktrees/agent-20261126-github-unread-notifications-source`。原查證基線 `d47354ef66dff4e3b1562a974aaabc486c246c6a`，執行基線 `dev` 的 `fa3329bfe78be069633d8e08a74ecc4389ab386c`。使用獨立工作樹隔離根工作樹的實驗文件變更。 [需求](../../analysis/github-unread-notifications-source/requirements.md) · [技術規格](../../analysis/github-unread-notifications-source/technical-spec.md)

## swift-implementation

下表的 `<topic>` 為 `github-unread-notifications-source`。Implementer 開工前核對九欄，Reviewer 核對 staged、unstaged 與允許新增的 untracked 檔。

| 欄位 | 執行契約 |
| --- | --- |
| In-Scope | Endpoint、PAT 接線、分頁、資料與失敗映射、套件測試、API Catalog 回寫及本機實作審閱。 |
| Out-Of-Scope | 新 BC 或 target、產品登入與憑證保存、通知 UI、系統通知、輪詢與快取、標記已讀、讀取主旨資源、comment-level last-seen。 |
| ReadOnly | `Written` 與 `Modify` 之外的 tracked 路徑。 |
| Written | `analysis/<topic>/{requirements,technical-spec}.md`、`plan/<topic>/<topic>.{plan,step}.md`、`Sources/BoundedContexts/GitHubIntegration/Notifications/GitHubUnreadNotificationsEndpoint.swift` 與同目錄的 Source、PageLinks 及必要資料型別。在 `Tests/GitHubIntegrationTests/REST/Endpoints/` 新增 `GitHubUnreadNotificationsEndpointTests.swift`，另於 `Tests/GitHubIntegrationTests/` 新增通知來源測試及 `StaticIsolationTests+Notifications.swift`。該擴充檔只持有通知專屬的 `notificationSourcePaths` 與 `notificationHTTPClientPaths` 兩組集合。 |
| Deleted | 無。 |
| Modify | `docs/github-api/rest-notifications-local-state.md` 的通知清單條目與 `docs/github-api/README.md` 的對應索引列。記錄套件能力、官方 `is_done` 參數及本次省略語意。另在 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 `targetContainsOnlyTheLockedSourceFilesAndNoForbiddenImports`，保留原清單，僅以 `expectedPaths.union(Self.notificationSourcePaths)` 執行既有整體精確比對，並在既有匯入分類條件加入 `Self.notificationHTTPClientPaths` 的成員檢查。`notificationSourcePaths` 只列 `Notifications/` 下的 `GitHubNotificationThread.swift`、`GitHubUnreadNotificationsEndpoint.swift`、`GitHubUnreadNotificationsPageLinks.swift`、`GitHubUnreadNotificationsSource.swift`。`notificationHTTPClientPaths` 只列同目錄的 `GitHubNotificationThread.swift`、`GitHubUnreadNotificationsEndpoint.swift`、`GitHubUnreadNotificationsSource.swift`。 |
| Goal | 完整、有序地交付同一憑證的通知清單，或回傳可辨識的失敗。 |
| Non-Goal | 推導產品通知排序、帳號身分或跨頁時間點快照。 |
| TestCase | `N01` 資料與順序、`N02` Endpoint 與分頁完整性、`N03` 存取與傳輸、`N04` 取消及回歸。 |

Endpoint、Source、PageLinks 和 outcome 依技術規格實作。先完成 Endpoint 與獨立測試，再串接 Source 與 PageLinks 並完成整體驗收。

## 產品驗收

先執行 `swift test --filter GitHubUnreadNotificationsEndpointTests`，核對 GET、`200`、首頁固定路徑與查詢、續頁附加頁碼，以及零與負頁碼拒絕。整合後以合成 PAT 和受控 REST 回應走正式套件入口。

- **N01。** 驗證空、單頁、多頁、順序、時間與 repository 欄位、可缺欄位、未知主旨類型、`unread=false` 和必要資料錯誤。
- **N02。** 納入獨立 Endpoint 測試，並驗證 Source 以 Endpoint 建構首頁與可信續頁。涵蓋合法終頁、異常 `Link`、錯誤目的地、查詢變更、跳頁和循環。確認分頁失敗時只交付分類。
- **N03。** 驗證每次請求的標頭與 Bearer 目的地、缺憑證零請求、`401`／`403`、限流、轉址與續頁失敗。沿用正式傳輸的轉址回歸測試。
- **N04。** 驗證事前取消、等待回應時取消、晚到的成功或失敗，以及結果與診斷脫敏。核對既有靜態隔離測試的來源清單與 RivetHTTPClient 匯入清單僅新增 `Modify` 指定的七筆，並通過既有精確比對與匯入隔離檢查。執行 `swift test --filter GitHubIntegrationTests`、既有 Swift format／lint 檢查與 `git diff --check`。

## 本機實作審閱

| 工具 | 執行與證據 |
| --- | --- |
| `$archify` | 使用 2.16。在 `.build/topic-evidence/<topic>/archify/` 產出繁中作者內容與英文 viewer 的 sequence diagram，涵蓋呼叫端、同一 PAT 的請求、`next` 驗證、完整結果、失敗與取消。執行 showcase validate、deliver 和四尺寸 visual-check，核對 9/9、零 errors／warnings，目視最大與最小尺寸的亮暗畫面，記錄收據或限制。 |
| `$pr-lens` | 使用 0.11.0。以實際 base 與本題 diff（含允許新增檔）作圖。若已有獲准的 commit，使用實際 base／head。在 repo 外暫存目錄依序 validate、light render，讀回 manifest 與 SVG。現況使用 `--no-config`，若執行時已有適用的 overlay 則唯讀使用。未提交差異若無法由工具如實呈現，直接核對本題 diff 並記錄缺項。 |
| `$graphify` | 使用 0.9.73，每次設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。只查 revision 已核對的既有圖，聚焦通知來源、headers、HTTP 和轉址，回原碼覆核。現況沒有可用圖，預設使用 `rg` 與原碼做定向覆核。 |
| `$show-me` | 在步驟帳本記錄短呼叫樹，對照 Source、Endpoint 與 PageLinks 三者，呈現首頁建構、Link 驗證、可信頁碼交回 Source、Endpoint 建構續頁，以及完整成功、失敗和取消。 |
| `$floorplan` | 將既有 ignored map 複製到獨立工作樹再 refresh，保留使用者筆記與自訂 flows。將 Recent work 限於本題，預覽本機 HTML，核對說明覆蓋、高嚴重度 Health 項目及未覆蓋檢查。根工作樹的 map 以唯讀方式使用。 |

Implementer 產出本機證據，Tester 覆核，Reviewer 核對差異與證據。產物留在 ignored 或 repo 外暫存路徑。工具受限時在步驟帳本記錄版本、所得證據、限制與未驗事項，能以本題 diff 或原碼覆核的項目照常執行。產品驗收依 `N01`–`N04` 判定。

## 交接與停點

獨立 Plan-Reviewer 讀回四份同 slug 檔案並明示 `approved` 後，依序交 Implementer、Tester 與獨立 Reviewer。若需變更已鎖定的套件歸屬、分頁信任範圍或交付契約，交回 Human 決定。

Human 已核准本計畫、獨立工作樹實作與本機 PR Lens／Graphify 審閱。若產品驗證與獨立成果審查無重大問題，依 `git-commit-convention` 核對 staged diff 屬單一 topic 並提出 commit message 後，依本輪明示授權執行一次 topic commit、push feature branch，並開一個指向 `dev` 的 Draft PR。條件不成立時停在提交前。讀回 Draft PR 後停在 Human Review。真實 PAT 驗證與合併各待另行授權。 [步驟帳本](github-unread-notifications-source.step.md)
