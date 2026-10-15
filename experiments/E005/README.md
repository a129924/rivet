# E005：Keychain 本機完整 OAuth 憑證保存

## 驗證什麼
- 設計日期：2026-10-15；實驗編號 E005，由 Implementer 重查占用後建立，未覆寫 E001–E004。執行日期：2026-10-15，獨立 Tester。
- 問題：完全不依賴付費資格，完整六欄假憑證可否跨程序及同身分真重建還原，首次最多一次提示、其後零提示？
- 假設：存在符合上述條件的本機 Keychain 路徑；本輪只驗一個候選，不核准正式採用。

## 為什麼
- legacy 歷史八測試與 E004 不支持本輪完整 Keychain bundle／重建／UX 結論。
- TN3137、TN3125 及 DTS 836816／845980 指出兩種實作、host/profile 與 legacy 限制，仍須本機實證。
- [正式契約](../../plan/github-oauth-keychain-local-feasibility/github-oauth-keychain-local-feasibility.plan.md)。

## 成功與失敗判準
- 寫入前固定：免費來源、完整還原、真同身分重建、替換、清理、首次最多一次提示／正常後續零提示均成立才成功。
- 前提滿足仍可重現不完整、讀不到或反覆提示為失敗。
- 身分／資格／觀察不足為無法判定；尚未嘗試為未執行。真 denial 無自然提示可保留缺口。
- 90 分鐘總額；02:41:28 UTC 起，03:56:28 停新增測量／圖作業，04:11:28 總上限。

## 環境與前置條件
- macOS 26.5.2（25F84），Apple Swift 6.3.3（swiftlang-6.3.3.1.3），arm64-apple-macosx26.0；版本證據見 [environment.json](evidence/environment.json)。
- 實驗 host 為 app-like CLI，以明確 ad-hoc 簽章，不建立憑證／帳號／profile。
- DPK 免費 profile 未建立且不進行新增帳號操作，首次寫入前選 legacy；selector false、sync false，全輪固定。這不證明 DPK 需要付費。
- 原始碼直接唯讀編譯既有三份 credential contracts，無 root manifest／production 修改或外部依賴。
- 所有資料為固定假值；namespace 為每輪 UUID。系統提示沒有人工觀察時必列未知，不以 exit code 推成零提示。

## 重現步驟
- `python3 experiments/E005/scripts/run_probe.py --backend legacy --out experiments/E005/evidence/normal-run.json`。
- runner 在系統暫存編譯 host：writer 結束→兩 fresh reader→marker 真重建／身分比較→正常替換→獨立負向→整輪 finally 清理。
- `--stop-after-write` 另用新 UUID 驗證提前停止清理，輸出至另一 evidence JSON。初版 early-stop 是正常 branch；修復後 controlled-stop 會明確 raise RuntimeError，經 exception path 進 finally。舊 receipts 保留不覆寫。
- 修復後 SIGINT／SIGTERM 轉為受控停止，finally 開始忽略重複同類訊號直到清理／receipt 完成。可重現 synthetic harness：`python3 experiments/E005/Tests/test_signal_cleanup.py`；fake build／identity／subprocess，不執行 Security。
- 重建身分不足不進行 acceptance read；恢復原 binary 只用於獨立 T04／T05 與清理，不作 T03 證據。
- 子程序正常退出保留項目；整輪正常／失敗／停止／例外統一精確清理主要與負向項目。

