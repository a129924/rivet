# Profile continuity 帳本

> **PR #67 遷移契約更新：** Human已明確接受DPK E008→E010的受限遷移。下列「PR67遷移」段落規範當前編號／檔案／Git授權；舊E008內容保留為遷移前研究／執行歷史，不可據其舊路徑或approval操作dev PKCE E008。M01/M03/M04已各依受限範圍approved、required_fixes=[]；M05首筆遷移commit819b26d已正常完成。M06已在feature受控整合dev並準備E010登記，待M07核對/M08訊息與第二commit/M09發布；不是合併至dev。S06仍human-check、主假設未執行。

- Topic：`github-oauth-dpk-profile-continuity-feasibility`
- Branch：`chore/github-oauth-dpk-profile-continuity-feasibility`
- Phase：PR67 M05首筆commit完成，M06受控整合/登記草稿待M07獨立核對及M08第二訊息確認；可行性live仍停S06 Human
- Current step：S06
- Current status：human-check
- Upstream verdict：本次M01獨立Plan-Reviewer複審approved、required_fixes=[]；原分期驗收/registry寫審角色needs-rework歷史保留。M03獨立Tester focused正式approved、required_fixes=[]、resolved M-RF01（收據SHA20ed1c8145c223cb26bd99aba65aa13243d3e870ef57bff8b497a66ac5594ad3）；原needs-rework歷史保留；M04獨立Reviewer已approved、required_fixes=[]。M05首筆正常commit819b26d完成，M06整合/登記待M07/M08。10/22 新獨立 Tester verificationResult=pass、verdict=approved、required_fixes=[]，只涵蓋 controlled-stop／zero-item FS／紀錄；本次 Reviewer approved、required_fixes=[]，僅本輪 controlled-stop／zero-item FS 與兩份 factual 文件。S06-D02 Plan-Reviewer 五文檔操作準備與前輪 C／bootstrap approvals、needs-rework 歷史保留，不是主假設／採用核准（以上既有角色結果僅原revision歷史，不是E010 approval）
- 主假設：未執行
- Experiment：DPK活動E010（feature已受控整合/本地登記草稿，待M07/M08/M09；未發布）；原DPK E008為封存歷史，dev PKCE E008必保護。
- 最後更新：Implementer記M01實際approval及M02離線遷移作者交付；無新真人輪起點，未改原收據。

## 原可行性Steps（S06狀態不變，遷移另依M序列）

