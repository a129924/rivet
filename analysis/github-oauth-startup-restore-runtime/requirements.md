# OAuth 冷啟動連線還原需求

## Goal / Non-Goal
提供正式 caller-owned OAuth 還原入口；從既存設定與憑證取得本地 ready scope 或明確未完成結果。本地 ready 不代表遠端身分、repository 權限或後續 request 成功。

## In-Scope / Out-Of-Scope
範圍限 GitHub.com、單一 OAuth、唯一 owner、正式組裝、必要刷新及完整保存、取消、busy、caller 明示重試、受控 consumer 與文件圖證據。
不含初次登入／設定、重新授權、清除、PAT、多帳號、產品 UI、PR 載入、新 storage、變更原登入 Outcome／provider／refresh／401 policy、跨程序、migration、真人 OAuth／DPK、E014 或全 repo mapping。

## 已鎖定決策
重疊立即 busy；一次 restore 只 prepare 一次，不自動重試。Provider 建立後永久沿用，不重讀 configuration、不快取 ready；取消等待原工作 settled，不回滾成功 rotation，不建立替代 writer。

## Acceptance Criteria
- AC1 正式入口，不依賴 experiments。
- AC2 未設定、未登入、authenticationRequired 與有限技術失敗可區分。
- AC3 必要保存成功後才 ready。
- AC4 取消不假成功、不回滾已完成保存。
- AC5 重試保持原 provider，terminal 不復活。
- AC6 重疊與收尾只有唯一 writer，無晚到 ready。
- AC7 不清除、登入或切換帳號。
- AC8 一般 import consumer 可使用公開 scope／clients；不宣稱遠端認證成功。

## 授權
Human 已採納對話計畫並授權在獨立 feature worktree 實作、按 topic commit、push、開 Draft PR，最終由 Human review。不得在 dev worktree 實作。時間邊界為 2026-11-17 18:20 Asia/Taipei；若尚有 required fix 或證據缺口，Draft PR 如實標 pending，不冒稱完成。

## 2026-11-18 Live 驗收追加授權
Human明確要求開始原未執行的live OAuth／DPK。原實作範圍與歷史證據保持；新增E018正式入口有限first/fresh驗證，不啟舊實驗、不做新登入／清除／強制到期。只因原credential自然到期而必要的正式refresh／save在授權內。

## M：正式 hosted integration 測試設施修訂

Human 已採納正式修訂計畫並明示 Implement the plan。本輪維持原 topic、branch `feat/github-oauth-startup-restore-runtime` 與 Draft PR #77；只在既有 feature worktree 實作，不在 dev worktree 實作。查核基準為 `0debe0b`；原正式 runtime 實作 `e31a75a` 及 E018 有限 live 結果均為歷史證據，不因整理而改寫。

### Goal / Non-Goal

Goal：將必要驗證能力納入有明確執行入口、框架斷言及結果判定的正式 hosted integration 測試設施，遷出必要能力後退役 active `experiments/E018/`，不因依賴組裝新增實驗編號。
Non-Goal：不修改正式還原 runtime／public contracts、不交付正式產品 App 或 UI E2E、不重新證明舊 live 結果。本輪實作 Offline 及明確手動 Live 入口，但只執行離線／mock 驗證，不執行 Live build／簽章／DPK／OAuth，不簽發或執行新的 live context。

### 官方能力、工程慣例與本案選擇

- 官方能力：Swift Testing 可直接組裝正式元件執行 unit／integration tests；`TEST_HOST` 指定承載 test bundle 的 executable。真 DPK 存取取決於實際執行 host 的受授權 access group／簽章，test bundle 不能自行擴大 host 權限。參照 [Apple 測試文件](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project)、[Build settings](https://developer.apple.com/documentation/xcode/build-settings-reference#Test-Host)、[Keychain sharing](https://developer.apple.com/documentation/security/sharing-access-to-keychain-items-among-a-collection-of-apps)及 [Apple DTS 說明](https://developer.apple.com/forums/thread/724013)。
- 工程慣例：快速受控測試、真實整合與產品 UI 測試分開；需要真人憑證及簽章的測試獨立手動啟動。
- 本案選擇：採 hosted Swift Testing、薄測試 host、Offline／Live configurations 與單一 runner。下列目錄與命名為專案選擇，不是 Swift 語言或 Apple 強制的目錄規範。

### 測試層級 / In-Scope / Out-Of-Scope

| 層級 | 本輪安排 |
| --- | --- |
| 受控測試 | 既有 SwiftPM fake／公開 consumer 測試保持，驗證結果、保存順序、失敗、取消與重疊。 |
| 真實整合測試 | 正式 hosted target 組裝唯一正式 runtime；本輪只驗證 Offline 與 mock Live 協定，手動 Live 路徑尚未實證。 |
| 產品 E2E | 未來由 XCTest／XCUIAutomation 啟動正式 Rivet App，驗證產品入口及使用者可觀察結果；本輪不建立。 |

In-Scope：兩個 hosted targets、測試組裝／觀測／斷言、離線跨程序驗證、手動 Live 工具介面、結果與人工綁定契約、必要文件、active E018 退役。原正式 Sources／public APIs／SwiftPM manifests／受控與 consumer 測試保持。
Out-Of-Scope：新登入、seed／clear、強制到期、provider／refresh／401 policy 變更、新 Apple 資產、產品啟動／UI 接線及任何新增 live 操作。

### M Acceptance Criteria

- MAC1：正式 test bundle 一般 import 唯一正式 GitHubIntegration runtime，不複製還原邏輯；薄 host 不自行 restore，不成為產品 handler。
- MAC2：存在明確可執行 Offline 命令；受控測試與一般 SwiftPM／consumer／hooks／CI 不會因此觸發 Live。
- MAC3：Offline first／fresh 的案例選擇、實際程序分離、退出、產物來源與失敗結果均有實證。
- MAC4：手動 Live context／資格、額度、first→Human→fresh 與 SHA 綁定經 mock 驗證；本輪沒有真實 Live 執行，也不宣稱 live-ready 已實證。
- MAC5：業務斷言及 xcresult 不洩漏 token／client secret／完整 credential；只斷言衍生布林及計數。
- MAC6：移除 active E018 九個 tracked files 與其執行依賴；原 safe evidence bytes／SHA／人工觀察保持，舊工具可由 `0debe0b` Git 引用追溯。
- MAC7：舊 P／I／T／R／L 完成紀錄與 H01 pending 保留；新設施離線結果不冒充舊 live 或產品 E2E。

### 歷史與授權邊界

原 L first／fresh 各 1/1 已使用完。新的 run-root 不構成新的 live 授權或額度；本輪不得重新利用舊 context／markers。未來實際 Live 的 fixture 與簽章具體值為明確授權後的執行輸入，不由本輪實作者自行取得新登入、清除或發出授權。
