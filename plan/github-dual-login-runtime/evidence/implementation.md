# R03 Implementer 交接（受控證據）

日期：2026-11-17。角色：Implementer `/root/runtime_implementer`。工作branch `feat/github-dual-login-runtime`，base `1f31b35`；全部變更在feature worktree，未改dev、commit／push或執行live。

## Planning gate

獨立Plan-Reviewer `/root/artifact_reviewer` 的R02明示approved，required fixes 0；本記錄只轉述該結論，不以本Implementer自評替代審查。

## 產出

- 正式public Sendable GitHubLoginService／GitHubLoginCoordinator，internal dependencies供受控測試；既有public登入、stores、provider／scope／clients未改。
- 共用bare HTTP `/user` probe，既有Bearer純轉換、redirect blocker與有限回應驗證；驗證後才save，另一store保持。
- 正式OAuth session／exchange搭配新loopback relay及MainActor opener，10秒startup／300秒authorization；internal browser/session seam可控制測試，不新增public測試開關。
- Relay shutdown等待listener與accepted connections的cancelled事件；startup timeout可取消，connection handler在取消時解除持有。Worker取消轉傳並等settled，釋放coordinator後最後同步check且無await。
- 獨立可移除package `experiments/github-dual-login-runtime`，只使用public module，root Package.swift未改。CLI預設不操作，live雙明示且secret只hiddenTTY；不簽章、不delete。長期docs／README／架構導覽已同步。

## Red／Green 與命令

首次新增PAT ordering test後，`swift test --filter GitHubLoginServiceTests`出現missing GitHubLoginService／GitHubLoginCoordinator，證實目標能力未實作；同輪亦出現獨立baseline測試compile問題，不把該baseline錯誤算作runtime red。

Baseline相容性修補：既有PAT isolation fake conform OAuth Security port，但sign-out合併後缺delete requirement。僅在測試fake新增會Issue.record並回errSecUnimplemented的stub，任何誤呼delete仍失敗；未改正式port／store、未新增產品delete。

最新受控執行：

| 命令 | 結果 |
|---|---|
| `swift test --filter GitHubLogin` | 20 tests／4 suites passed，含參數化cases；0.020s test duration |
| `scripts/check-github-integration-consumer.sh` | 19 tests／5 suites passed；一般import、public service／sharedcoordinator Sendable construction，無network／Security |
| `swiftlint lint --strict`限定新runtime／tests／consumer／獨立入口 | 11 files，0 violations |
| `swift format format --in-place`限定新增Swift檔 | completed；Tester仍須親跑strict format驗證 |
| `swift build --package-path experiments/github-dual-login-runtime --scratch-path <owned scratch>` | build成功，13.63s；未執行binary |
| `git diff --check` | exit 0 |

測試涵蓋OAuth完整bundle、PATvalidate→save ordering、兩路各階段failure、probe malformed/status/transport/Bearer與無retry、pre／probe／save取消barriers、cleanup時overlap拒絕、release後重試。OAuth flow另以fake exchanger＋loopback-only HTTP驗invalid callback繼續、browserfailure、timeout、Task cancel後channel收尾；無真GitHub、真Security或簽章存取。

## 剩餘與限制

- Archify正式sequence／showcase／deliver／visual-check／人工看圖尚pending，交下一個bounded圖工作；本Implementer未產圖。
- Tester尚須在最終產出親跑root swift test、format、strict lint、consumer、獨立入口build及契約核對；本記錄不是獨立驗證。
- TC08真OAuth／PAT與fresh-process readback仍Human停點，未執行。CLI build不代表signed DPK host ready，也不把present單獨當完整identity／字段比對證據。
- PR Lens由主agent對真實commit base/head產出，尚未產生。Graphify無可用圖，使用限定rg／source核對，不自動建圖。

## R04 回修：維持窄範圍 static isolation allowlist

Root 獨立 Tester 親跑 root suite，358 tests／45 suites 僅 static isolation source inventory 與 import allowlist 出現三項 mismatch。這是新增正式 runtime 檔案後的預期清單維護，不放寬整個 module。

只在 `StaticIsolationTests.swift` 加入四個真實 Login source paths，Network 例外限 `Login/GitHubLoginCallbackRelay.swift`；RivetHTTPClient 例外限 `Login/GitHubLoginAccountProbe.swift`。其餘 forbidden imports／Security 限制、target graph與全部測試保留，沒有 skip／排除全量測試。Focused 回修驗證結果由下一行交接記錄。

回修驗證：`swift test --filter 'StaticIsolationTests|GitHubLogin'` 為68 tests／7 suites passed，0.869s；受影響兩檔strict format及strict lint均exit0、0 violations。靜態清單僅合併既有字串換行以維持原lint長度限制，未移除任何assertion或forbidden root。

同輪消除新CLI編譯觀察到的browser default closure warning：改為明示 `await MainActor.run { ... }`，保留MainActor開瀏覽器及取消檢查，不抑制warning或變更編譯設定；上述focused重跑包含OAuth flow測試且無新warning。未重跑全量或live，交獨立Tester重新確認最終tree。
