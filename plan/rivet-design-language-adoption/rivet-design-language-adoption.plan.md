# Rivet Design Language Adoption — Phase A／B

- Topic `rivet-design-language-adoption`
- Branch `feat/rivet-design-language-adoption`
- Base `dev` @ `2764e64a77732902693b7890b346b2f3fa3f487d`
- 所有寫入限獨立 feature worktree。A／B 的 Draft PR 以 `dev` 為目標並承載 Human Review。原 I1 Draft PR #97 和 E024 只供來源追溯。
- [需求](../../analysis/rivet-design-language-adoption/requirements.md) · [技術規格](../../analysis/rivet-design-language-adoption/technical-spec.md) · [帳本](rivet-design-language-adoption.step.md)

## Goal

交付可重現的 Login／Inbox 正式元件基線、Inbox 原生候選與視覺盤點，讓 Human 決定 `RivetPresentation` 可共用的視覺角色。

## Non-Goal

保護已採用的 Login UI／UX、公用介面、parent-owned phase 與 intent，以及 PR Inbox 原生互動和現有 Presentation 職責。候選只驗證視覺語言在工作區呈現的可行性。

## In-Scope

- **A｜盤點。** 追溯八組 Login sRGB 值與使用位置、品牌幾何、文字與間距。在凍結的 `dev` 以 Xcode 渲染 `InboxHeader` 的「Standard · Needs Review」與 `PullRequestList` 的「Six PRs and Open probes」，各擷取 Light／Dark。標示正式元件、preview wrapper、I1 host 證據的各自來源。四格 Inbox baseline 收入 `design-language-candidate.png`。擷取失敗填列缺口、原因與對結論的影響，交 Human。B 候選及 I1 無法證明凍結基線的 Canvas 呈現。
- **B｜探索。** 在獨立原生預覽展示亮暗色板、表面、文字、間距、品牌及 Inbox 候選。以 `background`、`primary`、`secondary` 作優先評估。保留系統樣式的 List、segmented Picker、行內文字與 disabled 行為。預覽的詳細配置與歸屬見技術規格。
- 由 checkout 根目錄將 fixture 編譯到外部暫存路徑。以真正的 macOS 視窗操作，焦點移至其他應用程式視窗再回到候選。驗證後還原變更的系統設定。

```sh
preview_run="$(mktemp -d)"
xcrun swiftc -swift-version 6 -parse-as-library -g \
  plan/rivet-design-language-adoption/evidence/VisualDesignPreview.swift \
  -o "$preview_run/RivetDesignLanguagePreview"
```

## Out-Of-Scope

正式 Login、Inbox、Reader、根套件、既有 acceptance tool 和 I1 topic。包含 Sidebar／Content／Workspace、filtering、Open／Selection／Focus 行為、認證、Domain、Application、Integration、網路、儲存、新 package、framework 與 Theme Engine。

## ReadOnly

- `README.md`
- `docs/design-principles.md`
- `docs/development-workflow.md`
- `docs/architecture/README.md`
- `docs/architecture/bounded-contexts/pr-inbox.md`
- `docs/presentation/login-ui.md`
- `docs/presentation/native-interaction-contract.md`
- `Sources/Presentation/Login/RivetLoginArtwork.swift`
- `Sources/Presentation/Login/LoginStyles.swift`
- `Sources/Presentation/Login/RivetLoginView.swift`
- `Sources/Presentation/Login/RivetLoginView+Previews.swift`
- `Sources/Presentation/PRInbox/InboxHeader.swift`
- `Sources/Presentation/PRInbox/InboxHeader+Previews.swift`
- `Sources/Presentation/PRInbox/PullRequestList.swift`
- `Sources/Presentation/PRInbox/PullRequestList+Previews.swift`
- `Sources/Presentation/PRInbox/PullRequestRow.swift`
- `Sources/Presentation/PRInbox/PullRequestRow+Previews.swift`
- `plan/rivet-login-ui-adoption/evidence/human-acceptance.md`
- `plan/rivet-login-ui-adoption/evidence/acceptance-ownership-human-acceptance.md`
- `tools/acceptance/login-ui/README.md`
- `tools/acceptance/login-ui/scripts/build-app.sh`
- `Package.swift`
- `Package.resolved`

## Written

- `analysis/rivet-design-language-adoption/requirements.md`
- `analysis/rivet-design-language-adoption/technical-spec.md`
- `plan/rivet-design-language-adoption/rivet-design-language-adoption.plan.md`
- `plan/rivet-design-language-adoption/rivet-design-language-adoption.step.md`
- `plan/rivet-design-language-adoption/evidence/VisualDesignPreview.swift`
- `plan/rivet-design-language-adoption/evidence/visual-review.md`
- `plan/rivet-design-language-adoption/evidence/login-baseline.png`
- `plan/rivet-design-language-adoption/evidence/design-language-candidate.png`

