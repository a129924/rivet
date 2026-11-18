# OAuth／PAT 正式登入 Runtime 執行計畫

Topic：`github-dual-login-runtime`。Branch：`feat/github-dual-login-runtime`；起點／PR 目標 `dev`，只在 feature worktree 實作。

依據：[需求](../../analysis/github-dual-login-runtime/requirements.md)、[技術規格](../../analysis/github-dual-login-runtime/technical-spec.md)、[帳本](github-dual-login-runtime.step.md)。

## swift-implementation 執行契約

| 欄位 | 邊界 |
|---|---|
| Goal | 共同 Protocol 完成 OAuth／PAT 驗證、對應持久化與有限結果；成功具備驗證與保存依據。 |
| Non-Goal | UI 接線、session／clients 交接、恢復、refresh／401 擴充、登出、帳號切換、多帳號、跨程序協調。 |
| In-Scope | 正式服務、OAuth 通道、共用 probe、stores 組裝、取消／提交／重疊拒絕、獨立入口與長期契約。 |
| Out-Of-Scope | 新 BC／應用層 target、PAT store、legacy 適配、active-mode、跨 store transaction、migration、delete。必要驗證 target 非應用層、隔離且可移除。 |
| ReadOnly | 登入 VO／Protocol／Outcome、正式 OAuth session／exchange、stores、provider／scope／clients、legacy、Presentation、既有實驗來源與歷史證據。 |
| Written | 四份 artifacts；GitHubIntegration 新 runtime／probe／callback、測試／consumer、獨立驗證入口、長期說明、Archify 規格／HTML／receipts／視覺證據；PR Lens 產物放 repo 外 topic 專屬暫存目錄。 |
| Modify | 必要 README／架構導覽／能力說明、測試或獨立驗證 consumer 接線及 target wiring；不接產品 UI／Presentation，不改 ReadOnly 契約與歷史證據。 |
| Deleted | 無；不刪 repo、既有 token／credentials／PAT 或歷史資料。 |
| TestCase | TC01–TC08；受控／真實／真人分開，不以舊 live 冒充 runtime 驗收。 |

## 接口與鎖定設計

Public Sendable GitHubLoginService conform 既有 LoginAuthenticating，接收 OAuth configuration、正式 OAuth／PAT stores、caller-owned GitHubLoginCoordinator。OAuth view 綁 clientID，測試注入 internal。同目標／共用任一目的地的 instances 必須共用 coordinator，涵蓋整次登入及收尾，重疊立即拒絕，取消優先。

OAuth 正式 session／exchange 加必要 loopback／browser，10 秒啟動、300 秒授權。直接候選 Bearer `/user` 驗證（200、正 id、非空白 login），驗證後 save；不經 scope.prepare、不 refresh／retry。另一方式憑證保留，不保存 identity／active-mode。

取消轉傳並等原工作／session／relay settled；relay 有可等待 shutdown。提交前取消不開始 save；已開始 save 等待結束，晚取消可 cancelled 且保留保存，不回滾。釋放 busy 後最後同步檢查，不再 await。其他 writer 不得同時 persist 為組裝前提。

## TestCase

| ID | 情境與通過依據 |
|---|---|
| TC01 | OAuth／PAT 一般 import 共同入口成功，驗證先於保存，完整值讀回，另一 store 保持。 |
| TC02 | 授權拒絕、browser／relay 失敗、逾時／交換失敗回有限 failure，零保存。 |
| TC03 | 非200、transport／JSON／id／login／Bearer無效：不保存、不retry。 |
| TC04 | Save失敗回有限failure，不刪舊值／不寫另一store／不修復fallback。 |
| TC05 | Barrier覆蓋預先、授權／probe／save中、提交前後與最後檢查取消；原工作及通道已收尾，不用sleep。 |
| TC06 | 同實例及共享coordinator跨實例立即拒絕重疊；收尾仍拒絕、釋放可重試、取消優先。 |
| TC07 | 一般import／Sendable consumer、診斷遮蔽、既有登入／OAuth／PAT回歸；swift test、Swift format、consumer check、strict lint。 |
| TC08 | 未來正式入口真OAuth／PAT驗證→save→fresh-process讀回，另記來源環境，不重跑舊storage矩陣。 |

受控測試不呼真 GitHub／Security。診斷不得包含 token、secret、code、state、verifier、授權／callback URL 或原始錯誤。

## 執行順序與工具交付

1. Plan-Creator 落四檔；獨立 Plan-Reviewer 明示 approved 才交實作。
2. Implementer 依契約在 feature 完成程式、受控測試、獨立入口及長期文件，不在 dev 實作。
3. Tester 親跑 TC01–TC07 與相關品質檢查；獨立 Reviewer 核對契約與證據。
4. Archify 正式 sequence：繁中作者內容／English Viewer fallback，showcase9checks／0errors／0warnings、deliver receipts、四尺寸 visual-check、人工看圖；不發布。
5. Graphify pin0.9.73 有既有圖才 bounded query→source核對，每次 NO_AUTO_REFRESH=1；無圖／失敗fallback rg，不建圖或改整合配置。
6. PR Lens pin0.11.0 對實際base/head，repo外local map含unchanged neighbors/file refs/hashes，validate/render；config只讀、不上傳發布，不代替review。
7. 依已授權topic commit／push／Draft PR交Human review，遵commit慣例檢查staged diff。TC08另有Human停點，不冒稱live通過。

## Human 與回撤

TC08 前確認當次有效配置／簽章／host／隔離 namespace／exact-owned 資料處置，未到該停點不新授權／交換／讀寫真憑證。原P07僅支持5465d3c指定環境PAT儲存，原圖/topicHuman pending及其他topic額度保持。撤回程式不自動刪保存結果；無migration與產品delete。
