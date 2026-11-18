# R02：E016 → E017 路徑契約獨立審查

日期：2026-11-16。角色：獨立 Plan-Reviewer `/root/planner`，非本輪四文件作者。規劃基準：`98521e342b63eb6391e7d538882e984fcb8d39f2`。

**Verdict：approved。Required fixes：0。** 僅表示本次 bounded relocation 規劃充分，不代表搬移、測試或新 live 已完成。

## 受審內容與事實

已讀本次 requirements、technical-spec、plan、step 的完整變更，依 sdd-workflow-contract／plan-reviewer 檢查 R 階段契約與 gate。直接核對 tracked inventory 為十檔，包含 project Package.resolved；目標 E017 尚不存在。目前 tracked diff 僅四 planning artifacts，沒有提前搬移或改寫既有 evidence。

E017 available 的跨 worktree／remote heads／PR 探索採用呼叫端已交接的 Explorer snapshot；本次不另操作其他 worktree 或 PR72 staged 內容。搬移前仍須依契約核無新占用，衝突時停止，不能自行改號。

## 審查結論

- Goal／Non-Goal／In-Scope／Out-Of-Scope 與 ReadOnly／Written／Deleted／Modify／TestCase 九欄齊備。R 集合明確覆蓋已完成 P 階段的廣泛寫入清單，不重新授權 production Sources、Tests、API、簽章或 namespace 變更。
- 十檔一對一移轉清單明確：八檔 byte-identical；runner 只允許 docstring 編號及 HOST 常數兩字串；README 與現行導覽只作必要路徑／編號／歷史解釋。相同目錄深度的相對 package reference、schemes、設定與 lockfile 保持。
- PR73／topic／正式 store Sources 不變，PR72 保留 E016；其他 worktree、原 private generated metadata、私有 Xcode／signed artifacts／runs／收據／Human 觀察均排除。若 build 必須修改這些狀態或發現額外功能／簽章差異，停止回報。
- 舊 evidence 全 bytes、live export 的原 E016 source keys／hash 及圖 bytes 保持；新增 mapping 明確分開「既有 E006／E007／E015 成果→正式 Sources 採用→source5465 原 E016 實機驗收」與「現行 E017 工具位置」。E017 不追補新版本 live 通過，E007 限制、舊成功／unknown 與 HC04／HC05 pending 保持。
- R03 實作、R04 獨立 Tester、R05 獨立 Reviewer、R06 原 hooks／topic commit／push／既有 Draft PR 回讀的 gates 一致；需要 R02 approved 才搬，後續 required fixes 不得繞過。
- 相稱驗證已明訂 inventory／bytecompare／必要路徑、54 Python 離線案例、兩個全新 scratch unsigned variants 各113 fake-only checks、strict format／lint／diff 及原 hooks。不重跑無受影響的 root／consumer 或 Human DPK，不修改圖，不建立 Graphify graph，不冒稱初始 PR Lens map 涵蓋本輪。

## 邊界

本 Reviewer 僅唯讀查證及新增本審查記錄；未搬檔、改受審文件、執行測試／建置／App／DPK、操作私有資產或執行 Git mutation。HC04／HC05 仍 pending，整個 topic 不自行 complete；本結論不授權 merge／ready／release。
