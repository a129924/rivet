# GitHub REST 回應分類 Phase A 執行計畫

Topic `github-rest-response-classification`，分支 `feat/github-rest-response-classification`，基線 `dev` `4955cffee2eb9a0098e266b9a30ef42e1ffcd865`。實作位於 feature worktree。

## swift-implementation

`G` 為 `Sources/BoundedContexts/GitHubIntegration`，`T` 為 `Tests/GitHubIntegrationTests`，`S` 為 topic slug。檔案範圍以 topic 基線區分。

| 欄位 | 契約 |
| --- | --- |
| In-Scope | Internal classifier 與模型、離線測試、靜態隔離與既有回歸、驗證後的架構說明。 |
| Out-Of-Scope | Adapter 或 production 接線、公開 API、Endpoint、headers provider、分頁、DTO、transport、OAuth、GraphQL、取消契約、恢復政策與真實 API 測試。 |
| ReadOnly | 其餘 tracked files，含 `Package.swift`、既有 REST／Inbox 實作及測試、通用 HTTP、scripts、skills、hooks、config 與 dev 的兩份既有實驗文件。 |
| Written | `analysis/S/requirements.md`、`analysis/S/technical-spec.md`、`plan/S/S.plan.md`、`plan/S/S.step.md`、`G/REST/GitHubResponseClassifier.swift`、`T/REST/GitHubResponseClassifierTests.swift`。 |
| Deleted | 無。 |
| Modify | `T/StaticIsolationTests.swift` 的精確 source set 與 HTTPClient import allowlist。驗證後於 `docs/architecture/README.md` 回寫架構結論。 |
| Goal | 以可獨立測試的純邏輯解釋已拒絕的 GitHub REST 回應。 |
| Non-Goal | 判定 Endpoint 成功、修改業務 Outcome、產品接線或恢復。 |
| TestCase | TC01–TC09，結果記入 step ledger。 |

| ID | 預期結果 |
| --- | --- |
| TC01 | 固定 HTTP 類別、5xx 邊界、被拒絕的 2xx／3xx 及其他狀態依技術規格分類。 |
| TC02 | 兩種明示權限文案在有無剩餘額度 0 下均為 `.forbidden`。 |
| TC03 | 兩種 secondary 文案在缺少／無效 Retry-After 或正剩餘額度下均為 `.rateLimited`。 |
| TC04 | 模糊文案／無效 JSON 時，有效剩餘 0 仍為限流。無效、溢位、正值或缺失為未知。驗證不分大小寫 header。 |
| TC05 | 同一訊息同時含兩種明示原因為未知，包含剩餘 0。 |
| TC06 | 訊息缺失、錯誤型別及泛用、否定文案為未知。Retry-After、Reset 或必要權限 header 單獨有效或無效時同樣為未知。 |
| TC07 | 既有 REST 回歸驗證 raw response、一次 401 重送、終止及執行與取消錯誤。 |
| TC08 | 既有 Inbox 回歸驗證 DTO 成功及失敗、分頁與取消行為。 |
| TC09 | 精確 diff、internal 可見性、production caller 缺席、consumer 契約、format、lint。 |

先建 REST／Inbox 離線基線。Swift 實作完成後跑 focused suite、根目錄 `swift test`、`scripts/check-github-integration-consumer.sh`、`scripts/check-swift-format.sh`、`swiftlint lint --strict` 和 `git diff --check`。

## 審閱與交付

Plan-Creator 完成四檔後交獨立 Plan-Reviewer。核准才實作，後續交獨立 Tester 與 Reviewer。使用者本輪明確指示，實作無重大問題時「請直接 commit by topic -> push -> open Draft PR -> human review」。依該指示作本 topic 的事前確認。提交前仍依 git-commit-convention 核對完整 staged diff 的單一語意邊界並記錄建議 message。若 staged diff 混入其他工作、需要拆分或有重大問題，事前確認條件不成立，停止交由 Human 決定。條件成立時提交、推送及開 Draft PR，停在 Human review。

Show Me 使用對話內合成回應示意。Archify 使用本機 workflow 與 showcase／視覺驗證。PR Lens 僅使用真實 commit base／head 的本機差異與釘選 CLI。Graphify 在既有圖可用時作有界查詢，每次關閉 auto refresh，否則查原始碼。Floorplan 在受測 feature worktree 以既有地圖為基礎更新本機忽略資料，保留 custom flows。這些本機審閱證據獨立記錄，Swift 驗收依 TC01–TC09。
