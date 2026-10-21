# GitHub Account Login 可行性狀態帳本

- Topic：`github-account-login-feasibility`
- 最後更新：2026-10-21，Implementer；轉錄獨立 Plan-Reviewer 明示結果。
- 目前 phase：Human review
- 目前 step：H01／human-check
- 上游 verdict：獨立 Reviewer 明示 R01 approved，無 required fix；V01 TC01–TC05 已通過。
- [執行契約](github-account-login-feasibility.plan.md)；[需求](../../analysis/github-account-login-feasibility/requirements.md)；[技術依據](../../analysis/github-account-login-feasibility/technical-spec.md)。

## Steps

| ID | Status | Owner role | 完成條件 | Evidence | Blocker | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| P01 | completed | Plan-Creator | 在授權新文件 worktree 建立四份一致 artifacts，保留撤回與來源限制。 | 本 topic requirements、technical-spec、plan、step 已建立；僅編寫交接，未自審／測試。 | 無 | null |
| P02 | completed | Plan-Reviewer | 獨立審四 artifacts 的範圍、來源分類、manifest 與 workflow，明示 verdict。 | 獨立 Plan-Reviewer 已讀四檔並明示 approved：五文件範圍、來源 pin、撤回紀錄及順序一致，無必要修正；由 Implementer 轉錄。 | 無 | approved |
| D01 | completed | Implementer | P02 明示 approved 後，新增長期 docs 結論並回鏈 technical-spec，不改其他檔案範圍。 | 已新增 `docs/github-account-login-feasibility.md`；保留官方契約、90646c21 來源 pin／e941d88 執行版本區別、PKCE 限制及產品 B 撤回。 | 無 | null |
| V01 | completed | Tester | D01 交接後驗 TC01–TC05，報告 links／source pins／五檔 scope／無秘密與本機絕對路徑；不新增測試或實驗。 | 獨立 Tester 親跑 inline Python／唯讀 Git：五檔聯集、15 相對連結、6 唯一固定 permalink 的 object／行號、證據分類與敏感資訊檢核通過；無 required fix。詳下方 V01 紀錄。 | 無 | null |
| R01 | completed | Reviewer | 獨立審查五文件與 Tester 證據，明示 verdict，要求修正交適當角色。 | 獨立 Reviewer 已讀五檔及 V01，確認五文件聯集、來源版本及觀察／推論界線，明示 approved，無 required fix；不代稱後續工具與發布完成。 | 無 | approved |
| G01 | completed | Implementer | R01 approved 後檢 staged 語意／message，按既有授權 commit、push、開 Draft PR；以真實 base／head 五文件 diff 嘗試 PR Lens 本機 validate／render，記結果或具體 fallback，不 merge。 | 主提交 `c9063ebe6c1c18c256c978c0cb092705423cc38d` 已 push；Draft PR #63 已建立；hooks 全過，主提交 PR Lens validate／render 成功。詳下方 G01 實際紀錄；本筆為收尾帳本。 | 無 | null |
| H01 | human-check | Human | Draft PR 交付後由 Human review；agent 停止，不自行 merge。 | [Draft PR #63](https://github.com/a129924/rivet/pull/63)，base dev；待 Human 決定。 | Human review 待進行，不是自動核准 | human-check |

## Blockers

目前無阻止文件交付的外部 blocker。P02／R01 的獨立 approval 與 V01 文件驗證已記錄；最終停於 H01 Human review。GitHub keyring auth 已確認可用，sandbox 初次失敗不是 token invalid。

PR #61 的歷史 P／Q／R 人審或 indeterminate 不作本 topic 前置 gate。產品 B 與 S01–S06 已撤回，無待實作狀態。若需超出五文件 manifest 或新技術實驗，停止並交回 scope 決策。

## Human Check

H01 僅在 G01 實際交付 Draft PR 後生效。使用者本輪已明示 topic commit／push／Draft PR 授權，不重複要求相同確認；仍保留 staged 語意檢查、獨立審查及不 merge 邊界。P02–G01 已依序完成；當前到達 H01，等待 Human review，不自行 merge。

## 更新規則

各 owner 以實際成果更新 status／evidence；verdict 僅記對應獨立角色明示結果，未審為 null。不得把 completed、checkbox 或本帳本視為 approval；不虛構測試、來源檢核、工具 receipt、commit 或 PR URL。

## D01 Implementer 完成交接

- Goal：長期保存受限可行性與證據界線。
- Non-Goal：不恢復產品 B，不宣稱零配置 UX 或 PKCE enforcement 已驗證。
- In-Scope：新增長期 docs 並轉錄 P02／D01 實際狀態。
- Out-Of-Scope：Swift、App、實驗、真人 OAuth、其他 topic 及 dev worktree 改動。
- ReadOnly：固定 90646c21 原碼／紀錄、官方文件、既有 repo 文件。
- Written：`docs/github-account-login-feasibility.md`；本 topic 合計五份相對 base 的新文件。
- Modify：本新 step 文件的交接記錄；相對 base 無既有檔案修改。
- Deleted：無。
- TestCase：交獨立 Tester 檢核 TC01–TC05；此處不預填結果。

## V01 獨立 Tester 實際結果

2026-10-21。Tester 未參與五檔實作，以 inline Python、唯讀 `git status --porcelain --untracked-files=all`、`git diff --name-only <base>`、`git ls-files --others --exclude-standard` 及固定版本 `git show` 驗證；由 Implementer 如實轉錄。

- TC01–TC05 通過，required fixes 為空。
- tracked diff 與非 ignored untracked 的聯集恰為五份 manifest，當時五份皆 untracked；source／tests／apps／experiments／其他 topic 未變。
- 15 個相對文件連結均存在；18 個外部連結中的 6 個唯一固定版本 permalink，其檔案及行號可由 Git object 解析。外部 URL HTTP 可達性沒有由 Tester 重驗；使用呼叫端已完成的官方瀏覽與 GitHub pin 查證。
- 已核對 caller 配置、session／exchange 與 HTTP200／正 id／trim 後非空 login；保存 pin 90646c21 與 A07 執行版本 e941d88 分層正確。
- 未見憑證值、本機絕對路徑、trailing whitespace 或 EOF 問題；撤回 B、PKCE 限制與 PR61 非依賴均保留。
- 兩項初始自設字串重複檢查誤判已改為符合原契約的語義核對；未為此修改文件或改變實驗判準。本輪不是 OAuth 實驗。
- 未執行 Swift／產品／真人 OAuth，未把後續 commit hooks、PR Lens、push 或 Draft PR 預填通過。

本次只將 Tester 明示結果加入本新帳本；其餘受驗四文件 bytes 未變。V01 記錄當時獨立 Reviewer 尚待派遣，此紀錄不是成果 approval；後續明示結果另見 R01。

## R01 獨立成果審查

2026-10-21，Reviewer 明示 **approved**，required fixes 為空。已獨立讀取五文件及 V01，確認 tracked diff 與非 ignored untracked 聯集恰為五檔；無 source／tests／App／實驗改動。來源 pin、A07 執行版本及推論／觀察界線清楚；未把文件檢核當成 OAuth 或零配置 UX 實證。此 approval 不宣稱後續 hooks、PR Lens 或發布已完成。

## G01 實際發布紀錄

2026-10-21，依使用者本輪明示的 topic commit／push／Draft PR 授權執行，未要求重複確認。

- staged diff 為同一 topic 五份新文件，`git diff --cached --check` 通過，無其他 source／tests／App／實驗變更。
- 主提交：[c9063ebe6c1c18c256c978c0cb092705423cc38d](https://github.com/a129924/rivet/commit/c9063ebe6c1c18c256c978c0cb092705423cc38d)，message 為 `docs(github-account-login): 保存可行性結論與證據界線`，已 push 至 `docs/github-account-login-feasibility`。
- 此主提交既有 hooks 全部通過：trailing whitespace、EOF、Swift format、GitHubIntegration consumer contract、SwiftLint、renderer check。這些 checks 不是新的 OAuth 真人證據。
- [Draft PR #63](https://github.com/a129924/rivet/pull/63) 已實際建立，base `dev`，OPEN／Draft，未 merge；建立時 head 為上述主提交。
- PR Lens CLI 0.11.0 對真實 base `16606b89b8e3e6b61523c23aa0be9653c1ea7b44` 至上述主提交的五文件 diff：validate exit 0、render exit 0，3 lanes／7 nodes／7 edges／3 walkthrough steps／1 SVG。已讀回 manifest，其 headSha 與主提交一致；graph contentHash 為 `67c5ab9b2c426ae3357c61eee3cc34b5`，SVG contentHash 為 `375c90f3dfcac8973cae3646c9166d29`。
- `graph.json`、source diff／manifest 與 SVG 僅保存在外部本機暫存，未加入 repo 或上傳。這是主提交的實際收據，不冒稱尚未生成的後續 head；收尾發布會以實際最終 head 再產本機 map。
- Graphify 無既有 graph，維持定向 source fallback，未呼叫 CLI 或建圖；Archify 本輪不產圖。
- 本筆僅同步發布與 Human 停點，不改可行性結論、測試結果、產品 scope 或既有歷史證據；收尾提交仍限本 topic。

TC06 的 agent 文件交付部分已完成；Human 是否接受仍待決。不得把 Draft PR、hooks 或工具圖當成產品驗收或 PKCE enforcement 通過。

## L01 後續真人正向重驗

> **2026-10-21 更正（以此為準）：使用者隨後明確表示沒有遇到 GitHub 登入畫面，也沒有進行 GitHub 登入授權。L01「本輪新授權／正向重驗成功」判定撤回，狀態改為「無法判定」。以下原判讀只保留為已被更正的歷史，不是有效成功證據。**

- 狀態：成功；本輪受限正向重驗完成，不代表原 PR Human review 完成。
- Human 確認：本輪剛完成登入授權。
- agent 觀察：2026-10-21 06:15:08 UTC，`apiSuccess=true`、`busy=false`、`failureVisible=false`、`identityDisplayed=true`。
- 執行物：既有 App，binary SHA-256 `648435704a5a335040cb8abc6ad0f1841304500c4b9ab2dd96d79b1af7078a31`；路徑比對相符，未重建、不綁定未證實 source revision。
- 帳號、App 憑證、callback 與 raw HTTP 值均不寫入紀錄；沒有觸發額外授權、再次查詢或負向案例。
- 界線：Human 新授權陳述與 UI 結果各自標示；零配置 UX、PKCE enforcement 與原 Human-review 限制保留。
- Owner role：Human 負責新授權確認；Implementer 負責安全 UI 觀察與紀錄。
- 本次僅追加本 topic 五份文件，獨立 Reviewer 已明示 approved，無 required fix；按既有授權準備提交原 branch／Draft PR，沒有新 Swift、App 或實驗。

### L01 文件複核

獨立 Reviewer 已讀五檔 diff，明示 **approved**，required fixes 為空；`git diff --check` 通過，L01 連結 anchor 合理。Human 新授權、UI 布林、binary 指紋與原碼推論分層清楚，未見敏感原值或本機絕對路徑。此複核不代表 Human 已接受 PR，H01 仍待人類決定。

## C01 使用者更正後的現行狀態

- ID：C01；Owner role：Implementer；文件更正與獨立複核完成；commit／push 待執行。
- 使用者明確表示未遇到 GitHub 登入畫面，也未進行 GitHub 授權；L01 原「成功／完成」撤回，現行狀態為**無法判定**，本輪真人新授權驗證未完成。
- 當時 UI 四布林與 binary 指紋保留為觀察，不再作本輪新授權或新帳號查詢的證據；沒有足夠依據判斷畫面來源。
- 前述 L01 Reviewer approved 只記錄當時文件複核，所依賴的 Human 新授權前提已被更正，不能作現行 L01 成功背書；原 A07／V01／R01 的歷史範圍不擴張。
- 完成條件：五檔顯著撤回、關聯連結可解析、獨立複核、同一分支更正 commit／push 及 PR 讀回；尚未完成的發布不預填。
- 本次沒有再登入、授權、查帳號、清除憑證或 session，也沒有新 Swift／App／實驗。H01 PR Human review 保持待決，不 merge。

### C01 文件複核

獨立 Reviewer 明示 **approved**，required fixes 無；確認五檔撤回一致、現行狀態為無法判定、無畫面來源歸因或新 request 聲稱，C01 anchor 合理、`git diff --check` 通過。Implementer 的五檔更正標示、現行狀態、相對連結及本機路徑檢核亦通過。以上均為文件檢核，不是新的 OAuth 實證或 PR Human approval；發布結果以實際 commit／PR 讀回為準。

## M01 受限手動瀏覽器驗證增補（2026-10-21）

使用者於 C01 後明示授權本增補並要求開始。原計畫、A07、已撤回 L01 與 C01 均保留；本節不是產品 B 恢復。真人步驟尚未啟動，不能宣稱成功。

未知是「未登入且未授權測試帳號，能否在同一 session 完成登入、首次同意與有效帳號確認」。舊直接 callback 路徑不足以回答，故需要一次受限真人操作。工具現只有預設瀏覽器立即開啟；最小增補僅改 app-local opener，不改 runtime／relay／probe。E009 保存操作契約，操作前已核對所有已註冊 worktree 及歷史編號；E001–E008 占用。

工具修改沿用既有 feat/github-first-sign-in worktree；不建立或切換分支。既有四份未提交 first-sign-in planning 檔案不動、不 stage。feasibility artifacts 與 E009 留在本 docs worktree，兩個 diff 分開回填，不把文件 PR 當 Swift 成果。

設定契約尚未解：現有 App 僅畫面輸入及記憶體設定，未找到重建後的開發端注入來源；不擷取既有 process Secret、不新設儲存／注入方式、不要求 Human 手填憑證。此項解除前不停止現有 App、不啟動真人授權。

九欄：
- Goal：準備首次登入與首次授權的同流程驗證。
- Non-Goal：產品交付、production custody、PKCE enforcement、新協定。
- In-Scope：手動模式建立 session／listener、只在記憶體發布本次網址供 App 複製；保留自動方式；必要局部測試、受限 build 及紀錄。
- Out-Of-Scope：apps/Rivet、正式入口、OAuth runtime、cookies／憑證／授權清理、反向 PKCE、自動重試、其他 topic planning 變更。
- ReadOnly：runtime、relay、probe、credential store、project 設定與既有未提交文件。
- Written：experiments/E009/README.md；沒有新 source 檔案。
- Modify：本 topic 四 artifacts；另一既有 feature 的 apps/GitHubSignInVerification/Sources/GitHubConnectionCoordinator.swift、GitHubConnectionView.swift、GitHubSignInVerificationApp.swift、GitHubConnectionPresentation.swift，以及 Tests/GitHubConnectionCoordinatorTests.swift、GitHubConnectionPresentationTests.swift。
- Deleted：無。
- TestCase：manual 不開瀏覽器、同一 await 授權完成後才 probe、不能併發再啟動、取消／拒絕／逾時清理；auto 保留；四項真人結果分開記錄，設定未解即不執行。

執行判準：一次授權啟動，最多 300 秒；取消、拒絕、錯誤或逾時立即停止，不重試。Human 親自確認看到登入頁、完成登入、看到並同意授權；再加同流程有效帳號結果四項齊備才成功。直接 callback 僅支持返回路徑；build／tests／callback 或舊成功畫面均不足。

Graphify 無現有 graph，以定向 source 查核，不建圖。流程文字足夠，Archify N/A。PR Lens 僅對後續實際凍結 diff 本機產出，不發布；未產生不預填。授權網址與 credential／callback／帳號原值不進 log、文件或對話。

### M01 執行帳本

- ID：M01；status：planned；owner role：Implementer。
- 完成條件：四 source／兩 tests 的局部實作、mock 測試與 build、獨立 Reviewer 完成；actual diff／checks 回填後才能稱工具準備完成。
- 證據：唯讀 source 已確認只有自動 opener；工具準備尚未實作／測試。預先保存另 worktree 四份既有 dirty planning 指紋，確保不改動。
- Blocker：開發端設定交接未確認；build 準備可進行，但真人流程不可開始，也不停止舊 App 或讀其 Secret。Human 另須在啟動前確認獨立 browser session 未登入、測試帳號未授權此 App；不確定即不啟動。
- Human Check：原 H01 PR review 保留。M01 新操作到設定與帳號前置確認處停止，不能用 agent build／tests 替代。
- planning review：首次 needs-rework 兩項（帳本欄位與獨立 session 前置確認）已補正，待獨立回查。

M01 獨立 planning 回查 verdict：**approved**，required fixes 無；僅核准受限工具準備。兩項初審修正完成；設定及 Human 帳號條件未解前不啟動真人流程，不停止舊 App。局部 TDD 開始，實際結果待回填。

### M01 actual diff 與受限準備結果

- 本次 Modify 實際為另一既有 feature 的四 source（coordinator／presentation／view／App）與兩 tests（coordinator／presentation），與預定六檔一致；runtime／relay／probe／store／project／scheme 無改。本 docs worktree Modify 為四份 feasibility artifacts；Written 為 experiments/E009/README.md；Deleted 無。
- TDD red：build-for-testing exit 65，缺少手動啟動、copy dependency／presentation 等新成員；另有依賴新 signature 的 compiler diagnostic，未將其當真人證據。green：獨立 DerivedData 的 build test exit 0。
- 獨立 Tester 親跑 test-without-building exit 0，14 個 test definitions／15 次案例執行通過，0 failed／skipped；六檔 strict format 與 SwiftLint --no-cache exit 0。首次 lint 報 0 violations 但 cache 寫入遭拒，不計通過；後續無 cache 檢查已解。測試只用 mock，不驗真人或實際剪貼簿。
- 獨立 Reviewer：bounded code review **approved**，required fixes 無。同一次 session／relay 與原 300 秒 timer 保留；manual 不自動開 browser，單輪 guard、取消與結束清理複製入口；auto 保留。這不是 Human 操作許可或產品 approval。
- 六檔 bounded diff SHA-256：`fee0d2f958588a476892a31c4edc3d6dca4faf22dd2dd885c5a72212d2dbe1e6`；以私有 source-manifest 固定六檔內容，未把它冒稱新 commit／PR head。
- 並行變更：四份原有 first-sign-in planning 初查 4/4 指紋符合，末查全部與 baseline 不同。Main／Tester 未寫這四檔；來源尚未確認，不能聲稱整個 worktree 未變，也不歸入本輪 diff。已停止 source mutation／build／發布，未覆寫、stage 或還原這些內容。
- PR Lens 0.11.0：已凍結本機六檔 bounded patch 與內容指紋；validate 因未提交快照沒有 base/head provenance 而失敗，未捏造 head SHA、未 render／發布。fallback 為本機 source-diff.patch／manifest；不宣稱圖產出成功。Graphify 維持 source fallback；Archify N/A。
- 舊 App process 仍可辨識存在；沒有重啟舊 App、擷取設定、開真人授權、清除 cookies／憑證或撤銷授權。新入口已 build／mock 驗證，但尚未在真人用 App 載入。
- M01 工具準備完成；status：human-check。真人前仍須確認開發端設定交接、不共用登入狀態的 session，以及未授權測試帳號；來源不明 planning 並行變更需在發布前協調。設定未解前不要求 Human 填憑證或啟動 session。
- E009 狀態仍為**未執行**；四個真人觀察均未執行。原 A07、C01、PKCE 限制、產品撤回及 H01 均保留。未 commit／push 本次 source 或文件，也未更新任何 PR 為已完成。

## M02 開發端設定查核與具體待決方案（2026-10-21）

本節是尚待 Human 接受的增補，不是已實作的設定來源；M01 手動入口、A07、C01 與原限制保留。沒有啟動 OAuth，也沒有從舊 App 讀取 Secret。

### 唯讀查核結論

- 現行 SignIn App 的 composition 只讀 unit-test-mode 環境旗標；coordinator 的配置欄位初始為空，既有方式是畫面輸入、程序內記憶體。Shared Xcode LaunchAction 沒有 App 設定注入；VS Code 只有 Reader harness 啟動設定。
- public GitHubOAuthAppConfiguration 只接受 caller-provided ID／secret 並提供 redaction，不提供設定來源。
- 另一 persistent-connection 驗證 App 有 configurationStore，但綁 DPK group／service、signed host 與 embedded profile；credential-persistence 分支也有 explicit entitled access-group 的 shared store。這些不等於目前 ad hoc SignIn App 的可用設定來源；未讀 Keychain 內容，也未採用其 persistence／簽章契約。
- 歷史 E001 為 CLI client ID argument；E002／E003／PKCE 工具為 Human 互動輸入。它們不提供已備妥的 App 設定，且負向 PKCE 額度不動用。沒有讀取 env secret、私有設定檔、process memory 或舊 App secure field。
- 開發端仍須擁有有效的測試 OAuth App 配置；此方案只定義供給管道，不會產生或取得真實憑證，不能以 mock 代替。

### 唯一提案：一次性本機開發端啟動器

由擁有測試 OAuth App 的開發端管理者，在其本機非 agent 錄製的互動終端執行 E009 啟動器，以隱藏輸入提供既有 ID／secret；本輪登入驗證者不填這些資料。啟動器只以 app bundle 位置作命令參數，透過 NSWorkspace.OpenConfiguration.environment 啟動已核對的新版 bundle，使用兩個僅供此工具的程序環境 key：RIVET_VERIFY_GITHUB_CLIENT_ID／RIVET_VERIFY_GITHUB_CLIENT_SECRET。不可經 shell 字串、open --env 參數、scheme 檔或環境 dump 傳遞。

新版 App composition 讀取完整配對、建構既有 typed configuration，直接交給 coordinator；已配置時畫面僅顯示已準備，不展示配置值或要求輸入。缺值、半套、空白或 unit-test mode 不啟動真人能力；不從舊 App／Keychain／Token fallback。設定只存於 launcher 與 App 的程序記憶體／環境，不新增應用層持久化；不承諾 OS 不會留下痕跡或字串可安全抹除。退出後需由開發端再準備，不自動重啟／授權。已核對本機 SDK：OpenConfiguration.environment 只適用新程序；launcher 若發現同 bundle 已在執行便安全停止，不使用 new instance。切換時須先核實並結束指定舊 App，再由開發端準備新版啟動；不從舊程序搬移設定。啟動完成後，還須核對 NSWorkspace 回傳 App 的 bundle identifier、canonical bundle／executable 路徑及新 PID，確認與預期新 bundle 一致且不是啟動前程序。若重用既有程序、身分不符或無法確認，停止並不啟動 OAuth；不得只以 launch completion 判定設定已載入。

### 九欄與預定檔案（待接受）

- Goal：用明確的開發端供給管道解除新版工具設定缺口，使真人驗證者只負責 GitHub 登入與同意。
- Non-Goal：取得／產生憑證、產品登入、Secret store、DPK／Team／profile 變更、多帳號、persistence、新協定。
- In-Scope：一次性 launcher 與 app-local composition 配置接線、最小 mock tests；沿用 M01 manual session／listener。
- Out-Of-Scope：dev、apps/Rivet、OAuth runtime／relay／probe、另一工具的 storage、並行 PKCE 工作及其 planning、讀舊 App Secret。
- ReadOnly：既有 source 契約、schemes／launch 設定、相關 store 原碼及 source worktree 的其他變更。
- Written：只預定 experiments/E009/LaunchVerification.swift；不建立含配置的檔案或新 store。
- Modify：feat/github-first-sign-in 既有 apps/GitHubSignInVerification/Sources/GitHubSignInVerificationApp.swift（環境解析）、GitHubConnectionCoordinator.swift（typed configuration 注入）、GitHubConnectionView.swift（已配置狀態）、Tests/GitHubConnectionCoordinatorTests.swift（配對／缺值／test-mode／不顯示敏感值測試）；需要 presentation 狀態時才沿用既有 GitHubConnectionPresentation.swift 與其 test，不擴大 target／project。feasibility 四 artifacts 與 E009 README 只追加契約及實際結果。
- Deleted：無。
- TestCase：完整配對可注入；缺值／半套／空白安全拒絕；unit-test mode 零 live；未配置不啟動；已配置畫面不要求憑證；launcher 無秘密 args／檔案／log，錯誤有限分類；既有 App 在跑即拒絕、回傳錯誤 bundle／路徑／舊 PID／無法確認身分均拒絕；manual／auto 舊測試保留。真實供給與 UI 不由 mock 通過代替。

此工作排除「新版如何取得開發端配置」的具體缺口；現有欄位與另一 storage 契約不足以滿足本輪免手填且不擴張架構的要求。此新增注入契約尚待接受，未實作／build／測試。

### Worktree／Human 操作停點

source branch 仍為 feat/github-first-sign-in，feasibility 文件仍為 docs/github-account-login-feasibility；沒有建／切／推分支。M01 受審六份 Swift 指紋重查吻合；其他 planning／PKCE scripts／fixtures 的並行變更不歸入本輪，不覆寫、stage、commit 或執行。dev clean。

方案接受後完成必要實作／獨立檢查；開發端供給到位才切換新版。接著先提示 Human 準備不共用登入狀態且未登入 GitHub 的獨立 browser session，以及尚未授權此 App 的測試帳號；取得本輪 ready 後才啟動一次 session／listener及最多 300 秒等待。Human 從工具複製並貼上網址，親自登入／2FA／同意。取消／拒絕／錯誤／逾時停止不重試。四項觀察（看到登入、完成登入、看到並同意授權、同流程有效帳號）分別記錄，齊備前不宣稱成功。原 H01 保留。

### M02 提案審查與目前停點

ID：M02；status：human-check；owner role：Human（方案決定），Implementer（後續受限接線）。獨立提案審查 **approved**，required fixes 無；來源追溯與 launcher 啟動後身分核對已補齊。這不是 Human 接受新注入契約，尚未實作／測試 M02，未切換 App／啟動真人授權。完成條件為先取得對具體一次性本機方案的接受，再按 planned paths 實作並獨立檢核；設定供給及 Human browser／帳號 ready 未到位前不啟動 OAuth。不再要求 Human 提供抽象交接方式或貼任何憑證值。原 H01、C01 與 E009 未執行狀態不變。

### M02 Human 接受與實作進度

Human 已明示接受唯一的一次性本機方案。實際新增 experiments/E009/LaunchVerification.swift；app-local composition、coordinator、view、presentation 與既有 coordinator tests 已接線，M01 行為保留。沒有修改 runtime／relay／probe／store／project／scheme、另一工作的 PKCE scripts／fixtures 或其 planning；不新增 Secret storage。

TDD red 缺 Composition／init 接線；green build test exit 0。launcher synthetic self-test exit 0，live_launch_performed=false、credential_input_performed=false；嚴格格式與 lint 已通過（首次可失敗的字串解碼 lint 已修正為無效 UTF-8／過長輸入拒絕）。binary SHA-256 為 990917ac41d5543f342b6f32bc45daf8c665e44a67fa7d82e2da6379ec74e877，固定於 launcher；六檔 source bounded patch hash 為 a32959904d15c552bde67c676d68bc798e377f04d82498d23117e5f868651914。這是未提交工作快照與本輪 build，不冒稱新 head commit。

獨立 Tester／Reviewer 正在核對，未預填通過。真實設定尚未供給、App 未切換、OAuth 未啟動；操作指令與 Human ready 順序見 E009。所有原歷史與 C01 保留；H01 未通過、不 merge。M02 實際 Written=一個 launcher；Modify=本 topic 四 artifacts／E009 README，以及已授權六檔 Swift 的必要接線；Deleted=無。其他並行變更不混入本輪發布，尚未 commit／push。

### M02 獨立 Tester 實際結果

Tester 親跑 test-without-building exit 0，親讀 xcresult：17 個 test definitions／18 次案例執行通過，0 failed／skipped。六份 App Swift 與 launcher 的 strict format、SwiftLint --no-cache 全過；helper synthetic self-test exit 0，沒有 credential input 或 live launch。readonly preflight exit 0，當下 inventory 未觸發 existing-app guard；不能宣稱已實測「舊 App 在跑時拒絕」，該案例僅 synthetic pass。正式 runtime／relay／probe／store／project／scheme 無改；受驗六檔與 helper 指紋穩定。required fixes 無，待獨立 Reviewer。沒有讀 UI／Secret、沒有真實配置、真人 OAuth、App 切換或 PKCE 操作。

### M02 準備交付與真人前停點（現行）

M02 bounded code review：**approved**，required fixes 無。已獨立檢查配置缺漏／test mode 禁 live、配置後隱藏憑證欄位、TTY／binary／程序身分檢查與有限錯誤輸出；不代表 Human ready、真實配置載入或 OAuth 成功。結合獨立 Tester 的17 definitions／18 executions pass，設定機制準備完成。

Actual：Written 唯一 experiments/E009/LaunchVerification.swift；M02 source Modify 為既有 App composition／coordinator／presentation／view 及 CoordinatorTests 五檔；M01 PresentationTests 沿用未再改動，仍納入六檔回歸檢查。文件 Modify 為 feasibility 四 artifacts 與 E009 README；Deleted 無。runtime／relay／probe／store／project／scheme、dev 及並行 planning／PKCE 工作不屬本輪改動。所有本輪 source／文件尚未 commit／push。

現行 status：human-check。下一個實際前置是 OAuth App 開發端管理者依 E009 的具體命令，在其本機非錄製終端經 launcher 準備設定；不得要求本輪登入驗證者提供憑證，也不從舊 App 取得。管理者未供給前，工具準備成果不能冒稱「真實設定已到位」。

工具必須顯示「開發端設定已準備」，再由 Human 確認獨立 browser session 未登入 GitHub、測試帳號未授權此 App，並回覆本輪 ready。這三項未全備前，不啟動 session／listener，不開始300秒計時。之後按 E009 六步操作，四項真人觀察分開記錄。原 A07、C01、H01、產品撤回及 PKCE 限制均不變；E009 真人狀態保持未執行。

## M03 本輪真人結果與文件交接（2026-10-21，現行）

- ID：M03；owner：Human（操作與確認）、Implementer（來源核對與保存）。E009實驗狀態：**成功，受限於Human證據層級**；本步文件保存已完成，獨立Tester／Reviewer尚待執行，不預填approval。
- 完成條件：核對五項回報與三項前置／同輪答覆、追加六份文件、獨立審查、實際文件commit／push／Draft PR讀回；Human PR review另列H01。
- 證據：Human五項與三項補充全已收到，四個主判準成立；當下process executable路徑及binary與受驗snapshot相符。分層、限制與操作回報見[E009 M03](../../experiments/E009/README.md#m03-本輪手動真人驗證結果2026-10-21現行)。
- 限制：無agent全程UI觀察或network trace；精確起訖、歷史PID關聯、設定供給／互動launcher、啟動前主對話ready與2FA提示未獨立確認，不補造或重跑。
- 變更紀錄：本次只追加四artifacts／長期docs／既有E009 README；code與launcher未改，不stage並行source／planning／PKCE工作。先前未執行狀態是當時歷史，不覆寫；C01對L01撤回不變。
- status：文件驗證待執行；H01維持human-check。受限成功不放行產品採用、custody、PKCE或merge。

### M03 獨立 Tester 結果

Tester 明示 required fixes 無：四主判準及三前置／連續性確認均有 Human 來源；22 個相對連結與其中7個anchor可解析。四個關鍵session／relay／probe／store檔案從9f603f81至當時HEAD及工作目錄無diff；六Swift／launcher／binary八項指紋符合M02snapshot。六份文件未見原值或本機絕對路徑，發布manifest排除launcher與另一worktree所有變更。沒有把以前M01／M02 pending文件全歸為本輪新增。這是文件檢核，沒有新真人OAuth／UI／build；交獨立Reviewer，不自填approval。

### M03 獨立 Reviewer 結果與發布交接

Reviewer 明示 **approved**（M03 文件成果審查），required fixes 無。已確認六文件分開 Human／原碼／agent 現況、保留A07／C01／歷史，受限成功不擴張trace／產品UX／PKCE；staged恰六份文件且排除launcher。此approval不代表Human接受PR。依先前topic交付授權準備文件commit／push／同一Draft PR；尚未完成的Git／hooks／工具圖不預填，發布結果以實際commit與PR讀回為準，H01不merge。

### M03-G01 實際文件發布與 Human 停點

2026-10-21，文件提交 `1705e339f1ee023d334fb7b38cc414976592b1c7`（docs(github-account-login): 記錄 E009 真人驗證與證據界線）已實際push。staged六檔全為Markdown，launcher／另一worktree Swift及並行工作未納入。六項hooks全過：whitespace、EOF、Swift format、consumer contract、SwiftLint、renderer check；不當作新OAuth證據。

[Draft PR #63](https://github.com/a129924/rivet/pull/63)已更新並讀回：base dev、head為上述主提交、changed_files=6、Draft=true、merged=false。PR說明區分Human回報／原碼推論／agent現況；保留C01與缺口，不把產品或PKCE當通過。

PR Lens 0.11.0 對實際 base `16606b89b8e3e6b61523c23aa0be9653c1ea7b44` 至主提交的六文件diff：validate／render exit0，3 lanes／8 nodes／8 edges／3 steps／1 SVG；manifest headSha吻合，graph contentHash=81e29102de81f3cb92e7bce841d9ea6b。產物只在外部本機暫存，未上傳；此為主提交收據，後續帳本提交的map需按真正最終head更新，不冒稱此hash屬後續版本。

M03文件驗證、獨立審查及主提交發布完成；E009受限成功之證據資格不變。當前停在H01 Human review，Human尚未接受PR，不merge。此後僅同步本筆已發生的發布紀錄，按原topic授權提交／push，不新增真人操作。

## M04 將驗證程式碼交付到同一 PR #63（2026-10-21 增補）

Human 明示「直接到 #63，不要再開新的」。因此前輪文件-only交付限制在本節受限放寬；歷史M01–M03／A07／C01不覆寫，仍不交付產品登入。沿用目前既有PR head分支／worktree，不建立、切換、改名或另開PR；docs前綴是既有PR歷史名稱，本輪內容已擴為可重現的驗證工具，PR title/body將依最終內容更新，不把原docs分支當新功能分支建議。

依賴查核：此head尚缺五個既有OAuth配置／factory／session／exchange/error檔。只帶手動入口不能編譯，因此從固定9f603f81d77040a2e06ad178062e8cfecc4de468原樣重用五檔與必要測試，不重寫runtime、不依賴PR61合併。App完整host亦取同pin，但六份M01/M02受驗Swift按已核對工作快照帶入。原source worktree完全唯讀；其中PKCE工具、判讀fixtures、其planning或其他並行更動不帶入。不cherry-pick／merge整條分支。

### 預定九欄與檔案

- Goal：讓PR63包含可建置／測試的驗證host、M01/M02入口、一次性啟動器及必要既有OAuth依賴，補足重現性。
- Non-Goal：產品入口、runtime新設計、PKCE／refresh401真人重跑、Secret store、PR61依賴或merge。
- In-Scope：下列精確manifest的原樣搬入、局部建置／測試、啟動器對本PR產物重凍結及操作文件、長期現況同步。
- Out-Of-Scope：apps/Rivet、其他BC、PKCE tools／人工判讀／fixtures、原source worktree寫入、dev、任何新真人授權。
- ReadOnly：固定來源與M02六檔snapshot、原source worktree其他變更、現有runtime/lifecycle/transport、秘密與執行中App不讀取。
- Written：下列新增runtime五檔／root tests三檔／App host十六檔、既有未追蹤E009 launcher納入Git、docs/architecture/github-first-sign-in.md；共26新tracked paths，actual待回填。
- Modify：既有root consumer/isolation tests兩檔；本topic四artifacts／長期docs／E009README與README、design-principles、architecture overview、OAuth dual-client現況文件，共12 paths；原source worktree零寫入。
- Deleted：無。
- TestCase：root OAuth/隔離測試、跨target consumer、App hosted mock suite、strict format/lint、launcher synthetic與新binary指紋／source清單／秘密掃描；不將重建或mock當M03真人重跑。

### 精確重用 manifest

- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuth.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthAuthorizationError.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthAuthorizationSession.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Sources/BoundedContexts/GitHubIntegration/OAuth/GitHubOAuthCodeExchanger.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Tests/GitHubIntegrationTests/GitHubOAuthAuthorizationSessionTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Tests/GitHubIntegrationTests/GitHubOAuthCodeExchangerTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Tests/GitHubIntegrationTests/GitHubOAuthFactoryTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.pbxproj`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj/xcshareddata/xcschemes/GitHubSignInVerification.xcscheme`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Resources/Info.plist`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Sources/GitHubAccountProbe.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Sources/GitHubConnectionCoordinator.swift`（live-M02）
- `apps/GitHubSignInVerification/Sources/GitHubConnectionPresentation.swift`（live-M02）
- `apps/GitHubSignInVerification/Sources/GitHubConnectionView.swift`（live-M02）
- `apps/GitHubSignInVerification/Sources/GitHubLoopbackCallbackRelay.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Sources/GitHubSignInVerificationApp.swift`（live-M02）
- `apps/GitHubSignInVerification/Sources/InMemoryOAuthCredentialStore.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Tests/GitHubAccountProbeTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Tests/GitHubConnectionCoordinatorTests.swift`（live-M02）
- `apps/GitHubSignInVerification/Tests/GitHubConnectionPresentationTests.swift`（live-M02）
- `apps/GitHubSignInVerification/Tests/GitHubLoopbackCallbackRelayTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）
- `apps/GitHubSignInVerification/Tests/InMemoryOAuthCredentialStoreTests.swift`（9f603f81d77040a2e06ad178062e8cfecc4de468）

其他兩個新tracked paths為 experiments/E009/LaunchVerification.swift 與 docs/architecture/github-first-sign-in.md。既有docs只更新對應能力現況，保留deferred產品UI／持久化及證據限制。新架構文件只記既有契約與app-local新增入口，不搬入另一topic diagrams／PKCE資料。未新增boundary或流程設計，Archify本輪N/A；Graphify無可用圖定向查source；PR Lens依實際新base/head凍結本機重製，不發布。

### 執行／交接

ID：M04；status：planned；owner：Implementer。完成條件為獨立plan-review、精確搬入、Tester／Reviewer、topic commit／push到同一PR63、PR實際diff／title／body讀回；actual九欄／來源相等檢查回填。新build不追溯替代M03 binary990917ac的歷史結果；launcher需核新binary重新凍結，M03不重跑。Human review H01不自動通過，不merge。

### M04 搬入與建置 actual（2026-10-21）

M04 planning 已由獨立 Plan-Reviewer 明示 approved、無 required fixes；Implementer 已原樣搬入清單 26 檔：20 檔 byte-for-byte 取固定 `9f603f81d77040a2e06ad178062e8cfecc4de468`，6 檔先核對 M02 SHA-256 再複製。來源 worktree／dev 零寫入，未攜入 PKCE tools、fixtures 或另一 topic 文件。新增聚焦初次登入契約與既有 E009 launcher，更新本節授權的現況文件；未啟動真人 App 或 OAuth。

Implementer 檢查：host `xcodebuild test` exit 0（17 tests／5 suites）、正常 host `xcodebuild build` exit 0、root `swift test` exit 0（275 tests／34 suites）；strict Swift 6 launcher compile／synthetic self-test exit 0，輸出明示無 live launch／credential input。launcher 另以 `_ =` 明確丟棄清零操作回傳值，消除既有 unused-result warning，未改啟動／憑證邏輯。六 hooks 與局部 lint／format 結果另於最後檢查紀錄回填。

本 PR 新 build binary SHA-256：`781e1413dfae1f14ef46369c65c82435c76f7aebcee1154e452bcd671aae7153`；launcher expectedBinarySHA256 已更新至此值。這是 M04 本機重建，不替換 M03 的 `990917ac41d5543f342b6f32bc45daf8c665e44a67fa7d82e2da6379ec74e877` 歷史真人指紋。獨立 Tester／Reviewer 與同 PR #63 Git 交付尚待進行，未 commit、push 或 merge。

#### M04 現行執行狀態

目前 phase：M04 驗證交接；M04 aggregate 為 in-progress，不冒稱包含獨立審查與發布的整步已完成。Human 明示同 PR #63 的 M04 授權容許本次工作，舊 H01 不提前阻斷；實際 Draft PR 更新後仍停於 Human review，不 merge。

| ID | Status | Owner | Condition | Evidence | Blocker | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| M04-P | completed | Plan-Reviewer | 獨立審 M04 精確範圍 | 已明示 approved、無 required fixes | 無 | approved |
| M04-I | completed | Implementer | 原樣搬入、文件同步、build／局部檢查及 actual 回填 | 本節及 E009 M04；最後檢查結果另記 | 無已知實作 blocker | null |
| M04-V | planned | Tester | 獨立核對 38 paths、來源／指紋、建置與文件證據 | 待獨立 Tester | 待派遣 | null |
| M04-R | planned | Reviewer | 獨立審 code／scope／證據，明示 verdict | 尚未執行 | 前置 M04-V | null |
| M04-G | planned | Implementer | 審查後 bounded commit／push 同 PR #63，更新 title／body／實際 diff 與工具收據 | 尚未執行 | 前置 M04-R approved | null |
| H01 | pending | Human | 實際 PR 更新後人工 review | 未接受、未 merge | 前置 M04-G | null |

#### M04 Implementer 最後檢查收據

六項既有 hooks 全 pass：trailing-whitespace、end-of-file、Swift format、consumer contract、SwiftLint、renderer check。host／launcher 另跑 strict Swift format 與 SwiftLint（13 Swift files、0 violations），helper 以 `swiftc -swift-version 6 -strict-concurrency=complete -warnings-as-errors` 編譯及 `--self-test` 均 exit 0，無真人啟動或設定輸入。

實際範圍恰 38 paths：26 new、12 modified、0 deleted；26 reuse byte/hash 全相等，`git diff --check` clean，未見本機使用者絕對路徑或 GitHub token 格式原值。檢查只覆蓋指定檔案，不宣稱全面秘密偵測。外部本機 M04 log 包含 host test／normal build、root test、six-hooks、local-checks、scope-equality 與新 binary SHA，未納入 Git。所有內容未 stage／commit／push，交獨立 Tester／Reviewer；不產圖、不更新 PR、不 merge。

#### M04 Tester setup 與最終 build 重凍結（2026-10-21）

獨立 Tester 回報首次 hosted mock setup 缺測試產物，補 `build-for-testing` 後重跑：17 definitions／18 executions、0 failures；隨後 normal build exit 0。這是測試產物準備／重建，不是 source 修改，也不是新真人 OAuth。重凍結前已核對原 38 個 repo 檔案 SHA 全未改。

最終 bundle 已核為 `781e1413dfae1f14ef46369c65c82435c76f7aebcee1154e452bcd671aae7153`，與前次 launcher 凍結不符。現行 launcher 與 M04 build 指紋已同步至此最終值；前一 M04 normal build 指紋 `96ee9b8661850577495206e78c1db8114aa2489a50758f3f48cacff098b01170` 已被最終 build supersede，僅保留為歷史，不再作目前啟動依據。M03 `990917ac…` 的原始真人證據不變。

本修正不 rebuild、不讀秘密、不啟動 App 或 OAuth；只變更 launcher 指紋與本五份文件中的現行值／補充收據，26 reuse source／tests／project 仍原樣。修正後 helper strict Swift 6 warnings-as-errors 編譯、synthetic self-test、局部 strict format／SwiftLint 已 exit 0（0 violations）；文件 consistency／whitespace 與新版 frozen 38 收據保存在外部 M04 evidence，交 Tester 局部核對，尚未 commit。

#### M04 獨立驗證／審查完成與 Git 交付開始（2026-10-21）

Tester 已完成局部核對並解除 RF01：補測試產物後 17 definitions／18 executions、0 failures；最終 normal build 與 launcher／現行 M04 指紋均為 `781e1413dfae1f14ef46369c65c82435c76f7aebcee1154e452bcd671aae7153`，38 檔範圍及 26 reuse 相等。Reviewer 唯一 required fix 為 architecture overview 的舊「初次 authorization 未交付」敘述；已分開既有 initial factory／session／exchange 與 deferred 產品登入／持久化 adapter，局部複核後明示 **approved，required fixes=[]**。

現行：M04-V completed、RF01 cleared；M04-R completed／approved；M04-G in-progress。依既有 Human direct topic commit／push 與同 PR #63 授權，精確 stage 38 paths，staged 語意核對後提交；PR metadata 由主方後續更新與讀回，本 agent 不編輯 PR、不開新 PR。H01 尚未接受、不 merge。commit／push 真實結果另記，不預填 SHA 或發布成功。
