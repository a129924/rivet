# E001：GitHub OAuth 重導向 Step Ledger

## Current Phase

verification handoff。execution_plan_reviewer 正式 re-review approved；E001 核心實作已完成並有局部 red/green 證據，Archify deterministic delivery 通過但 desktop containment failed；Reviewer 已將圖 issue 分類為 nonblocking Draft residual。S04 核心獨立驗證 approved，圖驗收 needs-rework；S05 對 bounded Draft 交付明示 approved，圖驗收殘留不阻 Draft，不宣稱 topic 或真實實測完成。

## Ledger

| ID | Owner role | Status | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| S01 | Plan-Creator | completed | 建立同 slug 四份正式 artifacts。 | requirements/spec/plan/ledger 一致記錄 E001、九欄位、locked decisions、驗收與授權。 | 本 topic 四份 Markdown；2026-10-07 由 Plan-Creator 在指定 feature worktree 建立，未實作產品或執行測試。 |
| S02 | Plan-Reviewer | completed | 獨立審查 planning sufficiency、contract、path 與流程。 | 明示 approved／needs-rework／blocked／human-check，只有 approved 可進 S03。 | execution_plan_reviewer 獨立 re-review：approved（2026-10-07）；前次 required refinement 已解除，Dispatcher 交接此明示 verdict。 |
| S03 | Implementer | needs-rework | E001 package、runner、必要測試、README 與 Archify 圖。 | 只在 feature worktree、符合契約；交接實作與待測範圍。 | swift_implementer：核心 package／README 完成；red 合法 callback 被 stub 判 invalidCallback（1 test failed）；green 15 tests／3 suites passed；E001 strict lint 9 files／0 violations。Archify 9/9 showcase、deliver 通過；desktop 四尺寸 overflowY，達 2 輪修正上限，圖驗收未完成。 |
| S04 | Tester | completed | 獨立 package build/test、CLI/HTTP/cleanup 與 scope checks。 | 有可追溯命令／結果，模擬與真實結果分開。 | tester：build/test exit 0；15 tests／3 suites（1.008 秒）passed；實際 invalid CLI 四組 exit 2、安全輸出；external browser-stub main RunLoop timeout exit 1／SIGINT exit 130。scope／ignored build／receipt hashes 通過；核心 approved，desktop 圖仍 needs-rework。完整證據見 E001 README「獨立 Tester 證據」。 |
| S05 | Reviewer | completed | 獨立 correctness/scope/文件與圖視覺審查。 | 明示 verdict，重大 blocker 清楚分類，approved 才能交付。 | reviewer：bounded Draft delivery approved（2026-10-07）。未發現重大 code/scope blocker；親看 1440 light／2048 dark 確認 overflow，正式圖驗收 needs-rework，分類為 nonblocking Draft residual。真實授權仍未驗證。 |
| S06 | Implementer | pending | staged diff 語意檢查並依 topic commit。 | 單一 topic commit、真實 SHA；依使用者直接 commit 授權，不重複詢問例行確認。 | 待 staged diff review、message 與 commit SHA。 |
| S07 | Reviewer | pending | 以實際 commits 製作 local PR Lens，Graphify bounded source evidence。 | provenance 正確、validate/render receipts 或明確 fallback；不上傳，不建立 graph。 | 待真實 base/head 與 external local outputs；目前沒有 graph，targeted reads fallback。 |
| S08 | Implementer | pending | non-force push 並開 Draft PR 至 dev。 | PR 描述驗證工具、測試、真實可行性狀態；交 human review。 | 待 remote branch 與 Draft PR URL。 |
| HC-LIVE | Human | deferred | 註冊獨立 OAuth App、提供 Client ID、登入授權。 | 真實 callback code 非空、state 匹配才是 OAuth 實驗成功。 | Client ID 尚未提供；真實驗證未執行，不阻工具 Draft PR。 |
| HC-PR | Human | pending | Draft PR human review。 | 人類明確 review／後續決策；不自動 merge。 | 待 Draft PR 與人類 review。 |

## Verdicts

S02：approved（execution_plan_reviewer 正式 re-review）。S04：核心自動化 approved；圖驗收 needs-rework。S05：approved，僅限 bounded Draft delivery；沒有重大 code/scope blocker。S03 核心完成、圖驗收 needs-rework；desktop issue 已由 S05 分類為 nonblocking Draft residual，正式圖驗收仍未通過。不存在完整 topic approval 或真實實測成功；各角色只能更新自己有證據的工作，Dispatcher 不算 gate。

## Blockers