## 是否成功
- 執行日期：2026-10-15。正常 run：02:53:53.135235–02:54:00.436037 UTC；獨立提前停止 run：02:54:07.447658–02:54:10.198966 UTC。
- 實驗狀態：**無法判定**。正常 run 的 legacy 完整保存、fresh-process 還原、整筆替換及清理成功，但 ad-hoc 真重建後 designated requirement 不一致，初輪系統提示沒有人工觀察；下方後續 Human 補測已觀察原 binary 實際操作 0 提示，但仍未滿足主要假設的同身分重建前提。此不是 Keychain 機制失敗，也不能推論必須付費。
- 本輪 Keychain 驗證任務完成：**是**；已執行可用前提下的受限測量、記錄不足與決策限制，所有嘗試寫入項目已清理確認不存在。工具及整包交付由後續獨立 Reviewer 核對，不以此宣告完成。
- early-stop 與 controlled-stop receipt 的 `validationTaskComplete=false` 表示該 run 刻意不跑完整 T02–T05；其清理探針本身成功，不與正常 run 混合作同一筆憑證持久性證據。修復後 controlled-stop：02:57:52.206763–02:57:55.721547 UTC，新 UUID 真寫入後受控例外清理成功。

## 結果與證據
- 實際指令依上節順序，第二次為 `python3 experiments/E005/scripts/run_probe.py --backend legacy --stop-after-write --out experiments/E005/evidence/early-stop-run.json`。兩 run exit 0 只代表 runner 對應操作完成，不代表 UX 或主要假設成功。
- [normal-run.json](evidence/normal-run.json) 保存逐次 fresh subprocess 操作、時間、六欄布林值、遮蔽身分比較、namespace 及清理結果；[early-stop-run.json](evidence/early-stop-run.json) 為另一 UUID 的整輪停止清理證據。

| TestCase | 實際觀察與分類 |
| --- | --- |
| T01 前提 | 明確 legacy、selector false／sync false；app-like CLI ad-hoc signature verify 成功，沒有 team identifier／profile，不需憑證或付費資格。DPK 免費 host/profile 未確立，不能宣稱 DPK 不可用或需要付費。 |
| T02 完整還原 | 成功（資料機制）；writer 結束後兩個 fresh reader 的六欄均 true。提示次數均 null，UX 無法判定。 |
| T03 真重建 | 無法判定；實際 hash 改變且新簽章有效，路徑／bundle ID／簽章方式及 entitlements 比較相同，但 `designatedRequirementEqual=false`；未進行 acceptance read。還原舊 binary 只供 T04／T05／清理，不構成此案例證據。 |
| T04 完整替換 | 成功（資料機制）；在還原原身分後整筆替換 B，新程序六欄全 true。未支持新 binary 存取或 UX。 |
| T05 失敗邊界 | 真實 Keychain absent→nil、malformed→decode failure 成功。真 denial 未執行，沒有可用的自然提示觀察。synthetic 的 denied／cancelled／interactionUnavailable／unavailable 等分類皆 true，僅是函式注入分類證據，不能當真拒絕。 |
| T06 清理 | 正常 run 主要與負向兩項 delete／absence confirmed 皆 true；獨立 early-stop 寫入後故意停止，該主要項目亦 delete／absence confirmed true；負向項目未嘗試寫入。無已知殘留。 |

- Reviewer 回修後新增 [controlled-stop-run.json](evidence/controlled-stop-run.json)：真實 Keychain、新 UUID、`--stop-after-write` 受控例外路徑，精確 delete／absence confirmed 皆 true。初版 normal／early-stop 沒有 source hashes；新版 receipt 保存三 source SHA-256，不事後添加舊 provenance。Swift／build 不變，原 normal 六欄與同身分不足結論維持，沒有重跑或混用新舊 binary 持久性證據。
- [synthetic-sigint.json](evidence/synthetic-sigint.json) 與 [synthetic-sigterm.json](evidence/synthetic-sigterm.json) 為 **synthetic** 控制流程測試：fake write 登記後向本程序送真 OS 訊號，fake delete 中再送同訊號；兩個 testcase 成功，stopReason 對應訊號、所有假項目已追蹤並清理，receipt 均完整。這不證明真 Keychain 遭訊號中斷時的行為或 UX。
- 初輪及停止測試的 machine 收據提示欄位維持 `unobserved`／null；沒有用程序成功、stderr 空白或操作耗時推論零提示。下方另列後續 Human 全程觀察，原 machine 收據不覆寫。
- 真實 Security 操作與 synthetic 分類分開；JSON 不輸出 token、個人簽章識別或原始 system stderr。

