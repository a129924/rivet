# Async Request Lifecycle & Commit Guard Verification 執行計畫

Topic `async-request-lifecycle-commit-guard`，基線 `dev` `c389454`，隔離分支 `chore/async-request-lifecycle-commit-guard`。實驗編號 E023，建立前查本地目錄、索引及可達歷史。維持原 dev 工作樹既有修改。 [需求](../../analysis/async-request-lifecycle-commit-guard/requirements.md) · [規格](../../analysis/async-request-lifecycle-commit-guard/technical-spec.md)

## swift-implementation 交接

| 欄位 | 契約 |
| --- | --- |
| In-Scope | E023 的 SwiftPM owner、受控來源、情境驅動、CLI、Swift Testing 與八段 README 設計。 |
| Out-Of-Scope | 產品接線、公開介面、BC 契約、真網路、OAuth、正式採用。 |
| ReadOnly | 四份規劃檔、正式 Swift／WebView、根套件、既有測試、實驗與索引、Reader／Inbox Port、Outcome、Adapter、REST、Auth、Transport、取消基線文件。 |
| Written | 新增 `experiments/E023/Package.swift`、`README.md`、`Sources/**`、`Tests/**`。 |
| Deleted | 無。 |
| Modify | 實作階段僅能修正本輪新建的 E023 檔案。 |
| Goal | 以可重現事件驗證請求身分、取消、結果提交與清理。 |
| Non-Goal | 通用 TaskManager、產品 UI 驗收、HTTP 取消重驗、跨環境保證。 |
| TestCase | V01–V10、V06 六種順序、V08 獨立對照、V09 源碼檢查、V10 實際 handle 與對基線的寫入範圍核對。 |

## 驗證、工具與交付

Tester 從根目錄獨立執行 `swift test --package-path experiments/E023` 及 `swift run --package-path experiments/E023 async-lifecycle-probe`。保存日期、版本、指令、來源識別、exit 狀態及 JSONL。依規格既定判準與預算判讀。在八段 README 記錄狀態、本輪完成否與 Code-confirmed／Test-confirmed／Experiment-confirmed／Unverified 證據。經 Reviewer 確認仍有效的有限結論，回寫既有 Swift 取消基線。後續產品採用需另有 Presentation Session owner、產品整合測試及獨立審查。

| 工具 | 交付 |
| --- | --- |
| show-me | 對照實際源碼與 trace 的同步完成呼叫樹。 |
| graphify | 0.9.73，每次設 `GRAPHIFY_NO_AUTO_REFRESH=1`，查相符既有圖後回源碼。缺圖則用定向源碼。 |
| archify | 依 V08／V10 製作一張繁中 sequence，showcase 9/9、deliver、visual-check 及人工檢視，保存本機收據。 |
| pr-lens | 0.11.0 依真實 base/head 在外部暫存 validate／render。待真實 head 時直接核對白名單 diff。 |
| floorplan | 複製既有本機圖至隔離 worktree 刷新，Recent work 僅標 E023，本機預覽。受阻記錄原因。 |

輔助輸出留在本機，結果依源碼、測試及 trace 判讀。先完成獨立規劃審查，再實作、測試與獨立成果審查。Human 已授權無重大問題時提交單一 topic commit、push 及開以 `dev` 為 base 的 Draft PR，交 Human review。目標於 2026-11-24 18:20 台北時間收斂。
