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

## N：正式 hosted 有限 Live 驗收

Human 已明確授權使用既存 credential 與既存合格簽章，執行正式 hosted 設施的有限 first／fresh Live。此為 M 離線交付後的新受限階段，不重新開啟舊 E018；只在既有 feature worktree 執行，dev worktree 不修改。準備時 feature HEAD 為 `df801f6`，base dev 為 `0a71be9`，既有 PR #77 維持 Draft。既有 L／M 等歷史與 H01／M06 Human pending 保留。

### N Goal / Non-Goal / In-Scope / Out-Of-Scope

Goal：使用正式 hosted test bundle 與唯一正式還原 runtime，驗證既存連線 restore、交付 client 的 API、完整 credential readback 及 first→fresh 新程序連續性。
In-Scope：先離線／環境核對與獨立純 build-only 簽章 preflight，再以新授權 context 執行 first／fresh 各最多一次；每段實際程序退出後取得 Human 全程觀察與實際提示次數，SHA 綁定原 receipt；獨立結果審查與必要安全證據交付。
Non-Goal／Out-Of-Scope：初次登入／設定、seed／clear、強制到期、新 Apple 資產、舊 E018 重跑、產品 UI／產品 E2E、正式 OAuth runtime 或既有 contracts 的變更。不得因新 run-root 重設任何已使用額度，不自動重試任何 phase。

### N Acceptance Criteria

- NAC1：N02 獨立 planning approved 後，N03 先執行離線驗證及資產／程序資格核對；不得以正式 `--live --phase first` 作 preflight。
- NAC2：獨立 preflight 只允許新 owner-only root 的 `root_control(root, 'live', ctx)` 與 `build(root, 'live', ctx)` 純建置／簽章／驗證／測試列舉；不 bind context、不執行 phase、不 authorize、不讀 fixture、不消耗 first／fresh。
- NAC3：準備完成後由主 session 通知 Human，得到明確可全程觀察的回覆才可 first；先前其他輪次的回覆不代用。
- NAC4：first／fresh 每段最多一次、無 automatic retry。First machine passed、actual process 退出，且本段 Human 全程觀察、實際提示 0 次並綁定原 receipt SHA 後，才可 fresh。
- NAC5：每段後重新詢問是否全程觀察與實際 prompt count，不預設 0、不回填 machine placeholder；人工 attestation 獨立保存。
- NAC6：fixture 是否存在／到期只能正式 first 讀 DPK 後得知；缺失停止，不 seed。有效 credential 未觸發真 refresh 時，如實記錄本輪未涵蓋真 refresh，不強制到期。
- NAC7：新結果僅支持當次受限環境；原 E018／L／M 證據與人工觀察不改寫、不轉記。結果經獨立 Reviewer 後，按 topic commit／push、更新既有 Draft PR，再交 Human review。

N 授權參照為 `human-2026-11-18-hosted-live-first-fresh`；context 記錄此既有授權，不能自行擴張到登入、清除、額外 phase 或修工具。任何缺合格 profile／group／hosted 資格、工具問題或 runtime 失敗，停止並回報，不暗修或藉改 context／root 重試。

## N-R：nested test bundle 簽章路徑受限修正

N03 已依契約停止並保留失敗：Offline 通過、純 Live build 成功，但 runner `sign_products` 錯將 test bundle 視為 Products/Live 下外置產物；此 project 實際將它置於 host 的 Contents/PlugIns。獨立 Reviewer 已明示 needs-rework；主 session 已向 Human 明報缺陷與最小範圍。本節在原 Implement 授權內列明 bounded fix，不是暗修或新增 Live 額度。

### N-R Goal / Non-Goal / 受限例外

