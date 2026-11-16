# E016 managed profile build：獨立 bounded 補驗

2026-11-16，角色：獨立 Tester `/root/tester`，非本次 Implementer。分支 `feat/github-pat-dpk-storage`；基準 `0b0692ee9713c055b33d405075da413bae0949db`，修後未提交來源以本節 hash 綁定。

## 親跑結果

`PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s experiments/E016/github-pat-dpk-storage/Tests -v`：**exit 0，37 tests 通過**。

Tester 抽查實際 build()／inspect() 接線與對應測試：

- CLI 預設 manual、明確接受 automatic；Tester 另直接測非法 signing-style，parser 以 exit 2 拒絕，沒有 native 呼叫。
- Automatic argv 為 Automatic／Apple Development／空 provisioning specifier，selected settings 仍要求 40 位 hex certificate SHA-1；沒有 provisioning update／device registration 旗標。
- Manual 保留選定 certificate SHA-1／profile Name，明確 manual style。
- Inspect 私有回傳含 profileName／certificateSHA1；實際 build() 在 copy current／發布 identity／成功 build proof 之前核對 selected team／profile Name／certificate SHA-1，大小寫正規化僅用於 SHA-1 比較。
- 兩種 style × 三種 pin mismatch 共六個受控負向 subcases：均零 copy、零 identity、零成功 build proof，保留單一 attempt。
- 缺 cached assets 的受控 xcodebuild failure 只呼一次；不 inspect／copy／retry／provision，不發成功 build proof。

本次測試使用 mock xcodebuild／inspect／active-host 查詢，但實際呼 build() 並在 synthetic scratch 做檔案／proof 操作。未呼 native 用戶 app、Security、private key、sign、build、Run 或真 DPK。沒有 preparerun2、改舊 run／controller、改 source 或 stage。

## 已核來源

| 來源 | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `f0d873220e163014d8dd6e469f7a7e43996d9cb82203da84f1df9beae0e20dae` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `f2c23ab44a308e5dac2ca926f13b8ed29231f07553b18bcf57bae4e7f63c1362` |
| `experiments/E016/github-pat-dpk-storage/README.md` | `928b80e8a6d267f7a221410654113c9823ce8c16546801dbf7510e18188f0329` |

三個 hash 與 [Implementer 交接](managed-profile-build-fix.md)一致。先前 30 tests 與其來源 hashes 原樣保留，37 不與舊輪累加。

## 停點

Source `0b0692e`、run `71d51ebe-1a97-4ec7-be4c-a8f802baaba7` 的 setup unknown、原 machine SHA 與 Human 全程 0 提示不變。本補驗只支持工具相容性修正，交獨立 Reviewer 判讀；新正式 automatic-style 建置仍需新 source freeze／round 及當段 Human ready。不得把 fakes 綠、managed mode 或本節提升為 native build／P06／live 成功。