| ID | Status | Owner role | 完成條件 | 驗證證據 |
|---|---|---|---|---|
| S01 | completed | Plan-Creator | 四檔scope/固定profile-only/時間/授權/recovery明確 | requirements/technical-spec/plan/step已落地；僅編寫完成，不是approval。 |
| S02 | completed | Plan-Reviewer | 獨立審四正式artifacts並明示verdict | 獨立 Plan-Reviewer 正式 approved，required_fixes=[]；由上游路由授權 S03。 |
| S03 | completed | Implementer | S02approved後feature-only新harness/純tests/unsignedcompile | E008 最小準備已交付；初次 29 methods 未涵蓋跨語言邊界。RF01 修正已獨立複驗 approved；RF02–RF06 author fix 後 40 methods（0 skip）通過，15-source revision 見 preparation-check-review-fixes.json。Swift／project／resources 未變，沿 RF01 Swift 7 情境／unsigned 證據。沒有真 Security／asset／launch／arm／seed。 |
| S04 | completed | Tester | 獨立驗證guards/resume/deadline/recovery/mock/unsigned | 初次 RF01 needs-rework／修正與複驗歷史保留；RF02–RF06 focused retest 正式 approved，required_fixes=[]；40 methods／source／原證據與 build input 相符。收據 SHA 2545d48122579c4f41cb4dba0af7798c93c5a8308080770715b10f6e76a94d93。 |
| S05 | completed | Reviewer | 獨立審查準備實作／Tester與scope | 原 RF02–RF06 needs-rework 歷史保留；正式複審 approved，required_fixes=[]、resolved RF02–RF06；可到 S06，無採用核准。 |
| S06 | human-check | Human | 具體 scope／適用 ready 與完整可驗 host／product provenance | 10/22 dfc25e14 輪有新 S/grants／逐段 ready，但本次 matching Build Report/product provenance 不足，已 controlled-stop、root gone。Reviewer 後由 Human 決定下一步；不復用 closed run/grants，不自行新輪。 |
| S06-B01 | completed | Plan-Creator | Human已同意的bootstrap契約落四檔 | 四檔窄幅回修已編寫；僅author完成，不是revision approval。 |
| S06-B02 | completed | Plan-Reviewer | 獨立複審本revision四檔／邊界 | 原 W1 相容缺口 needs-rework 已同步四檔；獨立複審正式 approved，required_fixes=[]，可 B03；舊 S02 不替代。 |
| S06-B03 | completed | Implementer | B02approved後受限bootstrap code/tests/README回修 | 初次 author 50 methods／Swift helper／兩版 unsigned 歷史保留；B-RF01 author 已回修，刪除前先 durable pre-cleanup SHA index、export failure 不刪私有，刪除後 publication failure 如實分列。51 methods 0 skip／原 actual-driver fault repro 通過；見 preparation-check-bootstrap-export-order.json。8 份 App build inputs 未變、不重建。未真 arm/assets/live。 |
| S06-B04 | completed | Tester | 獨立核bootstrap純驗收與RF01–RF06必要回歸 | 原 needs-rework [B-RF01] 收據保留；唯一 setup-stop export order 修後獨立複驗正式 approved、required_fixes=[]、resolved B-RF01。focused 11 methods／原 driver repro／刪除邊界 pre-index 與 SHA 確認；新收據 SHA 769e1080532a02782ba597722c5be946a3e5e04e7deedc22022c2112c23f25d8。 |
| S06-B05 | completed | Reviewer | 獨立核修正版／Tester／scope後返回S06 | 獨立 Reviewer 正式 approved、required_fixes=[]、resolved B-RF01；僅 preparation，可回 S06 human-check，不解除 Human 資產／live／retention 邊界。 |
| S06-C01 | completed | Tester | 本控制輪受限停止／zero-item FS cleanup／公開紀錄一致 | 正式 approved、required_fixes=[]；收據 SHA 6375770c88f5c0951077c27559178e9a2e67bb33954d0837308ab8b03e90b174。T01 前提不足／無法判定、mainhyp/T02–06/T07 DPK 未執行。 |
| S06-C02 | completed | Reviewer | 獨立核本輪 controlled-stop 紀錄／zero-item FS cleanup | 正式 approved、required_fixes=[]；四 public index 94 refs（含重複）match、run 47 檔；不是完整 S08 或採用核准。上輪最後文件 closure check 依上游正式Reviewer回報亦已approved；僅紀錄一致與zero-item FS範圍，不是本S06-D新文件review或DPK核准。 |
| S06-D01 | completed | Plan-Creator | 既有四檔＋E008 README補settings-before-Build／Report-before-close | author文件完成；不改source/schema/收據，未執行清單，不是approval。 |
| S06-D02 | completed | Plan-Reviewer | 獨立審五檔一致／操作與授權界線 | 正式approved，required_fixes=[]；reviewer=/root/dpk_plan_reviewer，review_scope=僅五文檔操作準備，無新live/feasibility approval；review snapshot見下。本次帳本記錄另待窄幅closure check。 |
| S06-E01 | completed | Tester | 10/22 本輪受控停止／zero-item 精確 FS 清理 | 原 t0 13:46:23.523860、cutoff 14:11:23.523860／deadline 14:16:23.523860；cleanup 14:10:12.023672–14:11:27.478625，僅 cleanup 越 cutoff 3.954765 秒、deadline 前完成，無新 measurement/reset；run60原檔保持。 |
| S06-E02 | completed | Tester | 新獨立角色核本輪公共紀錄／清理／Human chain | verificationResult=pass、verdict=approved、required_fixes=[]；獨立 Tester 未執行本 run／撰寫原收據，非原 live Tester 自審。run 外 controlled-stop-20261022-dfc25e14-tester-verification.json SHA e16d7aea11eeaeda140195259f41a9cb00f502070917c7eff17a66f6661bdeaa；258 refs match，只限 controlled-stop/zero-item FS/紀錄。 |
| S06-E03 | completed | Reviewer | 獨立核本輪受限結果與作者兩份 factual 文件 | /root/dpk_reviewer 正式 approved、required_fixes=[]，僅本輪 controlled-stop／zero-item FS 與兩份 factual 文件；不核准主假設／DPK／UX／adapter。 |
| S07 | pending | Tester | 單自然週期三主動窗，原A恢復與prompt/availability/maintenance、精確cleanup | 主假設／baseline 未執行，無 seed／原 A／跨週 item；本控制輪只有 begin/setup/診斷與受控停止。 |
| S08 | pending | Reviewer | 獨立核對live結果/機器HumanSHA/控制與清理 | 完整自然週期未實證；前輪 C02 與本輪 E02／E03 受限 approval 均不替代完整 S08。 |
| S09 | pending | Human | review／後續決策 | commit/push/PR/adapter/merge均無本topic授權。 |

