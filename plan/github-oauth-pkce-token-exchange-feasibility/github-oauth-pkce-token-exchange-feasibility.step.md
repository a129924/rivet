# E002 — Step Ledger

- Topic：`github-oauth-pkce-token-exchange-feasibility`
- Branch：`chore/github-oauth-pkce-token-exchange-feasibility`
- Base dev／origin/dev：`a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f`。
- Current phase：L02 evidence-record approved；L03 證據 commit 準備，2／2 授權已用盡。
- Current step：L03，status=pending，owner=Implementer；此為證據 commit 前 snapshot，L04／L05 pending。
- Formal upstream verdict：approved；Dispatcher 轉交獨立 Plan-Reviewer 四檔審查（2026-10-07），無 required fix。
- 前序：使用者批准 processed-plan 與 feature-only／commit／push／human review 授權；對話稿經獨立審查，非正式四檔 gate。
- 最後更新：2026-10-07，Implementer 記錄 Dispatcher 轉交 L02 獨立 Reviewer evidence-record approved／無 required fix；舊交付 snapshot 保留歷史。
- 配對文件：[requirements](../../analysis/github-oauth-pkce-token-exchange-feasibility/requirements.md)、[technical-spec](../../analysis/github-oauth-pkce-token-exchange-feasibility/technical-spec.md)、[plan](github-oauth-pkce-token-exchange-feasibility.plan.md)。

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據 | Verdict |
| --- | --- | --- | --- | --- | --- |
| S01 | completed | Plan-Creator | feature worktree 四份同 slug 文件寫妥，保留已批准 scope 與最新人類授權。 | 四檔已寫入；尚未自評品質或正式 approval。 | null |
| S02 | completed | Plan-Reviewer | 獨立讀四檔，核對 locked decisions／workflow／scope，明示 verdict。 | Dispatcher 轉交 Plan-Reviewer 已獨立讀四檔，明示 approved／無 required fix。 | approved |
| S03 | completed | Implementer | 僅 E002 bounded TDD runner／README／sequence；無 root／E001／dev 修改；交 Tester。 | E002 runner／22 mock tests；RFC red exit 1→green；build／format／SwiftLint 0 violations。圖第二輪 failed，保留 v1 HTML／visual overflow 與 v2 failed candidate，交 Tester／Reviewer 分類；未真 OAuth。 | null |
| S04 | completed | Tester | P1/P2 回修後局部獨立重驗，圖檔保持凍結。 | root：27 tests 1.013 秒 exit0；format/lint 11 files 0 violations；diff check passed；v1 HTML／v2 JSON hashes unchanged。 | needs-rework |
| S05 | completed | Reviewer | 獨立複審 P1/P2 與圖 blocker classification。 | Reviewer：code-bounded approved，P1/P2 closed／無新增 code findings；圖 mandatory gate 未完成且預算用盡，整體 human-check，不允許 commit／push／Draft PR。 | human-check |
| S06 | completed | Implementer | Reviewer approved 且無重大問題，staged diff 語意檢查／繁中 message，按人類既有授權 commit by topic。 | 單一 topic staged semantic check；commit 819184f6ddebe05090608a11da602a67e247b5df；正常六 hooks 全 Passed，feature／dev clean／圖 SHA 不變。 | null |
| S07 | completed | Reviewer | 真實不同 base／head 的 PR Lens local validate／render／manifest；失敗 direct diff 並如實分類。 | Reviewer pinned 0.11.0 validate/render exit0、manifest 3lanes/8nodes/8edges/3walkthrough/1SVG 已讀；base a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f→head 819184f6ddebe05090608a11da602a67e247b5df。 | approved |
| S08 | completed | Implementer | 同 topic 收尾 README／ledger 必要文件 commit；僅反映實證與工具真實狀態。 | docs commit d87407fbdc739a5e564e8777f149a9fbc3f0e1b0；正常六 hooks 全 Passed，4 metadata files，source／圖不變。 | null |
| S09 | completed | Reviewer | 最終 commit diff／map SHA coverage 明確；若 head 改變則更新 map 或明示缺口，無新增無關工作。 | 獨立 Reviewer final map approved，base a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f→head d87407fbdc739a5e564e8777f149a9fbc3f0e1b0，graph SHA 32fafe4242513d39d1f20bf0cd39e5302d1495907ebe44c1ba0675c82158f61f，validate/render exit0／manifest matching。 | approved |
| S10 | completed | Implementer | non-force push topic branch；適用時 Draft PR target dev，無 merge／release。 | non-force push／Draft PR https://github.com/a129924/rivet/pull/47，base dev，前序 remote／PR head d87407fbdc739a5e564e8777f149a9fbc3f0e1b0 verified，未 merge。 | null |
| S11 | pending | Human | human review runner 與證據，決定後續；HC-LIVE 獨立保留。 | 待人類 review。 | null |

