# E008：DPK profile-only 自然到期後的原憑證恢復

## 驗證什麼

- Topic：`github-oauth-dpk-profile-continuity-feasibility`；設計日期：2026-10-20。
- E008 建立前已重查 registered worktrees，當時未占用。E007 為不同 topic，不改檔、不借用其授權或結論。
- 主要問題：同一台 Mac、GUI 使用者、Apple Development certificate、完整 App identifier／專用 access group，在 P0 profile 自然到期後，換為真正不同且有效的 P1 profile，能否讀回原假 OAuth bundle A，並在真正重新建置後維持零反覆提示？
- 假設：只有 profile 改變時，原 DPK item 可完整恢復；初次正常存取最多一次授權，其後正常讀取均零提示。資料恢復、到期期間 availability 與人工維護成本分別判讀。

## 為什麼

E006 已支持同一個有效 profile 下的受限 DPK 機制與 UX，沒有驗證自然到期與重新佈建。E005 的 legacy 自簽重新建置 UX 結果也不因本題改寫。本實驗只補 profile continuity，不重測整套 OAuth／refresh runtime，不交付正式 adapter。

研究依據與官方文件見 [requirements](../../analysis/github-oauth-dpk-profile-continuity-feasibility/requirements.md)，固定契約見 [technical-spec](../../analysis/github-oauth-dpk-profile-continuity-feasibility/technical-spec.md) 及 [plan](../../plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.plan.md)。唯讀文件無法代替本機自然到期後對原 item 的讀取及逐段 Human 觀察。

## 成功與失敗判準

判準在 live 前固定，不以 mock／build green 代替：

| 分類 | 必要證據 |
|---|---|
| 成功 | 完整 baseline；P0 真正自然到期；P1 bytes SHA 不同且建立／到期日期更新；同 certificate／完整 group／source／query；P1 與真正重建版均讀回原 A 六欄、沒有重新 seed／rewrite；首次正常存取最多一次、後續正常讀取零提示；exact delete/read-absent 與私有素材清理可追溯。 |
| 失敗 | 已滿足控制與完整觀察後，可重現原資料不能恢復或正常讀取反覆提示。availability 中斷與恢復結果分開記錄。 |
| 無法判定 | profile 沒真正改變、certificate／group 等混變、觀察不完整、缺有效 recovery host、前提受限或超出原時限。不能把 launch／App guard 拒絕當作 Keychain missing 或資料遺失。 |

原始 global t0 起最多 10 日；P0 到期須至少預留末段 30 分鐘，選定 certificate 的實際 NotAfter 須涵蓋 global deadline 再加 35 分鐘。最多 W1 baseline、W2 自然到期診斷＋P1、W3 真正重建＋cleanup 三個主動窗口。各窗口 30 分鐘，最後 5 分鐘只清理；設定／Human Xcode 操作計入，不重設 t0、不增第四個測量窗。無 daemon／排程，不承諾 agent 未執行時自動清理。

## 環境與前置條件

歷史準備環境（本 closure 不重查）：macOS 26.5.2（25F84）、Apple Swift 6.3.3、Xcode 26.6（17F113）、Python 3.14.0、arm64。日期與版本只描述準備環境，不外推其他 OS。

- Genuine AppKit Application target；每個 LaunchServices process 一項 operation 後退出。純 core 不 import Security；LiveStore 是唯一 SecItem 入口。
- 固定六欄假 A，DPK=true、synchronizable=false、UUID namespace、單一完整專用 group、AfterFirstUnlockThisDeviceOnly；只 seed 一次，沒有 upsert／update／fallback。
- 私有 Mac hardware UUID／使用者 UID binding 在原 global 凍結，每次 setup／resume／操作前先核對；profile 的 ProvisioningUDID 另作 membership，兩者不混用，公開只留 binding SHA。歷史準備未讀 IOKit；本控制輪 begin 已讀實際 Mac/user binding，公開只保留 SHA，不公開原識別。
- source／query／fixture、global／window／proof／machine／Human sidecar 的 SHA 與 exclusive-write guard；新 JSON 首次寫入前固定 UTF-8、sorted keys、terminal LF，寫入後才算 SHA。
- 本輪 Human 已明確同意完整 assets／跨週 retention／recovery 範圍，原話「同意上述完整範圍；各段 ready 另行確認」。scope consent 與各段 ready 分開；本控制輪曾取得適用 begin／setup／診斷／cleanup ready、建立原 namespace／grants／anchor，但已受控停止並刪私有 root，不能借舊 grants／ready 自行開新輪或 seed。
- 真 runroot 須非 Git／非暫存、owner-only 0700、無 symlink。Human 選定 App／source 與私有 proof 不進 repo；Xcode 個人設定使用外部實驗 project 副本，不將 Team ID／帳號識別寫回 template。
- P0／P1 須檢查實際簽章、profile CMS／certificate membership、目前 Mac 的 ProvisioningUDID、平台／日期與完整 group 授權。只檢查 Human 選定素材，禁止 inventory／自動 provisioning／revoke／改信任或搜尋清單。
- 兩輪（10/21、10/22）控制資料與各自 namespace 均已 closed，私有 root 已清。最新 10/22 Human 回報一次 Debug Build 成功、全程 0 提示、未 Run，但同 exact window 未取得本次 matching Build Report／product provenance；未選 App、未取得 actual binary hash／certificate/profile/group proof，也未執行 CMS、setup-only、complete-global、App／SecItem／seed 或跨週 item retention。Human 資產保留，其他素材未盤點。

