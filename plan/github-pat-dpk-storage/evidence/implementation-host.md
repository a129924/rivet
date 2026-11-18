# E016 與文件實作交接

2026-11-16，Implementer `/root`；僅 feature worktree，沒有 dev 實作、signed/live、真 Keychain 或 signing asset 查核。

## 產出

- E016 專屬 Xcode project／Debug 與 Rebuilt schemes、Info／entitlements 範本、Swift host、Python runner／offline controls、README。
- Host 一般 import 正式 PAT adapter，不複製 codec；`Probe.perform` 由 live wrapper 與 fake-only self-test 共用。Cleanup 只有 exact owned group／service／pat，且先有耐久 absence／write-attempt markers。
- Runner 將 prepare、build、run、observe、export 分開，signed build／run 必須 Human 當次 ready。固定 app 位置、有效 embedded profile／certificate／claims、DR、來源與 binary 綁定；OS process-start proof、無殘留 host 與前段觀察 gate。真 signed/live 路徑仍未實測。
- 初次 host compile 找到 actor property 在非 isolated autoclosure 存取，改為先 await locals 後比較；沒有改正式 API。
- Offline fixtures 發現 DR 不能包含 codesign 的 Executable 路徑，現在只保存 designated requirement，並驗 copy 前後一致。中斷 attempt 無 receipt 輸出 unknown，觀察 SHA 不符不輸出其 count／whole 成功旗標。
- PAT 長期契約、入口與 E016 索引已回寫，保留真 DPK／Human pending。

## Implementer 已執行

- Debug unsigned Xcode build 成功；獨立 Rebuilt DerivedData 的真正 clean/build 成功。不簽章，不 raw 啟動 live host。
- Debug unsigned binary `--self-test`：fake-only，7 checks passed；僅記憶體 store／journal。
- Python `-B -m unittest discover -s experiments/E016/github-pat-dpk-storage/Tests -v`：17 tests，exit 0；涵蓋實際 prepare／context／receipt／observation／export，及 fake signing metadata。沒有 Security／sign／launch。
- 新 host Swift strict format／lint：exit 0，無 violations。
- 兩個 unsigned builds 的 Apollo upstream warnings 與 Xcode headermap warning不視為 live 前提通過；正式 store／consumer 的結果另見 implementation-store 與獨立 tests 證據。

## 工具

Archify 最終 showcase 九項 checks、0 errors／warnings，四尺寸 containment 通過。實際 Agent 檢視與 immutable hashes 見 diagram BUILD／receipts；獨立 Tester 補看四張圖。Human 視覺仍 pending。

Graphify 沒有可用 graph，依 skill 回退限定來源搜尋；沒有 extract／build／provider／install／refresh。PR Lens 等實際 commit diff 後才建立外部本機 change map，不發佈或上傳。

## 待驗與限制

交獨立 Tester 親跑 root／consumer／controls、unsigned compile、strict checks 與圖形 evidence，再交獨立 Reviewer。任何受控或 unsigned 成功均不代表真 DPK、跨程序／重建還原、runtime 提示、真項目 cleanup 或完整 topic 已完成。

## RF-P05-01 bounded 回修

獨立 Reviewer 指出 host completed 不等於 runner 全 guard 通過。現新增獨占且耐久的 acceptance proof，綁 attempt／host SHA／run／phase／source proof／build proof；observed 必須核對，export 分開 hostOutcome／runnerAccepted／unknown。新增實際 launch 控制路徑的離線回歸：binary／variant 不符、重複 OS process tuple、open timeout（已有 completed receipt）都不能前進；完整有效路徑可前進，build proof 改變會失效。沒有操作真 Security 或重建 production store。

回修控制 suite 現 20 tests；初次執行有一例壞 receipt 缺欄引出 KeyError，已收斂為 acceptance=false，再回有限 guard 拒絕。待獨立 Tester 補驗與 Reviewer 收斂。
