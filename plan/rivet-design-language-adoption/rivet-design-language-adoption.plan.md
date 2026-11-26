# Rivet Design Language Adoption — Phase C／D Amendment

- Topic `rivet-design-language-adoption`，branch `feat/rivet-design-language-adoption`
- 獨立 feature worktree 為唯一工作範圍，由 Git operator 保持 checkout ownership。正式產品來源 `dev` @ `2764e64a77732902693b7890b346b2f3fa3f487d`。C／D 的 Git 部分凍結在 feature `ee836106e7256d2a209647916103dd5a73d4c8af`，入口的 Presentation、測試、套件、Presentation 契約及 acceptance tool 與正式來源一致。本機 `dev` `1fcdb2c` 較新，相關輸入無差異。
- HC-02 **Accepted**。本輪授權為 amendment 及獨立四檔 Plan Review。執行本契約仍須 C02 `approved` 和 Human 明示實作授權。Commit、push 及 merge 依之後的工作授權。
- [需求](../../analysis/rivet-design-language-adoption/requirements.md) · [技術規格](../../analysis/rivet-design-language-adoption/technical-spec.md) · [帳本](rivet-design-language-adoption.step.md) · [A／B 首輪計畫](https://github.com/a129924/rivet/blob/ee836106e7256d2a209647916103dd5a73d4c8af/plan/rivet-design-language-adoption/rivet-design-language-adoption.plan.md) · [Draft PR #101](https://github.com/a129924/rivet/pull/101)

## Goal

提取 HC-02 採用且 Login 直接使用的四色與 glyph，並以最小 Login 接線和同 fixture 前後驗證交付一項可驗收的共用視覺能力。

## Non-Goal

保護已採用的 Login 公開介面、版面、Workflow、parent-owned phase／intent 及原生互動。設計方向的採用與 Native Interaction Contract 的互動責任各自有效。

## In-Scope

- 現有 `RivetPresentation` target 新增 internal `RivetPalette` 和 glyph-only `RivetBrandMark`。只在 `RivetLoginArtwork.swift` 接上 Login 色彩與 22 pt glyph，並保留 feature-specific artwork、色彩及 accessibility。C 提取、D 接線在同一 feature 變更交付，合併其能力驗收。
- 交付 Visual Design Contract，明載 Light／Dark 的共同語意、表面層級、Variant B 低對比方向、原生 controls、文件化 Typography／Spacing、Login-specific styling、Border 及 symbol-only placement 待決與 Inbox 自有採用流程。
- 單一必要的四色表格測試、既有 Login／隔離測試、Debug／Release build、root suite、逐檔範圍驗證及 Login 前後原生證據。

## Out-Of-Scope

正式 PR Inbox／Reader、Workspace 與 Sidebar 接線、Toolbar／navigation／collapsed sidebar 的符號位置、原 I1／A／B fixture 回修、Domain／Application／Integration、認證、新 package／framework、Theme Engine、未經採用的共用 Border 或 Typography／Spacing Swift scale。

## ReadOnly

- `analysis/rivet-design-language-adoption/requirements.md`
- `analysis/rivet-design-language-adoption/technical-spec.md`
- `plan/rivet-design-language-adoption/rivet-design-language-adoption.plan.md`
- `README.md`
- `docs/design-principles.md`
- `docs/development-workflow.md`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/presentation/login-ui.md`
- `docs/presentation/native-interaction-contract.md`
- `.gitignore`
- `Package.swift`
- `Package.resolved`
- `Sources/Presentation/Login/LoginMethodSelection.swift`
- `Sources/Presentation/Login/LoginOAuthSection.swift`
- `Sources/Presentation/Login/LoginPATForm.swift`
- `Sources/Presentation/Login/LoginStatusNotice.swift`
- `Sources/Presentation/Login/LoginStyles.swift`
- `Sources/Presentation/Login/RivetLoginContent.swift`
- `Sources/Presentation/Login/RivetLoginPresentation.swift`
- `Sources/Presentation/Login/RivetLoginView.swift`
- `Sources/Presentation/Login/RivetLoginView+Previews.swift`
- `Sources/Presentation/Resources/Login/GitHubMark.pdf`
- `Sources/Presentation/PRInbox/InboxHeader.swift`
- `Sources/Presentation/PRInbox/InboxHeader+Previews.swift`
- `Sources/Presentation/PRInbox/PullRequestList.swift`
- `Sources/Presentation/PRInbox/PullRequestList+Previews.swift`
- `Sources/Presentation/PRInbox/PullRequestRow.swift`
- `Sources/Presentation/PRInbox/PullRequestRow+Previews.swift`
- `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`
- `Tests/RivetPresentationTests/RivetLoginContentTests.swift`
- `Tests/RivetPresentationTests/RivetLoginPresentationTests.swift`
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`
- `tools/acceptance/login-ui/README.md`
- `tools/acceptance/login-ui/Package.swift`
- `tools/acceptance/login-ui/Package.resolved`
- `tools/acceptance/login-ui/scripts/build-app.sh`
- `tools/acceptance/login-ui/Sources/RivetLoginAcceptance/main.swift`
- `tools/acceptance/login-ui/Sources/RivetLoginAcceptanceSupport/LoginAcceptanceConfiguration.swift`
- `tools/acceptance/login-ui/Sources/RivetLoginAcceptanceSupport/LoginAcceptanceFixtures.swift`
- `tools/acceptance/login-ui/Sources/RivetLoginAcceptanceSupport/LoginAcceptanceHost.swift`
- `tools/acceptance/login-ui/Sources/RivetLoginAcceptanceSupport/LoginAcceptanceParent.swift`
- `tools/acceptance/login-ui/Tests/RivetLoginAcceptanceSupportTests/LoginAcceptanceConfigurationTests.swift`
- `tools/acceptance/login-ui/Tests/RivetLoginAcceptanceSupportTests/LoginAcceptanceParentTests.swift`
- `plan/rivet-login-ui-adoption/evidence/human-acceptance.md`
- `plan/rivet-login-ui-adoption/evidence/acceptance-ownership-human-acceptance.md`
- `plan/rivet-design-language-adoption/evidence/VisualDesignPreview.swift`
- `plan/rivet-design-language-adoption/evidence/design-language-candidate.png`
- `plan/rivet-design-language-adoption/evidence/login-baseline.png`
- `plan/rivet-design-language-adoption/evidence/visual-review.md`

## Written

- `Sources/Presentation/DesignLanguage/RivetPalette.swift`
- `Sources/Presentation/DesignLanguage/RivetBrandMark.swift`
- `docs/presentation/visual-design-contract.md`
- `Tests/RivetPresentationTests/RivetPaletteTests.swift`
- `plan/rivet-design-language-adoption/evidence/login-after.png`
- `plan/rivet-design-language-adoption/evidence/cd-verification.md`

## Modify

- `Sources/Presentation/Login/RivetLoginArtwork.swift`
- `plan/rivet-design-language-adoption/rivet-design-language-adoption.step.md`

`RivetLoginArtwork.swift` 是唯一既有 production 路徑。帳本只更新狀態、gate 及證據。已審查的其他三份 planning artifacts 以凍結版本作為本次實作契約。

## Deleted

`None`

## 精確差異基線

C／D admission 由凍結的 Git HEAD、四個採用證據 SHA-256 及完成 C02 審查的四份 planning artifacts 快照共同構成。四個 A／B evidence 以其已採用工作檔為準，包含 HEAD 中尚無的 `login-baseline.png`。審查後、實作前留存四份 planning artifacts 的 bytes 或 SHA-256，與 A／B SHA、HEAD 一同存於外部實作收據。三份 readonly artifacts 與四份 A／B evidence 在 C／D 比對中須維持快照雜湊。帳本可作上述受限更新。四組路徑兩兩互斥。以該合成基線核對 ReadOnly／Modify 已存在、Written 尚不存在及 Deleted 為空。

| 已採用 A／B evidence | SHA-256 |
|---|---|
| `plan/rivet-design-language-adoption/evidence/VisualDesignPreview.swift` | `16ae31792f2ccefbb1a490e6ea667816281be1fa1dc7c6fc45cf884a6a04d21a` |
| `plan/rivet-design-language-adoption/evidence/design-language-candidate.png` | `cd9a977f6863cba040543c43ab3189d50b4299d88f88164d74d44cfcd4ebf486` |
| `plan/rivet-design-language-adoption/evidence/login-baseline.png` | `ce86bf0c262d743282b6c1ad328346d9d779854a5cffbbf8fef86854af8a9cdd` |
| `plan/rivet-design-language-adoption/evidence/visual-review.md` | `e8ac99394fc3251d92f26968ca3d5f0e256b5b5126e21b2975bbe7c6af3c46e6` |

Scope 證據須收集 HEAD／index／工作樹的差異，並列出未追蹤項。逐路徑對照合成基線，先核對所有 A／B 及 planning 錨定內容，再收斂到上列 C／D 增修差異。計畫核准或實作可留在目前的混合工作樹狀態，無需先提交前段 A／B。新命令的 build、cache、收據與原始個別 PNG 留在 checkout 外。既有 ignored 工具產物不列為新增路徑。封存前再次核對所有允許路徑和未追蹤項，任何意外差異或缺少證據均記錄並交相應角色判定。

## TestCase

| ID | Context／Trigger | 可觀察結果 | 證據及契約追溯 |
|---|---|---|---|
| DL-S01 | 同機依序使用同一份新審查的 Login artifact 啟動八組 fixtures，780 × 500 pt、standard copy、appearance、字級及可比較擷取條件對齊 before | Welcome、PAT、Waiting、兩種 failure 與 scaling 等效。逐格確認 glyph／tile／wordmark、版面、色彩和 control 前景。可辨識的 spinner phase／游標／焦點差異記在擷取條件。非預期產品差異立即停 Human | `login-after.png`、採用的 `login-baseline.png` 與 `cd-verification.md` 逐格記錄。HC-02、Login UI、Visual Design Contract |
| DL-S02A | 實際操作合成 PAT。初始空欄檢查 `Connect to GitHub`。輸入合成值，Show／Hide 後再編輯，檢查 Back／重進 PAT 及 token failure 的輸入焦點 | 空值不可提交、非空合成值可提交，顯示切換維持輸入及可達焦點。返回與失敗的預期焦點維持。事件僅以 acceptance receipt kind／count 查證 | 原生焦點、操作或 AX 觀測與 intent receipt。Login UI、Native §6 的 editable control 優先原則、§7／§10、`AC-NI-026/030` 的適用狀態部分 |
| DL-S02B | 以 browser failure 的 Retry 進 Waiting，再以 Cancel 或 Escape 回 Welcome。另從 browser failure 選 `Use a personal access token →` 進 PAT。用 21 pt、780 × 500 pt 視窗捲動 PAT／token failure 底部，檢查鍵盤與 enabled／disabled。代表性 PAT 子案例實際開啟 Increase Contrast，檢查輸入焦點環、文字及空欄 disabled，再還原原設定 | Retry／Cancel／showTokenEntry intent 與對應 phase、焦點恢復符合基線。底部內容及操作可達，停用不產生事件。Increase Contrast 時焦點環、文字與停用狀態可辨識 | 原生操作、intent receipt 及必要畫面。Increase Contrast 記錄實際結果與設定還原。若無原生操作許可，記未驗及其原因與影響。Login UI、Native §7／§10、`AC-NI-026/030/035` 的適用部分 |
| DL-S02C | Human 用 VoiceOver 親自聆聽 Welcome／Waiting、PAT 顯隱與 failure 的代表性焦點、名稱／狀態與宣告 | 同既有 Login 語意。焦點事件與語音內容有實際回報，品牌裝飾無重複朗讀 | 矩陣逐例記 Human 聆聽、未執行及影響，Login UI、Native §10、`AC-NI-026/030` 的適用部分 |
| DL-S02D | 檢查 Login 公開型別／initializer／phase／intent 的 diff，執行既有 Login 內容、表單和字級測試 | API、phase／intent、局部表單和 scaling 維持既有行為。GitHub 圖示等包內資源在已授權的 fresh process 正常顯示 | API／diff 檢查、`RivetLoginContentTests`、`RivetLoginPresentationTests`、`RivetLoginTypographyTests` 及 resource receipt。Login UI |
| DL-S03A | 執行一個新四色表格測試的 8 組 sRGB 案例 | 兩 appearance 四個 role 與 alpha 均符合技術規格，可辨識單一 RGB byte 差異 | `RivetPaletteTests` 測試輸出，Visual Design Contract、技術規格 |
| DL-S03B | 執行 Debug／Release build、root `swift test`，並以 focused suite 追蹤 Login／palette 與 `packageDeclaresTheLockedTargetGraph`。依凍結基線查 path delta、A／B hashes、Swift imports／符號引用 | Build 與套件測試通過。兩個新能力只在 Login 使用。無 target、Inbox、acceptance tool、API 或鎖檔改變。所有 staged／unstaged／untracked 差異有清單與來源 | 各命令、版本、exit code、hash 及依賴檢查，Native §13、Visual Design Contract |

各 AC 僅追溯 Login 的適用行為，對 Inbox／Reader 全文情境不宣告覆蓋。DL-S02 的受控內容只使用合成 PAT，測試及證據不接觸憑證。任何未執行／不可判讀的案例記錄項目、理由及對等效驗收的影響，不以 screenshot 或靜態 AX 代替原生互動。A／B 候選七項未驗維持 [需求的移交範圍](../../analysis/rivet-design-language-adoption/requirements.md)，不當作 C／D Login 結果。

八個 after 擷取配置如下，逐格用相同新 artifact 的 fresh process 啟動，完成後關閉。After 圖按 before 相同順序標註配置。Before 來源及歷史 artifact SHA 見視覺證據。

| 格 | `--state` | `--appearance` | `--text-size` |
|---|---|---|---|
| 1 | welcome | light | 17 |
| 2 | welcome | dark | 17 |
| 3 | pat | light | 17 |
| 4 | waiting | dark | 17 |
| 5 | browser-failure | light | 21 |
| 6 | token-failure | light | 21 |
| 7 | welcome | light | 13 |
| 8 | welcome | light | 21 |

套件驗證使用 repo 的固定 Swift 工具鏈與現有依賴，記錄 scratch 路徑與實際 invocation。Debug／Release 建置選 `RivetPresentation` target。Root `swift test` 及 focused Login／palette／target graph 測試都保存結果。驗收 App 使用既有 `build-app.sh` 和工具文件指定的 local Apollo cache、asset bundle 與 screenshot 環境。

## Admission、原生停點與交付

1. Plan-Creator 只寫四檔，C02 由獨立 Plan-Reviewer 核對採用決策、基線、九欄與界線。取得明示 `approved` 後等待 HC-03 實作授權。
2. HC-03 確認後，Implementer 按基線交付 C／D，準備新的 `RivetLoginAcceptance.app`。依既有工具文件由獨立 Reviewer 檢閱實際來源、resource 清單、source manifest、binary、app tree SHA-256 及有限 cases，再提交 HC-04。
3. HC-04 是 exact 新 App launch 的當下確認。HC-01 只屬 A／B 基線。未確認前可完成獨立非互動驗證。需要 TCC 許可時由 Human 對指定工具或操作決定。若 TCC 受限，記錄限制，使用 Human 操作可獨立完成的案例。
4. Tester 執行 DL-S01～03 與範圍核對，再交獨立 Reviewer。Login 有非預期改變時，停止並交 Human。未驗或無法判讀的證據須有明確處置。
5. Phase E 將兩份契約與 evidence、等效結論、Inbox 移交清單交 HC-05 最終 Human 接受。之後依 Git operator／topic workflow 確認對 `dev` 的整合。原 Inbox topic 同步新 `dev`、inspect、amend 並自有獨立 Plan Review 後再採用。

## C–E 本機工具

工具輸出留在 checkout 外，作為審查輔助，不新增 repo 路徑或產品 gate。

- **git-branch-naming**　沿用已核定的 `feat/rivet-design-language-adoption`。PR 目標為 `dev`，由 Git operator 管理分支與 worktree。
- **archify**　只呈現 B 採用、C 審查、D 等效與 E Human 交付的 workflow。繁中作者內容，Viewer／`html lang` 使用英文 fallback。Showcase 九項通過及零 errors／warnings 後 `deliver`，再 `visual-check` 並實看明暗擷取。本機保存。
- **pr-lens**　使用 0.11.0，對實際 Git base…head 執行 `validate`、`render` 並核對 manifest 與原始 diff。僅用既有 overlay，目前無。圖有缺口時直接查 diff。未提交內容及 A／B 合成基線另以 path 與 SHA 核對。
- **graphify**　使用 0.9.73。若仍無可用圖，對核准的 Presentation source 在外部 scratch 做 AST-only 索引。每次 CLI 設 `GRAPHIFY_NO_AUTO_REFRESH=1`，使用 `extract --code-only --no-cluster --no-gitignore --out`。記錄 revision／命令，以最小查詢定位後回查 source。失敗時定向查 source。
- **show-me**　對話使用最小流程圖。E 以已審查 Login 前後及 Inbox 候選說明差異。
- **floorplan**　保留現有 ignored map，日期 2026-11-24、536 files、來源 `4955cff`。對凍結 review head 的外部副本更新地圖副本，標示 Login／Design Language 實際採用與來源。僅本機檢視，停用 hosted Ask 與發布。
