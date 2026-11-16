# PAT store：Implementer 交接

日期：2026-11-16。分支 `feat/github-pat-dpk-storage`，基準 `5713025e3312c0fbc9a7b02a222db0b91d6e1b58`。本記錄對應尚未 commit 的 feature worktree 變更，不將基準 SHA 當作新程式版本。

## 受限變更

- 新增 `GitHubPATDataProtectionStore` 與有限 typed error、PAT 專用 internal Security seam，公開 actor／API／private JSON 依 technical-spec。
- 新增 fake Security tests；同一 fake 也接既有 OAuth adapter，以同 group／service 實際保存 OAuth configuration／credential 與 PAT，核對隔離及 namespace。
- 一般 import consumer 只建構 actor、驗 configuration、typecheck Sendable typed-throws load／save closures，不執行 closures 或真 Security。
- `StaticIsolationTests.swift` 只新增 store 的 expectedPaths／securityFiles 兩處白名單。
- 既有 OAuth store／PAT VO／package graph 無修改。E016／圖與長期文件由另一受限工作交付，不包含於本交接的已驗聲明。

## Swift TDD 證據

1. Red：先新增 PAT 往返／替換測試與 fake，執行 `swift test --filter GitHubPATDataProtectionStoreTests`，exit 1。編譯錯誤為缺少 `GitHubPATDataProtectionStore` 與 `GitHubPATSecurityClient`，可歸因於尚未實作；不是套件或主機故障。
2. Green：新增正式 actor 後，相同命令 exit 0，初始 1 test 通過。
3. 擴充 TC01–04：嚴格還原、讀取失敗零寫入、nil Data、有限錯誤、完整 query／accessibility、OAuth／legacy 隔離、同實例序列化、add／update／duplicate 各終端失敗、診斷遮蔽。測試不以 sleep 推測並行。
4. Formatter／lint 對 fake 的多協定宣告有不同排版要求；改用獨立 conformance extension 後兩者均通過，未變更產品契約。

## 已執行驗證

| 命令 | 實際結果 |
| --- | --- |
| `swift test --filter 'GitHubPATDataProtectionStoreTests\|GitHubOAuthDataProtectionStoresTests\|StaticIsolationTests'` | 最終 exit 0，73 tests／5 suites 通過；包含 PAT、OAuth 與既有 PR Inbox／Reader static suites。 |
| `scripts/check-github-integration-consumer.sh` | exit 0，18 tests／4 suites 通過，含新增 PAT consumer suite。 |
| `swift format lint --strict`（四個本交接 Swift 檔） | exit 0，無輸出診斷。 |
| `swiftlint lint --strict --quiet`（新 store／PAT suite／PAT consumer） | 最終 exit 0，無輸出診斷。 |

本記錄不是獨立 Tester／Reviewer verdict。尚需獨立執行必要驗證、全交付範圍審查，以及之後 Human 的真 DPK／跨程序／重建／提示／清理驗收。所有受控測試使用 fake Security，沒有本題真 Keychain 呼叫、簽章操作或 live 通過聲明。

## 獨立 Tester required fix：白名單排版

Tester 發現新增白名單後，原已達長度門檻的 `StaticIsolationTests.swift` 為 802 行、該 function body 超過 80 行；不能以新三檔 lint 的成功代表整個修改集合通過。只將 expectedPaths 相鄰 store 字串合併同列，保留相同集合／兩處 PAT 白名單，不放寬 lint 或隔離規則。最終檔案 800 行。

修後親跑 `swift format lint --strict Tests/GitHubIntegrationTests/StaticIsolationTests.swift` 與 `swiftlint lint --strict --quiet Tests/GitHubIntegrationTests/StaticIsolationTests.swift`，兩者 exit 0、無診斷；`swift test --filter StaticIsolationTests` exit 0，48 tests／3 suites 通過。交回獨立 Tester 補驗；本段不是獨立 approval。
