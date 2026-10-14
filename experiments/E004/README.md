# E004：GRDB＋SQLite OAuth 儲存可行性

## 驗證什麼

- 實驗編號：E004；建立前確認 E001–E003 已占用，E004 未占用。
- 設計日期：2026-10-14。
- 主要問題：真磁碟 SQLite 的 GRDB adapter 能否接入既有 OAuthCredentialStore，支援 provider 的還原、刷新、原子輪替與失敗處理？
- 假設：完整 bundle 可原子保存且跨程序還原；保存失敗不發布新版，並維持既有 provider-local unavailable 契約。
- Branch：`chore/github-oauth-sqlite-store-feasibility`；以最新可得 dev 基線建立獨立 feature worktree。

本輪定位為依 feasibility-validation 進行的受限實驗；下列九欄是實驗的交接界線，不代表正式 SDD topic。
依已核定範圍，不為本輪新增四份正式 topic artifacts；正式 adapter 採用須另開 topic，於實作前建立其 requirements、technical-spec、plan 與 step。

`swift-implementation` 實驗交接契約：

| 欄位 | 本輪界線 |
|---|---|
| Goal | 驗證候選 SQLite 儲存與既有 provider lifecycle。 |
| In-Scope | GRDB adapter、假憑證／fetcher／clock、六情境、sequence 圖及本地 review 輔助。 |
| Out-Of-Scope | 真 GitHub／秘密、產品 UI、正式儲存、加密、sandbox、跨程序 refresh 協調。 |
| ReadOnly | 既有 runtime、ports、tests、package、架構、skills 與可得 graph／diff。 |
| Written | E004 的 package、source、tests、README、公開 evidence 及 diagrams；本次 PR review 另回寫 docs 的受限證據。 |
| Deleted | 無既有檔案刪除；只清理本次暫存 DB。 |
| Modify | 實驗實作限新增 E004 內容；本次 PR review 僅補正文檔定位及 OAuth 架構文件的 E004 證據小節。 |
| Non-Goal | 不改 public API、root 工具鏈、Keychain 或長期架構；不自動正式採用。 |
| TestCase | 下列 T01–T06。 |

## 為什麼

