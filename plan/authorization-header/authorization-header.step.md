# AuthorizationHeader Step Ledger

## Current Phase

human-review；current_step：AH-06，status：human-check，owner：Human，upstream_verdict：AH-05 approved。

P 已建立且獲獨立 Plan-Reviewer approved。AH-03／AH-04 已完成，AH-05 明示 approved；功能 topic 已 commit／push，Draft PR #51 已建立。現在等待 Human review，不自動 merge。

範圍／代號／TC 定義引用 [plan](authorization-header.plan.md)；API 與 grammar 引用 [technical-spec](../../analysis/authorization-header/technical-spec.md)。各 step 九欄是全域 allowlist 的子集，不允許由引用擴張寫入範圍。

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據／verdict |
| --- | --- | --- | --- | --- |
| AH-01 | completed | Plan-Creator | 四份同 slug artifacts 落盤，對應已確認契約與授權。 | 2026-10-12 本次四份文件建立；未執行產品實作／測試；不是 approval。 |
| AH-02 | completed | Plan-Reviewer | 獨立審查四份可讀 artifacts，明示 verdict。 | 2026-10-12 獨立 Plan-Reviewer 明示 approved，沒有 findings；只核准 planning contract。 |
| AH-03 | completed | Implementer | 完成限定 S／T／D／M，更新實際狀態並提供 bounded diff／完成 handoff。 | 2026-10-12 S／T／D／M 已完成；focused green 9 tests passed；Archify 9/9 showcase 與四尺寸 containment passed，Implementer 已人工檢視四張截圖。詳見 handoff。 |
| AH-04 | completed | Tester | 獨立執行 TC-01 至 TC-06，保存分開命令結果、圖表 receipts 與人工 inspection。 | 2026-10-12 五項 commands exit 0；focused 9、package 81、root 187 tests passed；Archify fresh 9/9、四尺寸 containment 與獨立人工 visual_review passed。詳下列 handoff；不是 AH-05 verdict。 |
| AH-05 | completed | Reviewer | 獨立核對 source／tests／docs／證據與 drift；完成 TC-07；明示 verdict。 | 2026-10-12 獨立成果 review approved，沒有 findings；TC-07 如實採 direct diff／source fallback，詳下列 handoff。 |
| AH-06 | human-check | Implementer → Human | 僅於 AH-05 approved 後依既有授權 commit by topic、non-force push、開以 dev 為 base 的 Draft PR；Human review 待決。 | 功能 commit 74c7cde692ca2a6f95c93ba0a5db4e3b74dc3218 已 non-force push；Draft PR #51 已建立、base dev；delivery evidence 見下段，Human review pending。 |

## 每 Step 九欄契約

### AH-01：planning authoring

- Goal：落盤已確認契約；Non-Goal：實作或自審。
- In-Scope：P；Out-Of-Scope：S／T／D／M／X 及所有 Git mutation。
- ReadOnly：全域 ReadOnly 及非 P 路徑；Written：P；Deleted：無。
- Modify：僅 P 既有內容的本 topic 修訂；TestCase：N/A（文件 authoring，不是產品驗證）。

### AH-02：planning review

- Goal：獨立審查 planning sufficiency／scope／workflow；Non-Goal：代寫計畫或實作。
- In-Scope：只讀 P 與必要 source／skill evidence，回傳 verdict；Out-Of-Scope：修正文案或實作。
- ReadOnly：全部交付文件及全域 ReadOnly；Written：無；Deleted：無。
- Modify：只允許將明示 handoff／verdict 交由適當產出角色記入 P，不由 Reviewer 改受審內容；TestCase：核對 TC-01 至 TC-07 定義，不執行測試。

### AH-03：bounded implementation

- Goal：交付元件、獨立測試、圖與最小長期文件；Non-Goal：consumer migration／lifecycle／network／新抽象。
- In-Scope：S／T／D／M 與 P 的本 step evidence；Out-Of-Scope：X authoring、graph build、Git delivery 與全域排除事項。
- ReadOnly：全域 ReadOnly；Written：S／T／D；Deleted：無。
- Modify：M、P ledger 與已新增 S／T／D 的同範圍修正；TestCase：TC-01 至 TC-06（Implementation handoff 不取代 AH-04 獨立驗證）。

### AH-04：independent verification

