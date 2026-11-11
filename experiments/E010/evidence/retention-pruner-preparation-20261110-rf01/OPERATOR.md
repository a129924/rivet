# RP03 離線一次性縮減方案

這是 E010 的 external file job 準備，沒有修改或呼叫實驗 harness。C0 尚未開始；此目錄沒有任何實際 target inventory／刪除許可。R0 為 2026-11-10T08:10:57Z，全部離線準備與獨立 gates 截止 09:10:57Z，總截止 09:55:57Z，原 D=2026-11-20T07:22:03.379959Z 不延長。

- `retention_pruner.py`：FD-relative、no-follow inventory／typed closure、逐筆 raw uncovered、精確 cache allowlist、單批次與 partial file proof。
- `retention_caller.py`：唯一未來入口，固定 namespace／home-relative root／sidecar、source22 與 review tuple、時限先於 private load。
- `execution-parameters.safe.json`：完整參數與私有檔案必要性提案，C0=null。側車只新增本 job metadata，不搬走任何原 raw，現在未建立。
- `test_retention_pruner.py`：17 個 synthetic Python 方法，沒有原 CLI import、編譯、App、Signing、Keychain 或 DPK；lsof 全以 mock 代替。

獨立 Tester 在本目錄執行 `python3 -B -m unittest -v test_retention_pruner`。作者檢查不能取代 RP04／RP05。安全候選以每筆 opaque ID／內容 SHA／identity SHA／有限 context／理由表達；private paths／JSON pointers 的完整記錄只留本機，public 用 pointer SHA 與 field enum。這不是模型已看過 raw 的聲明。

原 `gui_build.capture_command` 沒有持久化每份隨機 raw 的 stage／tool 關聯。本 revision 不猜、不更改 producer，也完全不刪原 raw。每個 raw file 會標為 `retain-uncovered`；因此即使獨立 cache allowlist 全完成，仍是 minimumComplete=false／recoveryRequired=true。未知必要性與未知依賴分開；未解析依賴會阻擋 cache 刪除，無依賴的其他 unclassified material 仍保留。只有三個 source 明確產生的 cache roots 可成候選：DerivedData、intermediates、build-output；保留 root、configured／frozen-source／gui/p0/Products／hosts/p0.app／reference／proof 與 controls。沒有任何 DPK 可讀或 absence claim。

未來 gates 全過才能固定 C0；所有診斷至 C0+20min、全部 target／sidecar IO 至 C0+30min，均受更早總截止限制。offline review 與 actual delete-plan review 分開，前者不授權具體刪除。actual review 必須綁 exact action/caller/params、private inventory/map/plan/retain/delete 與 candidate SHA，並具有同 candidate SHA 的 readability/safety ACK。不得自寫批准。

未來確切入口（目前禁止執行；從此目錄使用、以實際 SHA 與 C0 取代佔位）：

```text
python3 -B retention_caller.py --phase diagnose --params execution-parameters.safe.json --params-sha ACTUAL_SHA --offline-review offline-review-approval.safe.json --c0 ACTUAL_C0
python3 -B retention_caller.py --phase execute --params execution-parameters.safe.json --params-sha ACTUAL_SHA --offline-review offline-review-approval.safe.json --c0 SAME_C0 --execution-review execution-review-approval.safe.json
```

`diagnose` exclusive 建立審定的單一 sidecar／window，不能重做 inventory。`execute` exclusive durable dispatch，最多一次；fresh source/root-parents/完整 entryset／retain fingerprint／handles 必須全過，每 mutation 再核 identity／deadline。任何差異、占用、權限或不確定就停，不刷新、不重試、不刪 root。完成或部分結果逐筆 journal；無剩餘時間不能補查 postcondition，保留 finalUnknown。原 raw 不外移，新 unique native failure 只封閉側車，不公開，沒有特定 ACK 不刪，也不授 whole raw 長留。所有後續私人檔案仍須按原 D 與必要性處理；沒有排程或到期自動刪除。

本次作者僅建立並測試合成檔案；尚未使用 C0、尚未建立側車、尚未盤點 root，沒有 live／GUI／Build／App／DPK／資產操作。兩階段 caller 都先核固定時限，再載 private bytes；截止後只有已取得的 in-memory safe facts 可以報告。

## RP-RF01 新 revision

此目錄是獨立 v2，原 v1 七檔與 RP04 needs-rework 收據保持原 bytes。本版 private typed-reference expectedSHA256 只接受 null 或 64 hex 字串；格式不合法以固定 coverage refusal 停止，safe_candidate 公開邊界再核一次。原 raw-uncovered／期限／sidecar 提案不變，舊批准不沿用。新增一方法驗 malformed string／長度／字元／型別與 public 邊界拒絕。