`visual-review.md` 收錄盤點、重現命令、環境與版本、兩張 PNG 的逐格索引、原生觀察和待決事項。PNG 使用可逐格核對的標籤與擷取圖。個別原圖、binary 與 build/cache 留在 checkout 外。

## Modify

`None`

## Deleted

`None`

## TestCase

| ID | 情境／觸發 | 可觀察結果 | 證據／契約 |
|---|---|---|---|
| DL-01 | 核對 pinned baseline 與 A inventory，渲染指定 Inbox `#Preview` 明暗版 | 八組色值、用途、品牌幾何、字級與寬度行為可追溯。四個 Inbox baseline 格呈現正式 Header／List，B 候選及 E024 有獨立來源標記。渲染缺口附原因和影響提交 Human | `visual-review.md`、`design-language-candidate.png`，草案 §4、§6 |
| DL-02 | 同一台機器、同一 Login acceptance binary、`.standard` copy 及 780 × 500 pt 預設視窗，依 Light／Dark 分別啟動 | Welcome 17 pt 明暗、PAT Light 17 pt、Waiting Dark 17 pt、browser／token failure Light 21 pt、Welcome Light 13／21 pt 有可比對畫面。每格記 `--state`、`--appearance`、`--text-size` | `login-baseline.png`、逐格紀錄與工具 receipt，Login UI 契約、草案 §14.2 |
| DL-03 | 預覽 samples 明暗、Inbox 明暗 × 760／420 pt | 色板、文字、表面、間距與品牌清楚。窄版長標題單行尾截斷，核心文字和控制項可讀 | `design-language-candidate.png`，Native §7／§8、草案 §14.1／§14.3 |
| DL-04 | 在 macOS 實際操作選取，切換 system accent、Increase Contrast、active／inactive 與 Reduce Motion | 所選列文字可讀，原生選取、失焦與 disabled 有別。回到 active 時保有選取，Reduce Motion 無自訂延遲 | 代表性畫面、操作紀錄，`AC-NI-026/027/028/035/036` 的 fixture 子集 |
| DL-05 | 以 Tab／Shift-Tab、方向鍵進入控制項並切換選取，請 Human 用 VoiceOver 閱讀 | 鍵盤焦點可見且可離開，讀出列名及選取語意，裝飾品牌圖形無重複朗讀。未實聽或未操作項記原因與影響 | 操作紀錄及 Human 回報，Native §7／§10 |
| DL-06 | 編譯候選，核對凍結基線到 worktree 的 tracked 與 untracked 變更 | 單檔原生候選 Debug 等效編譯通過。差異完整落於 Written 的八個精確路徑，沒有 package 或產品 target 依賴 | Build 退出碼與路徑清單，Native §13 |

## Gate 與交付

1. Plan-Creator 建立四檔。獨立 Plan-Reviewer 明示 `approved` 後，Implementer 才執行 A／B。Tester 交證據給獨立 Reviewer。
2. Login acceptance tool 的新 artifact 先經獨立 source review。出示來源 SHA、精確 App、binary SHA 與有限案例，取得當下確認才可 launch。工具規則與 Phase B 視覺採用各有停點。待確認期間可完成不依賴該 launch 的工作。
3. 無重大問題時依人類授權執行 scoped commit、push 與 A／B Draft PR。Draft PR 收錄已驗結果及缺口，承載 Human Review。必要原生內容未驗時送交 Human 釐清，未驗狀態照實登錄。
4. Phase B 停在 Human 採用。共用語意、品牌、原生邊界需要明確決定。若證據不足或有相容性衝突，提出影響與取捨。Draft PR 可供檢閱。進入 C 須另有視覺採用與同 topic amendment。

## C–E 後續里程碑

- **C｜共用能力。** 採用後以同 topic amendment 鎖定 Visual Design Contract 和 Swift 路徑，交獨立 Plan-Reviewer。`docs/presentation/visual-design-contract.md` 為候選位置。優先提取 Login 實際使用的最小色彩與 glyph 能力，保留 sRGB、幾何與語意。其餘角色採文件或 feature styles。共用能力留在 non-BC `RivetPresentation` 內部，依賴 SwiftUI／AppKit 與 Presentation 資源。
- **D｜Login 等效接線。** 以 DL-02 同機、同配置、同 fixture 前後比對，再核對 public interface、parent-owned phase／intent、focus、鍵盤及 VoiceOver。非預期差異交 Human。重跑既有 Login 測試、`packageDeclaresTheLockedTargetGraph`、Debug／Release、root `swift test` 及精確路徑核對。
- **E｜交付。** 交付 Visual Design Contract、Login 前後證據、Inbox 候選、回歸驗證及 Inbox 採用清單，等待 Human 最終接受。交付後停止。原 Inbox topic 待新 `dev` 基線獨立 Plan Amendment／Review，鎖定視覺角色、允許檔案與原生回歸。

