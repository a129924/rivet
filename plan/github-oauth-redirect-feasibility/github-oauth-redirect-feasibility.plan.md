# E001：GitHub OAuth 重導向可行性驗證執行契約

## Summary

在 feature worktree 交付 `experiments/E001/` 獨立 Swift package、Markdown 結果紀錄與受限圖證據。真實授權成功條件為非空 code 與相符 state；未執行時保持未驗證。經正式 planning review、獨立驗證與成果 review 後，依已明示授權 commit by topic、non-force push、Draft PR 至 dev，停止於 human review。

分支 `chore/github-oauth-redirect-feasibility`；從 dev 基線 `622abf662d73afd7e887c7684630663fcaae4a6f` 建立的指定 feature worktree。所有變更只發生於該 worktree；不得在 dev worktree 建立或修改任何檔案。

## swift-implementation Contract

| 欄位 | 契約 |
| --- | --- |
| Goal | 交付可執行且可重現的 OAuth redirect/code/state 驗證工具；真實授權成功後留下遮蔽結果證據。 |
| Non-Goal | 不宣稱 token、refresh、產品登入或產品 callback architecture 已驗證；不鎖定未授權架構。 |
| In-Scope | E001 獨立 package、runner、必要測試、README、四份正式 artifacts、一張 Archify sequence、受限 Graphify／PR Lens 證據。 |
| Out-Of-Scope | token exchange、Client Secret、產品整合、root package／產品 API／docs 修改、Graphify 建圖、工具安裝、工具上傳／發布、auto-merge。 |
| ReadOnly | 既有產品 Sources/Tests、root Package.swift、docs/、歷史 topics、.vscode/、skills、既有 configs；Git 狀態僅依已授權交付操作變更。 |
| Written | 本 topic 四份 artifacts；experiments/E001/ 的 Package.swift、Sources/、Tests/、README.md、diagrams/ 下規格／HTML／receipts／captures；PR Lens 僅外部暫存產物。 |
| Deleted | 無；不得刪除、搬移或更名既有 tracked file。 |
| Modify | 本 topic 與 E001 新建檔案的必要修正、實測結果與 ledger 更新；不得修改 ReadOnly。 |
| TestCase | 下節的 callback、CLI、listener／HTTP、清理、敏感值、圖驗收、provenance 與 path allowlist。 |

## Implementation Sequence

1. Plan-Creator 建立四份 artifacts，交獨立 Plan-Reviewer 明示 verdict；僅 approved 可進實作。
2. Implementer 在 feature worktree 實作獨立 package、CLI 與可注入測試邊界，README 實測先標未執行。
3. Implementer 完成一張 sequence 與 Archify validate/deliver/visual-check 證據；不新增架構邊界圖，不發布 artifact.cafe。
4. Tester 執行獨立 package build/test 與 bounded verification，記錄自動化結果；沒有 Client ID 時真實驗證維持 deferred。
5. 獨立 Reviewer 檢查 correctness、scope、文件、敏感值、視覺證據，給出 verdict。Graphify 無 graph 時以 targeted reads fallback。
6. 無重大 blocker 且 Reviewer approved 後，授權 Implementer 依 git-commit-convention 檢查 staged diff、單一 topic commit；不重複要求已授權的例行 commit 確認。
7. 有實際 base/head commits 後獨立 Reviewer 製作 external PR Lens local map、validate/render；不可用或缺 provenance 如實記錄，必要時直接 diff review。
8. 授權 Implementer non-force push、開 Draft PR（base dev），PR 清楚說明核心測試與真實實測狀態；未實測時標為未驗證，實測後依證據更新；停止於 human review。不 merge、release 或處理未授權 review comments。

## TestCase

- 正確 callback：code 非空且 state 匹配；code 缺少／空、state 缺少／不符、重複參數、GitHub error 均失敗。
- CLI 必填參數、正整數 timeout（預設 180 秒）與 unknown option；safe output 與結束碼符合 technical spec。
- 僅 IPv4 loopback、動態 port、listener 啟動上限 10 秒、ready 後開瀏覽器；listener/browser failure 可觀察。Security 32-byte 亂數編碼為 64 字元 hexadecimal state。
- 逾時／SIGINT 清理與單次終結；HTTP header 8 KiB／讀取 5 秒上限與分段讀取代表案例不掛住、無額外成功。
- `GET /oauth/callback` 才做 OAuth 驗證；其他路徑 404、指定 callback 的其他 method 405 都不終結 probe，仍可接受其後合法 callback。
- code/state 或完整 callback query／authorization URL 不出現在正常、錯誤輸出與 README。
- `swift build --package-path experiments/E001`、`swift test --package-path experiments/E001`；`git diff --check` 與 changed-path allowlist。
- Archify 9 checks、deliver receipt、四個 viewport containment/captures 與獨立 visual review；工具狀態如實。
- PR Lens provenance、diff 與 unchanged neighbors 正確；Graphify source reads 不擴張 graph build。
- 真實 GitHub 授權：由人類提供 Client ID／登入授權後，code 存在且 state 相符才可記錄成功；模擬不可代替。

## Stop Conditions 與 Delivery

scope/path/contract drift、未解除重大 blocker 或未授權行為即停止。工具 diagnostics 不得偽造成功，交獨立 Reviewer 判斷其是否影響交付。

真實 OAuth 授權為獨立 human-check；初次交付時因缺少 Client ID deferred，不阻驗證工具 Draft PR。2026-10-07 人類提供 Client ID、要求啟動並確認成功頁，HC-LIVE 依真實 callback 與 exit 0 證據完成；詳細結果記於 E001 README。使用者最後的 commit/push/Draft PR 授權覆蓋原計畫不含發布與例行 human commit confirmation 的限制；不覆蓋真實登入、架構新決策或 merge。

本次不修改 docs；未驗證研究不回寫長期真相。之後真實成功或提出產品整合需另行依授權確定長期文件與 topic。
