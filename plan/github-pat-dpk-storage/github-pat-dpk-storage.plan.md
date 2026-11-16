# PAT DPK 儲存：受限執行計畫

Topic：`github-pat-dpk-storage`。基準 `origin/dev@5713025e3312c0fbc9a7b02a222db0b91d6e1b58`；唯一工作分支 `feat/github-pat-dpk-storage`。只在本 topic feature worktree 工作，不修改 dev worktree。需求與 AC 見 [requirements](../../analysis/github-pat-dpk-storage/requirements.md)，唯一技術與路徑清單見 [technical-spec](../../analysis/github-pat-dpk-storage/technical-spec.md)，狀態見 [step](github-pat-dpk-storage.step.md)。

## Goal／Non-Goal／In-Scope／Out-Of-Scope

Goal 是正式 PAT DPK 的保存、讀回、整筆替換與獨立補驗。Non-Goal 是登入產品化或遠端有效性證明。In-Scope 為 PAT 專用 async actor、有限錯誤／隔離／協調／遮蔽、受控測試、public consumer、驗收 host（原 P 階段 E016，本次 R 階段移至 E017）、採用與清理證據。Out-Of-Scope 沿用 requirements 的登入 runtime／UI／session／clients／migration／產品 delete／同步與分發等排除項，不為實作便利擴張。

## ReadOnly／Written／Deleted／Modify／TestCase

四個檔案變更欄位及 TestCase 的精確清單只由 technical-spec 維護，本計畫以引用構成契約：ReadOnly 只能讀；Written 只新增；Modify 只作列明差異；原 P 階段 Deleted 為無；本次 R 階段僅舊工具路徑成對移轉，依 technical-spec 的 R 集合限制。TC01–TC04 是本輪必要離線驗證；TC05 與 AC2／3／9／10 的真人部分原先 pending；Human 續行後已在固定 source `5465d3c`／run `39c22b57` 完成並經獨立 P07 approved，圖與最終 Human 接受仍 pending。新增 store 所需 StaticIsolationTests 白名單變更已列 Modify，不修改 root package graph 或 OAuth 來源。

## 派遣與 gate

| Step | Owner | 工作與完成條件 | 下一步 |
| --- | --- | --- | --- |
| P01 | Plan-Creator | 四份正式 artifacts 一致落檔，保留 Human 決策、精確範圍與 live defer。 | 獨立 P02 |
| P02 | Plan-Reviewer | 檢查四文件、契約、scope、路徑與 readiness；明示 approved 才可實作。 | approved→P03；needs-rework→Plan-Creator |
| P03 | Implementer | 新 PAT actor／有限錯誤／internal fake seam、測試、consumer、E016 與使用說明完成；不呼真 Keychain。交付實際變更與待驗範圍。 | P04 |
| P04 | Tester | 親跑 TC01–04、受影響 OAuth／static 回歸、consumer、E016 runner 離線測試與 unsigned host compile、必要 format／lint／diff 檢查。記來源、命令、結果與 skip。 | P05 |
| P05 | Reviewer | 獨立檢查 bounded diff、公開／private 契約、隔離、證據與 live 準備，required fixes 清零。 | approved→P08／P09；needs-rework→Implementer |
| P06 | Human／Tester | Human 已逐段就緒並完成 TC05；六 runtime accepted／Human 各全程 0，setup／rebuild 另各 0，指定來源與 run 見帳本。 | Tester completed；交獨立 P07 |
| P07 | Reviewer | 已獨立判讀指定來源的 PAT 真 DPK／UX／清理證據並明示 approved；舊 unknown 不升格。 | P08 metadata 同步；Human 接受仍待確認 |
| P08 | Implementer → Tester → Reviewer | 回寫長期 PAT 契約、導覽、採用紀錄、Archify sequence 與工具結果，明列真人結果的來源與剩餘 Human pending；Tester 驗圖，Reviewer 獨立核對。離線文件可在 P06 前交付，未來補 live 結果仍需獨立 review。 | 離線 approved 可交 P09；最終 Human 接受仍 pending |
| P09 | Implementer | Human 本次已授權 topic commit／push／Draft PR。待 P02／P04／P05 與 P08 離線審查完成，檢查 staged diff、提出 semantic message 並依已明示直接 commit 授權提交；push topic branch、建立指向 dev 的 Draft PR、讀回核對。 | 交付可完成；整個 topic 不標 complete |

Reviewer／Tester 不審查自己的實作；需要修正只回對應產出角色。step status、checkbox 或 tracker 不替代獨立 approved。新 required fix 需 bounded 回修及對應補驗，不無條件重跑已通過檢查。

## 工具安排

### Graphify

目前無可用既存 `graphify-out/graph.json`，採 bounded source-search fallback。若後續有可用 graph，只做最小 query／path／explain，核對 revision 與來源。每次 CLI（包括 help／version）設 `GRAPHIFY_NO_AUTO_REFRESH=1`。不預設 extract／build、semantic/provider、刷新、安裝、修改 hooks／config 或寫 graph。Runtime 缺失／不相容／失敗記具體錯誤並回 source。

### Archify

執行階段在指定 diagram 目錄產一份 PAT 保存／還原 sequence；先讀 matching sequence schema、common schema、example，下一作者動作寫 candidate，不先研究 renderer internals。`meta.quality_profile=showcase`；繁中作者內容，省略不支援的 locale，固定 Viewer UI 與 HTML lang 使用 English fallback。每次 candidate 修改後及交付前 validate，必須完整 9 artifact checks、0 composition errors、0 warnings，最後以 deliver 產 HTML 與 receipt；不手改交付 HTML，保留 JSON、snapshot、hash／byte receipts。

