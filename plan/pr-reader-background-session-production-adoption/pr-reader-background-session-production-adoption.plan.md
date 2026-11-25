# PR Reader Background Session 正式採用計畫

Topic `pr-reader-background-session-production-adoption`，分支 `feat/pr-reader-background-session-production-adoption`，實作 worktree 起始基線 `dev` `b0ad6974a33cc53112083eefad60504462593d66`。所有工作限隔離 feature worktree 與下列路徑。受控整合消費正式 Reader 組裝、Session 與 adapter。

## swift-implementation

`S` 為本 topic slug。下列路徑均相對於 repo 根目錄。

| 欄位 | 契約 |
| --- | --- |
| In-Scope | Reader-owned 背景 Port 與 Facade、既有 adapter conformance、可觀察的 Session、請求識別及取消、同 PR 刷新保留資料、套件內組裝、受控整合及回歸、Reader BC 與既有邊界圖同步、採用紀錄。 |
| Out-Of-Scope | 完整 Snapshot、WebView、Viewed 持久化、產品登入／App Owner／Inbox 導覽、跨 PR cache、真 GitHub 驗收、HTTP／OAuth／Outcome 契約變更、E011／E012／E021–E023 改接。 |
| ReadOnly | 除 Written 及 Modify 外的所有 tracked files，包含現有 PRContentSource／GitHubClientScope、HTTP／OAuth、通用 RivetPresentation、skills／hooks／config 與主工作樹原有的 `experiments/README.md`、`experiments/VALIDATION-SUMMARY.md` 修改。 |
| Written | S01 建立 `analysis/S/requirements.md`、`analysis/S/technical-spec.md`、`plan/S/S.plan.md`、`plan/S/S.step.md`。S03 新增 `Sources/BoundedContexts/PRReader/Core/PRBackgroundSource.swift`、`Sources/BoundedContexts/PRReader/Core/PRReaderBackgroundFacade.swift`、`Sources/RivetPRReaderPresentation/ReaderBackgroundState.swift`、`Sources/RivetPRReaderPresentation/PRReaderBackgroundSession.swift`、`Sources/RivetPRReaderComposition/PRReaderBackgroundComposition.swift`、`Tests/RivetPRReaderPresentationTests/PRReaderBackgroundSessionTests.swift`、`Tests/RivetPRReaderCompositionTests/PRReaderBackgroundCompositionTests.swift`。 |
| Deleted | 無。 |
| Modify | S03 修改 `Package.swift`、`Sources/BoundedContexts/PRReader/Infra/GitHub/REST/GitHubPullRequestBackgroundSource.swift`、`Tests/GitHubIntegrationTests/StaticIsolationTests.swift`。S03 同步 `docs/architecture/bounded-contexts/pr-reader.md`、`docs/architecture/diagrams/bounded-context-map/scene.js`，依流程重建同目錄 `index.html`。取得驗證證據後更新 `docs/feasibility-adoption.md`。各階段更新 `plan/S/S.step.md` 所屬紀錄。 |
| Goal | 正式元件安全載入、切換、刷新及取消背景資料。僅當前有效請求提交，刷新保留最近一次成功資料。 |
| Non-Goal | 通用 Task 管理、跨套件公開產品、新 App 組裝與導航、完整 Reader 快照或基礎設施重設計。 |
| TestCase | P01–P17、原 Task 自取消對照、正式組裝整合、manifest 依賴隔離及根套件回歸。 |

## 執行與寫入範圍

- S01 Plan-Creator 寫入四份同 slug 正式檔。S02 Plan-Reviewer 以唯讀方式獨立審查契約並交 verdict。必要回修交 Plan-Creator 並重審。
- S03 Implementer 僅寫入表列 Swift／測試檔、manifest、精確 target graph 測試與 Reader BC／既有圖。圖面只更新 Reader 背景切片，將編譯期邊改為 Session → Reader Facade → Reader UseCase → PRBackgroundSource，標明 Session 選取／請求／狀態及 adapter conformance／REST 依賴。以繁中修訂現有 scene，依 architecture-canvas 驗證並重建 `index.html`，可用時瀏覽檢視。保留並行 Discussion Comments 的文件區段。
- S04 Tester 獨立驗收並回報證據。S05 Reviewer 獨立審查正式變更、測試及 scope。實作／驗證／評審進展只回寫 step 各自對應欄位，測試及審查本身保持 production 與契約唯讀。必要修正交對應 owner 再驗證。取得正式實作及受測證據後將版本、入口、替身、P01–P17、回歸、缺口與採用結論回寫既有 adoption record。
- S06 Implementer 依已確認條件作受限交付。S07 停於 Human Review。正式步驟與前提見 [step](pr-reader-background-session-production-adoption.step.md)。

## 驗證契約