## 重現步驟

以下只重現 preparation；在 feature worktree 執行，`<scratch>` 代表新建的外部暫存目錄，不能覆寫既有輸出。

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s experiments/E008/Tests -p 'test_*.py' -v
swiftc -module-cache-path "<scratch>/swift-module-cache" experiments/E008/Sources/DPKContinuityProbe/ProbeCore.swift experiments/E008/Tests/CoreTests.swift -o "<scratch>/core-tests"
"<scratch>/core-tests"
PYTHONDONTWRITEBYTECODE=1 python3 experiments/E008/scripts/prepare.py --out "<scratch>/unsigned-builds" --unsigned-build
```

`prepare.py` 僅使用 `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO` 建置 Debug／Rebuilt；兩版明確 `ENABLE_DEBUG_DYLIB=NO`，template 沒有 DEVELOPMENT_TEAM。準備期間建置產物與原始 log 存於本輪專用外部 scratch，不啟動產物。S04／S05 準備核准後已核對歸屬及無並發使用，精確移除該 scratch／unsigned outputs 與本輪 helper；repo 的安全 source／測試／build 收據完整保留，重現時另用新 scratch。

本輪 S06 [scope-consent 安全收據](evidence/S06-scope-consent.json) 只記已獲批准的範圍：私有位置模板 `~/Library/Application Support/RivetExperiments/rivet-E008-<newUUID>`，0700、非 Git／tmp、無 symlink；正常保留一份假 A 與最小 App／source／proof／namespace 至 actual t0+10 日。Human 使用單一免費 Personal Team，由 Xcode 重用合格既有 leaf certificate，設定新 UUID App ID／group、P0／P1 與同 certificate／完整 group 有效 recovery host 及本機註冊；沒有合格既有 certificate 就停止另問，不能默認新建或輪替。Apple 資產保留，不 inventory 其他資產、revoke／刪資產騰 quota、付費、改 trust／ACL／search-list。

以下為本輪執行前的固定契約／首段準備歷史，實際執行與 closed 結果見下方。開始前須另確認最晚開始時間 S 及 begin 全程觀察 fresh ready；三份 grant 的 validUntil 固定為 S+10 日，actual t0 必須不晚於 S。S 只是 grant 上限的對齊點，正常 retention／global deadline 仍為 actual t0+10 日，不以 S 延長實驗。三個主動窗口各 30 分鐘、第 25 分鐘停止新測量，包含設定／簽章／等待；不重設、不增第四窗、不排程。無有效 host、grant 到期或清理失敗時接受 recoveryRequired 殘留與最小材料，後續復原另取授權；cleanup-only 不延長原三 grant。

首段唯讀核對的實際 CLI 為 `continuity.py --live --root "<新持久 root>" --public-out "<本輪安全 evidence 目的地>" --begin-anchor`，不能同用 `--window`／`--cleanup-only`。收到 begin-ready 後才產生新 UUID／私有 root、固定並 exclusive 寫入三份 `grants/{assets,retention,recovery}.json` 及 `bootstrap/begin.ready.json`；grant／ready 使用同一實際 root、namespace、17-source map 與三 grant 的實際 bytes SHA，ready recordedUTC 須為當時且距 begin 不逾五分鐘。這些控制資料只能在適用 ready 後建立；本輪原 bytes／SHA 已封存，不沿用到新輪，也不需 Human 手填 SHA 或 Mac 識別。所有 Xcode／帳號／資產設定仍須在 anchor 固定原 t0 後、對應 setup-ready 成立才開始，不能漏計設定時間。

`begin_anchor` 會在當下讀取 Mac／user binding 並 exclusive 寫 `anchor.json`、`anchor.binding.json`、`windows/1.json`、`windows/1.binding.json`、`bootstrap/begin.machine.json`；anchor 不猜 P0／certificate 日期、沒有完整 global，也不具 App／SecItem 能力。本段結束先停，Human 完整觀察回報綁 begin machine SHA 後，才另取 setup-ready。此段是入口契約，不是目前未執行的斷言；本控制輪已實際完成 begin／setup 準備與診斷後停止，原 root／grants／clock 證據已封存且私有 root 已刪，不重建或重設。Human 觀察另存原 sidecar，不以機器狀態推論提示。

未來操作仍停在 Human fresh-ready 邊界。2026-10-21 S06-BOOTSTRAP 窄幅修正版以四個固定停點解開首次設定循環，不能直接照舊 `--begin`：

1. 第一筆設定前，三份適用 grants 與 `bootstrap/begin.ready.json` 綁新 namespace／私有位置／source，才以 `--begin-anchor` exclusive 固定原 t0、W1 與 10 日；anchor 不含未知 P0／certificate 日期。
2. 完整 begin Human sidecar 後，另給綁 anchor／W1／source／grants 的 setup-ready；`--setup-only` 僅檢查 Human 選定已簽素材，零 App executor／launch／SecItem，等待／Xcode 設定／素材檢查計入原 W1。
3. `--complete-global` 在原 cutoff 前重核 actual proof／日期／時間預算，後建完整 global→anchor／W1。W1 只綁 anchor，不回填 global SHA；partial state 不能讓 `Run`／App 放行，matching partial bytes 只能補缺連結，不能覆寫或重開時鐘。
4. 完整 setup Human 回報後，另取 `bootstrap/seed.ready.json` 才可進原 baseline preflight／seed／fresh；setup-ready／setup-only proof 不能當 seed-ready。`--window 1` 使用既有 W1，後兩窗仍綁 global SHA。舊 `--begin` 已拒絕；舊 `create_global` 僅留給明標 synthetic 歷史 guard fixtures，不能作 live 入口。

預設 CLI 不執行 live；synthetic proof 不可建構 LiveBackend。本控制輪已 arm 原 anchor/W1 並取得 begin／setup／診斷／cleanup ready；但未建立完整 proof/global，也未取得可放行 seed 的前提，零 App／SecItem，最後 controlled stop。舊 namespace 已 closed，不自行重開。

bootstrap 之後固定階段為原 W1 `preflight → seed → fresh`，等待自然到期後 W2 `expired → p1-setup → p1-read`，再 W3 `rebuild-setup → rebuilt-read → cleanup`。每段停止、寫 machine receipt，Human 全程觀察並回報後才有下一段 ready；ready 時間必須嚴格晚於上一完整 Human 回報，兩者均不得在未來，stage／machine SHA 要匹配。Human sidecar 綁 machine SHA，machine promptCount 保持 null。expired 模式唯讀並分開 launch／App guard／SecItem，沒有 call 即 OSStatus=null。

只有完整 W1 或完整 W2、matching retention／recovery grant 及全段 Human 證據可留存等待。其他失敗／未 ready／timeout／abort 均先 finally cleanup；process 退出不能確證即零新 launch、不換 bundle。沒有有效同 group host 時明列 recoveryRequired、可能殘留 item 並保留最低復原素材。確認 delete/read-absent 後，先保存去識別證據，再精確刪除 proven-owned 私有 run；Apple 開發資產交 Human 管理。

若 W2 在 P1 setup 前失敗、原 P0 已過期，future 手動復原使用 `continuity.py --live --root "<原私有 root>" --cleanup-only "<新 attempt UUID>"`。這不接受 `--begin`／`--window`，不重 seed、不重啟測量、不新增第四窗或重設 global／window 時間。必須另有同 namespace/global SHA 的 `recovery-attempts/<UUID>/grant.json`（明確 cleanup-only 與 selected asset inspection）、fresh ready 及 Human 選定同 group 有效 recovery host；不自動取得／簽章素材。cleanup-only grant 不延長原 assets／retention／recovery 三份 grant；Swift guard 仍要求原 grant 在實際操作當下有效。原 grant 若已過期，即使另有 cleanup-only grant，也不能保證 App 通過 guard 或完成清理。缺授權、無有效 host 或 process 無法確證退出皆保留 recoveryRequired，不宣稱必能清理。late cleanup 對原窗口 deadline 另記，不延長測量。

成功 delete/read-absent 後保存獨立 recovery machine；尚缺匹配 Human 全程 cleanup 觀察就停住保留最小私有素材。同一 attempt 補 Human sidecar 再進入口只完成封存／私有清理，不再 launch。必要公開 windows 起訖／cutoff、ready／Human 的先後、retained、grant 與原 private bytes SHA 關係在刪 root 前封存並納入 index；不輸出私人 statement、Mac／user／group／device 識別。刪除前的 export 失敗即保留私有素材；刪除後的完成收據發布失敗，不能宣稱私有素材仍在。

bootstrap failure 保存獨立 stopped machine、明記零 SecItem 寫入與私有素材仍待清理；可用 `--stop-setup` 作受限 filesystem controlled stop，先封存公開 anchor／W1／setup／Human／ready 與原 SHA，exclusive 寫完整並 fsync pre-cleanup SHA index、回讀核對各檔 SHA 成功後，才刪 proven-owned setup root。刪除前輸出失敗會保留私有素材與未完成狀態；刪除後 cleanup machine／final index 發布失敗則保留 pre-cleanup index，另記 physical cleanup 與 evidence publication，維持 cleanupComplete=false／recoveryRequired=true，不謊稱私有素材仍保留。若曾有 App attempt 就拒絕此零 item 清理；移除失敗回報 cleanupComplete=false／recoveryRequired=true，保留殘留、不碰 Apple assets。bootstrap 必要控制證據同樣納入最終 archive，刪私有 root 後仍可核原 t0／W1／Human→ready 先後。

selected setup verifier 僅在 scope／source／當段 ready 成立後檢查選定素材；可 launch 的 `LiveBackend` 要再等適用 actual proof 驗證完成才建構。純 driver 建構本身不具 App／Security 操作。


### S06 操作 checkpoint（2026-10-22 D02 已審準備契約；執行情況見結果）

本清單是 D02 approved 的五文檔操作準備，不自行授權新輪或操作。其後 10/22 `dfc25e14` 輪依新 Human scope/S/grants／逐段 ready 執行至 Report 來源停點並受控清理；目前兩輪 namespace/grants 均 closed，不能借舊授權重開。以下操作契約不改，完整欄位與原 schema 相容說明見 technical-spec S06 exact-window 段落；不是目前要自動重做的清單。

1. **新begin**：另取新輪授權／begin-ready後，原入口固定新anchor t0/W1；完整beginHuman回報後另setup-ready，anchor前無帳號或簽章操作。
2. **先核設定，不Build/Run**：在授權範圍open同privateproject，Human先只選Team與合格既有cert。匹配單一exactwindow/frontmost/privateproject/sharedscheme/appTarget/initialDebug/Macdestination/UUIDbundle/Team/automaticSigning/InfoEntitlements/ownedoutput。UI實讀、Human聲明、CLIparsed分開，不可用open0或CLI代替GUI；任一無法核對先停。
3. **另build-ready**：設定機器核對與完整Human觀察匹配後，Human另明確ready，僅一次⌘B，不Run；不自動重Build、換scheme或延時。
4. **關窗前取Report**：維持同exactwindow，先取得本次Build Report；無search/recent-only遮蔽、Alltasks，核target/config/result與actualproduct來源。沒有matching Report／product provenance先stop，不先close後拿CLI推回GUI；Human要求先close則先停並指出來源缺口。
5. **完整host才核proof**：ownedproduct的Info/main/profile、namespace/marker/source完整後，依原ready／授權核setup-only，完成global、完整setupHuman再另seed-ready。GUI核對不是CMS/profile/DPK成功。

未來operator補充machine/Human sidecars依原canonical UTF-8/LF/exclusive與SHA保存，機器提示null、Human才記count；公開只bool/hash，未驗null。欄位包含actualReadUI/matchingPrivateProjectWindow/schemeMatches/appTargetMatches/configurationMatches/ownedOutputSettingsMatch/GUIReportObserved/reportMatchesThisBuild/actualProductProvenanceEstablished及來源分類；不存rawAX/私人path/TeamID/certsubject/device/privatekey/token。這些是手動補充，不是harness新增的自動GUI驗證或原CLI新必填schema；build-ready不冒充seed-ready。

全部設定／確認／等待均原W1內，第25分鐘停新操作、最後5分鐘優先精確清理；同leaf/fullgroup/三窗/10日/不rewriteA與RF01–RF06/bootstrapguard不變。Report仍空或host不足即zero-item受控stop，不擴掃全域DD/其他assets；先封存再刪provenowned FS，不稱DPK刪除已驗。若現有入口無法達成，列具體缺口，不自行改source/config/CLI。


## 是否成功

- 控制輪日期：2026-10-21、2026-10-22（各自 closed）；DPK 操作執行日期：未執行。
- 主假設狀態：**未執行**。沒有自然到期、P1 新 profile、真 SecItem 或正常 DPK 憑證存取的真人提示證據。
- 2026-10-21 bootstrap 初次 author preparation：50 methods（0 skip）、actual Swift W1 helper 正負／W2/W3 回歸與兩版新 unsigned compile 通過；B04 獨立 Tester 正式 needs-rework，唯一 B-RF01 為 setup-stop export order。作者回修後 51 methods（0 skip）與原 actual-driver fault repro 通過；本次 B04 獨立複驗與 B05 Reviewer 均正式 approved、required_fixes=[]，resolved B-RF01。核准僅限 preparation，沒有解除 S06 Human 邊界。
- 本輪完整可行性驗證任務完成：**否**。目前 S03 preparation、S04 獨立 Tester 與 S05 Reviewer 均已完成準備範圍，Tester／Reviewer verdict=approved、required_fixes=[]；目前停 S06 human-check，因未取得完整、可驗且來源確定的 host。10/21 受限 controlled-stop／零 item FS 已由 Tester／Reviewer approved；最新 10/22 輪的新獨立 Tester verificationResult=pass、verdict=approved、required_fixes=[]，本次獨立 Reviewer 正式 approved、required_fixes=[]，僅本輪 controlled-stop／zero-item FS 與兩份 factual 文件。原自然週期 S07／完整 S08 未完成，這不是正式 adapter 或產品採用核准。
- 準備檢查：初次 29 個 Python methods、Swift 純 core 7 情境與 unsigned compile 通過，但獨立 Tester 發現 RF01 跨語言 bytes 不相容，正式 verdict 為 needs-rework。RF01 author 修正後 30 個 Python methods（含 actual Swift→Python 四組 roundtrip）、Swift 7 情境與兩版 unsigned rebuild 通過，獨立 Tester RF01 複驗 approved。其後 S05 Reviewer 正式 needs-rework，指出 RF02–RF06；author bounded fix 後 40 methods（0 skip）通過，獨立 Tester focused retest 與 Reviewer 均已正式 approved、required_fixes=[]。這只核准 preparation，不代表主假設成立或 live／retention／採用核准。

## 結果與證據

**2026-10-22 最新控制輪（已 closed；受限 Tester／Reviewer approved）**

公開證據為 [run-20261022T054623Z-dfc25e14](evidence/run-20261022T054623Z-dfc25e14/final-addendum.index.json)，namespace `dfc25e14-425c-4761-8d77-6556e852d5e5`。Human 新 S 為台灣 10/22 14:15，三 grants 到期為 11/1 14:15；actual t0 為 10/22 13:46:23.523860，cutoff 14:11:23.523860、deadline 14:16:23.523860。anchor 所定原 global／正常留存上限本應為 11/1 13:46:23.523860，不因 grant 延長；本輪沒有 complete-global、item 或跨週 retention。

| 本輪案例／範圍 | 實際結果 |
|---|---|
| T01 素材前提 | 前提不足／無法判定：沒有取得本次 matching Debug Build Report／target/config/product provenance，未選 selected App。 |
| 主假設、T02–T06 | 未執行；沒有 actual binary hash／proof、CMS、完整 global、App／SecItem／seed。 |
| T07 DPK delete/read-absent | 未執行；此前零 Keychain item，只有私有 FS 清理。 |
| zero-item FS cleanup | 10/22 14:10:12.023672–14:11:27.478625 完成，在 deadline 前；只有 cleanup 跨 cutoff 3.954765 秒，無新 measurement／clock reset。 |
| 受限獨立驗證／審查 | 新獨立 Tester pass／approved、required_fixes=[]；本次 Reviewer approved、required_fixes=[]，僅受限紀錄／zero-item FS，不完成 S07／完整 S08。 |

setup 的 mkdir 曾遇 template 已有的空 scaffold directories，原 failure receipt 保留；窄幅 continuation 只補缺 WorkspaceSettings／open，沒有改 frozen harness。GUI Build Action 兩列與實際 XML 一個 NativeTarget、一個 BuildActionEntry、空 TestAction 的觀察並存；具體 UI 原因 unknown，不推第二個真 target。GUI 原 DerivedData「Default Location」不足以證 owned placement；經獨立 Reviewer 分類為原 setup scope 內可選本 private project Custom，再另取 Human fresh ready，只改該 project 的 Custom owned DD，重開 GUI 並核私有設定，global preferences 不改。

Human「都是同一個／之前怎麼做現在也怎麼做／沒有提示」僅 same-existing attestation，不是 certificate 效期／profile／group 的實際 proof。Human 在獨立 Build-ready 後一次 Debug ⌘B 回報「Build成功，全程觀察，0次提示，未Run」；但保持開啟的同 exact private window Local Report 只有較早 13:51 Signing update，沒有本次 matching Debug Build Report／target-config-product 來源。依契約就此 STOP，不猜候選、不新 Build、不先關窗再尋來源；Human Build 成功與有界 Report gap 並列保留，不推 Human 未 Build、範圍外無 App、DPK 失敗或需要付費。

六份 machine-bound Human 全程觀察與一份獨立 Build attestation 都為 0 提示，只適用 bookkeeping／setup／Build／cleanup，不是 DPK UX 成功。Human 精確回覆／Build 起訖的 unknown/null 與原 machine pending、promptCount=null 保留，不補造 timestamp。先 close exact project、核 owner／無 symlink／無 handles，durable pre-index 寫入並回讀核 SHA 後才刪本 root。privateRootAbsent／ownedPrivateResidual=false 僅限此 bound root；outside GUI App／全機殘留 unknown，parent／global DD／Recent／其他 projects／Apple 資產不在清理完成宣稱，Apple 資產留 Human 管理。

原 run 保留 60 份 canonical JSON、10 indexes，final index 59 refs（不含 self）。[新獨立 Tester 收據](evidence/controlled-stop-20261022-dfc25e14-tester-verification.json) 位於 run 外，SHA `e16d7aea11eeaeda140195259f41a9cb00f502070917c7eff17a66f6661bdeaa`；該 Tester 未執行此 live run／撰寫原收據，核 258 refs（含重複）全 match。此 approval 僅 controlled-stop／zero-item FS／公開紀錄，不是完整可行性驗證或採用核准。獨立 Reviewer 已正式 approved、required_fixes=[]，僅本輪 controlled-stop／zero-item FS 與兩份 factual 文件；[本輪 closure](evidence/controlled-stop-20261022-dfc25e14-closure.json) 綁受審快照、收尾文件與關鍵證據，之後停 Human 下一步決策；live 已終止於 cleanup，之後都是 offline 封存／核對，不復用舊 grant/run 或延長原窗。

**2026-10-21 前輪紀錄（原受限 approval 與收據保持）**

本前輪公開證據位於 [run-20261021T035701Z-8e279f70](evidence/run-20261021T035701Z-8e279f70/final-addendum.index.json)，namespace `8e279f70-3c62-43ee-91b5-8e9f316f1245`。原 t0 為台灣時間 2026-10-21 11:57:01.736290，cutoff 12:22:01.736290、deadline 12:27:01.736290；未重設。實際 zero-item 私有檔案清理末 12:17:08.080796，在原 cutoff／deadline 前。原 scope consent 與 matching grants 僅綁此輪，不延長到新輪。

| 本輪案例 | 實際結果 |
|---|---|
| T01 素材前提 | 前提不足／無法判定；沒有取得完整可驗且來源確定的 host。 |
| T02–T06 | baseline／自然到期／不同 P1／原 A 恢復／真正重建讀取均未執行。 |
| T07 DPK delete/read-absent | 未執行；此前沒有建立 Keychain item。 |
| 受控停止與 zero-item 私有 FS cleanup | 完成；精確 bound root 已不存在，無該 root 的 owned residual，不宣稱 DPK 刪除成功。 |
| 原窗口／公開證據 | 受限 Tester／Reviewer approved、required_fixes=[]；不完成原自然週期可行性任務。 |

Human 的「Debug Build成功，確認免費PersonalTeam／既有憑證／未Run」宣告完整保留；同時，本輪 owned root 的一個 App 目錄缺 Info.plist、main executable、embedded profile，exact 私有 workspace 的 Local Build Report 為空，未建立完整 matching host 的 provenance。兩者並存，不能推論 Human 未 Build、整機沒有 App 或 DPK 不可用；授權範圍外是否另有 App 仍 unknown，未擴大搜尋。

begin／setup／GUI 診斷／cleanup 四段 Human 均全程觀察、0 次提示，綁各自 machine SHA；這四段沒有 DPK 憑證存取，不能當作零提示 UX 成功。最後 cleanup Human 的精確回報時間未提供，`recordedUTC=null` 原樣保留；原 machine 的 Human pending 亦不改寫，由後來的 Human sidecar 補證。

原 [controlled-stop machine](evidence/run-20261021T035701Z-8e279f70/controlled-stop.machine.json)、[cleanup Human](evidence/run-20261021T035701Z-8e279f70/controlled-stop.human.json)、[獨立 Tester](evidence/run-20261021T035701Z-8e279f70/tester-controlled-stop-verification.json) 與四份 public index 全保留。Reviewer 已核四 index 共 94 個 SHA refs（含重複）全 match；本 run 47 檔保持。受限 Reviewer 正式 approved、required_fixes=[]，只涵蓋 controlled-stop 紀錄／zero-item 私有 FS cleanup。新的 [factual closure](evidence/controlled-stop-20261021-8e279f70-closure.json) 保留當時尚待最後文件核對的快照；依上游後續正式Reviewer回報，該文件closure check已approved，僅受限紀錄一致／zero-item FS，不是本S06-D新文件或主假設approval。未改寫舊closure、未重跑驗證／測試。Apple 資產由 Human 保留；其他 projects、全域 DerivedData／Recent 不在清理完成宣稱。

以下為已完成 preparation 歷史，沒有覆寫成實驗成功。

bootstrap 初次 author revision 見 [preparation-check-bootstrap.json](evidence/preparation-check-bootstrap.json)、[50-method 輸出](evidence/bootstrap-pure-tests.txt)、[新 unsigned 收據](evidence/bootstrap-unsigned.json)。包含 17 份 current source hashes；舊 19 份 evidence 均保留。舊 15 份 source bytes 另存 `evidence/bootstrap-prior-source/`，逐份與原獨立 Tester SHA 完全一致；三個修改檔的舊 bytes 由本輪精確逆向 patch 還原並核 SHA，不偽稱事前備份。

本 revision 只改 bootstrap Python／LiveGate W1 鏈與必要測試，其他 App 功能不改。Swift helper 合法鏈先以 stub 觀察 rejected red，再實作至 green；早期人工 ready fixture 的微秒間隔改為一秒以符合既有日期解析精度，不冒充功能 red。W2/W3 負例先更新 fixture window binding，確保拒絕來自缺 global SHA，而非 stale hash。Python bootstrap 功能先實作後加入回歸，沒有宣稱其全部為 test-first red。

新 unsigned Debug main SHA `79ddf9b65ab66653910dfed244ad8d64643a68abe6eb117c79f0213ea1fc76d0`；Rebuilt `c4ca802d50bee51af9ac4e27b124a42eb210041bb31f80fc0bbe479086886d2e`，均 exit=0／無 debug dylib。只是 unsigned 準備，不是實際簽章、App launch 或主假設證據。

最新 B-RF01 author revision 見 [preparation-check-bootstrap-export-order.json](evidence/preparation-check-bootstrap-export-order.json)、[51-method 輸出](evidence/bootstrap-export-order-tests.txt) 與 [原 actual-driver fault repro 修後輸出](evidence/bootstrap-export-order-repro.txt)。B04 的 [needs-rework 收據](evidence/tester-preparation-bootstrap.json) 與原最小 repro／unsigned 收據全部保留；其後 B04 [獨立複驗](evidence/tester-preparation-bootstrap-export-order.json) 正式 approved、required_fixes=[]，focused 11 methods／原 actual-driver fault repro／刪除邊界 pre-index 與 SHA 均確認；B05 Reviewer 正式 approved、required_fixes=[]、resolved B-RF01。原 needs-rework 不改寫。

B-RF01 先用原 `--stop-setup` repro 重現 final index 寫入失敗時 private root 已刪、沒有 pre-index 的 red；再加 actual CLI driver 的四個 fault subcases，修前有三個 subcase 失敗，修後 focused 11 methods 與整合 51 methods 均通過。兩個刪除前 export faults 不呼叫 rmtree、保留原 anchor bytes；兩個刪除後 publication faults 留 durable pre-index／可核 SHA，另記完成證據未發布，不假稱私有資料仍在。四個 subcases 皆零 command／App executor／launch；純 fixtures 不代表 live 證據。

本修正僅改 `scripts/proof.py` 與 `Tests/test_bootstrap.py`；兩檔前一版原 bytes exclusive 留於 `evidence/bootstrap-export-order-prior-source/`，與 B04 source SHA 相符。17-source manifest 為 `ad74bf47a34e583c3c823c65c018ae20276934a4a94571eee68bcb93cba0eb41`；舊 40 份 evidence（含原 19、舊 source archive 15、bootstrap author 3 與 Tester 3）全數核 SHA 未變。8 份 App build inputs 未變，沿用前述 author／Tester unsigned 證據，本回修不重建、不簽章、不 launch。原 t0／窗口／grant 不重設，主假設仍未執行。

本次 [bootstrap factual closure](evidence/bootstrap-preparation-closure.json) 記錄上述獨立角色 verdict 與本輪 owned prep cleanup。核對 UID、零 symlink／特殊檔與無其他引用程序後，已精確移除本輪 bootstrap prep scratch／兩版 unsigned outputs 及兩份本作者 helper；repo 安全證據全留。本 closure 未重跑 test／build、不改 source／舊收據；不宣稱清理其他 scratch、Apple 資產或全域暫存。

以下保留 2026-10-20 preparation／回修與 closure 歷史；不替代本 bootstrap revision 的獨立審查。

初次 author [preparation-check.json](evidence/preparation-check.json)／[Python 輸出](evidence/python-preparation-tests.txt)／[unsigned 收據](evidence/unsigned-preparation.json) 與獨立 [tester-preparation-check.json](evidence/tester-preparation-check.json) 全保留原 bytes。Tester 的 `tester-initial-*` 最小 fixture／actual／expected 證據也不改寫；初次 green 未涵蓋跨語言 receipt 邊界，不能當作 RF01 已通過。

RF01 revision 見 [preparation-check-rf01.json](evidence/preparation-check-rf01.json)，綁定 14 份 source／config／tests SHA、全部舊收據 SHA 與 [新 Python 輸出](evidence/python-rf01-tests.txt)／[unsigned 重建收據](evidence/unsigned-rf01.json)。

- RF01 原因：Foundation 的排序、colon 空白與 empty object 格式不同於 Python canonical，實際 App receipt 會被拒絕 `nonCanonicalJSON`。修正 Swift receipt serializer 明確使用 Unicode scalar key 順序、兩格縮排、colon 後一格、inline empty collections、UTF-8 與末尾 LF；receipt 只接受整數 PID／OSStatus，不放寬 Python reader、SHA 或 exclusive write。
- 新 `Tests/ReceiptProducer.swift` 直接呼叫 App 同一 serializer，實際純 Swift producer 的 no-call/null、六欄成功、empty cleanup、Unicode／escape 四組輸出，均先 exclusive 寫入後交 actual `continuity.read` 比較 bytes／SHA；再次寫入同檔會被拒絕且原 bytes 不變。四組先重現 red，再修至 green。
- RF01 Debug main SHA：`38554d3acb1039ce748c8200f5499c90433571a3fdbe4edec724b51a7295e947`。
- RF01 Rebuilt main SHA：`d72d3be95668f24dc390e52607662f7ffffd54da7aff995f110cb24ca1324c0b`。
- Swift 變動後重新 unsigned build；兩版 exit=0、main hash 不同、均無 debug dylib。這只是準備證據，不是簽章／DR／profile 或 live rebuild 證據；RF01 已獨立複驗 approved；RF02–RF06 亦已獨立複驗／審查 approved。
- RF01 獨立複驗見 [tester-preparation-rf01.json](evidence/tester-preparation-rf01.json)；原 author／Tester 歷史收據全部保留。
- 最新 RF02–RF06 author revision 見 [preparation-check-review-fixes.json](evidence/preparation-check-review-fixes.json) 與 [40-method 輸出](evidence/python-review-fixes-tests.txt)，綁 15 份 source／config／tests SHA。focused red 曾顯示 ready 早於 Human 仍被接受、其他 device 未拒、缺 recovery／binding／archive，再修至 green；中途純 fixture selection／變數 typo 不當作行為 red。
- 新純回歸覆蓋 ready／Human 時序、其他 Mac／user／device、實際固定 driver 的失敗 W2→另授權同 group recovery host→exact cleanup、原時計／receipts 不變、未確證退出零新 inspection／launch、適用 ready/proof 前零 App executor，以及刪 synthetic root 後僅靠 archive 核對 window／gate／Human／retained／index SHA。外部 asset verifier 與 App executor 均 mock，沒有真正 Security。
- RF02–RF06 獨立 Tester 收據見 [tester-preparation-review-fixes.json](evidence/tester-preparation-review-fixes.json)，SHA `2545d48122579c4f41cb4dba0af7798c93c5a8308080770715b10f6e76a94d93`；Reviewer 正式 approved、required_fixes=[]，resolved RF02–RF06。文件／暫存清理 factual closure 見 [preparation-closure.json](evidence/preparation-closure.json)，不覆寫先前 needs-rework 收據。
- RF02–RF06 僅 Python／tests 變動，8 份 Swift／project／resource build inputs 與 RF01 unsigned 收據相同，未重跑無受影響 build／Swift core；actual Swift→Python roundtrip 隨 40-method suite 再通過。
- 純測試包含真正執行固定 coordinator branch 的三窗口、無 reseed、profile-only 控制、ready／SHA／deadline／grant、失敗 cleanup／無有效 host 殘留、未確認退出零新 launch、去識別輸出先保存再刪 synthetic root。formatter 測試使用既有 v6.0.0 EOF fixer，驗 canonical bytes 不變，沒有套用 E006 的舊例外。
- TDD 曾先觀察 canonical LF 缺口及六欄 comparison 未實作而失敗，再修至 green。最初 Swift 測試的編譯 typo、收尾 fixture 多傳參數也已修正，兩者不冒充行為 red 證據。
- [baseline-freeze.json](evidence/baseline-freeze.json) 綁定已合併 E006 全 126 檔；準備後逐檔 SHA 相同，包含兩輪原 index 與所有 immutable receipts。E005／E007／production 未修改；dev HEAD 與乾淨狀態保持。

## 結論與限制

2026-10-20 最小準備已通過獨立 Tester／Reviewer；2026-10-21 bootstrap 修正版在 B04 發現 B-RF01 後已由 author 回修，本次 B04／B05 preparation 均正式 approved、required_fixes=[]、resolved B-RF01；仍不能回答自然到期後的恢復／零反覆提示／人工維護成本。選定素材的真 CMS／平台 CLI 整合、同 certificate 取得不同有效 P1、自然過期 host 能否 launch 或呼叫 SecItem、跨週留存與清理 host 都尚未驗證。mock 到期只測 guard，不欺騙系統 API。

目前停 S06 human-check，缺本次完整、可驗且來源確定的 host／Build Report product provenance；最新 `dfc25e14` 與前輪 namespace 均 closed、各自精確 private root 已刪，沒有 item 或跨週留存。主假設／DPK／UX 均未執行，T01 前提不足／無法判定；只有受限 controlled-stop／公開紀錄與零 item FS 清理。最新新獨立 Tester 與 Reviewer 均 approved、required_fixes=[]，僅受限紀錄與 zero-item FS；下一 boundary 是 Human 決定下一步，不能借舊 grants／namespace、重開 clock 或默認續測。保留 E006 受限成功及 10/16 controlled-stop／逾時、E005 legacy UX 的歷史，不用本題覆寫。certificate rotation、多週期、多 Mac／OS、真 token／GitHub OAuth、正式 adapter／產品 UI、migration、公開分發與付費資格均非本輪範圍。
