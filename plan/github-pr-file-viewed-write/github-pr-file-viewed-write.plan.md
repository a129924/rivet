# GitHub PR 檔案已讀寫入執行計畫

Topic 為 `github-pr-file-viewed-write`。依 `git-branch-naming` 與 Rivet 的 `feat/<topic>` 慣例，採獨立工作樹和 `feat/github-pr-file-viewed-write`。本機及 GitHub 的 `dev` 起始基線為 `3468eaab4cf7a1646083332e1eef2223b107ebb4`，包含原草案查證基線 `4261f9c`。原工作樹的兩份既有實驗文件變更排除。 [需求](../../analysis/github-pr-file-viewed-write/requirements.md) · [技術規格](../../analysis/github-pr-file-viewed-write/technical-spec.md) · [步驟帳本](github-pr-file-viewed-write.step.md)

## swift-implementation

| 欄位 | 契約 |
| --- | --- |
| In-Scope | 套件內單檔 mark／unmark、呼叫端已核對的目標、本地輸入驗證、GraphQL mutations、結果映射、寫入 target、離線產碼、受控測試和本機審閱輔助。 |
| Out-Of-Scope | 產品 UI、WebView 接線、adapter 查檔或自動讀回、本機狀態同步、批次寫入、真人遠端寫入驗收、Thread、Merge。 |
| ReadOnly | Written／Modify 以外的 tracked 路徑。包括 PR Reader Core、讀取來源、固定 schema 及其產碼、GitHubIntegration transport、認證與憑證生命週期、REST review submission、`experiments/`、依賴鎖檔。 |
| Written | 本 topic 四份正式規劃文件。新增 `Sources/RivetPRWriteGitHub/PRFileViewedWriter.swift`、`Sources/RivetPRWriteGitHub/GraphQL/Codegen/PullRequestFileViewedWrite.graphql`、同目錄的 `apollo-codegen-config.json`、`Sources/RivetPRWriteGitHub/GraphQL/Generated/` 全量離線產碼、`Tests/RivetPRWriteGitHubTests/PRFileViewedWriterTests.swift`、`docs/architecture/github-pr-graphql-writes.md`。 |
| Deleted | 無。 |
| Modify | `Package.swift` 新增寫入與測試 target，`Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 更新 target graph 期望，`docs/github-api/graphql-write-actions.md` 更新 Viewed 條目。 |
| Goal | 已認證的呼叫端可對已核對的單一檔案明確標記或取消已讀，並分辨 GitHub 已接受、未送出、明確遭拒或結果待核對。 |
| Non-Goal | 完整檔案閱讀或審閱流程。Mutation 收據只確認操作接受，逐檔三態由既有讀取取得。 |
| TestCase | FV01 本地驗證及 GraphQL 操作。FV02 收據及結構化拒絕。FV03 取消及傳輸錯誤。FV04 產碼、target graph、Reader 回歸與範圍。 |

## 驗收

- **FV01**｜透過正式 `setViewed` 入口注入受控 `GitHubGraphQLServing`。核對兩個動作各自使用正確 operation，一次 `perform`、零次 `fetch`。核對 PR ID 及原始路徑的 UTF-8，包括空格、非 ASCII 和可形成 Unicode 正規等價的不同字面路徑。空 PR ID、含空白或控制字元的 PR ID、空路徑和含 NUL 的路徑均零次 mutation。
- **FV02**｜兩種同 PR 有效收據確認成功。驗證不影響必要欄位的 partial error、路徑缺席或覆蓋必要欄位的 error、不同 PR ID、空 payload、PR 缺席、結構化單一理由、混合理由或混合 path、未辨識理由、資料與拒絕訊號矛盾。明確終止的認證錯誤或 HTTP `401` 僅依既定契約回拒絕。
- **FV03**｜驗證送出前取消為零次 `perform`。進入 `perform` 後的取消、無法判定的狀態、逾時、斷線及晚到有效收據對應至技術規格結果。核對 adapter 一次提交上限及零次讀回。既有 client 的 `401` 復原由其回歸測試驗證。
- **FV04**｜核對固定 schema SHA 與 Apollo 版本，離線重生全部寫入輸出並逐檔比對。驗證寫入及測試 target 依賴、無額外 product、Reader 結構保留。執行 SwiftPM 測試（涵蓋寫入、GitHubIntegration、Reader）、既有 SwiftFormat／SwiftLint 檢查與 diff 檢查。獨立核對未追蹤新檔、已暫存及未暫存差異、API Catalog 與長期文件回寫。

## 本機審閱輔助

輔助證據與 FV01–FV04 各自記錄。圖、收據與暫存資料置於 worktree 外或既有 ignored 路徑。

| 工具 | 產物與查核 |
| --- | --- |
| `archify` | 依實際程式製作繁中 sequence、英文 viewer。執行 showcase `validate` 與 `deliver`，最終收據須 9 項檢查、0 composition errors 與 0 warnings。對交付 HTML 做 `visual-check`，核對 `1440×900`、`1600×1000`、`1920×1080`、`2048×1320`，目視最小及最大尺寸亮暗截圖。缺少瀏覽器或視覺檢視時記未驗，用原始碼及測試支援流程追查。 |
| `pr-lens` | 固定 CLI `0.11.0`，先以實際 base／head 或可追溯的受限差異核對本案，涵蓋允許的未追蹤檔。可取得真實來源時，在 repo 外暫存目錄出圖，保留 Reader、transport 與 schema 參照，以 `validate`、light render 與 manifest 核對。執行時依實際 worktree 的既有 overlay 決定參數。無可驗證來源、commit pair 或 runtime 失敗時保留直接差異查核。 |
| `graphify` | 固定 `0.9.73`，每次呼叫設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。只對能追溯至受查版本的既有本機圖限定 `query`／`path`／`explain`，並回查 Swift、GraphQL schema 及 manifest。規劃查證未找到可用 graph，由定向 `rg` 和原始碼檢查替代；本輪不需建圖。 |
| `show-me` | 依原始碼及受控測試將簡短 call tree 回填帳本，沿入口、無效輸入或取消、一次 `perform`、收據及待核對追蹤。 |
| `floorplan` | 複製主工作樹既有 ignored 地圖至 feature worktree，只 refresh 本 topic。保留手寫說明與自訂 flows，Recent work 僅標本組。核對新檔、target 依賴及實際呼叫。有授權時開本機預覽。預覽受限則記錄靜態核對與視覺未驗。 |

## 交接與停點

先由獨立 Plan-Reviewer 審查實際四檔。依明示 `approved` 交 Implementer，完成後由獨立 Tester 執行 FV01–FV04，繼而由獨立 Reviewer 審查。確立的實作契約回寫長期責任文件及 API Catalog 的 Viewed 條目。

Human 已授權獨立 feature worktree 實作。若產品驗收及獨立成果審查無重大問題、staged diff 符合九欄且屬單一 topic，Human 確認可依 `git-commit-convention` 檢查差異、提出並記錄訊息，執行一個 topic commit、推送功能分支和開以 `dev` 為目標的 Draft PR。建立並讀回後停在 Human Review。驗收未達標、獨立審查未批准、差異超出九欄或任何已鎖定契約需變更時停在提交前。Thread 與 Merge 各待相應前一組整合至 `dev`。