## 結論與限制
- 本輪支持「此 ad-hoc legacy host 可跨 fresh process 保存／還原六欄假憑證並整筆替換」的受限結論；主問題仍無法判定，不支持正式採用。
- 下一個必要證據為免費且可重建後維持相同 designated requirement 的 host，並在該穩定 host 下觀察首次／後續提示（本次原 binary 的 Human 0 提示不外推新 host）；需新增帳號或憑證操作時交還人類，不自行解除。DPK 免費前提仍未驗證。
- SIGINT／SIGTERM 受控停止有 synthetic 流程證據，寫入後受控例外有真 Keychain 清理證據；SIGKILL、程序 crash、host／系統失效無法保證 finally 清理，不將「所有退出路徑」外推至不可捕捉停止。若發生該類中斷須依 namespace／service／account／backend 人工恢復精確清理，不放寬安全設定。
- 只支持本次 OS、host、候選、簽章及假輸入；不外推產品登入、所有 macOS、公開分發或 provider runtime。

### 輔助工具交付

- [實驗 workflow](diagrams/keychain-workflow.html)、[delivery receipt](diagrams/keychain-workflow.delivery.json)、[四尺寸 receipt](diagrams/keychain-workflow.visual-check.json)、[另行視覺檢查](diagrams/visual-review.md)。Showcase 9/9、0 errors／warnings，四尺寸 containment 與明暗 captures 實際檢視通過；自動 `visualReview: pending` 原樣保留。作者內容繁體中文，固定 Viewer UI／HTML lang 使用 English fallback。
- [tooling.json](evidence/tooling.json)：Graphify 0.9.73 runtime 可用，但無可用 repository graph，依規範以限定 rg／source reads fallback，未 build／refresh。PR Lens 0.11.0 已確認 runtime，真實 topic commit 後才在 repository 外產生 bounded diff map，產物不發布；本檔不捏造尚未取得的 commit provenance。
- 獨立 Reviewer 已核對本輪受限成果及回修證據，明示 approved；這不改變主假設無法判定或核准採用。

### 交付與人類審查

