# P07：PAT 真 DPK 獨立審查

日期：2026-11-16。角色：獨立 Reviewer `/root/planner`，非儲存／host／runner 作者，未執行本題 live。受審來源：`5465d3c7308e74bc2b3b51878acd190d4f2babda`；完整新 run：`39c22b57-de4f-463c-aa4b-8de277c1f60a`。

**Verdict：approved。Required fixes：0。** 本結論限指定主機、GUI 使用者、有效簽章與 profile／相同存取身分下的 TC05；不取代 Human 最終接受，也不授權 merge。

## 直接查證

審查四份 planning artifacts、[真人紀錄](live-validation.md)、[有限公開收據](live-run-39c22b57.json)，並從指定私有 locators 讀取原始 proof、產物及 Tester 完成交接。未只依據敘事或帳本狀態判定。

- 對凍結 source map 逐項重算目前來源 SHA-256，並與記錄 commit 的 Git blobs 比對一致，包含正式 PAT adapter、既有 PAT VO、host、runner 與建置範本。
- 六個 runtime 的 raw receipt／attempt／acceptance／build proof／source proof 與 Human observation SHA 均匹配；run／phase／binary／variant 正確，OS PID-start tuples 與 instance 各自不同。已審查的 runner 只於正常 open、完整 receipt／identity gates、PID 退出及穩定 bytes 成立後發布 acceptance；原始 acceptance 與 Tester 的退出證據紀錄一致。
- save A、fresh A、replace B、fresh B、rebuilt fresh B、exact-owned cleanup 六段均 accepted=true，Human wholeStageObserved=true、promptCount=0。正式 frozen host 對應分支分別驗完整 A／B 或 cleanup 後正式 load=nil。
- 新 run 的 absence／write-attempt markers 與 exact run namespace 一致；cleanup 僅使用該 group／service／pat account。沒有依據允許清理 OAuth 或其他 run。
- Debug／Rebuilt／固定 current 三個實際 app 的唯讀簽章查核在外層均 exit 0。直接讀取 embedded profile、signed entitlements、公開 certificate 與 DR，重建 full identity 並比對 selected pins 一致；profile 到期日為 2026-11-23，查核時有效，certificate membership／有效期通過。未查私鑰或修改 trust／Apple assets。
- 實際 Debug 與獨立 Rebuilt build argv 均為 clean/build、沒有 provisioning update 旗標；Rebuilt 實際 compiler log 含 `-DPAT_STORAGE_REBUILT`。不同 binary hashes 與兩份 build proof 相符，完整簽章身分相同，current 對應 Rebuilt。Setup／rebuild 的 Human 全程 0 提示各自綁其 machine SHA，與 runtime 分開。
- 原 source55 namespace 的新 verify-absence recovery 有獨立 recoveryID、amendment／controller／attempt／host／build／source hash 綁定及全段 Human 0。其 frozen host admission 在 Security 前限制只讀，completed 代表正式 load=nil；沒有重做 save／delete。Amendment 引用的 original／host proof hashes 均保持。
- 原首次 setup unknown machine SHA、source55 read A／cleanup raw receipt SHA 與未產 acceptance 的事實均保持；新 recovery 只證明當次缺值，不追補舊 unknown 為成功。
- 公開 export 的有限欄位及 source map 與私有原證據一致；沒有輸出私人 group／Team／profile 名稱、DR、程序 IDs、本機絕對路徑、PAT 或原始系統 error。

## 查核環境與限制

Reviewer 最初在 sandbox 內對三個 exact app 執行相同唯讀 codesign verify，得到 CSSMERR_TP_NOT_TRUSTED；以同一命令在外層唯讀重查，三者皆 exit 0。此差異未被解讀為 artifact failure，亦未變更 trust、重簽或啟動 App。

本 review 沒有 Run、DPK 存取、刪除、建置、簽章、私鑰查詢或重新執行任何 runtime。公開 certificate extraction 僅在 Reviewer 自有暫存目錄讀取公開 DER，不改受審產物／private proofs。

AC2／AC3／AC9／AC10 的本次 TC05 證據成立；資料與錯誤／隔離等受控部分沿用已獨立 approved 的離線證據，不擴稱真系統拒絕／壞資料曾 live 驗收。仍不推論 profile renewal、certificate rotation、其他環境、公開分發、斷電 durability、遠端 PAT 有效性或產品登入。

長期文件、帳本、publication 與 Draft PR 的最新狀態回寫由 Implementer 接續，並保留逐段歷史；這些已知 metadata 待辦不改變本次技術 verdict。HC04 圖的 Human 視覺接受與 HC05 topic 最終 Human 接受仍 pending，整個 topic 不自行標為完成。
