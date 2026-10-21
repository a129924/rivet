# GitHub Account Login 受限可行性驗證計畫

日期：2026-10-21；Topic：`github-account-login-feasibility`。
[需求](../../analysis/github-account-login-feasibility/requirements.md)／[固定來源與限制](../../analysis/github-account-login-feasibility/technical-spec.md)／[狀態帳本](github-account-login-feasibility.step.md)。

## 1. 結論與執行狀態

技術路線可行；開發端提供 App 設定，使用者完成 GitHub 授權後，由程式 exchange token 並確認帳號，不自行註冊 App、輸入憑證或貼 token。OAuth 仍需 App 憑證；完整零配置產品 UX 未交付、本輪無真人重驗，公開發行 custody 未驗證。

保留原 A 五節結構與歷史限制。產品 B（`apps/Rivet`、launcher、composition、UI、產品測試、Human host 驗收及 S01–S06）已撤回，不恢復。本輪使用者明示保存文件並交付 Draft PR，因此 Written 由對話階段的無更新為五份新文件；新增固定來源僅提高追溯性，不代表真人重驗或產品交付。

本次為文件交付，不新增技術實驗；base 為 `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`。既有 source／歷史 A07 證據使用 technical-spec 的外部固定 permalink，不虛構本分支已有那些檔案。

## 2. 九欄契約與檔案影響

| 欄位 | 本輪契約 |
| --- | --- |
| Goal | 保存免除使用者配置的技術可行性、既有實現及證據限制，交付 Draft PR。 |
| Non-Goal | 不交付產品、不宣稱 readiness、不核准發行、不 merge。 |
| In-Scope | 官方／固定原碼／歷史證據分類，四份 planning 文件及一份長期結論，文件檢核與獨立審查。 |
| Out-Of-Scope | 已撤回 B、Swift／App／UI／新測試／新實驗／架構圖、production custody、persistence、多帳號、新協定、負向 PKCE 重跑及其他 topic／BC 修改。 |
| ReadOnly | README、既有 docs、Sources、tests、apps、experiments、其他 topic、可用 graph 及固定外部來源。 |
| Written | 下列五份新文件；PR Lens 產物限外部暫存，不加入 repo。 |
| Modify | 無既有檔案修改；新文件可依審查修訂。無產品 API／interface 變更。 |
| Deleted | 無。 |
| TestCase | 第四節文件驗證，不新增 source tests、驗證腳本或實驗目錄。 |

唯一 repo manifest：

1. `analysis/github-account-login-feasibility/requirements.md`
2. `analysis/github-account-login-feasibility/technical-spec.md`
3. `plan/github-account-login-feasibility/github-account-login-feasibility.plan.md`
4. `plan/github-account-login-feasibility/github-account-login-feasibility.step.md`
5. `docs/github-account-login-feasibility.md`（獨立 planning review 後由 Implementer 建立，回鏈 technical-spec）

分支 `docs/github-account-login-feasibility`，type=`docs`、work-item=`github-account-login-feasibility`、無 owner；使用本次新文件 worktree，不沿用 PR #61 branch。已獲使用者明示 topic commit／push／Draft PR 授權；執行者仍須檢查 staged 語意範圍及訊息，不由 Plan-Creator 執行。

`swift-implementation` N/A；未來若真需最小實驗，開始前預定九欄、完成後按 actual diff／證據回填，不視為本輪授權。

## 3. 工具適用性

- Graphify 0.9.73：inventory 無既有 graph，使用定向 `rg` fallback；不建圖、不安裝。未來 CLI 須 `GRAPHIFY_NO_AUTO_REFRESH=1`，重要關係覆核 source。
- Archify 2.16：文字足夠，不產圖。未來若有具體未知才考慮本問題 sequence，遵守 showcase 九 checks、零 error／warning、validate／deliver／visual-check、繁中作者內容、英文 viewer fallback、本機不發布；圖不證明 OAuth 正確性。
- PR Lens 0.11.0：final topic commit 後，用真實 base `16606b89b8e3e6b61523c23aa0be9653c1ea7b44` 至真實 head commit 的 `--find-renames` 五文件 diff，外部暫存 validate／render／manifest。保留 unchanged README 與 GitHub 來源依據的 context／file refs；外部來源以 pinned URL 標示，不假裝本 branch 有 source。記錄真實 SHAs／changed files，不採用舊 PR #61 diff、不造 commit 或 receipt。inventory 無 config，以 no-config 執行；若出現 config 只讀遵守，不改配置、不自動安裝或上傳。工具不可用時回報原因與 fallback，不冒稱成功；外部產物不增加 tracked files。

PR 建立由使用者獨立授權，非 PR Lens 授權。工具圖與 repo 文件驗證均不是新 OAuth 測試。

## 4. TestCase 與驗收

| ID | 文件檢核與通過條件 |
| --- | --- |
| TC01 | 官方憑證責任、code exchange 與有效帳號條件有來源；開發端配置標為推論。 |
| TC02 | 原碼／歷史紀錄均 pin 至真實版本；A07 執行 SHA 與保存紀錄 SHA 分開，零配置 UX 未冒稱已驗證。 |
| TC03 | P／Q indeterminate、版本限制、撤回 B 與 production 排除均保留；不依賴 PR #61 gate。 |
| TC04 | 相對文件連結／外部 pin／行號可追溯；沒有本 branch 缺檔的偽本機連結。 |
| TC05 | 實際變更恰為五新文件，無秘密或使用者本機絕對路徑；source／tests／apps／experiments／其他 topic 未變更。 |
| TC06 | 長期結論落入 docs，無新實驗；staged topic 語意一致，真實 commit／push／Draft PR 證據可追溯，停於 Human review、不 merge。 |

Tester 驗文件、來源與 scope，不跑產品測試或真人 OAuth；結果交獨立 Reviewer。尚未執行的步驟不得填通過，PR URL 產生前不得填寫。

## 5. 停止與交接

順序為獨立 Plan-Reviewer → Implementer 建長期文件 → Tester → 獨立 Reviewer → topic commit／push／Draft PR → Human。帳本逐步記錄實際證據，不以 status 代替 approval；Human boundary 僅在前置交付完成後生效，不提前阻斷文件工作。

若出現範圍外改動需求、未解來源衝突或工具權限問題，記錄具體限制交回，不擴成產品實作。每項新增技術工作須說明排除哪個未知、既有證據為何不足；本輪未知已由文件／來源解決，後續是明示保存交付而非新實驗。完成 Draft PR 後停於 Human review，不 merge。

## 後續 Human 正向重驗增補（2026-10-21）

本節記錄文件交付後的使用者追加授權，不追溯改寫原文件階段 scope。使用既有驗證 App，事前限一次新授權、以有效帳號與 API 成功為判準，不新增程式、實驗或產品入口；不動用反向 PKCE 預算，也不增加重試或再次查詢。Human 已確認本輪完成新授權，agent 已觀察四項結果布林，詳 technical-spec L01。

本次九欄交接：Goal 為保存本輪重驗；Non-Goal 為零配置產品與 PKCE enforcement 證明；In-Scope 為 Human 確認與安全 UI 結果紀錄；Out-Of-Scope 為 source／tests／App／新實驗／其他 topic；ReadOnly 為既有工具與 binary；Written 無新檔；Modify 為本 topic 既有五份文件追加本次紀錄；Deleted 無；TestCase 為結果來源、binary 指紋、版本界線、文檔連結及敏感資訊檢核。完整 PR 仍待 Human review，不 merge。
