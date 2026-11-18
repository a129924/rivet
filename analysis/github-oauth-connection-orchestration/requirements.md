# OAuth 啟動／重連：需求與驗證範圍

- Topic：`github-oauth-connection-orchestration`
- 基準：`ab77391b73291deb1ce3d96cef72f981aeb3104a`
- Branch：`docs/github-oauth-connection-orchestration`
- 日期：2026-11-17
- 契約：[technical-spec](technical-spec.md)、[plan](../../plan/github-oauth-connection-orchestration/github-oauth-connection-orchestration.plan.md)、[step](../../plan/github-oauth-connection-orchestration/github-oauth-connection-orchestration.step.md)

## Goal

釐清既有 OAuth configuration、store、provider、scope、登入服務與本地 signOut 能否安全組合冷啟動及重新授權，交付有界可行性結論、必要實驗設計、能力採用盤點、選擇性採用方案與現況圖。本 topic 不交付正式產品 orchestration。

## In-Scope

- 以文件與原碼優先的 feasibility-validation 核對現有能力與限制；必要時才設計最小實驗。
- 區分設定缺漏、credential absent、需要登入、restore／refresh／persist 失敗與本地 ready；不變更初次登入 Outcome。
- 可重試暫時錯誤沿用原 provider；重新授權才永久退休舊 provider，新 credential 完整保存後才建立新 provider／scope。
- 按能力做 feasibility-adoption-audit，並以 feasibility-adoption 提出必要能力、依賴、方式與缺口；不將成功實驗整包搬入。
- 繁中 Floorplan 現況導覽；Archify 冷啟動 sequence 與重新授權 lifecycle；工具分工與證據可追溯。

## Out-Of-Scope

PAT 連線、產品 UI、正式 orchestration 實作、public API／既有登入 Outcome 變更、跨程序鎖定、新 live OAuth／DPK、重跑 E014、修改正式 sources／tests／package、改寫歷史實驗、blueprint、自動修復、外部發布或 merge／release。其他既有 worktree 不得修改。

## Non-Goal

本輪不證明自然到期、profile 更新、certificate rotation、公開分發或所有環境保證；不把 scope ready 當遠端身份／權限保證，不把現況地圖當正式架構決策或安全審查。

## 已鎖定行為

1. 本題只 OAuth；不選 active-mode、不接 PAT scope。
2. 儲存失敗區分限啟動／重連的 restore／prepare／refresh persist；初次登入仍使用既有有限 Outcome。
3. 重新授權前先正式 signOut 並等待寫入收尾及清除；失敗不得開始 authenticate。清除後新登入取消／失敗不復活舊 provider。
4. authenticate 完整保存成功後才新 provider，再 prepare scope；保存失敗不 ready。已開始保存後取消不 rollback，沿既有契約保留已保存值。
5. persist 等 terminal 狀態不以自動重建 provider 掩蓋；只有既定可重試錯誤才 retry 原 provider。
6. 圖面區分既有正式能力、E014 獨立驗證工具、尚未接入的正式 orchestration；未接通不得畫成既有連線。

## 成功條件

每項需求有來源版本、位置、觀察事實、推論、缺口與決策影響；可行性結論不超過證據。Audit 五分類有依據，採用方案列選定／排除、必要依賴、方式、接入候選與待驗證項。對話、文件、實驗狀態及實際採用完成分開。

Floorplan 保留 identifier／相對路徑與使用者原始內容，揭露解析及覆蓋限制；Archify 通過 skill 指定驗證並保留真實視覺狀態。真實 diff 出現後才用 PR Lens。最終交付為 topic commit、push、Draft PR，停 Human review；不代表正式產品接入已完成。

## 授權與 Human boundary

Human 已核准完整計畫並明示建立隔離 worktree、實現本 topic、direct topic commit、push、Draft PR，再 Human review。此授權只涵蓋已鎖定文件／證據／圖面交付，不擴成 production 實作。Commit 前仍依 git-commit-convention 檢查 staged 語意；不增加已授權動作的重複確認。未解重大 scope／contract 衝突交回原流程。
