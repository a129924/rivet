# 將單一 GitHub 通知標記為已讀執行計畫

Topic 為 `github-notification-mark-as-read`。依 `$git-branch-naming` 和 Rivet 的 `feat/<work-item>` 慣例，使用已建立的獨立工作樹及分支 `feat/github-notification-mark-as-read`。起始基線為本機及遠端 `dev` 的 `a559f7a69f2fda6d25c6e50298905f777cd831b4`。發布前將 feature worktree 快轉至遠端 `dev` 的 `4261f9c55faf5ce0194906fcea45fb47de5b2574`，再做完整驗收。 [需求](../../analysis/github-notification-mark-as-read/requirements.md) · [技術規格](../../analysis/github-notification-mark-as-read/technical-spec.md)

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 既有 `GitHubIntegration` 的單筆 endpoint 與 package adapter、輸入驗證、結果映射、離線驗收、API Catalog 回寫及本機輔助審閱。 |
| Out-Of-Scope | 通知清單與輪詢、整批已讀、標記 done、逐則留言已讀、本機狀態同步、UI、憑證保存及真人驗證。 |
| ReadOnly | Written 與 Modify 之外的 tracked 路徑，包括 `Package.swift`、既有 REST／Bearer／transport、並行未讀通知工作、工具設定與原工作樹的實驗文件。 |
| Written | 本 topic 四份正式規劃文件。於 `Sources/BoundedContexts/GitHubIntegration/Notifications/` 新增 `GitHubNotificationMarkAsReadEndpoint.swift` 與 `GitHubNotificationReadMarker.swift`，後者包含專屬結果型別。新增 `Tests/GitHubIntegrationTests/Notifications/GitHubNotificationReadMarkerTests.swift`。 |
| Deleted | 無。 |
| Modify | Human 於 2026-11-27 核准 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 的 `expectedPaths` 與 `httpClientFiles` 各新增兩個本案 Swift 來源路徑，清單內換行調整以符合既有行數限制。驗收後回寫 `docs/github-api/rest-notifications-local-state.md` 的單筆 PATCH 項目及已驗證契約。 |
| Goal | 呼叫端可對指定 thread 送出單筆寫入，分辨已讀確認、未修改、存取遭拒及結果待核對。 |
| Non-Goal | 新建 Notifications BC、target、公開 API，合併並行讀取契約，或以自動讀回、重送解決待核對結果。 |
| TestCase | NR01 Endpoint、套件入口與本地驗證。NR02 HTTP 結果。NR03 取消、傳輸與憑證邊界。NR04 回歸與範圍檢核。 |

## 實作與產品驗收

1. 遵循技術規格，在既有 target 內建立 internal endpoint 與 package adapter。Adapter 以 endpoint 的 method 和固定 URL 組裝既有標頭與 Bearer，再進入呼叫端以 `package init(httpClient:)` 注入的 raw client。Human Review 確認正式組裝使用 `GitHubRESTTransport.makeClient()`，測試注入受控 transport。於同一測試檔涵蓋 endpoint 和套件入口。
2. Tester 獨立核對產品。驗收通過後，Implementer 回寫 API Catalog 的指定項目，Tester 核對回寫及最終差異，再交獨立 Reviewer。
3. Reviewer 依實際差異與證據審查。納入已暫存、未暫存及允許的未追蹤檔，按九欄核對。

- **NR01**｜以 `@testable` 直接測 endpoint 的 `.patch`、固定 HTTPS URL 與無 query、合法長 ID 和前導零保留原字面。空字串、全零、含空白、非 ASCII 數字與路徑字元在 endpoint 拒絕，經 adapter 也均零提交。以合成 PAT 與受控 transport 核對一筆 PATCH、`.standardREST`、Bearer 與無 body，並核對無效 Bearer 與提交前取消均零提交。
- **NR02**｜覆蓋空 body 的 `205`、`304`、`401`、未識別為限流的 `403`、可辨識的 `403` 限流、`429`、`5xx` 及其他非預期狀態。核對結果及提交次數，確認 `205` 直接按狀態碼交付。
- **NR03**｜覆蓋提交後取消、逾時、斷線、非 HTTP 回應，以及已取得有效回應的取消競賽。用現有 redirect 拒絕路徑及受控回應核對沒有第二次提交或轉址跟隨。錯誤及診斷的可觀察表示無合成 PAT 值。
- **NR04**｜執行 `swift test --filter GitHubIntegrationTests`、`scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`、`git diff --check`，有 staged 差異時另執行 `git diff --cached --check`。核對完整 topic 差異，包括範圍內新檔和 Catalog 回寫。

## 本機輔助審閱

產物留在 ignored 路徑或 repo 外。帳本記錄工具版本、來源、產物、驗證收據、失敗及未驗，與 NR01–NR04 及正式 verdict 分列。

| 工具 | 產物與查核 |
| --- | --- |
| `$archify` | 於 `.build/topic-evidence/github-notification-mark-as-read/archify/` 產出繁中 sequence，viewer 為英文。核對 `validate`、`deliver` showcase 的 9/9、零錯誤警告，完成四尺寸 `visual-check` 並目視亮暗。受限時用原碼及受控測試逐段核對。 |
| `$pr-lens` | 依 Human 明示要求，用 0.11.0 檢視實際基線與 bounded diff，包括允許的未追蹤新檔。待已有真實 base／head 提交對，才以 `--no-config` 在 repo 外暫存目錄製圖，標示未修改的相鄰節點並跑 validate、light render。無提交對或工具受限時留下逐檔查核證據。 |
| `$graphify` | 依 Human 明示要求，採 0.9.73 並每次設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。有可追溯至受查版本的本機圖才限定本 topic 做 query／path，結果回查原碼。規劃時預設圖不存在，遇此情況以 `rg` 與原碼追查並記錄限制。 |
| `$show-me` | 在帳本用原碼和測試回填短 call tree。核對 endpoint 驗證 ID 和固定方法與 URL，adapter 取得固定目的地再套 Bearer，無效 ID 零提交，有效請求提交一次並依回應映射。 |
| `$floorplan` | 複製既有 ignored `floorplan/` 到獨立工作樹再 refresh。保留手寫說明與 flows，只補本 topic 說明和 Recent work。核對本 topic 覆蓋、HTML 和本機預覽。既有全圖缺口另記，預覽受限時靜態核對 HTML 並記錄互動未驗。 |

## 交接與停點

- 四份文件先交獨立 Plan-Reviewer。明示 `approved` 後依序交 Implementer、Tester 與獨立 Reviewer，將實際證據與 verdict 記入帳本。
- 若需改變 endpoint 或套件入口可見性、通知責任、單次提交、結果契約或九欄的 tracked 路徑，停在 Human Check。重大問題、NR01–NR04 未達標、獨立審查未批准或差異超出 topic 邊界時停在提交前。
- Human 已明確授權在產品驗收與獨立成果審查無重大問題、staged diff 符合九欄與單一 topic 時，依 `$git-commit-convention` 檢查 staged diff 並提出和記錄訊息，直接做單一 topic commit、推送功能分支並開啟以 `dev` 為目標的 Draft PR。Draft PR 建立並讀回後停在 Human Review。真人寫入驗證與外部發布工具產物另依 Human 授權。 [步驟帳本](github-notification-mark-as-read.step.md)
