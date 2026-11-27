# PR Inbox I1 執行計畫

Topic `pr-inbox-i1-verification`，分支 `chore/pr-inbox-i1-verification`，`dev` 基線 `e0cab03`，實驗 E024。

| 欄位 | 契約 |
| --- | --- |
| Goal | 驗證可操作的原生 Inbox 與完整 PR 識別的單次 Open。 |
| Non-Goal | 正式產品接線、真網路及重試、跨環境保證與採用。 |
| In-Scope | SwiftPM App、原生元件組合、合成資料、情境、選取、焦點與事件證據。 |
| Out-Of-Scope | I2、R1、可操作 repository 導覽、篩選、重試及正式元件 API 變更。 |
| ReadOnly | 四份規劃文件於 Swift 實作階段、正式 Swift／WebView、根套件及 lockfile、正式測試、原型、既有契約、實驗與索引。 |
| Written | E024 套件、README、必要的 Sources、Tests、scripts 與可追溯證據。 |
| Deleted | 無。 |
| Modify | 僅修正本輪新建的 E024 檔案。 |
| TestCase | I1-01 至 I1-08。 |

## TestCase

| ID | 判準 |
| --- | --- |
| I1-01 | 初始選取並聚焦 A。選 B，再由 [A,B,C] 重排為 [B,A,C]，保留 B。移除 B 回退並聚焦 A。更新的 Open 增量為 0。 |
| I1-02 | 單擊、方向鍵、Home、End 只改選取。清單有焦點時 Enter 記當前安全 PR 一筆，失焦增量為 0。從 A 雙擊 B 選取並記錄 B 一筆。 |
| I1-03 | 不可開啟、未知與過期請求增量均為 0。移除 B 後注入 B 保持 A；下一個原生 Enter 記 A 一筆。注入涵蓋 Session。 |
| I1-04 | 載入保留版面與識別，停用列及 Open。保持有效焦點，否則聚焦載入標題。 |
| I1-05 | 成功空清單聚焦標題，停用列及 Open。 |
| I1-06 | 可讀錯誤保留清單、選取及有效焦點，標示可能非最新。無有效焦點時聚焦錯誤標題。不可讀或可用性未知時隱藏列、聚焦錯誤標題及停用 Open。復原停用。 |
| I1-07 | 已知離線且可讀時保留舊列及有效選取，標示離線及可能非最新。無可讀資料時聚焦離線標題並停用 Open。復原停用。 |
| I1-08 | 明暗與 Login 並排，察看鍵盤焦點及失焦選取，實際聆聽 VoiceOver 對列識別、標題、選取與局部狀態的宣告。 |

以一輪完整驗收為主。可補跑一次已定位的環境或取證問題。依法保留實際版本、命令、畫面、聆聽及逐步事件。全部符合才判成功。有效證據確認違例判失敗，已嘗試而證據不足判無法判定。

Graphify 查既有圖後回源碼。Archify 呈現受測流程，PR Lens 使用真實 diff，Floorplan 於隔離環境刷新，show-me 呈現手勢到事件紀錄。輔助圖留本機。

## Plan Amendment A1 · 2026-11-26

前段為 `9610830` 的歷史 I1 契約。A1 的後續實作邊界以下列條款為準，保留 I1-01～08 與既有證據。

**基線。** 已讀回開啟中的 Draft PR #97，head 為 `chore/pr-inbox-i1-verification` 的 `9610830`，feature worktree 與遠端 head 一致，撰寫前 Git index、tracked diff 與一般 untracked 清單均為空。另有既存、被忽略的 renderer `node_modules`。本機 `dev` 停在 `5127b5d`，兩份實驗索引已有本機修改。整合基線為 2026-11-26 複查的遠端 `dev` 與本機 `origin/dev` `d92eea7`。設計採用基準為 tag `v0.1.97-rivet-design-language-adoption` 指向的合併提交 `e53214e`，它是整合基線的祖先。兩者之間只有實驗索引與驗證摘要的整理。開始實作前重新讀回 refs 與 worktree，確認基線變動對本契約的影響，再將核對後的 `origin/dev` **合併**進同一 feature branch。逐檔核對合成基線與原證據，保留 `9610830` 的歷史。本輪是 planning amendment 與獨立 Plan Review。

**Goal。** 正式 Inbox 採 HC-02 核准的 Variant B，並以 E024 的合成資料、原生視窗和七項缺口驗收。

**In-Scope。** 共用四色、16 pt compact glyph、原生控制項周邊的版面與文字角色，以及受限寬度與驗收工具。新增正式容器的單一公開接線為本 Amendment 提案，既有 public 介面維持原樣。