## Blockers

- 正式 S02／A02 approved；S04／A04 completed；A05 已明示 runner＋v3 完整 approved，原 S05 human-check 為歷史；S06／S08／S10 completed、S07／S09 approved；L02 證據 approved，L03／L04／L05待新證據提交路由。
- 歷史 Archify 原兩輪預算用盡：v1 trusted HTML 四 viewport vertical overflow；v2 validate/deliver fail。v1 原始 spec／delivery receipt 被覆蓋，provenance 缺口如 README；原圖 human-check 停點保留為歷史；A001 經人類追加預算後 v3 在追加 1／2 輪通過 A05，未延長或豁免驗收。
- Graphify 無可用 graph：targeted source fallback，記導航缺口，不建圖、不阻本體。
- 歷史 PR Lens deferred 已解除：S07 approved 具真實 base→819184f6ddebe05090608a11da602a67e247b5df coverage；S09 已對 d874 head approved；本次 L03 新 head 未形成，L04 coverage pending，不冒造 map。
- 真實 OAuth 已執行 2／2：exchange／schema／API 成功，PKCE 無法判定；原始反向回應未保存，不能追補，未追加授權。

## Human Check

| ID | Status | Owner | 條件與界線 | 證據 |
| --- | --- | --- | --- | --- |
| HC-AUTH | completed | Human | feature-only；無重大問題直接 commit by topic、push、human review。保留 staged diff semantic check／繁中 message；不需例行再次 permission，不 merge。 | 本輪使用者明確授權，由 Dispatcher 交接。 |
| HC-LIVE | human-check | Human | 人工輸入與兩次授權已完成；不自行第三次授權。PKCE 原因缺口另待人類決策，不等實驗成功或正式採用。 | 真實 exchange／schema／API 成功，PKCE／overall 無法判定，exit1；見本輪 receipt，L02 evidence-record approved；第三授權／採用仍需人類決策。 |
| HC-DIAGRAM | completed | Human | 人類追加預算、A02 approved、A04 completed、A05 完整 approved，圖停點解除。 | 獨立 Reviewer 實看四 captures；v3 matching delivery／無 overflow／語意正確，舊失敗與缺口僅歷史。 |
| HC-REVIEW | pending | Human | push／Draft PR 後人類 review；是否真實測量／後續採用另決定。 | 既有 Draft PR #47 已推送；本次 L05 更新真實證據／人類 review pending。 |

## 長期結論與路由

未真實實證時，`docs/architecture/github-oauth-dual-client.md` 維持唯讀；後續僅實證與獨立 review 成立的受限結論可 append，不改架構。

明示 approved 才前進下一 phase；needs-rework 回對應產出角色，blocked／human-check 停止自動前進。checkbox／completed／tool receipt 不等 approval。HC-LIVE pending 是獨立實驗人類停點，不把它誤當已局部驗證 runner 的重大 blocker。

### 歷史 S04 獨立 Tester 交接

2026-10-07 — root Tester 完成上述分項驗證；程式檢查通過，圖的四尺寸 overflow 與 spec／receipt 缺口尚待 Reviewer 分類，未產生完整成果 approval。HC-LIVE 仍 pending；dev、E001、root package 與長期 docs 維持唯讀。