## Locked decisions

Human已同意的S06-BOOTSTRAP契約澄清：未來第一筆設定前固定immutableanchor的原t0/W1/10日與bindings；原W1內setup-only核實際日期，不launch/SecItem；後建global/actualproof引用原anchor/W1，另seed-ready才baseline。四檔 B02 已獨立 approved；code author 完成，本次 B04／B05 preparation 亦正式 approved、required_fixes=[]，返回 S06 human-check，不由本段放行 live。

只profile-only自然到期，同certificate/fullprefix+AppID/group，P1必實際換新有效；no rewrite/read原fakeA。certificate rotation另案，DR記錄不當DPK跨cert必然same。baseline首次≤1、後續正常read0、六欄一致，資料恢復／availability／維護成本分開。三窗各30min/+25minstopmeasure，global≤10日原t0不reset；無daemon/automation/改系統時間。只有明確grant且完整baseline或完整P1待W3可retained；其他failurecleanup優先，無host則明列殘留不假稱alwaysclean。production/E006/E007不改、providerownership不變。

## Blockers

- S06-D02 五文檔操作準備 approved 歷史保留；後續 10/22 輪另有新 Human S/grants／ready 並已執行至 Report 停點。現缺本次 matching Build Report/product provenance、沒有 selected host；新獨立 Tester approved，本次 Reviewer approved、required_fixes=[]，僅本輪 controlled-stop／zero-item FS 與兩份 factual 文件。已 closed grants 不能借用，不自行新輪／延時。

- 本 revision 原 Planner 首次日期循環／Plan-Reviewer W1 鏈相容 needs-rework 歷史保留；四檔 B02 複審已 approved。B03 author 完成後，B04 曾正式 needs-rework [B-RF01]；唯一 export-order 缺口修正後，本 revision B04／B05 均正式 approved、required_fixes=[]、resolved B-RF01，原收據完整保留。

- S02／S04／S05 準備範圍已正式 approved，required_fixes=[]；歷史 needs-rework 與所有收據保留。
- 最新本輪 T01 前提不足／無法判定：Human 一次 Debug Build 成功／全程 0／未 Run 宣告與 exact window 只有較早 Signing update、缺本次 matching Report 並存。未選 selected App／actual hash/proof/CMS/global，outside unknown，不推 Human 未 Build、全機無 App、DPK 失敗或需 paid。
- E008 建立前占用檢查已完成；E006 全 126 檔 freeze／兩輪 index 原 SHA 未變，E007 不改；live 所需真 proof 尚未取得。
- 同certificate新有效profile能否取得／自然expiry恢復行為／維護負擔均未實證；官方與E006不替代本題。

## Human Check

最新 10/22 `dfc25e14-425c-4761-8d77-6556e852d5e5` 輪是新 Human 授權與逐段 ready，不借前輪 grant；S=台灣 10/22 14:15，三 grants 到 11/1 14:15。actual t0=13:46:23.523860，anchor 原 global／正常 would-be 留存上限=11/1 13:46:23.523860；無完整 global/item，沒有跨週留存。該 run 已 closed、精確私有 root gone；未來新輪須 Human 決策／新適用授權與 ready，不自行重開 clock、namespace、grant。

