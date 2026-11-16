# 本地登出與 OAuth 憑證清除：需求

## 目標與成功條件

正式 non-BC `GitHubIntegration` 提供本地登出。單一 caller owner 管理同 credential namespace 的唯一 provider／store，沒有其他 facade／程序並行 writer；這是 Human 已選定的邊界。

- 登出先永久停止舊 provider 供應 token。
- 成功返回後 credential item 不存在；晚到 restore／refresh 不得發布 token 或重新保存。
- 指定簽章環境下 fresh process 無法還原舊連線；必須另有系統實驗證據，不能由單元測試推論。
- 保留 OAuth App configuration 與相鄰 namespace。
- 清除失敗仍保持退休並明確報錯；不得宣稱重啟不還原。只可重試清除，不能復活舊 provider。

## swift-implementation 九欄

| 欄位 | 契約 |
| --- | --- |
| Goal | 舊連線永久退休、精確清除 OAuth credential、防止晚到 refresh 寫回、fresh process 不還原。 |
| Non-Goal | 不收回既有 token 副本或已送出 API request，不保證記憶體安全抹除、跨程序 writer 隔離、斷電 durability。 |
| In-Scope | clearing capability、provider retirement／pending-write ordering、DPK exact delete、相關 client/scope mapping、測試、長期文件、隔離系統實驗。 |
| Out-Of-Scope | 產品 UI、PAT、遠端 revoke、多帳號、跨 provider/facade/process 協調、E001–E015 cleanup、其他 topic 實作。 |
| ReadOnly | 原 topic／其他 topic 歷史證據、E001–E015、非本輪 BC／Presentation／HTTPClient、技能與工具配置、既有 Graphify graph/metadata、既有 PR Lens config。 |
| Written | 四份同 slug artifacts；新增 clearing protocol、sign-out error、focused tests；E016 候選實驗必要 harness／八段 README／安全收據；最多一份 Archify sequence specification／HTML／receipts。PR Lens 僅 repo 外產物。 |
| Deleted | 無 repo 檔案刪除計畫；runtime 只刪 owner 所屬 exact credential item。 |
| Modify | provider、正式 DPK adapter、REST/GraphQL/scope 相關 mapping、對應既有 tests/consumer/isolation checks、OAuth 長期文件及必要入口連結。不是整個 Sources 的寫入授權。 |
| TestCase | execution plan T01–T09，受控交錯與系統證據分列。 |

## 已鎖定決策

- 不重設原 OAuth refresh、401-only recovery、caller cancellation 或 persistence 契約；登出是明確 lifecycle 意圖。
- 新登入等待清除成功後另建 provider；舊 instance 永不復用。
- additive clearing refinement 保留既有 store conformers／provider initializer；unsupported store 不得宣稱清除成功。
- branch：`feat/github-oauth-local-sign-out`，依專案命名 skill 不捏造 owner。

## 依據與證據限制

基線 `2973150b2789d63c10226b57150073ccc793c509`。Planner 唯讀查到 store 只有 load/save、provider 無退休、await 後無 fencing、scope 強持有 provider、正式 Security seam 無 delete。詳見 technical-spec。

文件／原始碼足以選定 concurrency 方向，無須獨立 concurrency feasibility harness。規劃時真 DPK exact delete／fresh-process absence 尚未執行；既有 E015 cleanup 不是本次產品清除證據。2026-11-16 最新 E016 有限實驗成功且獨立 Reviewer approved，受測來源固定 bb6752a；適用範圍與舊停點見下段。

## 連結

- [技術契約](technical-spec.md)
- [執行計畫](../../plan/github-oauth-local-sign-out/github-oauth-local-sign-out.plan.md)
- [狀態帳本](../../plan/github-oauth-local-sign-out/github-oauth-local-sign-out.step.md)

## 2026-11-16：T09 續行邊界

Human 續行原計畫；只補 E016 獨立 signed harness 與一次兩程序序列，不重開已受限 approved 的 src API／競態設計。不新增或更新 cert/profile/AppID，不修改 E010／E015 bundle、profile、items 或歷史。沿既有 E010 AppID 的可用簽章資產，新 E016 output 與每 run UUID namespace；選定資產及程序契約見 technical-spec。剩餘 configuration／sentinel 如實記錄，不額外清理。提示數未知不能填 0。

## 現行驗收狀態（2026-11-16）

T09 本次有限實驗成功／驗證任務完成，詳[系統證據](../../plan/github-oauth-local-sign-out/evidence/e016-live.md)。受測commit為bb6752aa483a68043174723a6b3ff2653abe79ce；first/fresh同一frozenbinary/profile/source、不同exactprocess均退出，Human各完整觀察zero，獨立Reviewer approved。只支持當次同機／GUI使用者／既有signer與有效profile／exactgroup／synthetic／uniquewriter。晚到refresh沿既有受控tests，不外推其他profile／真OAuth／UI／crosswriter／durability。

舊ff672c7 first無法判定與已耗額度保留，新增序列first/fresh也用完；configuration/sentinel留存，不cleanup。原public Human unknown由獨立attestation補充，原bytes不改。Human最終topic接受仍pending；本段是結果同步，不重開scope或改寫歷史run。