### S05 回修歷史與局部交接

2026-10-07 — Reviewer 明示 needs-rework 與圖 human-check，由 Dispatcher 交接。Implementer 只修 E002 Measurement／mock tests：前置 OAuth error indeterminate stop；四軸 finite enum reason 保留。新增 4 red tests／10 issues exit 1，修正後最終 27 tests 1.012 秒／exit 0、strict format／SwiftLint 11 files 0 violations、diff check 通過；有效無 token failure 仍失敗。S04／S05 等獨立複驗；mandatory 圖全部不變、未增加 budget、未 stage／commit／push／PR，真授權仍 0／2。

### 回修後 Tester 交接

root Tester 複驗上述 27 tests／format／lint 通過；P1/P2 交 Reviewer 複審，圖的 mandatory gate 未通過且修復預算用盡，HC-DIAGRAM 維持 human-check。未授權自行降低圖 gate 或第三輪；本輪尚不 commit／push。

### 歷史前次 Reviewer 交接與人類停點

2026-10-07 — 獨立 Reviewer 已關閉 P1/P2，code-bounded verdict approved；整體 verdict human-check。HC-DIAGRAM 需人類明確決定延期圖驗收或修改修復預算，再由 Plan-Creator 記錄新契約。當前未 stage／commit／push／建立 PR；所有 implementation 只在 feature，dev 未更動。

## A001：追加圖修復預算

- 人類決策：2026-10-07 明確批准「追加最多兩輪圖修復，維持原驗收標準（建議）」。
- Amendment verdict：approved（2026-10-07，Dispatcher 轉交獨立 Plan-Reviewer／無 required fix）；此為 bounded 預算核准，不是圖成果 approval。
- 原圖修復：2／2 已用盡且失敗；追加圖修復：1／2 已執行並達成自動驗證；A04 completed、A05 approved；累計 3／4，最大四輪。
- 真實 OAuth：0／2，HC-LIVE pending；S06 819184f6ddebe05090608a11da602a67e247b5df 已 commit／S07 approved；S08 收尾前、尚未 push／PR，既有授權保留。
- 原失敗紀錄與 v1／v2 證據完整保留其現有狀態；v1 spec／原 delivery receipt 缺失不得補造。

| ID | Status | Owner role | 完成條件 | 驗證證據 | Verdict |
| --- | --- | --- | --- | --- | --- |
| A01 | completed | Plan-Creator | 四正式檔案記錄人類追加授權與原兩輪／追加兩輪獨立計數；不改程式或圖。 | 本節與四檔 A001 附錄；非品質 approval。 | null |
| A02 | completed | Plan-Reviewer | 獨立審查 bounded amendment／歷史保留／驗收不變，明示 verdict；approved 前不修圖。 | Dispatcher 轉交獨立 Plan-Reviewer approved／無 required fix（2026-10-07）。 | approved |
| A03 | completed | Implementer | 最多追加兩輪新 v3／v4；保留原 v1／v2／hash／缺口，逐輪記 diagnostic／最佳 error count／containment；不改 runner。 | 追加 1／2，v3 validate/deliver/visual-check exit0，9／9／0errors／0warnings、四 viewport 無 overflow；spec/html SHA/bytes matching，舊檔全部 SHA unchanged，詳 README。 | null |
| A04 | completed | Tester | 複驗原檔 hashes 未變、新 showcase 九項零 errors／warnings、四尺寸無 overflow、light／dark captures；不宣稱自動視覺 acceptance。 | root Tester 重跑 validate／visual-check exit0；matching SHA／bytes；21 個原檔 hash 全未變，四尺寸與四 captures 通過，visualReview pending。 | null |
| A05 | completed | Reviewer | 獨立實看最小／最大 light／dark captures 與新圖，判視覺 gate／blocker；完整 approved 才銜接 S06。 | Dispatcher 轉交獨立 Reviewer runner＋v3 完整交付 approved：四 captures 實看可讀平衡／語意正確／無偽造；v1 歷史缺口不阻 v3。 | approved |

