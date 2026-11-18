# OAuth 啟動／重連：受限執行計畫

Topic `github-oauth-connection-orchestration`；base `ab77391b73291deb1ce3d96cef72f981aeb3104a`；branch `docs/github-oauth-connection-orchestration`；日期 2026-11-17。

相關：[requirements](../../analysis/github-oauth-connection-orchestration/requirements.md)、[technical-spec](../../analysis/github-oauth-connection-orchestration/technical-spec.md)、[step](github-oauth-connection-orchestration.step.md)。

## 九欄契約

| 欄位 | 契約 |
| --- | --- |
| Goal | 交付可行性結論、必要實驗設計、能力盤點、採用方案、現況／流程圖，非產品 orchestration。 |
| Non-Goal | 不宣稱自然到期、profile 更新、分發保證、遠端授權成功或正式已接通。 |
| In-Scope | OAuth 冷啟動與重新授權能力組合、失敗分類、退休／寫入交接、有界證據及地圖。 |
| Out-Of-Scope | PAT 連線、UI、production 實作／public API 改動、新 live、重跑 E014、改歷史證據、blueprint、發布／merge／release。 |
| ReadOnly | 相關正式 source／tests／package、歷史實驗／evidence、長期 docs、現有 graph／overlay、Git metadata、既有 Floorplan 使用者內容。 |
| Written | 僅下列 allowlist；目前 PC01 只建立四份 planning artifacts。 |
| Modify | 後續依角色限本題 allowlist；保留其他採用紀錄／Floorplan 使用者內容，production 修改為零。 |
| Deleted | 預設無；Floorplan 只可淘汰已刪來源的衍生 entries／graph／cache，原始 notes／custom flows 不刪。 |
| TestCase | 下列 TC01–TC10；必須分清閱讀來源、親跑檢查與未執行實驗。 |

## Written／Modify allowlist

僅指定隔離 worktree；不得改原 dev 或其他 worktree。既有不同內容不得未經授權覆寫。

1. `analysis/github-oauth-connection-orchestration/requirements.md`、`technical-spec.md`、`source-audit.md`、`adoption-audit.md`。
2. `plan/github-oauth-connection-orchestration/github-oauth-connection-orchestration.plan.md`、同名 `.step.md`，及 `evidence/` 的 implementation、verification、review、publication 記錄與必要圖面驗證收據／索引。
3. `analysis/github-oauth-connection-orchestration/diagrams/cold-start.sequence.json`、`cold-start.sequence.html`、`reauthorization.lifecycle.json`、`reauthorization.lifecycle.html`，及 Archify 為這兩份圖產生的 frozen snapshot／receipt／visual-check HTML、JSON、PNG sidecars；不得 unrelated assets。
4. `docs/feasibility-adoption.md` 僅新增／更新本 topic 段，保留其他內容；不擴 root README 或既有長期架構檔。
5. 本機 ignored `floorplan/`：必要 `architecture.json`、`descriptions/*.json`、`provenance.md`、`recent-work.json`；生成 `graph.json`、`index.html`、`.cache/**`、工具必要支援檔及目錄內 `.gitignore`。必要備份限 `floorplan/.backup/`，先列具體清單；原始 notes／annotations／custom-flows.json 作保護對象，不擅改。不得手改生成物、untrack、改 repo ignore／Git settings／AGENTS／CLAUDE notes。若不能在此界線內完成，保留真實缺口，不擴權。
6. PR Lens 只在 repo 外 topic 暫存目錄寫本次 actual diff 的 graph／SVG／manifest；不加入 PR 附件／留言，不改 repo `.pr-lens` 或 overlay。
7. 新實驗預設無。若 source-audit 證明需要，先依既有授權查未占用 E 編號，最小新增限該 `experiments/E<未占用編號>/README.md`、`harness.swift` 與合成 fixture／脫敏結果；不改正式來源。需更多範圍回原計畫變更流程，不自行擴張。

## 執行安排

