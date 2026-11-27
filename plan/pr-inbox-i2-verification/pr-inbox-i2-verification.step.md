# PR Inbox I2 · 步驟帳本

Phase 為 Completed。Topic `pr-inbox-i2-verification`。 [執行計畫](pr-inbox-i2-verification.plan.md)

| ID | 狀態 | Owner role | 完成條件 | 驗證證據／verdict |
| --- | --- | --- | --- | --- |
| I2-P01 | completed | Plan-Creator | 四份 planning artifacts 涵蓋已確認範圍、接線、案例及停止點 | 已寫入本 topic 四份檔案。 |
| I2-P02 | completed | Plan-Reviewer | 獨立審查四份檔案及契約一致性 | 初審 `needs-rework`。補上 I2-02 非首列選取及 I2-05 第二頁等待期間的觀察。複審 `approved`，必要修正 0。 |
| I2-P03 | completed | Plan-Creator | 補齊 `swift-implementation` 九個欄位、分支名稱及五項輔助工具的用法 | 已更新執行計畫，保留 I2-01～07 判準及完成條件。 |
| I2-P04 | completed | Plan-Reviewer | 獨立審查執行契約增補、路徑邊界與產品驗收一致性 | 增補審查 `approved`，必要修正 0。九欄、分支、五項輔助工具及原驗收邊界相符。 |
| I2-H01 | completed | Human | 審閱完整版並明示是否授權執行 | Human 核准增補版 processed-plan，授權從 `dev` 建立獨立工作樹、實作與驗收。 |
| I2-I01 | completed | Implementer | 在 E025 實作共用資料呈現與受控、真人兩個入口 | 工作樹已從 `dev` `0623246` 建立，分支 `chore/pr-inbox-i2-verification`。Graphify 的現行 checkout 無可用圖，已回讀正式來源、Facade、REST、OAuth 與 Workspace 原碼。E025 已建置並交 Tester。 |
| I2-V01 | completed | Tester | 核對 I2-01～06 與既有 Inbox 回歸 | 獨立 Tester 自動化 7／21 項通過，原生 I2-01～06 通過。 [驗收證據](../../experiments/E025/evidence/acceptance.md) |
| I2-V02 | completed | Tester／Human | 驗收當下獨立核對真人樣本與原生四欄，或記錄未能取得證據的原因 | Profile 已續期，Human 授權並完成同一 OAuth App 登入。I2-07 原帳號與原生四欄比對通過。 [真人驗收](../../experiments/E025/evidence/i2-07-live.md) |
| I2-R01 | completed | Reviewer | 核對實作範圍、受控與真人結果和完成判定 | 獨立 Reviewer `approved`，必要修正 0。核對首輪受控通過及當時 I2-07 未執行。 |
| I2-R02 | completed | Reviewer | 獨立核對 I2-07 續期、登入與原生上屏證據 | `approved`，必要修正 0。獨立核對 GitHub 詳情、原生四欄、安全收據、同身分簽章及私有截圖 SHA-256。 |
| I2-H02 | completed | Human | 審閱並接受有界驗收結果 | Human 於 2026-11-27 明示接受 I2-01～07 的驗收結果，並要求回寫已驗收範圍及證據連結。 [視覺採用文件](../../docs/presentation/pr-inbox-visual-adoption.md) |
| I2-V03 | completed | Tester | 在最新遠端 `dev` 的整合候選驗證 E025、根套件與合併前檢查 | E025 測試 7 項、Inbox 回歸 21 項、App 組裝與根套件 640 項測試通過。六項 pre-commit 檢查通過。見下方整合回歸。 |
| I2-H03 | completed | Human | 接受 I2-V03 整合回歸並確認交付 | 使用者接受 I2-V03 並授權合併與清理。 |

## 最新 dev 整合回歸

- 獨立審查接受 PR #110 的 I2 有界成果，指定合併前重驗最新基線。原基線 `0623246ae36da158c4d858e9290087b28e9ae9db`，遠端 `dev` 為 `4261f9c55faf5ce0194906fcea45fb47de5b2574`，已審查 HEAD 為 `03d77f683b3776dfdf5f9eaf842b55d018bdecf8`。在隔離 checkout 測 GitHub 產生的 `refs/pull/110/merge`，commit 為 `eac67cf1a132139f3417af020d5496dc0192402a`，tree 為 `c06ff983ae651ea20726091229eec89830bfbc94`。兩個 parent 及驗證結束時的遠端 refs 均核對相符。 [PR #110](https://github.com/a129924/rivet/pull/110)
- `dev` 新增送出 Review 的 JSON request header preset 和 HTTP 422 技術分類。`GitHubSelfReviewSource` 保持既有 REST header preset，並將新增的 `.unprocessableContent` 一樣映射至 `PRInboxFailure.unavailable`。根 `Package.swift` 新增 Review 的實作與測試 target，套件 pins 相同。整合候選的 E025 與已審查 HEAD 相符，正式程式、測試、根套件及 WebView 檔案與 `dev` 相符。
- `verify.sh test` 7 項（展開 10 案）、`verify.sh regression` 21 項（展開 39 案）、`verify.sh build` 均通過。確認 `InboxI2Verification.app` 含可執行檔與 RivetPresentation 資源 bundle。根套件 `swift test` 640 項、79 個 suites 通過。I2-07 真人結果沿用原已接受證據。 [I2-07 真人原生驗收](../../experiments/E025/evidence/i2-07-live.md)
- 整合差異的 `git diff --check` 與六項 pre-commit 檢查通過，涵蓋行尾空白、檔尾、Swift format、GitHubIntegration consumer contract、SwiftLint 及 renderer check。GitHub 顯示 `MERGEABLE`／`CLEAN`，PR 維持開啟，當時無 CI checks 列出。

[PR #110](https://github.com/a129924/rivet/pull/110) 於 2026-11-27 14:50:39（Asia/Taipei）合併至 `dev` 並關閉。合併 commit `b14be5f1b341dc783cb5b07ba031a6c0d1ece622` 的兩個 parent 與 I2-V03 使用的 base、HEAD 順序相同，Git tree 均為 `c06ff983ae651ea20726091229eec89830bfbc94`。

Annotated tag `v0.1.103-pr-inbox-i2-verification` 已推送至 `origin` 並讀回，指向合併 commit。本機與遠端 feature 分支、遠端追蹤分支及 feature worktree 的目錄與 Git 註冊均已移除。 [驗證摘要](../../experiments/VALIDATION-SUMMARY.md#pr-110-e025-pr-inbox-i2-整合驗收)

**輔助工具**　Archify showcase 9／9 與四種視窗尺寸通過。PR Lens 已驗證實際本機差異。show-me 收錄原生畫面。Floorplan 於隔離副本驗證 15／15 檔案描述及直接依賴，Swift 外部 REST 連線依原碼補入。

**Blockers**　無未解阻礙。

**Human Check**　執行授權、I2 原生驗收與整合回歸接受分別記於 I2-H01、I2-H02 與 I2-H03。

**最後更新**　2026-11-27（Asia/Taipei）。I2 有界驗收、最新 dev 整合回歸及 PR #110 合併後清理均已完成。