追加 rounds 沿用原兩次連續未改善最佳 objective error count 即停止規則；追加兩輪用盡仍未達標同樣停止 human-check，交還人類，不加輪、不延期／豁免 mandatory gate。四 desktop／showcase／deliver SHA 與獨立視覺標準不變。若 A02 needs-rework 回 Plan-Creator，blocked／human-check 停止；A03–A05 依明示 verdict 路由。此前「不做第三輪」表示不得自行續原預算，本人類 amendment 只在 A02 approved 後允許另計追加 rounds。

### A03 v3 局部證據交接

2026-10-07 — A02 approved（Dispatcher 轉交獨立 Plan-Reviewer，無 required fix）後，追加第1輪建新 v3；validate／deliver／visual-check exit0。objective errors 由四 viewport overflow／v2 timeline failure 收斂至 v3 0 composition errors、0 warnings、0 overflow viewports。v3 frozen spec 540936…77f3／3170 bytes，trusted HTML 80a34d…1214／701257 bytes，來源／artifact 真 hash matching；四 captures 與 receipt 存在。原所有圖檔 hash 未變，v1 provenance 歷史缺口未補造。追加1／2（原2／2、累計3／4），交 A04／A05，不自評 approved、不跑真 OAuth、不改 runner、不 commit／push。

### A04 獨立 Tester 複驗（2026-10-07）

root Tester 重新執行 v3 showcase validate 與 visual-check，均 exit 0；九項檢查通過、零 errors／warnings，四 viewport scrollWidth／scrollHeight 均等於對應 viewport，四張明暗 captures 完整。spec／HTML SHA-256 與 byte count 與 matching delivery receipt 一致。修復前既有 21 個非 README 檔案（11 Swift、10 舊圖證據）hash 全部未變，故保留先前 27 tests／format／lint 證據，未重跑 Swift 或真實 OAuth。自動 visualReview 仍 pending，交獨立 Reviewer 實看與 gate 判定；追加使用 1／2，原 2／2，真實授權 0／2。

### A05 完整成果放行（2026-10-07）

Dispatcher 轉交獨立 Reviewer 明示 approved：runner＋v3 完整交付、四 captures 實看可讀平衡且語意正確，無偽造 overflow 手段。HC-DIAGRAM 解除，v3 為主入口；原 v1／v2 失敗／v1 provenance 缺口維持歷史。A001 approved、追加 1／2（累計3／4）、真 OAuth0／2。歷史 S06 準備時 commit 尚未發生；現已完成 S06／S07，見下方當前 snapshot。

### S08 收尾前／push 前 snapshot

S06 已 commit `819184f6ddebe05090608a11da602a67e247b5df`、正常六 hooks 全通過；S07 獨立 Reviewer approved，graph SHA `24bf5c1ebc591b17b93b56b69136c54c283a8e506053f09096a33da8e3c83422`，coverage 僅 base `a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f` → `819184f6ddebe05090608a11da602a67e247b5df`。產物僅外部 topic scratch `pr-lens/819184f6/graph.json` 與 `rendered/overview-light-3310335da44d6334c6755d1c8cd2c36b.svg`／`manifest.json`，不是 repo artifact。S08 此 metadata commit 尚未發生，不預寫自身 SHA；S09 final coverage／S10 non-force push／HC-REVIEW pending，後續交付以 PR／remote 證據為準。v3 approved／追加1／2，真 OAuth0／2，HC-LIVE pending；原失敗停點／deferred 皆保留為歷史。

## 真實 OAuth 測量（2026-10-07）

使用者明確要求開始真實 OAuth，提供 E001 App 的公開 Client ID，並在本機 Terminal 的 runner 隱藏提示輸入 secret；兩次系統瀏覽器授權由人類處理。執行 feature worktree 既有 commit `d87407fbdc739a5e564e8777f149a9fbc3f0e1b0` 的已建置 runner，參數為人類提供的 Client ID 與 `--timeout-seconds 180`；未改 runner／判準，無額外 scope 或重試。build exit0。