## C／D Swift Implementation Admission

B 獲 Human 採用後，在同一 slug 四份 SDD artifacts 鎖定 C／D 九欄、基線、分支與 checkout ownership。獨立 Plan-Reviewer 明示 `approved` 才能變更正式 Swift。下表列填寫條件，採用項目與確切檔案由 amendment 鎖定。

| 欄位 | C／D 要求 |
|---|---|
| Goal | 提取 Human 採用且 Login 直接使用的最小共用視覺能力，同 fixture 驗證 Login 外觀與互動等效 |
| Non-Goal | 保護 Login 公開介面、phase／intent、版面與原生互動，不重設 workflow 或改既有契約 |
| In-Scope | 採用後的契約、最小 internal Swift 色彩與品牌能力、Login 接線及回歸。Typography／Spacing 優先文件化 |
| Out-Of-Scope | 正式 Inbox 採用、PR Reader、Workspace／navigation、新產品狀態、Theme Engine、新 package、Domain／Application／Integration 及認證行為 |
| ReadOnly | 列出凍結基線已存在的精確 repo-relative 契約、驗收入口與保護元件 |
| Written | 列出凍結基線尚未存在的精確新增檔案，每個 Swift 抽象有直接 consumer |
| Modify | 列出凍結基線已存在且確需變更的精確檔案，限經審查的接線與 SDD 更新 |
| Deleted | 預設 `None`。若證據支持，鎖定基線已有的確切檔案、必要性及恢復方式 |
| TestCase | 預先鎖定穩定 ID、可重現 trigger、預期結果、證據與採用契約追溯 |

Path sets 兩兩互斥，空項填 `None`。按凍結 C／D 基線核對存在性，逐檔核對最終差異。必要決策或路徑有缺口時，交對應角色判定並停在該階段。

| 候選 ID | 觸發及結果 | 證據及追溯 |
|---|---|---|
| DL-S01 | 按 DL-02 同機、同窗與同 fixture 前後比較，各 phase、scaling、sRGB 及 glyph 等效 | 前後圖、配置與版本，採用的 Visual Design Contract 與 Login UI 契約 |
| DL-S02 | 原生操作 Welcome／PAT／Waiting／Failure，界面、phase／intent、鍵盤、focus 與 VoiceOver 維持基線 | 既有測試、原生及 Human 聆聽紀錄，Login UI 契約、Native §7／§10 與受測的 `AC-NI-026/028/035/036` 適用部分 |
| DL-S03 | Debug／Release、root `swift test`、`packageDeclaresTheLockedTargetGraph`、精確 path diff 與 imports／符號檢視 | 退出碼、依賴與 scope diff，Visual Design Contract、Native §13 |

## 後續本機工具

C–E 工具輔助檢視和交付。工具產物放 checkout 外，沿用既有設定及 SDD 停點。

- **git-branch-naming**　沿用已確認且通過 `git check-ref-format` 的 `feat/rivet-design-language-adoption`，符合 repo 的 `<type>/<work-item>`。無 owner 命名慣例。PR 目標 `dev`，Git 運作依 operator 分工。
- **archify**　以 workflow 畫 B 採用、C 審查、D 等效及 E Human 交付。繁中作者內容，英文 Viewer／`html lang` fallback。Showcase 九項通過及零 errors／warnings 後 `deliver`，再執行 `visual-check` 並實際檢視明暗擷取。本機保存。
- **pr-lens**　使用 0.11.0，記錄真實 base…head，執行 `validate`、`render` 並對照 manifest 與原始 diff。既有 overlay 才使用，已查無 overlay。若失敗記原因，回直接 diff。
- **graphify**　使用 0.9.73。C 若仍無可用圖，針對核准的 Presentation 來源，在外部 scratch 使用 AST-only `extract --code-only --no-cluster --no-gitignore --out`。每次 CLI 設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。記錄 source revision 和命令，查詢後回源碼證實。失敗記錄並定向查源碼。
- **show-me**　用對話最小圖說明 readiness。E 使用已審查的 Login 前後證據與 Inbox 候選說明差異。
- **floorplan**　現有 ignored map 建於 2026-11-24，含 536 檔，來源 `4955cff`。C／E 對凍結 review head 建立外部 scratch 副本並刷新地圖副本，保留現有 map。標出已採用的 Login／Design Language 與來源，只供本機檢視，停用 hosted Ask 與發布。
