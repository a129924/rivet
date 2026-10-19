# DPK 可行性執行帳本

- Topic：`github-oauth-dpk-local-feasibility`
- Phase：2026-10-19 受限實驗已發佈／P3 文件狀態同步／Human review
- Current step：S09
- Current status：human-check
- Upstream verdict：approved（本次文件獨立 Reviewer approved，required_fixes=[]，P3 已解決；原受限實驗 S08 approved 不變，不代表新實驗或產品核准）
- Branch：`chore/github-oauth-dpk-local-feasibility`
- 實驗：E006；目前 round `b832a57f-cced-4361-ba38-ac370d265e03`
- 最後更新：2026-10-19，Implementer（僅記錄本次文件獨立 Reviewer approved、required_fixes=[]，P3 已解決）

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據 |
|---|---|---|---|---|
| S01 | completed | Plan-Creator | 四份 planning artifacts 與候選／範圍／授權邊界 | 四檔已落地；編寫完成不替代 approval。 |
| S02 | completed | Plan-Reviewer | 獨立審查正式四檔 | 歷史正式 approval，required_fixes=[]；本輪未改候選／判準。 |
| S03 | completed | Implementer | feature-only 最小 App／guards／tests／圖 | unsigned／pure 準備及 bounded fixes 完成；不改 production／E005／docs。 |
| S04 | completed | Tester | 獨立驗證準備實作 | 27 pure tests／unsigned main hash 差異／無 debug dylib／guards 已核對，最後 device-selector receipt SHA `4d883f0550c85ae155b99c4bf1e4640f5a8be62177aa35f5a9cc62dc84ffffee`；本輪18 source SHA及toolchain不變，沿用不重跑。 |
| S05 | completed | Reviewer | 獨立審查準備／bounded fixes | 歷史 preparation Reviewer approved、required_fixes=[]；不冒充本輪 S08。 |
| S06 | completed | Human | 本輪資產授權／操作、完整前提、逐段 ready | 2026-10-19 新輪明確授權；Human 私有 Xcode 操作及免費來源聲明；兩 App／GUI／profile／ProvisioningUDID／35min／cross-DR 成立。gate1–4 actual ready先於下段，五段全程觀察；精確私有清理另有Human直接確認。 |
| S07 | completed | Tester | 單輪 phase0–4、完整資料／Human觀察、清理及分類 | `run-20261019T021023Z-b832a57f/tester-live-validation.json` SHA `f07c4fff31568e533b2d2ed503c3990b62203662837bb32844a94bec372bb123`，approved／requiredFixes=[]；資料成功、受限UX成功、驗證任務完成。 |
| S08 | completed | Reviewer | 獨立核對本輪收據鏈／結論／清理／文件一致性 | 獨立 Reviewer 正式 approved，required_fixes=[]；已核61份證據／18 source SHA／歷史SHA／五段Human0／gates／資料機制／UX／清理一致性。僅接受受限實驗證據與紀錄，不核准正式採用；Git發布另由Human明確授權。 |
| S09 | human-check | Human | review／後續正式規劃與發布決策 | 原交付兩筆commit／push／Draft PR59已依Human授權完成；本次文件Reviewer approved、required_fixes=[]，P3已解決；本修正訊息確認與發佈完成狀態依對話／PR實際紀錄。新輪／merge／正式adapter採用未授權。 |

## Locked decisions

唯一候選為免費 Personal Team／Apple Development／有效 development profile／真 macOS App／DPK；單一 App private group，不手填 Team ID、不 fallback。GUI user session，兩版 main hash不同、同certificate／profile bytes／entitlements／DR且雙向requirements成立。首次≤1、fresh0、rebuilt0；Human-only逐段stop／freshready，machine與Human sidecar SHA分離；失敗finally清理不等ready。原t0+25min停止新測量、+30min截止，+35min有效餘裕不延時窗。root production／E005／docs與provider ownership不改。

## Current round evidence

- Namespace：`b832a57f-cced-4361-ba38-ac370d265e03`；UTC t0 `2026-10-19T02:10:41.483264+00:00`／cutoff `02:35:41.483264`／deadline `02:40:41.483264`，台灣 `10:10:41／10:35:41／10:40:41`，未重設。
- P0台灣10:10:41–10:21:48完整前提；P1 10:24:05 save-read A、P2 10:24:57同binary fresh read、P3 10:25:43 rebuilt read，三段六欄全true；P4 10:26:56 delete-read-absent=true。五段Human全程promptCount皆0，gates1–4各先完整前段觀察／新ready才啟動下段。
- First main SHA `b2d0ec7706b2682c70249867eba42fc587428d2ee139c6d711ab6f1d4a784840`；rebuilt SHA `b9320e1eac2b6d3f08faa538d781101ad6e15f876d288f18226f3f3a437182d8`。四組launch／exit與frozen open -W -n／owned-exit guard支持fresh process；rawPID未保留，不宣稱PID值相異。
- DPK資料已精確刪除並確認不存在；owned私有setup／runroot／selected App copies／raw proof／唯一proven DD／activepointer全清，cleanup end UTC `02:28:04.712768`早於原deadline。Appleassets Human-owned retained、不revoke；globalRecentpreferences未改，捷徑有無未查，不聲稱本輪Recent殘留。
- Machine promptCount=null保持；driver `round.machine.json` SHA `e1034d0024ccb9e7fec3823d4b7be4b42b1510cdd552ab0ed7b6bcab35330c8f`當時Human4未回的UXunknown未覆寫，新增final validation才據完整sidecars判成功。Human4 SHA `24add9e06881ce90459c69cf9cae0da73427dc80cf3826359b60545f2585650a`。
- Final index：`experiments/E006/evidence/run-20261019T021023Z-b832a57f/final.index.json` SHA `8e054090b7ac05c0a31e4a5775319a48337dfb2bbbbe1737c33d2bfe3e1d1141`，60 indexed immutable files＋index共61。來源／所有收據freeze，沒有新host測量或tests。