六份 machine-bound 完整 Human 觀察加一份 Build attestation 均 0 提示，僅 bookkeeping/setup/Build/cleanup；不是 DPK 憑證 UX。Human「同一個／之前怎麼做現在也怎麼做／沒有提示」只 same-existing attestation，certificate 日期／profile／group 未驗。Human 精確回覆與實際 Build 起訖 null、原 machine pending 保留。Apple 資產留 Human 管理；parent/global DD/Recent/其他 projects 未納清理宣稱。

新獨立 Tester／本次獨立 Reviewer 均已 approved、required_fixes=[]，僅受限紀錄／zero-item FS；停 Human 決策。Current S06 human-check、S07／完整 S08 pending；T01 前提不足／無法判定，主假設／T02–T06／T07 DPK 未執行、整體驗證未完成。正式 adapter／Git 未授權。

### 前輪 Human scope／操作契約歷史（非本輪待執行狀態）


本輪 Human 最新明確答：「同意上述完整範圍；各段 ready 另行確認」。[S06 scope-consent](../../experiments/E008/evidence/S06-scope-consent.json) 記此同意，不當作 begin-ready、實際 grants 或全程觀察。Current S06 human-check 不變，但這不是目前仍待 begin 的斷言：本控制輪後來已取得 S／實際 namespace、grants 與 begin/setup/診斷/cleanup ready，並在原時計下受控停止；該 namespace 現已 closed、私有 root 已刪。

批准的私有位置模板為 `~/Library/Application Support/RivetExperiments/rivet-E008-<newUUID>`，0700、非 Git／tmp、無 symlink；正常留一假 A 與最小 App/source/proof/namespace 至 actual t0+10 日。Human 用單一免費 Personal Team，Xcode 重用合格既有 leaf cert，設定新 UUID App ID／group、P0／P1、同 cert／完整 group 有效 recovery host 及本機註冊。無合格 cert 就停止另問，不默認新建／輪替。不 inventory 他人資產、revoke／刪資產騰 quota、付費、改 trust/ACL/search-list；Apple 資產由 Human 保留。

開始前先明確確認 latest-start S；三份 grant 的 validUntil=S+10 日，actual t0<=S，正常 retention/global 仍 actual t0+10 日。最多 3×30 分鐘，各第 25 分鐘停新測量，setup／簽章／等待均計入原窗口；不 reset、不第四窗、不 schedule。無 host／原 grant 過期／清理失敗接受 recoveryRequired 殘留與最低復原材料，Human 另授權；cleanup-only grant 不延長原三 grant，Swift 仍要求原 grant 當時有效，逾期後不能保證清理。

原首段已依適用 ready 建立 root／grants／anchor/W1，Mac/user binding 私有保存，未借歷史 metadata。begin 後的 setup／GUI 診斷／cleanup 各有 Human ready 與全程 0 提示回報；未到 CMS／setup-only／actual proof/global／App／SecItem。現在缺完整可驗 host，不是可以補 S 就自動重跑；新輪／新 namespace／時計必須另由 Human 決策與 ready，不能借本輪已關閉授權。

先前 preparation-only／窄幅 bootstrap 的授權與 needs-rework／approval 歷史保持；本次完整 consent 是較新的獨立授權，不覆寫原收據。不沿用 E006/PR59/E007。正式 adapter／Git publication 仍未授權。

## Handoff

10/22 本輪受限紀錄／zero-item FS 與作者 README／step 已由新獨立 Tester／Reviewer approved、required_fixes=[]，S06-E03 completed。[本輪 closure](../../experiments/E008/evidence/controlled-stop-20261022-dfc25e14-closure.json) 綁受審快照、收尾文件與關鍵證據；停 Human 下一步決策，無新 live／clock／grant／root／selected host 操作授權。原 run 60 canonical JSON／10 indexes／final59 refs（exclude self）保持，final-addendum SHA aec4b697d54f7a877c9ba1011357e778004817e61e161a93e61814201c5ee1be。