PR01 獨立 approved 前不做 IM01。IM01 先原碼／既有證據判讀並盤點，再選擇性採用方案；不因新實驗未做而擋既有證據可回答的盤點。Source audit 分開事實／推論／缺口／決策影響，記是否需要實驗；採用狀態與實驗四狀態分開。

Floorplan 依 status 選 update 或 create；建立來源清單與使用者內容保護依據，再依 skill 掃描／描述／build 並人工核實 Swift 關係。不虛構未來 orchestration 檔案／edges，不為 coverage 修改來源／安裝工具。只交本機靜態地圖，追蹤描述與 links 分母／缺口及無損比對；不中斷既有其他圖內容。

Archify 產出冷啟動 sequence 與重新授權 lifecycle，圖面明示候選組裝尚未接產品；按 technical-spec 的 showcase／deliver／visual-check 流程保存 evidence。Graphify 只既有 graph 有界查詢，否則 targeted rg。沒有責任邊界改變不另做 canvas。

IM01 完成後交獨立 Tester，再 Reviewer。TE01 僅執行本題文件／圖面／範圍檢查及必要已界定實驗，不默認全 repo build／suite 或任何 live。檢查未執行／skipped 不宣稱 passed。Reviewer 可回 required fix 給 Implementer，規劃 drift 回 Plan-Creator。

DL01 在 RV01 approved 後依 git-commit-convention 檢查 staged 語意與本題範圍，使用 Human 已明示的 direct topic commit 授權執行 commit／push／Draft PR；不增加同一授權重複確認、不 merge。真實 bounded diff 已存在後，可完成本機 PR Lens，將來源 commit IDs 與驗證結果記入 publication，不由工具發布。若 commit hooks 造成不在 allowlist 的變動，先停止並交原流程，不順帶提交。最終 HC01 Human review。

## TestCase／驗收

| ID | 案例與完成條件 |
| --- | --- |
| TC01 | 設定缺漏／credential absent／store failure 具不同證據與語義，不把儲存失敗說成未登入。 |
| TC02 | refresh persist 失敗不交 scope；local ready 不代表遠端身份／權限，取消不假成功。 |
| TC03 | 可重試暫時錯誤沿用原 provider；terminal 不自動重建；重新授權完整保存後才新 provider。 |
| TC04 | signOut 失敗阻止 authenticate；clear 後取消不復活；新保存失敗不 ready；取消後不 rollback。 |
| TC05 | 舊 refresh／已開始 save 的現有受控證據足以回答則引用；有決策性未知才一輪 fake barrier 實驗，按三判準，不以 build 成功代替。 |
| TC06 | Audit 五分類與採用方式分開，各有來源版本／實際接入／行為證據或明確缺口；方案不是已採用。 |
| TC07 | Floorplan 描述／相對 links 按明示 scope 核對，保留 identifiers；Swift parser 限制／未涵蓋清楚，不造假 100%。 |
| TC08 | 正式來源／E014 歸屬與尚未實作 orchestration 標示正確；Floorplan notes／custom flows 前後無損，只有允許的本機 map 變動，無 source／AGENTS／Git config 變動。 |
| TC09 | 兩 Archify 圖 showcase 9 checks 0 errors／warnings、deliver receipt、四 desktop containment／light-dark evidence，實際 Agent 視覺與 Human pending 分開。失敗或 skipped 如實記。 |
| TC10 | 本題文件相對 links／版本／scope／evidence 可追溯；實際 diff 只 allowlist。PR Lens 只 actual diff、固定 runtime 本機驗證／render，無 diff 則 deferred；無 live／發布／正式實作。 |

## Stop condition

終點為證據、必要實驗設計、盤點、採用方案與現況圖交付及 Draft PR；未解依賴不能因文件完成當已解除。需要 production／public contract 改動、真秘密／live、新 boundary decision、工具要求刪使用者內容或改 Git／agent 設定時停止受影響動作並回原流程。Human 最終接受／圖面接受另記，禁止自行宣稱通過。