- 前次 planning required refinement 已解除，正式 re-review approved；不再是 implementation blocker。
- Client ID／真實授權缺少，屬 HC-LIVE deferred human-check；不能宣稱真實可行性成功，但不阻獨立實作、測試或 Draft PR 交付。
- scope、contract、workflow drift 或重大問題由獨立 Reviewer 分類；禁止自行擴張或標完成。
- Archify desktop containment failed：1440×900 scrollHeight 1645、2048×1320 1773；四尺寸均 overflowY。candidate 已凍結，兩輪修正已用完，未重啟修圖。deterministic delivery 通過不等於視覺通過；Reviewer 已分類為 nonblocking Draft residual；正式圖驗收仍 needs-rework，human review 時須明示。
- PR Lens 缺少 commit provenance，仍 pending；不能以工具 exit 0 冒稱人工視覺審查。

## Human Check

使用者已接受計畫並授權只在 feature worktree 實作、無重大問題直接 topic commit → push → Draft PR → human review。本授權不允許 dev worktree 改檔、auto-merge/release、工具上傳或新架構決策。HC-LIVE 與 HC-PR 分開追蹤，deferred 不等於成功。

## Last Updated

2026-10-07 — swift_implementer 完成 E001 核心、局部 red/green 與圖 deterministic delivery；S02 re-review approved，S03 圖驗收 needs-rework，交 Tester 與獨立 Reviewer。Baseline `622abf662d73afd7e887c7684630663fcaae4a6f`，branch `chore/github-oauth-redirect-feasibility`。

## Implementer Handoff

只在指定 feature worktree 新增 E001 與本 topic artifacts；未修改 root package、產品、docs 或 dev worktree。

Tester 下一步：

```sh
swift build --package-path experiments/E001
swift test --package-path experiments/E001
swift format lint --strict --recursive experiments/E001/Package.swift experiments/E001/Sources experiments/E001/Tests
swiftlint lint --strict --no-cache experiments/E001/Package.swift experiments/E001/Sources experiments/E001/Tests
experiments/E001/.build/debug/oauth-redirect-probe
```

最後一個命令必須 exit 2、不開瀏覽器、不輸出參數值。可對其他無效 CLI 使用合成資料驗證 exit 2；不得以有效 Client ID 啟動真實瀏覽器。SIGINT 已由 runtime test 確認 outcome 130／終結一次，真實 GUI 與授權仍未驗證。檢查 path allowlist、SHA-256／byte receipts 與 desktop failed captures；不 rerender frozen HTML、不繼續圖修正，不自行推定 gate approved。

## Tester Handoff

2026-10-07 — tester 只更新自身 S04 與 E001 README 證據，未修改實作、凍結圖、其他 owner 的結果或 dev worktree。核心 build/test 與入口代表路徑通過；真實 GUI、GitHub 授權及 OS listener 啟動失敗注入未執行。兩張 light/dark 截圖與 hash receipts 已複核，四種 desktop containment 仍 failed（scrollHeight 1645／1743／1743／1773）；未把 capture 成功當作 visual gate 通過。交獨立 Reviewer 評估 correctness、scope 與 desktop 殘留是否構成交付 blocker；Tester 不授予 topic 或 Draft PR approval。

## Reviewer Handoff

2026-10-07 — reviewer 獨立讀取四份 artifacts、全部 E001 source/test 與 README，確認 root package、產品 Sources/Tests、docs 與 .vscode 對 baseline 無 tracked diff。未發現需要回交 Implementer 的重大 code/scope findings：Network handlers 在 serial queue，start/interrupt 只 enqueue，finished/delivered 保證單次終結；callback response 與連線等待有上限，cleanup 包含 listener、timers 與 connections；query/CLI 判定與固定安全輸出符合受限契約。`127.0.0.1` numeric host 與動態 port 符合 IPv4 loopback 要求，未擴張產品 API。獨立 Tester 的 15 tests／3 suites、invalid CLI 與 external RunLoop/SIGINT 證據納入判斷；Reviewer 未重跑測試或啟動真實授權。

已親看 1440×900 light 與 2048×1320 dark captures，確認流程下半部／結論超出首屏；receipt 的四尺寸 scrollHeight 1645／1743／1743／1773 符合所見。正式 Archify desktop 視覺 gate 為 **needs-rework**，不是 approved；不改凍結圖、receipt 或用 capture success 代替 acceptance。此 auxiliary residual 未影響 runner 行為、敏感值邊界或核心證據，依使用者「Swift implementation 無重大問題即可 Draft」授權，判為 **nonblocking Draft residual**。

**S05 verdict：approved，僅限 topic commit → local PR Lens → push／Draft PR 的 bounded delivery readiness。** 真實 OAuth 可行性未驗證、完整 topic 未完成、Archify 正式圖驗收未通過；三者不得因本 verdict 轉為成功。下一步交 Implementer S06 staged semantic check／topic commit；真實 base/head 產生後再交 Reviewer S07。Draft 必須明示上述殘留，停止於 HC-PR human review；不得 auto-merge、發布、重新啟動圖修正或代人類完成 HC-LIVE。