本輪 setup mkdir 的已知空 scaffold failure／窄幅只補缺 WorkspaceSettings/open 原紀錄保持，frozen harness 未改。GUI 兩列與 XML 單 NativeTarget／BuildEntry／空 TestAction 並存，UI 原因 unknown。Default DD 不足後經獨立 Reviewer 分類原 setup scope，Human 另 fresh ready 才僅 per-project Custom owned DD 並重開 GUI／核私有設定；globalprefs 不改。Human 一次 Build 成功宣告保留，同窗 Report 只有較早 13:51 Signing update，未建立本次 target/config/product 來源，依契約停止，不猜候選、不新 Build、不先關窗後找來源。

cleanup 末台灣 14:11:27.478625，在 deadline 前；只有 cleanup 跨 cutoff 3.954765 秒，live 於 cleanup 終止，其後全 offline。先 close exact project／核 owner-nosymlink-nohandles／durable pre-index 回讀確認才刪本 root；privateRootAbsent／ownedPrivateResidual=false 僅該 root，outside GUI App／全機殘留 unknown。沒有 Keychain item，不是 DPK delete/read-absent。source17／E006126／所有 prior96 與 protected40／run60／新 Tester immutable receipt 保持；dev 自行位於 fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4 且 clean，沒有同步／merge 到 feature16606b89。

### 先前交接快照（10/21 與 D02，非本輪 current 狀態）


2026-10-22：S06-D01 author已補五檔，D02獨立Plan-Reviewer正式approved、required_fixes=[]，僅五文檔操作準備；本次最小帳本閉環交同Reviewer窄幅closure check，不預填該核對結果。Current S06 human-check不變。上輪C01/C02及最後closurecheck皆為其受限approved歷史。本次只是操作清單，不新建private root/grant/namespace/clock、不UI/Xcode/build/test/CMS/Security/App/DPK/Git；D02已通過，仍需Human明示新輪/S/適用grants與逐段ready。

本真控制輪 `8e279f70-3c62-43ee-91b5-8e9f316f1245` 已 closed。原 t0 台灣 2026-10-21 11:57:01.736290，cutoff 12:22:01.736290／deadline 12:27:01.736290；清理末 12:17:08.080796，在 cutoff 前。精確 bound private root 已不存在、無該 root owned residual；此前零 Keychain item，不能稱 T07 DPK delete/read-absent 已驗證。Human Apple 資產保留，其他 projects／global DerivedData／Recent 不屬本清理完成範圍。

Human 宣告 Debug Build 成功／免費 Personal Team／既有憑證／未 Run，原話保留；scope-owned App 不完整與 exact workspace Local Build Report 空亦保留，授權範圍外是否另有 App unknown，不能推論 Human 未 Build／整機無 App／DPK 失敗。begin/setup/診斷/cleanup 四段 Human 全程 0 提示，不是 DPK 憑證 UX 證據；最後 cleanup Human 精確 recordedUTC 未提供，維持 null，原 machine pending 不改。

[本輪 Tester](../../experiments/E008/evidence/run-20261021T035701Z-8e279f70/tester-controlled-stop-verification.json) 與獨立 Reviewer 均正式 approved、required_fixes=[]，僅本輪 controlled-stop 紀錄／zero-item FS cleanup；S07／完整 S08 不 completed。T01 前提不足／無法判定，主假設與 T02–06／T07 DPK 未執行，完整 feasibility 未完成。詳 [本輪 factual closure](../../experiments/E008/evidence/controlled-stop-20261021-8e279f70-closure.json)；上輪文件閉環依上游正式Reviewer回報已完成唯讀核對approved；舊closure JSON的pending是當時快照不覆寫。本次S06-D文件另交獨立Plan-Reviewer，不預填新approval。

Current S06 human-check，原因是欠完整可驗 host；不自行開新 run／namespace／clock、不延時、不借舊 grant。source 17 manifest ad74bf47a34e583c3c823c65c018ae20276934a4a94571eee68bcb93cba0eb41／本輪 47 檔／全部歷史 evidence／其他三份契約／E006 126 檔原 SHA 保持；本 closure 不重測、不建置、不碰 private root 或開發資產，無 Git／正式 adapter 授權。

### 歷史 preparation closure（保留，不是bootstrap新revision放行）