本 topic 核心 commit `e6438ad` 已 push，已建立 [Draft PR #58](https://github.com/a129924/rivet/pull/58)，base 為 dev。全部 pre-commit hooks 通過；初次 renderer check 缺既有依賴快取，在 lockfile 相同下唯讀複用快取至 feature worktree 後通過，未安裝／更新依賴或修改 dev。PR Lens 0.11.0 已對核心 commit 的實際 diff 完成本機 validate／render；最終交付帳本 commit 後的 head 核對只在 repository 外進行，結果記於 Draft PR。圖表不是 correctness review。後續停於人類 review；主假設仍為無法判定，不核准採用或 merge。

### 後續真人授權提示觀察（2026-10-15）

使用者明確選擇「親自觀察 Keychain 提示，沿用原範圍」。重用 E005 的相同主要問題、macOS／Swift、legacy backend、ad-hoc host、固定假資料與既定判準，另建新 UUID；不新增帳號／憑證／ACL 操作，也不覆寫先前 receipts。

獨立 Tester 執行單輪 03:16:56.242858–03:17:01.549622 UTC（台灣時間 11:16:56–11:17:01），13 次子程序操作 exit 0、無 timeout。T02 兩個 fresh reader 六欄全 true；T04 完整 B 六欄全 true；真 absent／malformed 成立。主要與負向兩項均刪除並確認不存在。T03 真重建 hash 改變、designated requirement 不同，未執行 acceptance read。

- [machine receipt](evidence/human-observation-run.json)：保留原始 promptCount=null／unobserved，不以 exit 0 宣稱沒有提示。
- [獨立 Human 觀察](evidence/human-observation.json)：使用者回覆「全程觀察，完全沒有 Keychain 提示」，整輪觀察 0 次；以 machine receipt SHA-256 綁定時窗。
- 此證據支持本次原 binary 身分下的保存、fresh-process 讀回、替換及清理沒有觀察到提示；不外推未執行的新 binary acceptance read、DPK 或所有 macOS。真 denial 未觀察，不能由 0 提示宣稱拒絕測試成功。
- 主假設仍為無法判定；本次僅補上已執行操作的人工 UX 觀察，沒有核准正式採用。

- 後續補測之 machine／Human 觀察與條件化措辭已由獨立 Reviewer 核對，明示 approved；不取代 Human 對 Draft PR 的接受決策。

### T03 限定自簽身分預檢補充（2026-10-15）

**驗證什麼／為什麼。** 使用者明確允許一張實驗專用自簽 Code Signing 憑證／私鑰、repository 外獨立實驗 Keychain，以補相同 legacy／假六欄的 T03。重用 E005 同一問題、環境及判準；不覆寫 ad-hoc 或 Human 零提示收據。[Apple Code Signing Tasks](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html) 說明自簽憑證可用於內部測試、驗證版本來源一致性；文件本身不證明此 macOS 的 Keychain UX。[Apple Security 原始碼](https://github.com/apple-oss-distributions/Security/blob/main/OSX/libsecurity_keychain/lib/StorageManager.cpp) 的 `shouldAddToSearchList` 說明私人 Keychain 建立不應改全域搜尋清單；本次仍實測比較，不將源碼外推為環境保證。

**成功與失敗判準。** 維持既定六欄／首次最多一次提示／後續零提示；先完成兩次真重建與 DR 相等預檢，再以固定路徑 first writer、second reader 核對實際 hash。預檢不成立即不寫 OAuth item，不調整 trust／預設 Keychain／search-list／既有 ACL／partition-list。原 03:56:28 UTC 停新測量及 04:11:28 UTC 總上限不延長。

**環境與前置條件。** 同 E005 macOS／Swift，OpenSSL 3.6.4；私有 Keychain 直接 `SecKeychainCreate`、隨機密碼僅記憶體；0700 scratch、0600 秘密素材。只在新私鑰匯入時設定 `/usr/bin/codesign` 初始存取，沒有全 app 存取或既有 ACL 修改。自簽 host 未建立成功，未取得可比較的 DR。

**重現步驟。** 新增 `scripts/run_self_signed_probe.py`，預設只做簽章預檢並 finally 精確清理；`--measure` 路徑未執行。獨立 Tester 依序執行：

```sh
python3 experiments/E005/scripts/run_self_signed_probe.py --out experiments/E005/evidence/self-signed-preflight.json
python3 experiments/E005/scripts/run_self_signed_probe.py --pem-import --out experiments/E005/evidence/self-signed-pem-preflight.json
```

第二輪僅為一次 PEM transport 相容性檢查，沒有 backend／簽章政策 fallback。首輪執行的原始碼快照位於 `evidence/source-snapshots/45c995f97c0b4c1872db8930e37af08b9796a376056682f00c38322709531f4a.py`，SHA-256 與首輪收據一致；此為歷史來源快照，重現入口仍為 scripts 目錄。第二輪收據 hash 綁定當時執行腳本，後續診斷前另存 SHA-256 一致的 `0b24e6e01e35c4729f9a0e883c295380a6ecc423135c848a32f9738a09dbb287.py` 歷史快照；目前腳本由下方新診斷收據綁定。沒有秘密或原始 system stderr 進入 repository。

**是否成功。** 本補測狀態 **無法判定**；T03 acceptance **未執行**。兩份 machine receipt 的 `validationTaskComplete=false` 表示簽章預檢未達成，不冒充 T03 完成。受限驗證與紀錄工作可在如實保存停止原因、缺口、清理與決策限制後完成；主假設及正式採用仍受阻。

**結果與證據。** [PKCS12 收據](evidence/self-signed-preflight.json)：03:32:17.382262–03:32:18.185115 UTC，生成／封裝 exit0，匯入 exit1。 [PEM 收據](evidence/self-signed-pem-preflight.json)：03:33:40.699403–03:33:44.072436 UTC，生成、編碼、憑證及私鑰匯入均 exit0，首次簽章 exit1。兩輪均未取得兩版有效簽章／DR 比較，OAuth commands 為空、零 OAuth 寫入。已知錯誤分類不足以指出根因，不能稱為已確認的信任錯誤。兩輪私有 Keychain create/delete status0、專用 Keychain 與秘密 scratch 確認不存在，建立後及清理後 default／search-list 比較全部相等。桌面工具連線確認成功；程序清單抽樣未見 SecurityAgent，不等同全程可見提示觀察，也不補造本輪 UX 結果。

**結論與限制。** 原 binary 的 Human 全程零提示證據繼續有效，不能外推此次尚未建立的自簽 host。現有 host 已有 `.app` 包裝；目前缺口為可成功簽署且可維持 DR 的免費身分，不是已證實需要 GUI App。此次自簽候選未滿足前提，不能判定 Keychain 保存失敗、不能推論必須付費或自簽方案普遍不可用。沒有放寬信任／安全設定或增加其他簽章變體。下一步需另行釐清簽章失敗原因及免費穩定 host，才可重新安排 T03 與該 host 的人工 UX 觀察；本輪不核准正式採用。不可捕捉停止／程序或主機失效仍不保證 finally 清理；實際兩輪清理完整。

### 同一自簽候選的失敗診斷（2026-10-15）

使用者要求續行後，僅改善非秘密診斷，不變候選、判準、原時限或禁止信任變更的邊界。新增 `--diagnose` 只對本輪專用 Keychain 查詢 `security find-identity -p codesigning`，僅保存數量與公開錯誤片語 allowlist，不掃全域身分、不存 raw stderr／個人識別。上輪 PEM 原始碼另存 SHA-256 一致的 `evidence/source-snapshots/0b24e6e01e35c4729f9a0e883c295380a6ecc423135c848a32f9738a09dbb287.py`，舊收據不覆寫。

獨立 Tester 執行 `python3 experiments/E005/scripts/run_self_signed_probe.py --pem-import --diagnose --out experiments/E005/evidence/self-signed-diagnostic.json`。 [診斷收據](evidence/self-signed-diagnostic.json) 時窗為 03:46:15.198788–03:46:19.466323 UTC：本輪隔離 Keychain 有 1 matching／0 valid identities，codesigning policy 明確分類 `CSSMERR_TP_NOT_TRUSTED`；首次簽章 exit1，公開錯誤為 `no identity found`。這指出本次重現的可用簽章身分前提未成立，不回填前兩輪未保存的診斷，也不證明自簽方案普遍不可用或必須付費。[Apple TN3161](https://developer.apple.com/documentation/technotes/tn3161-inside-code-signing-certificates) 說明 codesign 的身分查找與憑證鏈前提；本次分類仍以實際隔離查詢為證據。

本輪零 OAuth 寫入、T03 acceptance 未執行，整體仍**無法判定**。machine `validationTaskComplete=false` 仍代表穩定 host 前提未達，受限診斷工作可在完整紀錄及清理後完成。專用 Keychain／秘密 scratch 已刪除，default／search-list 建立後及清理後均相等，無已知殘留。桌面工具已確認連線，沒有安排新 UX 測量；原 Human 零提示證據保留。

若沿此自簽身分繼續，下一個涉及信任設定的操作超出既定授權，需由 Human 明確決定；尚未執行任何信任調整。單純改 GUI App 未解除已觀察的簽章前提。診斷結果不核准正式採用，不外推其他 macOS／簽章方式／DPK。

### 限定 user-domain／Code Signing trust：準備與待測

使用者已明確授權「僅實驗憑證、使用者範圍、Code Signing 用途」的唯一 trust 例外。新窗 03:54:20–04:24:20 UTC，04:19:20 UTC 停新測量；舊時窗保留為歷史。新計畫經獨立 Plan-Reviewer approved，不改 legacy／假六欄／first writer 與 second reader／UX 判準，也不允許 admin／system domain、SSL、broad trust、既有 ACL／partition-list、default Keychain 或 search-list 變更。

新增 `Sources/TrustProbe.swift` 僅接受 `Rivet-E005-UUID` cert DER。exact-cert 三 domain baseline 皆須嚴格 `errSecItemNotFound`；新增只用 `.user`、`SecPolicyCreateWithProperties(kSecPolicyAppleCodeSigning, nil)` 及明確 trustRoot。讀回須恰一 entry、恰 Policy／Result keys、AppleCodeSigning OID／trustRoot；空 array（AlwaysTrust）、SSL、多 entry 或額外 allowed error 都拒絕。[Apple trust-settings API](https://developer.apple.com/documentation/security/sectrustsettingscopytrustsettings(_:_:_:)) 區分 absence 與空 array，並說明 per-user 修改需系統驗證使用者。

runner 的 trust cleanup ownership 僅在三 domain baseline absence 已證實且本輪 add 已嘗試時成立；helper 明確回 `mutationAttempted=false` 會清除 ownership 並停止，不撤別人設定。timeout／可能 partial add 仍進精確 remove、exact-cert 三 domain absence 讀回；信任清理失敗保留撤回材料與殘留原因，不先刪證書而失去依據。正常退出先清 OAuth item，再撤 trust／核對，再刪專用 Keychain／秘密；不可捕捉停止仍無 finally 保證。

同一程序在兩版簽章／DR 預檢成功後寫出非秘密 ready notice，保留同 cert／first／second，等待本輪 namespace 綁定的 Human ready gate。未收到獨立 T03 ready 不寫 OAuth；gate 必須起初不存在，等待及新操作受硬 UTC deadline 控制，cleanup 不被 deadline 阻斷。互動 trust 與 T03 兩個 ready 時點分開，密碼／系統 approval 由 Human 處理。可重現入口（參數中的外部路徑須由主工作 session 指定新檔，不能重用 gate）：

```sh
python3 experiments/E005/scripts/run_self_signed_probe.py --pem-import --diagnose --trust-code-signing --measure --observer-gate <external-new-gate> --ready-notice <external-new-notice> --measurement-deadline-utc 2026-10-15T04:19:20+00:00 --out experiments/E005/evidence/<new-receipt>.json
```

目前只完成 Swift6 compile／Python syntax 與獨立純檢查。[Constraint 收據](evidence/trust-constraint-check.json) 為 7／7 synthetic checks；[cleanup 收據](evidence/trust-cleanup-check.json) 為三個 fake Security／subprocess adversarial cases 通過，驗證拒絕 mutation 不撤 foreign trust、failed partial add 與 timeout 仍撤回並核對。缺 gate 的 CLI 在 argparse exit2，早於 scratch／Security 初始化。這些都不是真實 trust 或 T03 證據。上輪診斷來源另存 `evidence/source-snapshots/b104dd3d649451aee270b86fa926ee6727c204c28f4f4e301f5ec2aa85dec159.py`，SHA 與原收據一致。

限定 trust 真實補測狀態 **未執行**；本輪真實驗證任務未完成。尚待 Human 確認可留意 trust 系統授權，再執行；若簽章預檢成立，另確認 CUA 連線並請 Human ready 後才 T03。沒有新增 trust、OAuth 寫入或本輪殘留，主假設仍無法判定；既有原 binary Human 零提示依據保留。授權與純檢查不核准正式採用。