正向 exchange 成功；JSON 六欄符合本地嚴格 DTO 並可建立 public bundle；唯一一次 `GET /user` 回 200 且有效 id／login。反向使用新 state／challenge／code 與錯誤 verifier，回應落在「反向回應／錯誤未確認，無法歸因」，總體無法判定、exit1。依固定 runner 控制流程，此分類表示兩次授權與交換均已到達；並不支持將反向拒絕原因歸為 PKCE，不能當成 PKCE 失敗。

`experiments/E002/evidence/2026-10-07-live-safe-report.txt` 與 `experiments/E002/evidence/2026-10-07-live-receipt.json` 保存四軸、exit、runner commit、上限與報告 hash／bytes，不含 code／state／verifier／token／secret／userinfo／完整 URL／原始 body。原始反向回應依資料邊界只留記憶體，程序已結束，不能追補其 error code／status。若需改善分類，須先另定有限診斷與新授權預算；本輪不改既定判準或自動第三次授權。

外層日期腳本用了錯誤 executable 路徑，start／end 時間文字未寫入；不影響 runner 測量。receipt 的時間只取外層檔案建立時間，約 06:53:54–06:54:27 UTC（14:53:54–14:54:27 Asia/Taipei），明示非精確 OAuth 事件時間。App 全域 expiring-token 設定未另查證；本次 offline_access 請求與實際六欄相容性有證據，不能外推全部 App／正式部署或 secret 配送。

本輪有效完成兩案例的執行與遮蔽紀錄，總體無法判定；L02 evidence-record approved／無 required fix，HC-LIVE 的人工操作已完成，PKCE 證據缺口保留為 human-check。上述舊 0／2、未實測與 pending 敘述均是前序歷史，不改寫原證據；長期架構與圖保持唯讀。

| ID | Status | Owner role | 完成條件 | 驗證證據 | Verdict |
| --- | --- | --- | --- | --- | --- |
| L01 | completed | Tester | 人工授權內執行既定 runner，最多兩次，保存四軸遮蔽結果，不改判準。 | 本輪 stdout／receipt；2／2、exit1、三軸成功、PKCE 無法判定。 | null |
| L02 | completed | Reviewer | 獨立核對實證、分類、時間與限制；不以執行完成宣稱總體成功。 | Dispatcher 轉交獨立 Reviewer evidence-record approved／無 required fix：三成功、PKCE／overall indeterminate、exit1、2／2、時間proxy與限制如實；只核准紀錄。 | approved |
| L03 | pending | Implementer | 僅四檔遮蔽證據／README／ledger staged semantic check、正常 hooks、原授權 topic commit；不預寫自身SHA。 | 此 snapshot 為證據 commit 前；runner d874／27 tests／v3證據保留。 | null |
| L04 | pending | Reviewer | 新證據 commit 後刷新既有外部 PR Lens finalhead coverage；source／圖不變不重畫架構。 | 待新真實 head／manifest／graph SHA。 | null |
| L05 | pending | Implementer | L04 approved 後 non-force push 同 branch、更新既有 PR #47 body 真實四軸／HC-LIVE；不新增PR／merge。 | 待 remote 新 SHA／PR 更新，human review pending。 | null |

### L02 approved 與證據 commit 前 snapshot

L02 evidence-record approved／無 required fix 由 Dispatcher 轉交；PKCE／overall 的 human-check 僅阻第三授權／採用，不阻本輪如實證據 commit／push。正向三軸成功、反向無法歸因、2／2、exit1 與時間外層 proxy 保持，不追補未保存原 body／status／error。前序 S08 commit d874／S09 final map approved／S10 Draft PR #47 pushed 已發生；L03 新commit尚未發生，不預寫自身SHA。僅四檔，source／image／長期docs／dev唯讀；L04／L05及HC-REVIEW pending。