| ID | 受測情境 | 預期 |
| --- | --- | --- |
| P01 | 首次載入成功 | loaded，清除當前 slot。 |
| P02 | 切換不同 PR | 新 PR loading，前一筆 PR 資料離開顯示狀態。 |
| P03 | 晚到成功 | 保留當前狀態。 |
| P04 | 晚到失敗 | 保留當前狀態與失敗資訊。 |
| P05 | 同 PR 刷新成功 | 先保留已提交資料，新成功才替換。 |
| P06 | 同 PR 刷新失敗 | 保留資料並顯示最近失敗。 |
| P07 | 連續刷新 | 僅最新 token 可提交。 |
| P08 | 取消首次載入 | 回 selected，保留 PR ID。 |
| P09 | 取消刷新 | 回 loaded 並保留 previous。 |
| P10 | 失效 | 拒絕晚到結果，來源未放行時可釋放最後的 Session 強引用。 |
| P11 | 有效失敗 | 按 Reader failure 提交，包含未取消的 unavailable。 |
| P12 | 過期清理隔離 | A 真正完成後 B 的 handle 仍可由正式入口取消，另有 B 正常提交並清空 slot 對照。 |
| P13 | 同 PR 選取 | 不變更當前請求或狀態。 |
| P14 | 刷新失敗後重試 | 保留資料，清除舊錯誤，接受有效新結果。 |
| P15 | 來源忽略取消 | 仍拒絕過期結果。 |
| P16 | 重複失效 | 冪等且無新副作用。 |
| P17 | 失效實例再用 | 操作保持無副作用且無新來源請求。 |

- actor 受控來源以已登記的 continuations 及事件屏障排序，返回前在原 Task 記錄 `Task.isCancelled`，覆核取代、顯式取消與失效。原 Task 自取消但 token 仍 current 時分別交成功與失敗，驗證恢復狀態及清理。程式審查確認 token、取消各有 guard，提交無 suspension。以唯讀完成等待 closure 等 `.value`，P12 在 A settled 而 B 仍懸掛時正式取消 B，確認 B 返回前自己的取消旗標。P10 在來源到達屏障後 invalidate 並釋放最後一個強引用，先確認 weak Session 為 nil 再放行來源和等待完成。事件順序不用 Task.sleep，測試收尾排空 continuations。
- 組裝測試以 `makePRReaderBackgroundSession(rest:)` 和受控 REST 走正式 adapter，驗證所選 PR、背景投影、有效 failure 映射、取消後晚回及重開 Session 獨立。執行兩個新增 suite、manifest graph checks、根套件 `swift test` 和 `git diff --check`。記錄 Reader／Inbox／GitHub 回歸及受測版本。E021–E023 沿用原受測證據。

## 本機審閱

工具產物各別記實際版本、範圍、輸出及缺項。工具結果不作 Swift 或既有架構圖驗收的額外前提。附加產物限本機 topic scratch 或 feature worktree 的 ignored `floorplan/`。

- Show Me 提供對話內 per-request ownership 示意，交付時依實際本地來源及證據更新，不新增獨立檔案。
- Archify 在受測 Swift 實作後，於 repo 外 topic scratch 交付一份繁中 sequence。使用 showcase、9 檢查零錯誤與警告、deliver receipt。visual-check 以 scratch 根為相對路徑基準，查驗 1440×900、1600×1000、1920×1080、2048×1320，核對 light／dark 截圖並記實際目視狀態，註明固定英文 Viewer UI 和 html lang fallback。
- PR Lens 沿用 pin 0.11.0。查核時無 `.github/pr-lens.yml`。比較實際且不同的 base／head，以 `--find-renames` 記 SHA、unchanged neighbors 與 file refs，於 topic scratch 寫入 `pr-lens/graph.json`、驗證及渲染至 `pr-lens/rendered/`。缺可比較 commits 時以有界 diff 審查並記 pending，依原授權時點提交。
- Graphify 沿用 pin 0.9.73。查核時無標準 `graphify-out/graph.json`。實作前重核版本、來源及 revision。僅查同 revision 的圖，每次關閉自動刷新，查詢預算 1500，回讀原碼佐證。圖缺失或過期時使用限定 rg。
- Floorplan 既有 ignored 地圖建於 `4955cff`，查核時與基線差 115 tracked files。只在 feature worktree 使用地圖副本 refresh，保留 custom flows，按 NEXT 補必要內容並核對 Recent work topic 卡片。重建限 ignored `floorplan/`，以離線 HTML 交付，依環境開啟預覽。主工作樹與 tracked files 皆不在工具寫入範圍。

## Human Check

Human 已明確授權在正式驗證通過、無重大問題且 staged diff 只含本 topic 時，建立一個 topic commit、推送 feature branch 並開以 `dev` 為 base 的 Draft PR。提交前依 repo commit 慣例檢查 staged diff 並記錄建議訊息。條件不成立時停於提交前。條件成立則交付 Draft PR，停於 Human Review。
