# E023 非同步請求生命週期與提交守門

## 驗證什麼

實驗 E023，設計日期 2026-11-24。建立前已查本地目錄、索引與可達 Git 歷史。問題是被取代或取消的 Task 即使仍成功或失敗，能否由 MainActor owner 保護目前請求的結果、loading 與 handle。假設同步檢查 owner、generation 和取消旗標即可維持這些狀態規則。

## 為什麼

Swift 的取消由 Task 合作觀察，actor 可在 await 期間執行其他工作。E021 和 E022 覆蓋較低層的受測路徑。需要受控事件驗證 owner 的提交與清理。若成立，後續可用現行 nonthrowing Outcome 接線。若失敗，先檢查 owner 契約及其假設。 [規格與判準](../../analysis/async-request-lifecycle-commit-guard/technical-spec.md) · [Swift 取消基線](../../docs/architecture/swift-cancellation-baseline.md)

## 成功與失敗判準

V01–V10 的預定觀察全部成立，含 V08 的兩個獨立對照與 V09 同步隔離證據才成功。控制有效且觀察違例或源碼存在 suspension 即失敗。建置、事件控制、證據缺失或 watchdog 阻礙判讀時為無法判定。事前判準固定。Tester 執行一輪，只有確認排除環境或證據收集故障後才可補跑一輪。每案 10 秒 watchdog 只用來停止卡住的執行。

## 環境與前置條件

SwiftPM 6.0、Swift language mode 6、macOS 15 以上。來源完全合成，無外部依賴。規劃環境為 arm64 macOS 26.5.2／Swift 6.3.3。

## 重現步驟

在 repository 根目錄執行：

```sh
swift test --package-path experiments/E023
swift run --package-path experiments/E023 async-lifecycle-probe
```

測試和 CLI 以同一 driver 執行事件。先等來源安裝 continuation，再取消、切換或放行。每次釋放後確認 Task 完成。CLI 每案輸出一筆 JSONL，含事件順序、輸入、取消旗標、結果、前後快照、斷言與失敗清單。V09 另讀同步的 `RequestStateOwner.finish`。

## 是否成功

2026-11-24 18:11:13–18:11:20 台北時間，獨立 Tester 完成一輪。兩條指令均 exit 0。實驗狀態為**成功**，V01–V10 事前觀察成立，本輪任務完成。

## 結果與證據

arm64 macOS 26.5.2（25F84）、Apple Swift 6.3.3，基線 `c3894545d3ed58b20206152dfaa12d050e803b46`。實際命令在 `--package-path` 後以 `--scratch-path` 指定同一獨立建置目錄。Swift Testing 17 案全部通過。[原始 JSONL](evidence/trace.jsonl) 共 17 筆、167 個事件、351 項通過的檢查，無失敗。各列實際觀察均符合事前預期。

| 案例 | 合成輸入與順序 | 實際結果 |
| --- | --- | --- |
| V01 | 當前 A 成功 | A 提交，ID、handle 與 loading 清除。 |
| V02 | 等待 A → 取代為 B → B 成功 → 排空 A | A 取消，B 持有 loading 並提交，晚到 A 被拒。 |
| V03 | B 成功 → A 成功 | A 因過期被拒，保留 B。 |
| V04 | B 成功 → A 的 `.unavailable` | A 因過期被拒，保留 B。 |
| V05 | 等待 A → 失效兩次 → 嘗試 B → A 成功 | A 取消且被拒，owner 保持失效，來源只接到 A。 |
| V06 | 同 PR A→B→C，以六種排列完成 | 僅 C 提交，完成前後的 slot 與狀態皆正確。 |
| V07 | 當前 A 返回 `.unavailable` | failure 提交，slot 清空。 |
| V08 | 一般取代、同 PR 未取消取代、只取消當前 handle、撤銷後重啟 | 過期 A 的兩處旗標分別為 true／true 或 false／false，均被拒。仍為 current 的 A 兩旗標為 true，丟棄 payload 後只清自身 slot 並回 idle。正常撤銷後晚到 A 被拒，B 可提交。 |
| V09 | 讀取完成方法並對照前後快照 | 檢查、提交及清理都在同步 MainActor 方法，無 await，執行快照符合分支。 |
| V10 | A 在 B loading 時回成功 | A 兩旗標為 true，成功仍被拒。B 的實際 handle、generation 及 loading 保留至 B 完成。 |

V01–V08、V10 為 **Test-confirmed** 及 **Experiment-confirmed**，V09 同步區段為 **Code-confirmed**。產品接線及真實來源的取消時序為 **Unverified**。

| 對象 | SHA-256 |
| --- | --- |
| JSONL | `a0bbbeab91f006a2165f240ad7471b120b979256e1fe4fb1591ba734272ff2e0` |
| 受測 RequestStateOwner.swift | `031029fe114104b811ddcfb70e43fdbc0880afd73240684d11d931c8bd9691c9` |
| 受測 Scenarios.swift | `6a5585d5cb82fb2dad397a50d1ffd31e3542e1af31a9ac438b2a901395c73dd2` |
| 受測 CLI binary | `404af2287cab2d3c996ec954ccd0f18807afa71a5c819f42e18c35fffc2d2157` |

測試後依 SwiftLint 調整 `Scenarios.swift` 中 `ticketA`、`ticketB`、`ticketC` 的局部命名與兩個換行。反向核對確認其餘內容相同。本輪實驗未重跑。

## 結論與限制

合成來源與隔離 host 是本輪適用邊界。建議正式整合由擁有選取、loading 與顯示結果的 Presentation Session 封裝 handle、發起取消並保留 nonthrowing Outcome。產品採用須驗證同 PR 刷新、跨 PR 切換、離開後重建、有效與過期 failure、晚回結果及 handle 清理，再交獨立審查。若產品證據顯示現有 Outcome 無法區分 caller 必須辨識的下層取消，另立 Port 契約議題。