- Goal：獨立確認功能／回歸／品質／圖表證據；Non-Goal：修復實作或擴張 scope。
- In-Scope：plan 列出的五項 commands、Archify receipts／visual-check／人工 inspection；Out-Of-Scope：改 S／T／M、另建圖、Git delivery。
- ReadOnly：S／T／M、可信 D spec／HTML 與全域 ReadOnly；Written：D 內工具實際產生的本流程驗證 receipts／contact sheet／screenshots；Deleted：無。
- Modify：P ledger 的實際命令／結果／blocker；TestCase：TC-01 至 TC-06，逐項保存 evidence。

### AH-05：independent review

- Goal：獨立評估正確性／scope／contract／workflow 與實際 diff；Non-Goal：自行修復或把 map 當 correctness verdict。
- In-Scope：只讀 source／docs／evidence、TC-07、local PR Lens X；Out-Of-Scope：consumer edges 推論、graph build、repo config／實作修改或 Git delivery。
- ReadOnly：所有受審 tracked 交付檔及全域 ReadOnly；Written：X；Deleted：無。
- Modify：將實際 review handoff／verdict 記入 P ledger，不修改受審 source／docs；TestCase：TC-07，核對 TC-01 至 TC-06 的 fresh evidence。

### AH-06：authorized delivery → human review

- Goal：依既有授權交付 topic commit／push／Draft PR，停在人類 review；Non-Goal：merge／release／非本 topic 變更。
- In-Scope：approved bounded diff、staged diff 語意檢查／message、既有 hooks、non-force push、Draft PR base dev；Out-Of-Scope：force push、額外 PR 操作／review comments、dev mutation。
- ReadOnly：全域 ReadOnly 與 external X（不入 Git）；Written：無新增 tracked 交付檔；Deleted：無。
- Modify：P ledger 的實際 delivery evidence；TestCase：沿用 AH-04／AH-05 已核實 evidence，記錄 hooks fresh results，不以舊證據取代失敗。

## AH-03 Implementation Handoff

- S：純標準庫實作，唯一 bearerValue 驗證／formatting；applyingBearer 只做 ASCII Authorization 替換，不經 HTTPHeaders。
- T：9 個 Swift Testing tests，含 7 組合法、21 組非法 token、4 組 header casing，以及重複欄位／保留／近似名稱／input 不變／冪等／內容確定性／token-free error。
- M：architecture README 最小能力與流程圖回寫；既有 consumers 未整合。沒有改既有 source／tests、manifest 或 dependency。
- TDD red：focused command exit 1，原因為尚無 AuthorizationHeader symbol；外部暫存 tdd-red.log。Green：同 command exit 0，9 tests passed；tdd-green.log。不以 Implementer green 取代獨立驗證。
- D：dataflow，validation／delivery 均 9/9 showcase、0 errors、0 warnings；receipts 的機器路徑轉為 repository-relative，hash／byte count 不變。
- D visual：四尺寸 1440×900、1600×1000、1920×1080、2048×1320 containment 均通過；Implementer 實際檢視最小／最大 light／dark 四張 screenshot，visual_review：passed。
- Visual correction_rounds：2。第一輪移除多餘 viewBox 留白以修復垂直 overflow；第二輪將 Headers 輸入改從底部進入，避免主路徑重疊，並依 endpoint-side diagnostic 補單一 via。最終 candidate 已 frozen，未再修改。
- 最終 specification SHA-256：e9262ad997c07655e9140a8a7a4bf79ab215ac0704340fdd8069445a14b3fe4c。
- 最終 artifact SHA-256：1dd8d983b679d4ac2e402dfcd1ec86bce1108babfca42fa7a9a3647c62b3c92e。
- 自動 visual-check receipt 保留 visualReview pending；上列人工檢視是分開的證據，不改寫自動 receipt。
- 待 Tester 獨立執行五項 commands、複核 TC-01 至 TC-06／receipts／screenshots；此 handoff 不是成果 gate approval。

## AH-04 Independent Verification Handoff

所有操作僅在授權 feature worktree；沒有修改 S／T／M 或 frozen spec／HTML。採用 swiftpm-macos；SwiftPM build 依序執行。外部 evidence 位於 topic scratch 的 `tester/`，不納入 Git。

| 實際命令 | Exit | 獨立結果 | External evidence basename |
| --- | --- | --- | --- |
| `swift test --package-path packages/RivetHTTPClient --filter AuthorizationHeaderTests` | 0 | 9 tests／1 suite passed | `focused.log` |
| `swift test --package-path packages/RivetHTTPClient` | 0 | 81 tests／12 suites passed | `package.log` |
| `swift test` | 0 | 187 tests／23 suites passed | `root.log` |
| `scripts/check-swift-format.sh` | 0 | passed，無診斷輸出 | `format.log` |
| `scripts/check-swiftlint.sh` | 0 | 102 files，0 violations／0 serious | `lint.log` |