S04 Tester／S05 Reviewer 均正式 approved，required_fixes=[]；停 S06 human-check。主假設未執行、完整 feasibility 任務未完成，不開始真人測量／跨週留存／資產操作／clock arm／正式 adapter 或 Git publication。Human 下一步須明確確認具體資產、私有持久位置／期限、recovery 與殘留方案，再分段 fresh ready；本次不預填授權。

[最新 Tester](../../experiments/E008/evidence/tester-preparation-review-fixes.json) 與 [factual closure](../../experiments/E008/evidence/preparation-closure.json) 保留結果邊界；README 維持八段。已核對並移除本輪 proven-owned prep scratch／unsigned outputs／五份 helper，安全證據留 repo；source／全部舊 receipts 原 SHA 未動，dev 乾淨。沒有 Apple 資產可清理，本輪未操作該資產；不宣稱其他人或全域暫存已清。

## S06-D02 review snapshot（非本帳本更新後SHA）

Reviewer：`/root/dpk_plan_reviewer`；verdict=`approved`；required_fixes=[]；review_scope=僅五文檔操作準備，沒有新live/feasibility/adapter核准。以下為Reviewer實際審查時bytes，非本次最小記錄變更後的自我SHA；舊immutable closure/receipts原樣保留。

- `analysis/github-oauth-dpk-profile-continuity-feasibility/requirements.md`：`c83ea7bafdcd95ec80022410fcc212cf96df85008d0d8cd6f055dc84b046984d`。
- `analysis/github-oauth-dpk-profile-continuity-feasibility/technical-spec.md`：`7d1d7f0a8c1547dfac4d139d8f05142505476dad8f0129e9aec7b21b87d075c4`。
- `plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.plan.md`：`e445ea9e0e0230e7074fd43d5965453d784319856657faba6da994ae9aac63d8`。
- `plan/github-oauth-dpk-profile-continuity-feasibility/github-oauth-dpk-profile-continuity-feasibility.step.md`：`9bb6d9ae5dc262744bba8f41b6336e25e5562b0489eebb95051bcdb7d28deb18`。
- `experiments/E008/README.md`：`ac8102609f1d80596969d6eaf3e54e515119b1fbb42871cca25cee02fdc97545`。

## PR67遷移帳本（當前附屬工作；不取代S06）

Human已接受E010活動身分、22快照/171immutable映射/5source缺口保留、append migration與受控dev整合/登記；Planner前置approved，不代表本次四檔或E010實作approved。當前Current仍S06human-check、S07/完整S08pending、主假設未執行；沒有新DPKitem/live/grant/clock/資產。

