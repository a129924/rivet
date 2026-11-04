# GitHub 連線驗證結果摘要

來源基準為 [PR #62](https://github.com/a129924/rivet/pull/62) 於 2026-10-21T06:56:54Z 的合併點 `aa16de91b560027325419b7bc904d831851c9fcb`。E001–E007 與持續連線段落保留該來源；另於下節補已合併 PR #61 的固定來源 `14d0832f042720889993d769b4cbfb720078e6b1`，並補 PR #63 的合併點 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`。本次於 2026-11-03 整合 `613a505025774b3841ab73b4ed3b8774be38274a` 內已合併 PR #65／E008 的後續事實。本文彙整已有證據，不新增實驗、真人測量或正式產品採用決策。[導覽](README.md)列出各來源入口。

## 快速總覽（保留上游各輪限制）

| 實驗 | 觀察與來源 | 未由此證明的事項 |
| --- | --- | --- |
| [E001](E001/README.md) | 2026-10-07 真實 OAuth callback、非空 code、state 相符、exit 0。 | token exchange、refresh、儲存或正式產品登入。 |
| [E002](E002/README.md) | 真實正向 token、六欄 bundle、GET /user 成功；反向歸因不足。總體無法判定。 | PKCE enforcement；不將後續 X 或 E008 補成此輪成功。 |
| [E003](E003/README.md) | 2026-10-08 T01–T04 遠端測量成功，舊 refresh token 重用回 bad_refresh_token。 | 自然到期、provider 自動刷新、401 recovery、持久化或所有遠端配置。 |
| [E004](E004/README.md) | 2026-10-14 T01–T06、真 SQLite／跨程序／rollback 成功；fake refresh 與受控失敗。 | 加密、真遠端 rotation、sandbox、斷電 durability 或正式 adapter 採用。 |
| [E005](E005/README.md) | 最後 human-only 輪六欄保存與同身分重建讀回成功；Human 提示數首次／fresh／重建為 0／0／1，候選 UX 失敗。 | 所有免費 Keychain 路徑失敗、DPK 不可用或必須付費。早期 unknown 與 machine receipt 原值保留。 |
| [E006](E006/README.md) | 2026-10-19 假 bundle，首次／fresh／真重建讀回完整且 Human 均零提示，受限成功。 | profile 更新／過期恢復、certificate rotation、真 OAuth、公開分發。2026-10-16 controlled-stop／逾時歷史保留。 |
| [E007](E007/README.md) | 兩輪 renewal 前提未成立，renewal read 均未執行，結果無法判定；Human 已接受該未知限制。 | 不同 profile 的讀回成功；新版 export-clean 的受控檢查不代替原真人輪或新增真人驗收。 |
| [E008](E008/README.md) | 2026-10-22 單次安全 JSON 與兩名獨立先封存 enum；依固定判準無法判定。 | 普遍 PKCE enforcement、OAuth 漏洞、完整 wire 或正式安全決策變更。 |
| [E009](E009/README.md) | M03：Human 確認獨立未登入 session、未授權帳號、同輪登入／同意／300 秒內有效帳號；來源契約支持。 | agent 直接見證歷史 UI／network、2FA、完整零配置 UX、產品 readiness 或 PKCE。後續 build 不回填真人來源。 |
| [E010](E010/README.md) | PR #67 原 DPK E008 的準備／兩輪 controlled-stop 紀錄改號保全；M03/M04 遷移驗審通過，主假設未執行。 | 自然到期／P1 原 A 恢復、DPK／UX、GUI T01–03；原零 item filesystem cleanup 不當 Keychain 刪除驗證。 |

## E001–E007：已知結果與不能推論之處

| 來源 | 已觀察的結果 | 證據界線與缺口 |
|---|---|---|
| [E001](E001/README.md) | 2026-10-07 真 GitHub 瀏覽器授權回到本機 loopback，code 非空、state 相符，exit0。 | 沒有 token exchange；不證保存、refresh 或產品登入。 |
| [E002](E002/README.md) | 同日正向 exchange 成功，回應符合完整六欄並可建 public bundle；一次 GET /user 成功。 | 反向 PKCE 及 overall **無法判定**；兩次授權額度 2／2 已用完，不能將正向成功當作 PKCE enforcement 成功，也不自行第三次授權。 |
| [E003](E003/README.md) | 2026-10-08 一次真 refresh 產生新 pair、六欄相容，新 token API 與初始 user ID 相同；舊 refresh token 唯一重用回 `bad_refresh_token` 且無新 token。 | 只證該次真交換與輪替；沒有驗證持久化、既有 provider 自動刷新、自然到期或產品流程。 |
| [E004](E004/README.md) | 真 SQLite／GRDB 與獨立程序，配合假 credentials、fake refresh／受控 clock，驗證完整 bundle、交易 rollback、single-flight 及 accepted-save-failure 停止契約。 | 是真儲存加合成 OAuth 控制；不證真 GitHub、秘密加密、斷電耐久或正式儲存採用。 |
| [E005](E005/README.md) | Legacy Keychain 的完整假 bundle 資料機制成功；最新 human-only 首次／fresh／同身分重建提示為 **0／0／1**。 | 重建多一次憑證提示，既定零提示 UX **失敗**。早期 ad-hoc 身分不足與 UX unknown 保留；不能外推 DPK 或付費資格結論。 |
| [E006](E006/README.md) | 2026-10-19 假 bundle 存於真 DPK；免費 Personal Team、原 certificate、有效且相同 profile 下，fresh-process 與切換至 Rebuilt configuration 真正重建後六欄相符，首次／fresh／重建提示 **0／0／0**。 | 非真 OAuth／refresh，也未更新 profile。2026-10-16 setup 中止、DPK／UX 未測及清理超過原 deadline 的 unknown 歷史不被後輪成功覆蓋。 |
| [E007](E007/README.md) | 兩輪均安全收尾，但 **profile 更新後讀回未執行、無法判定**。第一輪 B 仍為相同 profile bytes；第二輪 backup／restore-check 的 provenance xattr 不符，在移出前停止。 | 第二輪 cache move／refetch／B Build 均0，不能說已更新後失敗或成功。Human 已接受「profile 更新後讀回未驗證」限制；不改為 pass，不開第三輪。 |

E007 [第一輪](E007/evidence/run-20261020T055923Z-6ff205d6-7110-4ba3-bf42-c98cd24d3302/final.index.json)與[第二輪](E007/evidence/run-20261020T065827Z-39443a2b-5d73-4a9b-a285-4d416cf70120/final.index.json)收據保持原工具版本。其後 `bf0db99` 僅版本化修正 runner／protocol tests／README，其他29份 E007 歷史不變：[新舊 SHA 清單](../plan/github-persistent-connection/evidence/verification-host-manifest.md)、[C03–C05 獨立驗證及審查](../plan/github-persistent-connection/evidence/verification-host-review.md)。36個 Python tests 與4組獨立 fresh-process CLI 只證合成故障下先耐久匯出、checkpoint 與可恢復清理；不是新版 runner 真人、第三輪 E007、物理斷電耐久或 renewal 證據。7個未變 SwiftCore tests 未重跑。

## PR #62：新獨立驗證 App 的整條流程

2026-10-21 的 [GitHubConnectionVerification](../apps/GitHubConnectionVerification/README.md) 明示「驗證用途，非 Rivet 正式產品」。真實服務與儲存結果見[新 host 真人證據](../plan/github-persistent-connection/evidence/verification-host-live.md)：

| 流程 | 本輪結果 |
|---|---|
| 簽章與前提 | 原免費 Personal Team／既有 Apple Development certificate、新驗證 identity／private group、有效 embedded profile、固定安裝位置。 |
| 登入 → 保存 → API | Human 在新 App 完成真 GitHub 授權，真 DPK 保存設定／完整 bundle，GET /user 顯示有效帳號。 |
| 完整退出 → 新程序 | 相同 binary／位置的新 PID 還原完整 bundle，無重新授權或 refresh，同帳號 API 成功。 |
| 真正 Clean／Build → 還原 | 舊 built product 確認不存在後重編譯／link／簽章；不同 binary、同身分／profile、同位置替換，新程序還原及 API 成功。 |
| 受控到期 → 真刷新／保存 | 只改 provider 注入 clock，真 GitHub refresh attempt1／accepted1、真 DPK save1；accepted＝persisted 六欄 digest，保存後回 real clock，同帳號 API 成功。 |
| 輪替後再退出 → 新程序 | 未強制到期、未重新授權，完整讀回新 digest＝前次 accepted／persisted，無 refresh／save，同帳號 API 成功。 |

六個流程共有七項 Human 分段提示觀察：setup／Team／build前、build完成，以及後續五個結果段，均為 **0次**。機器結果與 Human 回報分列，不能用沒有機器錯誤推定零提示。

初 grant 程序的 exclusive observe receipt 在空設定階段已寫出，**未觀測 grant 後 digest**；第一次完整已保存 bundle digest 在 fresh 程序直接觀測。新舊六欄 digest 不同及 aggregate tokenPairChanged 只證 pair 整體改變，不宣稱兩個 token 各自 hash。受控 provider expiry 觸發的是真 GitHub refresh，不等自然等候到期；未改 OS clock、response 真實接收時間或保存日期。

自動驗證另列：[契約測試](../plan/github-persistent-connection/evidence/verification-host-contracts.md)為 fake-only unsigned hosted **78 tests**；[隔離驗證](../plan/github-persistent-connection/evidence/verification-host-isolation.md)以當前 source 排除整個 App 後，production 普通 build、**202 tests／22 suites**、consumer **12 tests／3 suites**通過。真 legacy Keychain suite 明示未跑，未刪原測試。production Sources／Tests／Package／locks 還原 topic 前 `16606b89` 基線，沒有驗證專用正式 API、共用 UI、控制或反向依賴；逐檔歸屬與版本見[manifest](../plan/github-persistent-connection/evidence/verification-host-manifest.md)，獨立結果見[review](../plan/github-persistent-connection/evidence/verification-host-review.md)。這些通過不等正式產品登入能力已完成。

## PR #61：正式初次 OAuth 能力與單次反向收尾

[PR #61](https://github.com/a129924/rivet/pull/61) 已於 2026-10-22T03:17:27Z 合併；本節以合併點 `14d0832f042720889993d769b4cbfb720078e6b1` 的[長期說明](https://github.com/a129924/rivet/blob/14d0832f042720889993d769b4cbfb720078e6b1/docs/architecture/github-first-sign-in.md)及[安全證據](https://github.com/a129924/rivet/blob/14d0832f042720889993d769b4cbfb720078e6b1/plan/github-first-sign-in/evidence/pkce-semantic-review.md)為索引。真實執行的工具來源仍為 `4dbf3df`，不把文件合併 commit 冒充測量版本。

正式 `GitHubIntegration` 保留初次 OAuth configuration／factories／session／code exchange／errors，沿用既有 credential／provider／scope／clients。獨立 `GitHubSignInVerification` 收納配置及驗證 UI、loopback relay、coordinator、程序內完整 store、probe 與 hosted tests；使用真 OAuth／API，該來源當時正式 Rivet 產品登入 UI 尚未交付；目前產品入口依其自身工作線判讀。來源 `e941d88` 的正常登入、真 API 與同程序再次查詢成功，與 PR #62 的 DPK／跨重啟／refresh 驗收分開。

| X 收尾層級 | 實際結果與界線 |
|---|---|
| Native 正常操作 | 明確 click copy、Human 手貼公開 synthetic 句並逐字核對通過；不涵自然 timeout／cancel／Enter／late、OS 清除或無留痕。 |
| 唯一 wrong HTTP 事實 | 新授權／新 code／單 POST；HTTP400 invalid_grant、remote_rejected=true、無 token。本機 prepared 一致，提交合法但不同 verifier、challenge 不同。 |
| Provider 描述語義 | 兩獨立 AI 先封存一致 `verifier_mismatch_asserted`，來源 `provider_description_ai_review`；屬 provider 對當次拒絕的 mismatch claim，不是普遍 enforcement 或遠端 wire 證明。 |
| 保留的自動結果 | v3 outcome=indeterminate、pkce_rejection_proven=false、description_class=unknown、match_source=none；AI 軸不改既有判準或歷史。 |

新 X 預算 **1/1 已用盡**，本輪結束、沒有 retry／第二次／追加研究。P／Q 各 2/2、共享 R→T 1/1 的耗盡與舊 unknown、missing 無法判定均不回改；E002 的 2/2 與 overall unknown 仍是其獨立歷史。僅支持這次新授權、合法但不同 proof 的交換被拒且 provider 歸因 verifier 不符，不泛化所有設定／帳號／missing。正式登入 topic 的完整遠端 refresh／401 未因此驗證；PR #62 的受控到期真 refresh 是另一驗證 App 與來源的結果。

67 項工具受控測試與獨立 code review 沿原凍結證據，X 沒有重跑它們。原文只走已批准的單欄 clipboard／Human 手動 AI 閱讀例外；索引不保存描述原文、秘密、callback、code、state 或 token，不保證剪貼簿／同步／AI 服務留存消失。

## PR #63／E009：首次登入、授權與有效帳號

[PR #63](https://github.com/a129924/rivet/pull/63) 於 **2026-10-22T03:51:18Z** 合併，固定來源為 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`，最後 feature head 為 `fe9af0dbbbbf2cf72befd45fec23488e5ebf55c2`。[E009 原始分層紀錄](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/experiments/E009/README.md)及[長期結論與 C01 更正](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/docs/github-account-login-feasibility.md)採固定 permalink，保留原索引來源版本；本次合併後 E009 亦可由本機相對路徑查閱。合併 commit 是保存來源，不冒充真人或本機 build 的執行版本。

### M03：Human 回報與事前判準

Human 親自回報五步：使用工具的本次網址手動開啟；看見登入頁並完成登入；看見授權頁並親自同意；看見 callback 收到提示；返回工具看見 API 成功與帳號結果。另逐項確認三個前置／同輪條件：獨立／無痕 browser session 不共用原登入狀態且開始時未登入；測試帳號操作前尚未授權此 App；使用 E009 新版同一次手動準備的網址，API 成功在 300 秒內，期間未重啟／再啟動／改用舊網址。

| 事前判準 | 判讀與來源 |
|---|---|
| 看見 GitHub 登入頁 | Human 明示確認。 |
| 完成登入 | Human 明示確認；未獨立確認是否出現 2FA。 |
| 看見並親自同意授權 | Human 明示確認。 |
| 同流程取得有效帳號 | Human 確認同輪 API 成功／帳號結果，配合原碼契約支持。 |

因此 **M03 為受限成功**，僅成立於上述 Human 陳述的單輪條件；不等於 agent 獨立看見全程。

| 證據層級 | 實際取得與限制 |
|---|---|
| Human 觀察 | 上述五步與三項補充確認；不以 agent 未見錯誤代替。 |
| Agent 觀察 | 當時程序 executable 路徑、磁碟 binary／六份 source snapshot 指紋核對；M03 binary 為 `990917ac41d5543f342b6f32bc45daf8c665e44a67fa7d82e2da6379ec74e877`。不是歷史 PID／整輪關聯收據。 |
| 來源推論 | 同一 session／relay 的網址、callback 與單次 exchange，之後 probe；HTTP 200、正 id、trim 後非空 login 才是有效帳號。不是當輪 HTTP status／body／token POST 的獨立擷取。 |
| 未取得 | 全程 UI、network trace／server log、精確起訖與獨立計時、歷史 session 關聯、實際配置供給者／是否使用互動 launcher、當時主對話 ready 收據及 2FA 提示。 |

C01 已撤回 L01 的「新授權成功」判定，仍為無法判定；M03 是其後的新證據，沒有覆寫更正、A07 或 M01／M02 當時的未執行紀錄。A07 的 `e941d88` 真 API／再次查詢及 E002、P／Q、R→T、X 的來源、額度與判讀均保持各自歷史；M03 不新增反向 PKCE 證明或額度。

### M04 工具交付與合併相容性

PR #63 已納入同 repository 的初次 OAuth runtime、完整 `GitHubSignInVerification` host／必要 tests，以及 E009 一次性開發端 launcher。手動網址沿用同一 session／state／verifier、最多 300 秒、單輪後停止；開發端以 hidden TTY 供給程序環境配置，登入驗證者沒有配置欄位。Launcher 契約含 binary／程序身分核對、拒絕既有 App，不以秘密 argv／檔案／log 傳遞；這是工具機制，不追溯證明 M03 實際如何供給。

M04 的 hosted mock 為 17 definitions／18 executions、0 failures，root 275 tests／34 suites；helper synthetic／strict checks 與六 commit hooks 通過。其後兩次同步 dev 的合併只處理文件／source 相容性；涉及 host 的最後一次依序 build-for-testing、test-without-building、normal build 通過，仍為 17 definitions／18 executions、0 failures，未重跑 root 全 suite 或新增真人授權。最後本機候選 binary 為 `66aa6f9af216198df2e982aa2e9295fc16f9124e05a848aadac9676ae57dba2f`；M04 先前 `781e1413…`／`96ee9b…` 與 M03 `990917ac…` 均保留各版歷史。合併、重建或 mock 通過都不構成新的 live 結果，也不保證其他環境重建同 hash。

結果不外推完整零配置產品 UX、正式產品入口、production secret custody、persistence、公開發行或普遍 PKCE enforcement；不吸收並行 PKCE／產品 UI topic 成果。

### #63 已完成的 Git 收尾

Annotated tag `v0.1.57-github-account-login-feasibility` 已推送，遠端 peeled commit 與 `fccaf2b6` 一致；原 topic local／remote branch 與 managed worktree 已正常移除，沒有 force 或 GitHub Release。這是 #63 當時的收尾事實；當時 #64 尚未合併的交付快照不回寫，#64 後續結果另見文末。

## E008：三層結果

1. **交換觀察**：Human 手動提供的 [CLI 安全 JSON](E008/safe-result.json) 回報 HTTP400、invalid_grant、remote_rejected=true、token_present=false；新嘗試、單次 exchange、本機一致性與 verifier 欄位省略均有有限欄位紀錄。本機 prepared inputs 不等於完整遠端 wire 證明。
2. **Provider 聲明**：[封存結果](../plan/github-pkce-missing-verifier-feasibility/evidence/live-semantic-observation.json) 中，A／B 的 provider_claim 同為 verifier_required；A 的 pkce_causality=not_asserted，B=asserted。原始描述不保存，不重建原句或追加第三人重判。
3. **主要假設**：因當次因果判讀分歧，依執行前固定判準維持**無法判定**。CLI 的 outcome=indeterminate、pkce_rejection_proven=false 原樣保留；HTTP、錯誤碼、關鍵字及要求 enum 不能單獨取代因果共識。

執行來源 `d067c2c6adad7b1bcb19639c3f0ca58fc437e251`；工具凍結未改。[獨立 Tester](../plan/github-pkce-missing-verifier-feasibility/evidence/live-verification.md) 與 Reviewer 接受的是有限證據的如實整合，required fixes=0；不是 missing-verifier 假設成功。任務完成、1/1 額度用盡，不補次；未使用 token 呼叫 API，也未執行 revoke。

[PR #65](https://github.com/a129924/rivet/pull/65) 已於 2026-10-22 合併並關閉，merge commit 為 `0276ff3385495ed7fb0444e02b3b6da0757dd17a`。PR 合併只更新交付狀態，不解除因果缺口；E008 README 與 step 中的 Draft／待 review 文字保留為當時交付快照。

## 版本與仍未驗證的範圍

2026-10-20 舊 Rivet 名義 host 的[原端到端紀錄](../plan/github-persistent-connection/evidence/product-e2e.md)及圖、0次提示保留為 `ca00bc0` 歷史，正式產品歸屬與完成宣稱已撤回，不能冒充新 App 驗收。舊 source `7e81b77` 僅供追溯；新舊真人 build 都依當時工作樹 source SHA、私有 project 與原生 build log 識別，不偽稱由後來才產生的 commit 建置。

下段有效 profile／private group／原 certificate 等前提專指 PR #62 的 DPK 持續連線驗證；PR #63／E009 的獨立 SignIn host 使用 [ad hoc 簽章、不需 Team／profile／Keychain entitlement](https://github.com/a129924/rivet/blob/fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4/docs/architecture/github-first-sign-in.md#L19)，不套用該組儲存前提。

已知可行性依賴有效 profile、同 Mac／GUI 使用者、相同 AppID／private group／原 certificate 等前提。以下均保留未驗證：

- 自然 access-token 到期等待。
- profile 更新後讀回（Human 已接受限制）及已過期 profile 的恢復。
- certificate rotation、跨使用者／跨機器及公開分發。

本摘要只涵上述已合併 PR #62／#61／#63／#65 的各自來源，不吸收其他尚未合併 PR 或其他 worktree 的成果。原 PR #62 的文件與 Git 收尾仍依[本 topic 帳本](../plan/github-persistent-connection/github-persistent-connection.step.md)追溯；#63 已完成收尾另列於上節。兩份索引已由 PR #64 合併至 dev；其先前 Draft／pending 記錄保留為原時點快照，後續實際收尾另見文末。

## 決策邊界

各實驗的成功只適用其來源版本、前提與觀察層級；測試／build 通過、文件審查通過、驗證任務完成或 PR 合併均不能代替主要假設的證據。E002 反向／舊 missing 未知、E005 候選 UX 失敗、E007 renewal 未驗證與 E008 無法判定分別保留；既有 X wrong 的單次支持性證據不代替 missing。

正式登入 UI 依自身工作線推進。後續正式 adapter、安全決策、憑證 lifecycle 或產品採用仍依各自既有流程，不由本總覽自動核准。

## PR #64：文件驗審完成與實際清理（2026-11-03）

[PR #64](https://github.com/a129924/rivet/pull/64) 已於 GitHub `mergedAt=2026-11-03T06:04:24Z` 合併並關閉。固定 merge 為 `71d395cc9ca3cfe645b13a93ee0e83f22c255edd`，最後 feature head 為 `572e366e03471324cd745a4e4a103d19374e5009`；它是文件交付版本，不是新的真人執行 build。

[R64 保存契約與交接](https://github.com/a129924/rivet/blob/71d395cc9ca3cfe645b13a93ee0e83f22c255edd/plan/github-persistent-connection/github-persistent-connection.step.md)記錄本輪 Tester R64-T01–T05 **22／22 通過**與 Reviewer **approved／required fixes=[]**。兩項修正分別補齊 #61／#62／#63／#65 的現行來源契約，以及 E006 的 Rebuilt configuration 重建措辭；[範圍 thread](https://github.com/a129924/rivet/pull/64#discussion_r4451328613)與 [E006 thread](https://github.com/a129924/rivet/pull/64#discussion_r4451328654)已由主方 API 讀回 resolved，未解決數0。這不沿用原 D04／D05 作新核准，也不新增實驗或產品採用結果。

E006 原 partial Human receipt 只記切換 Rebuilt configuration；Debug／Rebuilt 的不同 binary hash 與後續完整 Human 觀察支持既有受限 0／0／0，沒有 Clean 操作證據。E006 原判定／收據不改；#62 獨立持續連線 App 的真正 Clean／Build 段保持原證據。M03 的 Human／agent／source 界線、C01／A07、各輪 PKCE 預算及 indeterminate、DPK 前提與產品限制均保留。

本次已核對 annotated tag `v0.1.59-github-connection-validation-summary` 的本機／遠端 object 與 peeled commit 一致，精確指向 `71d395cc…`；不是後續文件維護 commit 或 GitHub Release。原 topic local／remote branch 與本輪 managed feature worktree 已正常移除；無 force／prune，其他 feature worktree 與所有 App／Keychain／Apple 資產未操作。PR #64 原文件交付與 Git 清理完成不代替實驗主要假設的證據，舊 D／R64 pending／交付前狀態只按當時版本閱讀。

## E010：profile 自然週期尚未執行（PR #67 登記）

此節只登記尚未合併 PR #67 的獨立 DPK profile-continuity topic，不改上游已合併來源範圍或 E001–E009 結果。[E010 README](E010/README.md)保留原 10/21／10/22 Human Build success 與有界 host／matching Report 缺口並存；未取得 selected App／actual proof／完整 global，沒有 App/SecItem/seed 或跨週 item。原 grants/run 均 closed，私有 root 已精確清理；10/22 僅 cleanup 越 cutoff 3.954765 秒但在 deadline 前，舊收據不改。

遷移保存 22 原檔快照與 171 同 bytes 移動資料，原 193 檔逐筆 accounting；[typed map](E010/history/renumbering-map.json)的 1952 file refs 與 3 non-file aggregate digests 分開，五個歷史 source 版本無法取得，不能稱所有舊 source 可重建。M03 Tester／M04 Reviewer approved 只核受限遷移與離線準備，不是 profile cycle/DPK/UX 成功。

本地已正常首筆 commit `819b26d20272cfcc9e664c4dccba867bcd34c92d`，受控整合 `758aca9bb518f2a21f20f47609335fac49043370` 與兩 registry 登記仍待 M07 獨立核對及 M08/M09；尚未第二 commit 或 push，不宣稱 GitHub 衝突已解除。S06 human-check、自然週期／完整 S07/S08 pending；未核准 Keychain adapter 正式採用或 merge 至 dev。