**Non-Goal／Out-of-Scope。** App 正式啟用或導覽、真資料、Reader、資料篩選、重試策略、共用 Border、symbol-only、全域 typography／spacing scale、BC 或 SwiftPM 目標重整。

### 精確路徑

本輪規劃只可 **Modify** 下列四個既有檔案，**Written** 與 **Deleted** 均為無。其餘檔案為規劃階段的 ReadOnly。

- `analysis/pr-inbox-i1-verification/requirements.md`
- `analysis/pr-inbox-i1-verification/technical-spec.md`
- `plan/pr-inbox-i1-verification/pr-inbox-i1-verification.plan.md`
- `plan/pr-inbox-i1-verification/pr-inbox-i1-verification.step.md`

下列路徑契約適用於獨立 Plan Review 而且取得後續實作授權後的 swift-implementation／驗證。四類互斥，只有列在 Written 或 Modify 的檔案可納入採用差異。規劃帳本另由流程記錄角色維護。

#### ReadOnly

- `README.md`
- `Package.swift`
- `Package.resolved`
- `docs/design-principles.md`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/presentation/visual-design-contract.md`
- `docs/presentation/native-interaction-contract.md`
- `docs/presentation/login-ui.md`
- `Sources/Presentation/DesignLanguage/RivetPalette.swift`
- `Sources/Presentation/DesignLanguage/RivetBrandMark.swift`
- `Sources/Presentation/Login/RivetLoginArtwork.swift`
- `Sources/Presentation/Login/RivetLoginView.swift`
- `Sources/Presentation/PRInbox/PullRequestList.swift`
- `Sources/Presentation/PRInbox/PullRequestRow.swift`
- `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift`
- `Tests/RivetPresentationTests/InboxHeaderTests.swift`
- `Tests/RivetPresentationTests/PullRequestListTests.swift`
- `Tests/RivetPresentationTests/PullRequestRowPresentationTests.swift`
- `Tests/RivetPresentationTests/RivetPaletteTests.swift`
- `experiments/README.md`
- `experiments/VALIDATION-SUMMARY.md`
- `experiments/E024/Package.swift`
- `experiments/E024/Package.resolved`
- `experiments/E024/scripts/verify.sh`
- `experiments/E024/Sources/InboxI1Verification/InboxSession.swift`
- `experiments/E024/Sources/InboxI1Verification/InboxBoundaryKeys.swift`
- `experiments/E024/Tests/InboxI1VerificationTests/InboxSessionTests.swift`
- `experiments/E024/evidence/native.jsonl`
- `experiments/E024/evidence/source-sha256.txt`
- `tools/acceptance/login-ui/scripts/build-app.sh`
- `plan/rivet-design-language-adoption/evidence/VisualDesignPreview.swift`
- `plan/rivet-design-language-adoption/evidence/visual-review.md`
- `plan/rivet-design-language-adoption/evidence/cd-verification.md`
- `plan/rivet-design-language-adoption/evidence/design-language-candidate.png`
- `analysis/pr-inbox-i1-verification/requirements.md`
- `analysis/pr-inbox-i1-verification/technical-spec.md`
- `plan/pr-inbox-i1-verification/pr-inbox-i1-verification.plan.md`
- `plan/pr-inbox-i1-verification/pr-inbox-i1-verification.step.md`

#### Written

- `Sources/Presentation/PRInbox/InboxWorkspace.swift`，正式容器與 compact 版面。
- `Tests/RivetPresentationTests/InboxWorkspaceTests.swift`，驗證新容器的版面門檻與降階選擇。
- `experiments/E024/evidence/variant-b-native.md`，七項案例、Login 對照、Human VoiceOver、環境、設定及還原結果。
- `experiments/E024/evidence/variant-b-native.jsonl`，新原生 run 的選取、焦點與 Open 紀錄。
- `experiments/E024/evidence/variant-b-source-sha256.txt`，新 run 的來源及校驗值。
- `experiments/E024/evidence/variant-b-screens.png`，明暗、受限寬度與各必要狀態的截圖索引。
- `docs/presentation/pr-inbox-visual-adoption.md`，驗收及 Human 接受後回寫正式採用及適用限制。

#### Modify

- `Sources/Presentation/PRInbox/InboxHeader.swift`，僅提供 workspace 的內部 title／subtitle 樣式與 Picker enablement 接線。保留 standalone Header 契約。
- `experiments/E024/Sources/InboxI1Verification/InboxWindow.swift`，使用正式容器與 420 pt 驗收入口，保留原 Session、焦點和 Open 接線。
- `experiments/E024/Sources/InboxI1Verification/InboxI1VerificationApp.swift`，加入唯有驗收使用的 Picker／長欄位 fixture 控制。
- `experiments/E024/README.md`，補上 A1 重現方式與新證據連結，保留舊判讀及受測來源。

#### Deleted

無。

### 新增原生驗收

同一個 Variant B App 產物記錄來源、binary SHA-256、版面實際 pt、macOS／Xcode 版本、實際系統設定、操作與結果。用既有 Login 驗收工具在同機、同 appearance 擷取並排畫面。原 I1-01～07 的資料連續性、錯誤、已知離線及精確 Open 次數再跑一次。合成資料與 disabled filter 原案例均保留，啟用 Picker 的 fixture 只供驗收。先記錄強調色、Reduce Motion、Increase Contrast 與 Reduce Transparency 的原值。驗收結束後復原本輪改動的設定並核對原值。

| ID | 情境 | 必要觀察與證據 |
| --- | --- | --- |
| A1-01 | Light 鍵盤 | 使用啟用的驗收 Picker，觀察 Tab／Shift-Tab 在 Picker、List 與既有可聚焦項依原生順序移動。方向鍵與 Home／End 只改選取，Enter 僅在有效焦點／可安全開啟時恰好一次。原 disabled fixture 無作用。錄下焦點與前後事件數。 |
| A1-02 | 非預設系統強調色 | 同一已選列在系統預設與至少一種非預設 accent 下比較。原生選列、焦點與啟用 Picker 隨系統表現，停用狀態可辨，Rivet 非控件表面角色維持。保存設定與明暗代表畫面。 |
| A1-03 | Increase Contrast | 比較 off／on 的選列、焦點、分界、靜態文字與 disabled Picker／復原，確認可辨識且可操作。記錄隨動的 Reduce Transparency，驗後復原兩者。 |
| A1-04 | Reduce Motion | off／on 各切可讀／空／錯誤與寬窄版。焦點落在相同目的地，Open 與資料保持預期。新增容器在 on 時無自訂動效阻斷操作。保存設定與逐步事件。 |
| A1-05 | 跨 App 作用中／非作用中 | 在 Inbox 選 B，切至另一個實際 App 的 key window，再切回 Inbox。保存兩 App 的作用中依據和明暗其中一組的 active／inactive 畫面，確認 inactive 仍可辨且 B 保留。失去焦點後不產生 Inbox Open，回到 List 後安全 Enter 恰一次。 |
| A1-06 | VoiceOver 實際朗讀 | Human 實聽 compact 品牌一次、目前列的完整 PR 識別／標題／選取、Picker 與 disabled 語意，以及載入／空／錯誤／離線的局部通知與焦點。逐案記下實聽結果。AX 樹與截圖保留為輔助證據。 |
| A1-07 | 完整 workspace 受限寬度 | Light／Dark 各量測整個 window content width 為 420 pt，同時記錄列可用寬度。確認 compact 側欄、Header、Picker、Surface、List／狀態與事件區皆可用。長標題單行尾截斷且完整 AX 名稱和 PR 識別可得，無水平溢出。由寬到窄再回寬仍保有選取及可操作焦點，調整寬度本身的 Open 增量為零。舊 420 pt 圖僅涵蓋裸 Inbox 候選。 |

### Plan Review 與停點

1. 獨立 Plan-Reviewer 核對四份修正、精確路徑、`origin/dev` 與 tag、唯一新增公開接線、原生契約及七項證據。明示 verdict，若有 required finding 先回修送複審。
2. 不在此輪進入 Swift 實作階段。Plan Review 的批准與後續實作授權均有明示紀錄後，再同步 feature branch、實作並跑既有 Presentation／E024 測試、格式／lint／diff 範圍檢查與 A1 原生驗收。
3. 驗收記錄每案通過、未通過或無法判定。VoiceOver 及產品採用仍需 Human Review。任何需要擴大正式 API、套件、路徑或採用 Border 的結果先回 A1 審查。

[PR #97](https://github.com/a129924/rivet/pull/97) · [PR #101](https://github.com/a129924/rivet/pull/101) · [Visual Design Contract](https://github.com/a129924/rivet/blob/v0.1.97-rivet-design-language-adoption/docs/presentation/visual-design-contract.md) · [Inbox 移交](https://github.com/a129924/rivet/blob/v0.1.97-rivet-design-language-adoption/plan/rivet-design-language-adoption/evidence/cd-verification.md)
