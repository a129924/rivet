# R05 — E016→E017 獨立成果審查

日期：2026-11-16。角色：獨立 Reviewer `/root/planner`，非 R03 搬移作者或 R04 Tester。基準 `98521e342b63eb6391e7d538882e984fcb8d39f2`；受審為尚未提交的搬移變更，包含 untracked 新 E017 來源與三份新 evidence。

**Verdict：approved。Required fixes：0。** 限已批准的工具歸屬搬移與離線驗證，不代表 E017 新來源 signed／live 通過。

## 直接審查

已讀四份 R planning artifacts、[R02](e016-e017-planning-review.md)、[R03 mapping](e016-e017-relocation.md)、[R04 Tester](e016-e017-tests.md)，並直接比對 HEAD 的舊 E016 blobs 與新 E017 完整檔案，沒有只看 git diff 的舊路徑刪除。

- 完整十檔在新位置一對一對應，原十個 tracked source paths 均移出，mode 保持。Project／lockfile／兩 schemes／Info／entitlements／Swift host／Python tests 八檔逐 bytes 相同。Runner 逐 bytes 等於原內容只替換 docstring 編號與 HOST 兩字串，沒有新增 old-run resume、namespace、簽章或 runtime policy。
- 新 README 的完整差異只含現行操作路徑／編號、歸屬與固定歷史 links；current PAT doc／experiments index 指 E017，PR72 保留 E016。其他入口不需修改處保持。Topic、PR73 與正式 Sources 不變。
- 直接重算全部34份既有 tracked evidence／圖與 HEAD blobs，一致；production Sources、Tests、root／package manifests 與圖沒有 diff。原 live export 的 E016 keys／hash、原成功／unknown／Human 觀察與 signed artifact 證據未改寫。
- Mapping 清楚分開「E006／E007／E015 既有成果→正式 PAT Sources 採用→source5465 原 E016 實機驗收」與「E017 現行工具位置」。保留原 E007 限制、HC04／HC05 pending；不將 relocation 或 unsigned 成果冒充新 live 驗收，不重新執行 Human DPK。

## 獨立驗證證據判讀

R04 Tester 親跑 E017 Python **54 tests／exit 0**。Reviewer 另直接讀取本次 scratch 的 inventory、links、checks、兩份原始 build logs、fake outputs 及 metadata snapshots：

- Debug／Rebuilt 均 BUILD SUCCEEDED，signing allowed／required 均 NO，沒有 CodeSign step 或 provisioning update flags；Rebuilt 實際 compiler flag 生效。
- 兩 unsigned binary 各113 fake-only checks passed／exit0，stderr 空，binary hashes 不同。這些結果只支持新位置 unsigned／fake 接線。
- Strict format／SwiftLint／diff 的記錄均 exit0／無診斷；45 relative links／28 fixed commit links 與 package reference 檢查成立。
- 原兩處 private .swiftpm 的12項 stat snapshots 前後完全相等；原 signed setup／runs／receipts 未被本輪驗證使用。Reviewer 未進行私有資產操作。

本 Reviewer 沒有重跑測試／build／Run／DPK、修改受審產出或原 evidence，只新增本審查記錄。原 hooks 留 R06 正常執行；Tester 與此 verdict 可由 Implementer 回填 R04／R05 實際狀態，再作 staged semantic review／topic commit／push／既有 Draft PR73 更新與讀回。不另開 PR、不 merge／ready、不自行 complete topic。