計數為三個獨立 runs：9／81／187，不合計為 unique tests。Swift Testing 前的 XCTest 顯示 0 tests 為預期 runner 輸出，不取代 Swift Testing 結果。Root build 有既有 `JSONSemanticDecodingError.Kind` Sendable warning；該檔沒有 topic diff，本次不代修。

- TC-01／02：source 與 tests 複核 7 組 valid、21 組 invalid arguments；ASCII grammar、任意尾端 `=`、兩個 API typed error、sentinel diagnostics／reflection 無 token 均符合驗收。
- TC-03／04：4 組 casing、重複變體、近似名稱不匹配、其他鍵值保留、成功／失敗原始 input 不變、冪等、不同 token、插入順序內容一致均覆蓋並通過。
- TC-05：一般 public module import；測試未建立 HTTPClient、URLSession、Apollo 或 provider。五項命令均通過。
- TC-06：獨立重跑 `node <archify>/bin/archify.mjs validate dataflow <spec> --quality showcase --json` exit 0，9/9 checks、0 errors、0 warnings；external `archify-validation.json`。沒有重新 render／deliver frozen HTML。
- TC-06：delivery receipt 的 specification／artifact SHA-256 與 byte counts 均由實際 bytes 複核一致；hash 同 AH-03。獨立 `visual-check <html> --repo-root . --json` exit 0；D 內 receipt／四張 screenshots／contact sheet 為本次 fresh tool evidence，external `visual-check.json` 保存命令輸出。
- TC-06 containment：1440×900、1600×1000、1920×1080、2048×1320 均 scrollWidth／scrollHeight 不超過 viewport，無 X／Y overflow；artifact hash 仍符合 delivery receipt。
- TC-06 人工 inspection：Tester 透過 image reader 實際檢視 fresh 最小／最大 light／dark 四張 screenshots；主路徑、invalid 分支、headers 入口、標籤與 cards 清楚，無遮擋／裁切／交叉；最大尺寸 panel／cards 分布平衡。`visual_review: passed`；Tester `correction_rounds: 0`。自動 receipt 保留 `visualReview: pending`，不冒充人工 verdict。
- Graphify：tracked graph 搜尋無結果，沿用限定 source reads；未 build／refresh graph。TC-07／PR Lens 仍交獨立 Reviewer。

AH-04 完成，可交 AH-05 獨立 Reviewer；本 handoff 不是 correctness review approval，不授權跳過 AH-05。

## AH-05 Independent Review Handoff

- Verdict：approved；沒有 correctness、scope、contract 或 workflow findings。Reviewer 未 author／implement／test 本次產品變更；只讀檢查受審 source／tests／docs／receipts 與獨立 Tester evidence。
- 實際 bounded diff：`git diff --cached --find-renames 4805061a0d8d08d7690c0acd288a374860fa71c8`。審查時 HEAD 仍是該 base，尚無 topic commit。17 個 staged files 符合 P／S／T／D／M allowlist；既有 consumers、HTTPHeaders、manifest、dependency 沒有 diff。`git diff --cached --check` 通過。
- 核對 RFC grammar、任意尾端等號、UTF-8 非 ASCII 拒絕、唯一 formatting、精確 ASCII header matching、其他鍵值保留與 input value semantics；新 tests 正常 public import 並覆蓋已鎖定情境。README 與單張 dataflow 真實反映實作，未宣稱既有 consumers 已遷移。
- 複核 Tester 三個獨立 runs 9／81／187 tests、format pass、lint 102 files 零 violations；不將它們合計為 unique tests。Archify fresh validation 9/9、零 errors／warnings，實際 spec／HTML bytes 與 SHA-256 重新計算符合 delivery receipt，visual receipt 四尺寸 containment passed；人工 inspection 沿用獨立 Tester 明示 passed，不把自動 pending 冒稱人工通過。
- TC-07 PR Lens：已讀指定 skill／graph-document／example；pinned CLI 實際版本 0.11.0。外部 topic scratch `pr-lens/` 已 author 最小 graph candidate（新增 API／tests、source-backed unchanged BearerAuth→HTTPHeaders 鄰居，沒有虛構新 consumer edges）、`provenance.json`（實際 base／HEAD／staged diff hash）及 `validation.log`／`status.json`。
- TC-07 PR Lens validation exit 1：schema 強制 provenance.repo／base／head；目前 staged working-tree diff 沒有可代表變更的 topic head commit。未偽造 head 或相同 SHA 的 patch pair，未 render、未宣稱工具 passed。依 plan 採 direct staged diff review fallback；外部 candidate 不納入 Git。待實際 topic commit 存在後才可另補真實 commit-pair provenance。
- TC-07 Graphify：版本 0.9.73，CLI invocation 帶 `GRAPHIFY_NO_AUTO_REFRESH=1`；tracked／local graph 搜尋沒有可用 graph，採 targeted source reads，未 build／extract／refresh／安裝或改 config。
- 僅更新本 P ledger 的實際 review evidence／verdict；未改 source／tests／docs／frozen diagram，未 commit／push／開 PR。AH-06 可依既有明確授權進行，Draft PR 後仍停在人類 review。