## Historical rounds

- E005 legacy：完整資料成功，但首次／fresh／重建0／0／1，該候選UX失敗；本輪DPK成功不覆寫legacy結論，也不證明已解legacy ACL根因。
- E006 2026-10-16：原13:53:52arm、14:14:38controlledstop；DPK／UX未執行、主假設unknown。Human全段partial／promptCount=null，partial0與CUA UIclosed不外推零提示。首版曾凍結與readonly檢查，Human第二版Build回報不等同兩版比較；舊Apps清理後已刪。
- 舊setup-stop archive全留：stage1／2 owned檔案最終清理完成，blocked→Human直接confirm→同scope retry preserved；end UTC06:24:21.339999對原deadline06:23:52.294158晚29.045841秒，timebox未滿足，不稱如期完成。舊cleanup SHA `52d50e6d21612bf6df32c1966f3d6ad3af933868b63019c38fe1664bd874cb72`／finalindex SHA `6abec4907a3823230e2ae4de2335c115baea44858fed7a2acbfe2c72633ce40d`不變。該輪Appleassets及Recent記錄不外推本輪。

## Blockers and limitations

- 原受限實驗 S07 Tester／S08獨立Reviewer皆approved，required_fixes=[]；S09仍human-check。後續Human已另行授權並完成原交付Git發布；本次文件獨立Reviewer approved、required_fixes=[]，P3已解決，不重開實驗結論或adapter決策。
- 真拒絕／損毀／技術失敗邊界只有pure fixtures；profile expiry／renewal／reprovision／certificate rotation／長期恢復／其他OS／公開分發／realOAuth／refresh未驗證。B替換不屬本輪。
- 支持本次有效profile／同cert／group／DR／固定App路徑的受限本機UX；成功只支持後續正式規劃，不核准adapter／產品整合。
- 準備期工具收據的「無獲授權head／PR Lens deferred」為發佈前快照；原交付PR Lens已完成的實際base／head範圍見下段。Archify準備證據保留，Graphify無可用圖而採限定來源核對；圖工具不當UX證據、產物不對外發布。

## Publication status

- Human已明確授權並確認原交付兩筆訊息：`9ce209429d2b1fe8e9b98a3d24a2de311710eda1`（工具）與 `ebbb71f9237ac883914ebfc32d4838e6ba2df517`（契約／證據）均已push；[Draft PR59](https://github.com/a129924/rivet/pull/59) 為OPEN／Draft，base dev；本次P3開始前head仍為`ebbb71f`。
- PR Lens 0.11.0已在外部scratch以原交付base `05b039b39f4f7cf136b10ddcba654a07b0a448d8`／head `ebbb71f9237ac883914ebfc32d4838e6ba2df517` 完成本機validate／render與全圖視覺核對；此事件不涵蓋後續文件修正head。Graphify 0.9.73無可用圖，沿用限定來源核對，不extract／build／upload。
- 原交付工具commit六hooks全passed；證據commit的94檔EOF副本檢查通過，8份immutable machine JSON保留原bytes，經獨立Reviewer核准僅該次略過EOF formatter、其餘五hooks全passed。本次兩份Markdown不沿用該例外。

## Human Check

本輪新授權與Human-only逐段ready均已完成，現已停止。Apple開發資產由Human管理保留，個別new/reuse細項未inventory、不刪他人資產。S08已完成，目前停S09Human review；原交付Git commit-push-DraftPR已獲Human授權並完成。Human亦已授權P3文件修正及審查後commit／push更新PR59；本修正訊息確認與發佈完成狀態依對話及PR實際紀錄。新實驗／merge／正式adapter實作與採用未授權。

## Handoff

原受限實驗獨立 Reviewer 已正式 approved、required_fixes=[]，S08 completed；S09仍human-check。原交付已發佈Draft PR59，Human已授權P3文件修正與後續commit／push；僅支持受限實驗證據與紀錄，不核准正式adapter實作／採用、merge或新真人輪。

原實驗閉環曾在requirements／technical-spec／plan開頭標記2026-10-16原始準備契約；這些檔案本次不改。本次P3僅更新README／step的發佈時序；獨立Reviewer已approved、required_fixes=[]，P3已解決。Human已授權本修正commit／push；訊息確認與發佈完成狀態依對話及PR實際紀錄。原候選、判準、source、圖、immutable收據與indices不變；不重跑test／live／host。10月16日unknown／partial／late29.045841、E005legacyUX失敗及machine原null／driver舊unknown皆保留。