使用者選擇 GRDB＋SQLite 作候選後端，不代表正式採用。既有單 access-token Keychain 與完整 OAuthCredentialStore 是不同契約。
原始碼依據為既有 public OAuthCredentialStore、GitHubOAuthCredentialBundle、OAuthTokenProvider；本實驗不改 runtime。
[GRDB 7.11.1](https://github.com/groue/GRDB.swift/tree/v7.11.1) 提供交易、binding 與 connection ownership；
[Apple TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) 區分 legacy 與 Data Protection Keychain，不能泛稱 Keychain 都需付費。
文件可回答可行性，但不能證明此 adapter 與既有 runtime 的實際磁碟、跨程序及 rollback 行為，因此進行受限實驗。

## 成功與失敗判準

以下判準於執行前固定，不以 build/test green 代替觀察：

| 案例 | 成功觀察 |
|---|---|
| T01 | 程序 A 保存完整 bundle A 後結束；程序 B 逐欄讀回，未到期 snapshot 為 A 且 refresh=0。 |
| T02 | fake clock 到期後 fake fetcher 接受雙 token 都不同的 B；snapshot、磁碟及新程序皆為完整 B。 |
| T03 | 同一 provider 並行需求僅 refresh 一次、相同 snapshot；後續 stale unauthorized replacement 不再 refresh。 |
| T04 | 真 SQL 改寫 access 欄位、交易內確認部分變更可見，commit 前拋錯；重開後仍完整 A。 |
| T05 | fake accepted rotation B 後使用同一故障 seam；.persist、後續 terminal .persist、不再 refresh，磁碟仍完整 A。 |
| T06 | 空 store 是 missingCredential；壞 DB 讀取是 restore；唯讀寫入失敗傳出而非偽裝空 store。 |

- 成功：全部主要案例符合表列觀察。
- 失敗：可重現 mixed bundle、未保存即發布、terminal failure 後仍交付 snapshot，或 storage failure 偽裝 missing。
- 無法判定：相依、權限或環境阻止關鍵操作，或缺少跨程序／失敗路徑證據。
- 設定時間：2026-10-14，首次實驗執行之前。
- 投入上限：核心 runtime 60–90 分鐘；需改 public contract、真秘密或付費前提時停止；工具依各 skill 有限修復停點。

## 環境與前置條件

- 本機 Apple Swift 6.3.3、arm64 macOS 26.5.2（25F84）；實驗 tools 6.1、macOS deployment 15、GRDB 精確 7.11.1，lockfile 同時固定 Apollo 2.1.2。
- 本地 dependency 使用既有 GitHubIntegration；root tools 6.0 與 public API 不變。
- 真實條件：SQLite 磁碟、交易、GRDB、獨立程序、既有 provider。
- 模擬條件：所有 credential 都是假資料；fake fetcher 不呼叫 GitHub，clock 可控。
- 相依假設已在本輪確認：套件取得與建置成功、獨立 child 可啟動、暫存 DB 可讀寫。未驗證其他 compiler／OS。

## 重現步驟

從 feature worktree root 執行：

```sh
probe_scratch="$(mktemp -d -t rivet-e004)"
swift test --package-path experiments/E004 --scratch-path "$probe_scratch"
"$probe_scratch/debug/oauth-sqlite-probe"
swift format lint --strict --recursive experiments/E004/Sources experiments/E004/Tests experiments/E004/Package.swift
swiftlint lint --strict --no-cache experiments/E004/Sources experiments/E004/Tests
```

Probe 自行建立 UUID 暫存 DB 並於完成後清理；30 秒 watchdog 為 fake gate／child 等待設限。
T01 的 writer 與 reader 都是獨立 child，writer 結束後才開始 reader；T02／T04／T05 也由新 child 逐欄讀回。
T03 的 12 個 black-box demands 在 fake refresh 暫停時進入，觀察一次 refresh 與相同結果；未使用 runtime internal join hook，不能外推所有排程。
T04／T05 在實際 SQL 改寫且交易內可見後拋錯；T06 另確認 SQLite `SQLITE_NOTADB` 與 `SQLITE_READONLY`。

實際命令使用單一外部 scratch，指令形式如上；實際執行結果保存於 evidence/，不提交 DB 或 build artifacts。

## 是否成功

- 執行日期：2026-10-14。
- 實驗狀態：成功。
- 判準：T01–T06 均符合事前觀察，probe exit 0；6 個 Swift Testing tests 全部通過。
- 本輪驗證任務完成：是；已取得本機真磁碟、跨程序、rollback 與 terminal failure 證據。
- 此完成只表示受限驗證任務完成，不是正式採用核准；人類 review 仍 pending。

## 結果與證據

| 證據 | 內容 |
|---|---|
| [Runtime stdout](evidence/2026-10-14-runtime.txt) | T01–T06 實際結果、child 逐欄比較、refresh/save 次數與錯誤分類。 |
| [Runtime receipt](evidence/2026-10-14-runtime-receipt.json) | UTC 執行時間、exit code、模擬條件。 |
| [Swift Testing](evidence/2026-10-14-swift-test.txt) | 最終 6 tests 通過；路徑以相對 placeholder 遮蔽。 |
| [Red / Green](evidence/2026-10-14-red-green.md) | red 失敗摘錄、green 與 format/lint 結果及既有 build warning。 |
| [Sequence](diagrams/credential-sequence.html) | 候選實驗流程圖，非 runtime trace；保存成功／失敗為二選一。 |
| [Delivery receipt](diagrams/credential-sequence.delivery.json) | 9/9 showcase、specification／HTML SHA-256。 |
| [Visual evidence](diagrams/credential-sequence.visual-check.html) | 四尺寸 containment、light/dark 截圖；人工觀察見 visual-review。 |
| [Visual review](evidence/2026-10-14-visual-review.md) | 實際檢視四張截圖後的判斷，與工具 pending 欄位分開。 |

觀察：磁碟完整 bundle 往返成功；相同 provider 的本次 12 demands 只 refresh 一次。
已觀察真 SQL 的未提交部分變更；rollback 後新程序仍讀到完整 A。
fake accepted B 後保存失敗，同一 provider 的後續 snapshot／replacement 持續 .persist、沒有額外 refresh 或 save。

Graphify 0.9.73：建立前未找到可用 graph，因此依 skill 作 bounded source fallback，未 extract／安裝／修改 hooks 或 config。
PR Lens 0.11.0：在 commit 後依實際 base/head diff 於 repository 外 validate/render；不提交本地圖、不上傳、不自動修改設定。此圖供理解變更，不作 correctness reviewer。

## 結論與限制

本輪假設在上述本機條件成立：GRDB＋SQLite 可作完整 OAuthCredentialStore 的候選後端，並沿用既有 provider 的持久化與失敗契約。
偏好 Swift package 的方向可行；本次僅一個 adapter／單一 DatabaseQueue，不建立 app-wide ORM 層。

沒有驗證真 GitHub、登入／登出、client 401 retry、sandbox 隔離、加密、斷電 durability 或跨程序 refresh 協調。
SQLite 路徑名稱不提供秘密保護；舊 bundle 在 fake rotation persistence failure 後雖完整保留，不表示真遠端仍接受它。
完成後仍成立的受限觀察已回寫 [OAuth 架構文件的 E004 證據小節](../../docs/architecture/github-oauth-dual-client.md#e004-受限-sqlite-儲存與-provider-lifecycle-實證)；這是本次 PR review 的文件補正，不改既定架構或升格為正式 adapter。
正式秘密儲存、工具鏈最低版本、reconciliation 與正式採用須回原決策流程；本實驗不改長期架構。
下一步為 PR 的人類 review，再決定是否另開正式 adapter topic。