Goal 僅為修正此 project 的 signing target：test bundle 使用 `GitHubIntegrationTestHost.app/Contents/PlugIns/GitHubIntegrationHostedTests.xctest`，先簽 nested test bundle，再簽 host；缺任一預期產物須 fail-closed。
僅允許修改 `scripts/check-github-integration-hosted-tests.py` 的 `sign_products`，及 `Tests/GitHubIntegrationHostedTests/test_driver.py` 的純 mock／暫存 fixture TDD 回歸；其餘 tests／project／Swift 正式 Sources／manifests／contracts／CLI／context schema／phase budget／Apple 資產／舊收據仍 ReadOnly。不新增掃描或替代產物路徑，不藉此擴充一般 signing 系統。
Non-Goal 為改 runtime／hosted cases、重建 credential、變更授權或以 first 探路。原 N03 blocked 與失敗 preflight root／safe proof 保留 immutable；修後 source 另凍結，不反寫舊 pins。

### N-R Acceptance / phase 邊界

先 N02r 獨立 planning review → bounded Implementer TDD → Tester 完整 Offline／新回歸及 helper-only 純建置 preflight → Reviewer 審查修後 source／pins。仍使用同一 N context 與私有 parent `TMPDIR/rivet-hosted-live-n-20261118-m2mhtqhu/`，不改 authorizationRef、fixture、budget；目前未 bind、無 journal、正式 run-root 不存在，first／fresh 各使用 0/1、剩餘各 1。
修後只允許另一獨立純建置 root（`preflight-fixed`）固定修後 source；它不是 Live phase retry，不能 authorize／讀 DPK／呼 API。獨立 Reviewer 通過後，主 session 仍須通知並等本輪 Human ready 才正常 first。若再遇工具／環境失敗停止回報，不自動重試、擴修或換 context／root 重設額度。

## N-R2：App 內嵌程式碼 inside-out signing 受限修正

NR02 的第二次 blocked 已由獨立 Reviewer 分類 needs-rework：Live build 使用 CODE_SIGNING_ALLOWED=NO，framework 複製時排除 Modules 等 sealed files，但沿用 SDK CodeResources；原 SDK strict verify 通過、App 內複本失效。既有 sign_products 漏簽 App 內嵌 executable code，不是 profile／get-task-allow 已被證明無效。
僅在原 facility Implement 授權內，允許同兩個 py 檔的最小例外：runner 的 sign_products／內部受限 discovery helper 對本次 App 內實際 executable frameworks／dylibs 及其巢狀 code 由內而外簽章；test_driver.py 以純 mock／temp fixture TDD 驗證。維持手動 pipeline，不重構 Xcode native sign-on-copy，不改 project／Swift／CLI／schema／budget／正式 runtime／contracts／profile／identity／group，不新增 Apple 資產。
所有候選 resolve 後必須仍在本次 App 內，禁止誤簽 SDK；最內層先簽，再 test bundle，host 最後。全用同一既存 identity，只有 host 使用既定 DPK entitlements；純 resource bundle 不作 executable。任一內層簽章失敗立即停止；保留 deep strict verify，不刪 seal、不降格驗證、不用 codesign --deep --force。
保留原 N03 root 與 NR02 preflight-fixed／safe proof immutable；同一 N context 未 bind、無 journal／attempt／authorize／hello／正式 run-root，first／fresh 各使用 0/1。新修後 preflight-insideout 僅一次純建置，不是 phase retry／額度重設。新回歸＋full Offline → helper-only preflight → 獨立修後 source／pins review → 主 session 等 Human ready 才 first；再失敗停止，不自行擴大。

### N執行結果與待審邊界（2026-11-18）

正式hosted first／fresh各一次取得ready／API／完整讀回及同帳號新程序continuity，兩段Human重新全程觀察各0提示、原SHA分別綁定。兩段credential未到期，prepare／final refresh與save皆0，無本輪真refresh／rotation-save coverage。兩phase各1/1已耗盡，停止額外操作。原工具缺陷與失敗preflight、受限修正與NR13準備審查、新機器／Human結果各留來源；[新安全結果](../../plan/github-oauth-startup-restore-runtime/evidence/hosted-live.md)已由N06獨立有限結果review approved、無required finding；N07交付中，不改source或原machine。H01／M06及Human最終接受pending。
