# 非同步請求生命週期驗證規格

## 隔離契約

E023 使用 SwiftPM tools 6.0、Swift language mode 6、macOS 15 以上，零外部依賴。核心、CLI 與測試共用情境驅動器。來源是合成的 nonthrowing async 請求，返回成功或 `.unavailable`。

`@MainActor` owner 建立 Task 並持有存活狀態、遞增 generation、當前 generation／handle 與 UI 狀態。每次開始都配發新 generation，包含同 PR 刷新。同步換入新 slot 與 loading，再取消舊 Task。等待來源時弱持有 owner。`cancelCurrent()` 撤銷 slot、回 idle 並發起取消，owner 可再使用。`invalidate()` 永久失效、撤銷並取消，重複呼叫具冪等性。

來源返回後，由原 Task 呼叫同步 actor 完成方法。先檢查 owner 存活與 generation，再讀自身取消旗標。過期或已失效只記錄拒絕。仍為當前但具取消旗標時，丟棄 payload 並清理當前 slot 回 idle。有效結果提交成功或 failure，並清理當前 slot。檢查至寫入沒有 suspension。取消與提交以 owner 的同步順序為準。當前 handle 僅在實驗對照可直接操作。

Swift 協作式取消及 actor reentrancy 給出設計依據。能否獨立拒絕兩類結果並保護清理，需要實際跑受控事件。 [SE-0304](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0304-structured-concurrency.md#cancellation) · [SE-0306](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md#actor-reentrancy)

## 事前情境

| ID | 受控觀察 |
| --- | --- |
| V01 | 當前 A 成功後清空 ID、handle 與 loading。 |
| V02 | A 等待後由 B 取代。A 收到取消，B 持有 loading 並提交，排空 A。 |
| V03 | B 成功後釋放 A 成功，拒絕 A 並保留 B。 |
| V04 | B 成功後釋放 A 的 `.unavailable`，拒絕 A 並保留 B。 |
| V05 | A 等待時失效，晚到結果被拒，重複失效穩定且再次啟動零來源工作。 |
| V06 | A→B→C 的六種完成順序，每步檢查狀態與 slot，僅 C 提交。 |
| V07 | 有效 A 的 `.unavailable` 正常提交並清空 slot。 |
| V08 | 一般取代後已取消 A 仍回成功並被拒。同一 PR 取代且省略取消時，A 未取消仍因 generation 被拒。保持 A current 僅取消 handle 時，丟棄 payload 並清理回 idle。另確認正常撤銷與重啟。 |
| V09 | 源碼確認檢查、寫入、清理在同一同步 MainActor 方法，且與前後快照吻合。 |
| V10 | A 在 B loading 時返回，B 的實際 Task handle、ID 與 loading 保留，B 完成才清空。 |

來源先安裝 checked continuation 再通知等待。driver 等待後才取代、取消或放行，每次放行後等 Task 結束。來源於返回前測取消旗標。每案 10 秒 watchdog 僅為停止及診斷。正常結束排空 continuation 及 driver 持有的 handle。CLI 以 JSONL 記案號、順序、來源結果、兩處旗標、決策與狀態快照。

全案觀察與 V09 靜態證據成立才判成功。受控事件有效但觀察違例或同步邊界違例為失敗，保存證據並停止。建置、事件控制、watchdog 或證據失落致不足判讀為無法判定。Tester 一輪完整執行，僅可確認並排除環境／收集故障後補跑一輪，判準固定。