對 delivered HTML 執行帶 repo-root 的 visual-check：1440×900、1600×1000、1920×1080、2048×1320 containment，保留最小／最大 light／dark 截圖、contact sheet 與 sidecars。Tester 實際檢視，不把 visualReview=pending 或 screenshots 當自動人工通過；Human 視覺接受另列 pending。非零、skipped 與未執行如實記錄。兩輪無改善依 skill 停止診斷，不擅自發布或啟動 preview。

### PR Lens

只在有真實 bounded diff 後讀實際 base／head 與必要 source，記真 commit IDs，依 references 建本機 change map，含 unchanged direct neighbors。固定 CLI 0.11.0 在 repository 外 scratch validate／render；目前無 `.github/pr-lens.yml`，使用 `--no-config`，若真 PR 階段已有 config 則只讀並使用。保留圖與 render manifest 的來源映射，不模擬未來 diff、不把 change map 視為 correctness verdict。Runtime 缺失回報具體錯誤，不 install／upgrade／npx；不在 repo 建 `.pr-lens`，不執行 analyze／provider／upload／publish／server。Draft PR 建立由 P09 的明示授權另行執行，不是 PR Lens 能力。

## 驗收序列與停止條件

Live 固定序列為 save A→writer 結束→fresh A→replace B→fresh B→真正同身分 clean/build→rebuilt fresh B→exact owned cleanup→正式 load=nil。Human 提示 save A ≤1，其餘四 runtime 各 0，build／sign 另計。失敗／unknown 不啟動相依段；marker／原收據保留，不換 run 或 namespace 掩蓋。

初次 P06 defer 讓離線成果先交付；後續 Human 續行後已完成本次 P06／P07，見帳本與固定來源證據。新的 live 執行仍需當次有效 profile／主機與 Human ready，不能沿用本輪放行。scope／path／contract 衝突、缺 required gate、runtime／圖驗證失敗或 required fix 未解時，依明示 verdict 回修或停止；不得把缺證據標成已通過。E007 profile renewal 的歷史與 OAuth 舊證據保持。

## 交付與 topic 完成分離

初次離線成果已按 topic commit／push 並開 Draft PR；本次追加受測 code freeze `5465d3c7308e74bc2b3b51878acd190d4f2babda` 的 live 證據及 metadata 回寫，後續文件 commit 不冒充 native 受測來源。P06 完成、P07 approved，圖的 Human 視覺與 topic 最終 Human review 仍 pending，整題不標 complete；merge、release、tag 不在本次授權。後續 metadata 先交獨立 bounded doc review，再提交／推送，不重跑已通過 runtime 或改寫失敗歷史。

## 本次 bounded relocation：E016 → E017

本次基準 `98521e342b63eb6391e7d538882e984fcb8d39f2`，topic／feature branch／Draft PR #73 不變；PR #72 保留 E016。Scope、ReadOnly／Written／Deleted／Modify／TestCase 以 technical-spec 的 R 節為準。原 P03／P04／TC05 的 E016 是真實歷史，不改名成 E017 已驗收。

| Step | Owner | 完成條件／gate |
| --- | --- | --- |
| R01 | Plan-Creator | 四 planning artifacts 同步現行 E017 path、十檔 inventory、唯讀證據與驗證邊界；只編寫，不搬移。 |
| R02 | Plan-Reviewer | 獨立審查 R 契約明示 approved 才能 move；needs-rework 只回 Plan-Creator。 |
| R03 | Implementer | 在既有 feature worktree 一對一搬十檔，只允許 runner 兩字串／README及 current docs 最小路徑文字；新增 relocation mapping，既有證據及圖 bytes 保持。 |
| R04 | Tester | 親跑 TC-R01–05 中搬後 paths／byte inventory、Python54、新 scratch 兩 unsigned variants 各113 fake checks、format／lint／diff；不 signed build／live Run／DPK／Human 重驗。 |
| R05 | Reviewer | 獨立核必要差異、P 歷史／新工具兩鏈、既有 evidence 全 bytes 與私有狀態未碰；明示 approved、required fixes 清零。 |
| R06 | Implementer | staged semantic review 後按已明示 topic commit／push 授權提交，原 hooks不skip；更新既有 Draft PR #73 的 E017 歸屬與限制並回讀，未 merge／ready。 |

E017 available 的 Explorer snapshot涵蓋四 worktrees、五 remote heads、未合併 PR68／72／73 與最近五個 closed PR；搬移前只確認無新占用，不能碰 PR72 staged 內容。搬後驗證不重跑原真人序列，舊 successful／unknown 與 Human 觀察不被改判，原 live export E016 source map／hash 不重算。PR Lens 原初始 diff map 不冒稱涵蓋本次 relocation；不建 Graphify graph、不改圖。

新 evidence `e016-e017-relocation.md` 保存完整新舊 path／編號 mapping、fixed commit links 與兩鏈：E006／E007／E015 既有成果→正式 Sources 採用→原 E016 路徑實機驗收；E017 為現行驗收工具歸屬。其餘三份新 evidence 分別記 R02／R04／R05 verdict 或實際結果，不改既有 evidence。若涉及 byte-identical 項目變更、行為／簽章 contract、私有 metadata 或 package reference 寫入，停止回報，不為移動順便修復。HC04／HC05 仍 pending，整 topic 不自行 complete。

R 階段現況（2026-11-16）：R04 [獨立測試](../../plan/github-pat-dpk-storage/evidence/e016-e017-tests.md)完成、R05 [獨立審查](../../plan/github-pat-dpk-storage/evidence/e016-e017-review.md) approved／required fixes 0；R06 publication 進行中，實際結果依帳本與 Git／Draft PR #73 記錄，不預填推送成功。HC04／HC05 仍 pending，topic 不標 complete。
