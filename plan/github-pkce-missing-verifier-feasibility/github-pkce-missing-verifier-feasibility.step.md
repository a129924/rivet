# GitHub PKCE missing-verifier 執行帳本

相關：[需求](../../analysis/github-pkce-missing-verifier-feasibility/requirements.md)／[技術設計](../../analysis/github-pkce-missing-verifier-feasibility/technical-spec.md)／[計畫](github-pkce-missing-verifier-feasibility.plan.md)。

## Current state

- Topic：`github-pkce-missing-verifier-feasibility`。
- Phase：Human review；current step：M08；owner：Human；status：human-check。
- Feature branch：`chore/github-pkce-missing-verifier-feasibility`；基線 `fccaf2b6e38bcd38eaef1f09aecb2dd6068efed4`，target `dev`。
- 上游：Human 已接受對話計畫及 feature worktree／離線交付／topic commit／push／Draft PR；M02 獨立 Plan-Reviewer 明示 approved、無 required fix，只放行 M03–M07 離線交付。
- 真人實驗：E008 已執行；本輪額度 1/1 用盡；HTTP400 拒絕、無 token，因果判讀分歧，主要假設無法判定。

## Steps

| ID | Owner role | Status | 完成條件 | 驗證證據／verdict |
| --- | --- | --- | --- | --- |
| M01 | Plan-Creator | completed | 四份同 slug artifacts 已建立，承接 Human 接受計畫及授權邊界。 | 本 topic requirements／technical-spec／plan／step；只表示撰寫完成，無自審 approval。 |
| M02 | Plan-Reviewer | completed | 獨立審查四文件、scope／workflow／安全界線並明示 verdict。 | 獨立 Plan-Reviewer：approved，無 required fix；不含 live／原文授權。 |
| M03 | Explorer | completed | 有範圍官方／source 調查、必要性與配置限制、來源日期／版本交接。 | [文件／source 證據](evidence/document-source-investigation.md)；來源、日期、工具 SHA 與剩餘未知已保存。 |
| M04 | Implementer | completed | 新長期結論／最小索引／單張 workflow，archify deliver 與證據交接。 | 新長期文件／索引、source evidence、workflow HTML／SHA receipts 已交付；9/9 與四尺寸 containment 通過；完整人工看圖交 M05。 |
| M05 | Tester | completed | 驗證新增文件與 diff 界線、來源、圖 receipts／四尺寸與人工看圖。 | [獨立離線驗證](evidence/offline-verification.md)：passed、無 required issue；9/9／SHA／四張人工檢視符合契約，只支持離線產物。 |
| M06 | Reviewer | completed | 獨立 bounded review，確認歷史、資料安全、三層結論並明示 verdict。 | [獨立 Reviewer](evidence/independent-review.md)：approved，required fixes=0；只核准離線交付。 |
| M07 | Implementer | completed | staged semantic check、按 topic commit／push／Draft PR，真 SHA 本機 pr-lens validate／render／manifest。 | [交付紀錄](evidence/publication.md)：內容 commit 62f6ef6 已 push、Draft PR #65 open／draft；本機真 SHA map validate／render 通過。 |
| M08 | Human | human-check | 審閱 Draft PR 與可 review 產物。 | [Draft PR #65](https://github.com/a129924/rivet/pull/65) 待 Human review，未 merge。 |
| L01 | Tester＋Reviewer | completed | 單次操作完成，安全結果整合後獨立審查三層結論與限制。 | [E008](../../experiments/E008/README.md)／[Tester 整合](evidence/live-verification.md)：1/1 用盡，因果判讀分歧，主要假設無法判定；獨立結果 Reviewer approved、required fixes=0，只核准紀錄與交付。 |

## Blockers

M02 approved；M03 調查已交付。未查得工具實作缺口；Human 已完成唯一操作；安全 JSON 與兩 reader 封存結果已整合。主要假設的因果共識缺口仍在；結果 Reviewer 已明示 approved、0 required fixes，沒有新操作額度。需要改工具或無法確認前提時停止依賴動作並回報最小缺口。

## Human Check

- M08：Draft PR 交付後 Human review；不自動 merge／release。
- L01：本輪一次授權／交換與原文手動傳遞已完成，1/1 用盡；不再 OAuth、重判或增加 reader。結果紀錄可交付，不解除因果共識缺口。
- 任一 token 鍵存在即停，不 API、不保存、不自行 revoke。無法判定可完成有限紀錄，不能放行仍受阻決策。

## Last updated

2026-10-22，由 Implementer 同步 Human 回報與獨立 Tester 結果；L01 結果 Reviewer approved、0 required fixes，M08 Human review 尚未完成。帳本狀態不替代 approval。

M06 approved／0 required fixes 保留；M07 實際 publication 與 metadata 收尾見 evidence/publication.md，不代替 Human review。

## L01 執行時序（歷史快照，以 Current state 為準）

2026-10-22 L01 更新：來源 d067c2c，Human 已明示 OAuth／單欄 AI 閱讀與同 OAuth App 配置，E008 設計已記錄；尚未開啟終端命令或瀏覽器授權，使用量 0/1。未宣稱新 preflight／真人結果或 Human review 通過。

L01 執行前 Tester 明示前提足夠、required issues=0；已嘗試向 Human 本機 Terminal 交付唯一命令，實際遠端狀態待安全回報，沒有讀取配置／終端內容或 provider 原文。不得啟動第二次。

E008 語義結果：兩名全新獨立 Reviewer 已先封存，provider_claim 都為 verifier_required，pkce_causality 分別 not_asserted／asserted；有分歧，依原判準維持無法判定。只保存有限 enum，安全 CLI JSON 尚待 Human 回報，未核實 HTTP／token／prepared／single。不得追加 reader、重新判讀或再開 OAuth；詳 experiments/E008/README.md 與本 topic evidence/live-semantic-observation.json。

E008 安全 JSON 已回：HTTP400／invalid_grant／remote_rejected=true／token_present=false，fresh／single／callback true、prepared consistent／omitted；1/1 使用。兩 reader 因果有分歧，不能標主要假設成功。待獨立 Tester／Reviewer 整合，沒有第二次操作或新增 reader。

2026-10-22 L01 Tester 更新：單次操作已結束、安全 JSON 與封存 enum 完成整合；四態無法判定、1/1 用盡，結果 diff 待獨立 Reviewer。其餘狀態由主 Implementer 同步。

L01 結果審查收尾：獨立 Reviewer 核對實際 10 staged paths，approved／0 required fixes；未看原文、重判或測試。只允許本次有限結果 commit／push 更新原 Draft PR #65，之後停 M08。1/1 用盡，不追加 OAuth／reader／研究。