## AH-06 Delivery Evidence

- 2026-10-12 首次 topic commit 的 whitespace、EOF、Swift format、GitHubIntegration consumer、SwiftLint hooks 通過；renderer hook 因 fresh worktree 尚無本地 biome 而 exit 127，commit 未建立，未 bypass hooks。
- 依既有 docs/toolchain.md，在 feature worktree 的 surfaces/pr-reader-webview 執行 bun install --frozen-lockfile，exit 0；只恢復既有鎖定 dev dependencies，沒有修改 manifest／lockfile、安裝新 global runtime 或升級工具。後續重試已完整通過全部 hooks，見下段。
- 單一 topic staged diff 已依 git-commit-convention 核對；message 為「feat(http-client): 新增無狀態 AuthorizationHeader」，沿用使用者本輪直接 commit 授權。
- Topic feature commit：74c7cde692ca2a6f95c93ba0a5db4e3b74dc3218，message 為「feat(http-client): 新增無狀態 AuthorizationHeader」。完整 whitespace、EOF、Swift format、GitHubIntegration consumer contract、SwiftLint、renderer check hooks 全部 passed；沒有 bypass。
- 已 non-force push 至 origin/feat/authorization-header，tracking branch 正確；dev worktree 維持乾淨、無產品寫入。
- Draft PR：https://github.com/a129924/rivet/pull/51，base dev、head feat/authorization-header、Draft，Human review pending。
- PR Lens：實際 topic commit 存在後，獨立 Reviewer 使用 base 4805061a0d8d08d7690c0acd288a374860fa71c8 → head 74c7cde692ca2a6f95c93ba0a5db4e3b74dc3218 重新補真實 provenance；pinned CLI validate／render 均 exit 0。外部 pr-lens/graph.json、provenance.json、rendered/manifest.json 與 overview-light-2d7a1481d62915ba890e31f953242905.svg 已產生；沒有上傳、附加或發布。
- PR Lens 一張 light view，2 lanes／4 nodes／2 edges；僅測試→新增 API 與既有 BearerAuth→HTTPHeaders 的 source-backed 關係，不宣稱 consumers 已整合。先前 working-tree validate failure 是歷史，當前 committed map passed。
- Graphify：保留無 existing graph 的 targeted source fallback，不建圖或 refresh。
- 本次 ledger delivery evidence 將以同 topic 的 docs commit 保存並 non-force push；僅更新交付事實，不改功能／測試／圖表，既有驗證與成果 verdict 保持適用。Draft PR 後的下一個產品動作由 Human review 決定。


## Blockers

- 無未解除 implementation blocker。AH-02 planning approved、AH-04 verification completed、AH-05 correctness review approved；AH-06 已交付 Draft PR，等待 Human review。
- AH-03／AH-04／AH-05 evidence 已分開記錄。任何後續 failure、allowlist gap 或 locked decision 衝突如實列出。
- Archify 不通過交 needs-rework；PR Lens／Graphify 可依 plan 如實 fallback，不能把 fallback 記成 tool passed。

## Human Check

- 使用者已接受本 topic 完整計畫，本輪明示「請直接 commit by topic」，明確授權 feature worktree → implementation → topic commit → push → Draft PR → human review；不是 gate approval，不重複要求已授權 commit 許可。
- AH-02／AH-05 只有獨立角色明示 approved 才能前進；blocked／human-check 停止，needs-rework 交回適當角色。
- AH-06 Draft PR 建立後必須停在 Human review；不得自動 merge／release。

Dispatcher 交接環境證據：Swift 6.3.3、Graphify 0.9.73、PR Lens 0.11.0 可用；gh auth 在 network-enabled 環境有效，sandbox 先前的 invalid 屬連線限制。無 graph，仍採 targeted source fallback；本 topic actual verification evidence 見 AH-04 handoff。

## Last Updated

2026-10-12 — Implementer 記錄 topic commit／non-force push／Draft PR #51 與 committed PR Lens passed；AH-06 human-check，等待 Human review。