| ID | Status | Owner role | 完成條件 | 驗證證據 |
|---|---|---|---|---|
| M00 | completed | Implementer | originCommit422d0c7的22原檔保全＋193清冊 | 23新保全檔，original-files.json SHA ac06351613c2aa198b2139e71cc72c8106b177f051c4732a107fa7dafc4855ef；171未搬，原193尚未在M02改動。 |
| M01-A | completed | Plan-Creator | 本次Human遷移細則落實四檔 | author已完成，非approval；不改23保全/source/evidence。 |
| M01 | completed | Plan-Reviewer | 實際四檔獨立複審 | 獨立複審正式approved、required_fixes=[]；原分期/角色needs-rework歷史保留，由上游明示路由M02。 |
| M02 | completed | Implementer | 占號/來源再查、17active/README與171move/map/newmanifest | 作者完成：首次5遠端完整trees/5registered worktrees/open PR占號無他owner；193accounting/22快照/171immutable移動、固定E010身份拒舊E008、typed map/新manifest/必要pure及兩版unsigned。新證據見E010 renumbering-preparation-check.json；五source缺口及舊文件SHA不符保持unknown，M03/M04待獨立。 |
| M03 | completed | Tester | 只核已交付M-T01–04、M-T05可當下部分與M-T06首次占號，必要pure/unsigned | 原needs-rework [M-RF01]/a467c6…保留；同Tester focused正式approved、required_fixes=[]、resolved M-RF01，收據SHA20ed1c8145c223cb26bd99aba65aa13243d3e870ef57bff8b497a66ac5594ad3。56pure/Swift7/兩unsigned及193/171/22/23/14indexes/352refs均已核；M-T05批准base PKCE、M-T06首次保存占號記錄補核通過，非新全球占號/登記聲明。 |
| M02-RF01 | completed | Implementer | 三聚合digest明列non-file且零filelookup | 作者回修：新增focused schema負例、新map/manifest/prep統計一致，1952 file refs＋3 non-file digests；原23/171不改，無runtime/Swift/build變動，M03 focused已approved，原回修產物保持。 |
| M04 | completed | Reviewer | 獨立審M03已發生的遷移證據及實際stage/hooks | 獨立Reviewer正式approved、required_fixes=[]；已審首筆patch cf83168…、221檔及原六normal hooks。只核M04已發生範圍，不預先核准M06整合/登記或M09發布。 |
| M05 | completed | Implementer | 真stageddiff/message→Humanconfirm→append migrationcommit | Human明確確認「chore(dpk): 將 profile 延續性實驗遷移至 E010」；commit 819b26d20272cfcc9e664c4dccba867bcd34c92d、parent422d0c7，原六hooks正常全Passed無skip。221 committed bytes吻合受審stage、23/171不變；尚未push。 |
| M06 | in-progress | Implementer | 占號再查、merge --no-commit --no-ff origin/dev，整合後修改experiments/README.md與experiments/VALIDATION-SUMMARY.md只增E010 | 第二次5remote完整trees/5registered worktrees含Markdown及openPR無他E010owner；PR67仍Draft/head422d0c7/base758aca9bb518f2a21f20f47609335fac49043370。受控merge成功無衝突，HEAD819b26d20272cfcc9e664c4dccba867bcd34c92d未移動、MERGE_HEAD758aca9；兩registry只增E010、E001–009/PKCE與其餘dev全樹保持，待M07獨立核對與M08第二訊息/commit。 |
| M07 | pending | Reviewer | 只審Implementer完成的experiments/README.md、experiments/VALIDATION-SUMMARY.md及PKCE/整合diff | 不代寫檔；補核第二次占號/M05已發生commit/Human訊息/hooks，未發生不預填。 |
| M08 | pending | Implementer | 第二真stageddiff/message→Humanconfirm→hooks/commit | 不預填messageapproval。 |
| M09 | pending | Implementer | push前第三次占號、補M08 commit證據，發佈/PR67readback與本機工具交付 | M-T06後段/M-T07只於實際發生後核；仍Draft且非CONFLICTING才稱解除，未push，不改舊圖/不extractgraph。 |
| M10 | pending | Human | 依M09實際發布/readback/工具交付作review與後續決策 | 不merge至dev、不正式adapter採用；不是工具製作步驟。 |

### Migration Blockers／Human Check

- M01已正式approved；M02作者交付，M03已focused approved、required_fixes=[]；M-RF01 needs-rework與作者修正歷史保持，M04已受限approved；M05已commit，M06整合/登記草稿待M07/M08。新E010 source另有manifest/準備證據，不能借原ad74…/approval。
- 五歷史source內容既存缺失保留content-unavailable-in-published-snapshot；receipt/index完整不等全部source可重建。
- E010開始前、整合/登記時、push前三次重查，其他owner占用停Human、不E011；登記前不稱保留。
- M05與M08各需實際stageddiff和具體message Humanconfirm，舊commit訊息不構成授權；普通dev→feature整合只允許--no-commit --no-ff，不merge至dev。
- 所有S06-B/C/D/E與舊收據approval是歷史受限結果；舊S09「Git未授權」為當時快照，本次只新增上述受控遷移/PR67授權，不授權新真人/GUI/資產/adapter。

### Migration Handoff

交獨立Tester/Reviewer核M06實際整合與兩registry、當期PKCE/全dev樹保護、第二次占號及M05已確認訊息/commit/hooks。M01/M03/M04受限approved、M05已正常commit；M06保持merge pending，不自commit。M08第二訊息依本次真stageddiff另待Human確認，M09第三次占號/push/PRreadback/工具交付未執行。map/source manifest/prep保持受驗M-RF01快照，文件destinationSHA是當時版本，不冒稱本次狀態同步後bytes；23/171/活動source不改。S06 human-check/主假設未執行不變；不真人/GUI/App/資產/Keychain/adapter/merge至dev。
