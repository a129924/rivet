# Cancellation Trace & Contract Review 執行計畫

分支 `chore/cancellation-trace-contract-review`，base `dev` 的 `386af9e`。在獨立 feature worktree 工作。先取得四份文件的獨立審查，再執行 A01 靜態分析、B01 既有測試、C01 必要的隔離實測、D01 獨立成果審查。具長期效力的結論回寫架構文件。依 topic 提交、push、開 Draft PR，停在 Human review。

| Swift 交接欄位 | 契約 |
| --- | --- |
| In-Scope | 以現有公開 Swift 入口寫必要的隔離 harness 與合成 fixture。 |
| Out-Of-Scope | 正式程式、公開介面、既有測試、產品接線、retry、真 GitHub／OAuth／Keychain。 |
| ReadOnly | 根套件、production、既有測試、E012／E020、既有實驗索引。架構文件只在 D01 證實後回寫穩定結論。 |
| Written | 必要時新增 E021／E022 各自的 harness、八段 README 與可重現證據。另保存四份正式文件及審查結果。 |
| Deleted | 無既有檔。 |
| Modify | C01 限此次新增的實驗檔。 |
| Goal | 取得會改變契約選擇的取消證據。 |
| Non-Goal | 產品修正、跨環境保證、UI 狀態驗收。 |
| TestCase | C01-1 Foundation loopback 取消、C01-2 Inbox 晚到成功回應，各有對照組與取消組。 |

輔助工作包括 show-me 呼叫樹、Archify sequence 在地驗證、依同版 graph 可用性使用 Graphify 或定向來源、依實際 topic diff 使用本地 PR Lens，以及可用時刷新本地 Floorplan。輔助產物各自記錄狀態，證據驗收使用原始碼、測試與實測結果。
