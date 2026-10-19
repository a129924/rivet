# E006：免費 Personal Team／Data Protection Keychain UX 可行性

## 1. 定位與問題

**目前結果：2026-10-19 受限真人輪已執行，獨立 Tester 判定資料機制成功、受限 UX 成功、驗證任務完成（approved，requiredFixes=[]）；S08 獨立 Reviewer 已正式 approved、required_fixes=[]，目前停於 S09 Human review。** 實驗只使用隔離假 OAuth bundle；這不是正式 Keychain adapter 的實作或採用。

本題是在不新增付費 Apple Developer 資格下，以真正 macOS App、免費 Personal Team 的 Apple Development 簽章及有效 development profile，使用 DPK 跨程序、同身分真正重建後免反覆授權讀回完整假憑證。

Topic：`github-oauth-dpk-local-feasibility`；branch：`chore/github-oauth-dpk-local-feasibility`，僅 feature worktree。四份 planning artifacts 鎖定候選、範圍與判準；其初期準備／未執行／待授權文字是當時狀態，本輪實際授權、結果與 gate 進度由 [step](../../plan/github-oauth-dpk-local-feasibility/github-oauth-dpk-local-feasibility.step.md) 及本紀錄追溯更新。契約另見 [requirements](../../analysis/github-oauth-dpk-local-feasibility/requirements.md)、[technical-spec](../../analysis/github-oauth-dpk-local-feasibility/technical-spec.md)、[plan](../../plan/github-oauth-dpk-local-feasibility/github-oauth-dpk-local-feasibility.plan.md)。

## 2. 既有證據與依據

- [E005](../E005/README.md) 歷史 baseline：legacy 資料成功；最後分段首次／fresh-process／重建提示為 0／0／1，密碼並選「允許」，故該候選 UX 失敗。設定／清理指紋另記，該結論不變，不外推為 DPK 結果。
- E006 2026-10-16 setup 輪：14:14:38 controlled stop，DPK／UX 未執行、主假設無法判定；Human 全段為 partial／promptCount=null。Owned setup 最後清理完成，但晚於原 deadline 29.045841 秒，timebox 未滿足。歷史證據與 blocked／Human 直接確認／重試均保留，不能被新輪成功覆蓋。
- 最小 App 曾因 debug dylib、macOS profile debugging entitlement 誤判、owned process cleanup guard、setup t0 reset、CLI argv 及 ProvisioningUDID selector 回修；各 red／green、獨立驗證收據保留。最後準備版 27 pure tests 已獨立核對，詳 [準備 Tester 收據](evidence/tester-preparation-device-selector-fix.json)。

六欄 fake A／比較邏輯來自 `E005/Sources/KeychainProbe.swift`；僅複製必要實驗 DTO／固定值，不改 production bundle／store／provider。文件依據為 [免費帳號](https://developer.apple.com/help/account/basics/about-your-developer-account)、[macOS capabilities](https://developer.apple.com/help/account/reference/supported-capabilities-macos)、[TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)、[TN3125](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)、[TN3127](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)。這些文件不取代本輪實證。

## 3. 假設與判準

唯一候選：真正 macOS App／免費 Personal Team Apple Development／有效 embedded development profile／唯一 private access group／DPK。寫入前固定判準：首次正常存取最多一次提示；同 binary 新程序與同身分真正重建各零提示；三段六欄完整相符；隔離資料與 owned 私有檔案精確清理，保留證據。

資料、UX、驗證任務完成否分開記錄為未執行／成功／失敗／無法判定。前提與觀察完整而超標為失敗；資格／host／profile／觀察不足為無法判定。Machine exit code、耗時、build 或 mock green 不代替 Human 觀察；清理完成與是否符合原時窗分開。

本輪 Human 全程觀察五段，promptCount 各為 0；首次／fresh-process／真正重建為 **0／0／0**，符合預固定 UX 判準。此結論是 Tester 已驗證、獨立 Reviewer 已核對的本輪受限結果，不是所有 macOS、所有 profile 或 Keychain 一般保證。

## 4. 前提與範圍

| 欄位 | 契約與本輪適用內容 |
|---|---|
| Goal | 確認有效免費 profile 下完整假 bundle 的跨程序、同身分重建資料與提示行為。 |
| Non-Goal | 正式 adapter／採用、產品登入、真 OAuth／refresh、公開分發、長期續期恢復。 |
| In-Scope | 單一 App／private group、前提核對、分段 Human-only ready／觀察、收據及精確清理。 |
| Out-Of-Scope | legacy fallback、其他身分對照、付費資格、既有 ACL／partition／trust／搜尋清單及帳號安全設定變更。 |
| ReadOnly | E005、既有架構／production、Apple 依據與必要本機工具設定；不 inventory 無關資產。 |
| Written／Modify | 本 topic／E006 的規劃、實驗、測試、流程圖、不可覆寫收據；本次閉環只改 README／step。 |
| Deleted | 本輪 UUID DPK 項目及 proven owned 私有 setup／runroot／唯一 DerivedData；證據與 Apple 開發資產保留。 |
| TestCase | 第 6 段 T01–T08；pure fixtures 不冒充真人失敗邊界。 |

2026-10-19 Human 另明確授權新輪與受限資產操作，並於各段給 fresh ready。Human 使用外部私有 project／設定操作 Xcode；feature template 不寫入 Team／account 識別，不呼叫 `-allowProvisioningUpdates`。免費 Personal Team 資格來源是 Human 明確聲明，不能只從 Apple Development certificate 推論。

本輪已證實非 root GUI／console user、Apple Development chain、當下與原 t0+35min 有效性、ProvisioningUDID 的精確 profile membership、bundle／marker／唯一 group 與 profile 授權；兩版 certificate、profile bytes、entitlements、DR 相同且雙向 requirements 評估成功。Hardware UUID 不作 fallback；macOS unrestricted debugging entitlement 不要求出現在 profile。簽章／profile／device 的 raw identifiers 僅在私有 proof，公開證據只留必要 hash／布林核對。

## 5. 最小 host／操作

`DPKProbe.xcodeproj` 單一 AppKit Application target，main executable 執行 Security；Debug／Rebuilt 只差 marker 與其編譯條件，兩者均 `ENABLE_DEBUG_DYLIB=NO`。`ProbeCore` 純資料／比較；`LiveStore` 為唯一 SecItem 入口，只在 proof／namespace／binary／phase／Human gate 通過後建立。不依賴 root package、不改 public API 或 provider lifecycle。

每次 add/query/delete 明指定 DPK=true、synchronizable=false、唯一 group／UUID service/account；add 為 `AfterFirstUnlockThisDeviceOnly`，不加 user-presence／biometry／ACL。每 process 執行一個操作即輸出 exclusive receipt 並退出。固定安裝路徑透過 LaunchServices `open -W -n` 啟動；phase 2 不重寫 A，phase 3 替換為真正重新建置版後唯讀 A。

新輪 namespace：`b832a57f-cced-4361-ba38-ac370d265e03`。原窗口 UTC `02:10:41.483264` 起、`02:35:41.483264` cutoff、`02:40:41.483264` deadline；台灣時間分別為 `10:10:41.483264／10:35:41.483264／10:40:41.483264`。Setup 開始前保存 exclusive window；proof／manifest 綁原 t0 及 SHA，沒有重設或延長。Human 登入／資產／簽章建置計入同窗口，unsigned／pure／圖工具在窗口外。

每段完成即停；gate 1–4 含實際 Human ready，綁上一段 matching machine SHA 與完整觀察，且 ready 時間早於下段起點。採 Human-only，不以桌面連線為前提。四組獨立 launch／exit 記錄、frozen `open -W -n` 與退出 guard 支持 fresh-process；未保留 raw PID，不聲稱 PID 數值不同。

實際 main executable SHA-256：first `b2d0ec7706b2682c70249867eba42fc587428d2ee139c6d711ab6f1d4a784840`；rebuilt `b9320e1eac2b6d3f08faa538d781101ad6e15f876d288f18226f3f3a437182d8`。兩版不同 hash 並通過相同身分／DR 前提，不能以重跑原 binary 冒充重建。

## 6. TestCase／結果

| 案例 | 本輪證據與結果 |
|---|---|
| T01 免費／profile／group／device／GUI | Human 免費來源聲明與實際 host／簽章／profile／ProvisioningUDID／35min gate 成立。 |
| T02 真正重建身分 | 兩版 main hash 不同，cert／profile bytes／entitlements／DR 相同，雙向 requirement 評估成功。 |
| T03 首次保存／還原 | phase 1 六欄 true，Human 全程 0 提示。 |
| T04 同 binary fresh-process | phase 2 獨立 launch／exit，唯讀六欄 true，Human 全程 0 提示。 |
| T05 真正重建版 | phase 3 換 rebuilt hash，唯讀六欄 true，Human 全程 0 提示。 |
| T06 控制／失敗分類／redaction | 同 toolchain／18 reviewed source SHA 未變，沿用獨立 27 pure tests，本輪未重跑；真拒絕／損毀等邊界未新增真人測量。 |
| T07 精確清理 | phase 4 delete＋read-absent 成功，Human 全程 0 提示；私有 owned 檔案全清且早於原 deadline。 |
| T08 本機圖工具 | [準備期工具收據](evidence/tool-preparation.json) 保留發佈前 PR Lens deferred 的快照；Archify showcase 9／9及視覺核對不變。原交付發佈時，Graphify 無可用圖而採 targeted source fallback；PR Lens 已對第 8 段指定的原交付 base／head 完成本機 validate／render 及視覺核對，不當成 UX 證據。 |

2026-10-19 台灣時間；每段的精確 UTC／machine／Human SHA 由 [Tester validation](evidence/run-20261019T021023Z-b832a57f/tester-live-validation.json) 列明：

| Phase | 時間 | 操作／比較 | Human 提示 |
|---|---|---|---|
| 0 | 10:10:41.483264–10:21:48.403003 | setup／完整前提，不存取 OAuth | 全程，0 |
| 1 | 10:24:05 | first save-read A，六欄 true | 全程，0 |
| 2 | 10:24:57 | 同 binary 新程序 read A，六欄 true | 全程，0 |
| 3 | 10:25:43 | 真正 rebuilt 新程序 read A，六欄 true | 全程，0 |
| 4 | 10:26:56 | delete＋read-absent=true | 全程，0 |

## 7. 證據／清理

本輪 [evidence](evidence/run-20261019T021023Z-b832a57f/) 的 [final index](evidence/run-20261019T021023Z-b832a57f/final.index.json) 索引 60 個 immutable files，連 index 共 61 份；SHA-256 `8e054090b7ac05c0a31e4a5775319a48337dfb2bbbbe1737c33d2bfe3e1d1141`。獨立 [Tester validation](evidence/run-20261019T021023Z-b832a57f/tester-live-validation.json) SHA-256 `f07c4fff31568e533b2d2ed503c3990b62203662837bb32844a94bec372bb123`，verdict=approved、requiredFixes=[]。每段 Human sidecar 綁 matching machine SHA；phase 4 Human SHA 為 `24add9e06881ce90459c69cf9cae0da73427dc80cf3826359b60545f2585650a`。

Machine `promptCount=null` 保持原樣；Human 的實際五段全程 0 提示另存 sidecars，不回填 machine。Driver 原 [round.machine.json](evidence/run-20261019T021023Z-b832a57f/round.machine.json) SHA `e1034d0024ccb9e7fec3823d4b7be4b42b1510cdd552ab0ed7b6bcab35330c8f` 在 Human phase 4 尚未回報時保留 UX unknown；後續新增 Tester validation 綜合完整 sidecars 判為成功，沒有覆寫當時 outcome 或歷史 partial 回報。

DPK 項目已於 phase 4 精確刪除並讀回不存在。Human 直接確認 Build stop／project close 及精確私有清理授權另存；[private cleanup](evidence/run-20261019T021023Z-b832a57f/private-cleanup.machine.json) UTC `02:28:04.470501–02:28:04.712768`（台灣 `10:28:04`），owned private setup／runroot／selected App copies／raw proof／唯一 proven DerivedData／active pointer 已移除，早於原 cutoff／deadline。Apple developer assets Human-owned retained，不 revoke／刪除。全域 Recent preferences 未修改；捷徑有無未檢查，不能斷言本輪存在 Recent 殘留。

### 2026-10-16 歷史輪獨立保留

[舊 setup-stop archive](evidence/setup-stop-20261016T055352Z/)：原 t0 `13:53:52`、`14:14:38` controlled stop，二 App 完整前提及 DPK／UX 未完成，主假設無法判定。Human partial 0 回報原樣保留，全段觀察 false／總 promptCount=null。停止前首版曾凍結並唯讀檢查；Human 回報第二版 Rebuilt Build 成功，未完成兩版比較；清理後舊 Apps 已刪。CUA Stop disabled／Build Succeeded→close→Welcome 僅支持 UI 關閉，不是提示觀察。

舊 stage 1／2 owned setup 最後清理完成；auto-review 曾拒絕、Human 直接確認後同 scope 重試成功，原 blocked 收據保留。舊 cleanup end UTC `06:24:21.339999`，對原精確 deadline `06:23:52.294158` 晚29.045841秒，`cleanupCompleteForThisSetupWindow=true`，`completedBeforeOriginalDeadline=false`；沒有重設／延長，不稱如期完成。舊 [cleanup machine](evidence/setup-stop-20261016T055352Z/cleanup-stage-2.machine.json) SHA `52d50e6d21612bf6df32c1966f3d6ad3af933868b63019c38fe1664bd874cb72`／[final index](evidence/setup-stop-20261016T055352Z/final.index.json) SHA `6abec4907a3823230e2ae4de2335c115baea44858fed7a2acbfe2c72633ce40d` 不變。該輪 Apple 資產新建或重用細項未 inventory，Human-owned retained；其 Recent 記錄不外推新輪。

## 8. 結論／限制／下一步

依本輪實際前提、三段六欄、Human 首次／fresh-process／真正重建皆零提示及時限內精確清理，**資料機制成功、受限 UX 成功、驗證任務完成**；本輪 Tester 及 S08 獨立 Reviewer 均 approved，Reviewer required_fixes=[]。S08 已完成，目前停於 S09 Human review／後續決策（human-check）；此 Reviewer approval 僅接受受限實驗證據與紀錄。Git 發布另依 Human 明確授權，正式 adapter 仍未核准。

可支持的本機條件是本次 Mac／GUI user session、Human 聲明的免費 Personal Team、有效 embedded development profile、相同 Apple Development certificate／group／DR、固定 App 路徑。不能由本輪成功推論已修復 E005 legacy 根因，或覆寫 E005 UX 失敗／10月16日 unknown 與逾時。

真拒絕授權、損毀／技術失敗邊界仍只有 pure fixtures；profile expiry／renewal／reprovision、certificate rotation、長期恢復、其他 macOS、公開分發、真 OAuth／refresh、B 替換與跨程序 refresh 協調未在本輪驗證。正式 Keychain adapter／產品整合／採用仍未核准，provider ownership 不變。新輪／新測試、merge 及正式 adapter 仍未授權；原受限實驗獨立審查已完成，目前停於 Human review，只支持後續正式規劃。

2026-10-19 原交付發佈狀態：Human 已明確授權並確認 topic 分組與訊息，`9ce209429d2b1fe8e9b98a3d24a2de311710eda1`（實驗工具）與 `ebbb71f9237ac883914ebfc32d4838e6ba2df517`（契約／證據）已 push 至 topic branch，並建立 [Draft PR #59](https://github.com/a129924/rivet/pull/59)，base 為 `dev`。此為已完成的原交付事件；本次 P3 僅同步 README／step 的發佈時序，不重跑實驗、不改 source 或 immutable 收據。

原交付 PR Lens 0.11.0 的已完成範圍為 base `05b039b39f4f7cf136b10ddcba654a07b0a448d8` 至 head `ebbb71f9237ac883914ebfc32d4838e6ba2df517`；於外部 scratch validate／render 通過且已完整視覺核對，產物只保留本機。這項核對不涵蓋後續文件修正 head；Graphify 0.9.73 沒有可用圖，沿用限定來源核對，不建立或上傳圖。

原交付第一筆 commit 六個 hooks 全通過；第二筆的 94 檔以實際 EOF formatter 外部副本檢查通過，8 份 immutable machine JSON 經獨立 Reviewer 核准保留原 bytes，僅該次 commit 略過 `end-of-file-fixer`，其餘五個 hooks 全通過。本次兩份 Markdown 修正不沿用該例外。
