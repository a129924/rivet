# E016 managed profile：明確建置模式修正

日期：2026-11-16。分支 `feat/github-pat-dpk-storage`，基準 `0b0692ee9713c055b33d405075da413bae0949db`；本段記錄尚未提交的 bounded tooling fix，不將基準 SHA 當修後來源。

## Native 失敗來源與授權界線

[原 live-validation](live-validation.md)記錄 formal Debug setup 的 `xcodebuild` rc 65、machine unknown，以及 Human 全程觀察 0 提示。Root 的後續唯讀輸出分類確證：既有 Xcode-managed profile 被 manual signing settings 拒絕。本次只修相容該既有 profile 的工具建置策略，原 run／attempt／machine SHA／來源及 Human observation 保留，不追補為成功、不 reset、不重試。

Human 已另授權 Agent 配置 automatic signing 並 Build；這份程式修正仍只以 fakes 驗證，不自行執行任何 native build、sign、私鑰、Run 或 DPK 操作。後續須用新 source、新凍結 round 與當段 Human ready。

## 受限變更

- `build` 新增 optional `--signing-style manual|automatic`，預設 manual。
- 兩模式的私有 settings 仍只有 `team`、`identity`、`profile`：identity 為選定 certificate 的 40 位十六進位 SHA-1，profile 為選定 profile Name。SHA-1 只作既有 certificate identifier，不作秘密驗證或新加密機制。
- Manual 保留 selected certificate SHA-1／profile Name argv，明確 `CODE_SIGN_STYLE=Manual`。
- Automatic 明確 `CODE_SIGN_STYLE=Automatic`、`CODE_SIGN_IDENTITY=Apple Development`、空 `PROVISIONING_PROFILE_SPECIFIER=`；不將 selected SHA-1／profile Name 當 manual selection argv，不加 provisioning updates／device registration 旗標。
- 只可重用 cached assets；缺資產讓原命令失敗，不安裝、下載、建立 certificate／profile，也不 retry／改用其他設定。
- `inspect()` 私有 identity 增加 `profileName`、`certificateSHA1`。新 built app 經原有效 profile／certificate、signed groups、固定 App ID、DR 等檢查後，再核 team／profile Name／certificate SHA-1 與 selected settings 相同，才允許 copy current、發布 identity 或成功 build proof；SHA-1 比較大小寫正規化。
- Rebuilt 原 full identity 相等及不同 binary 檢查保留。公開 PAT API、Swift、Xcode project、DPK query、既有 run/proofs 都未修改。
- README 明記模式、selected 三欄 pin、cached-assets-only 與新 source／round／Human ready 的停點。

## TDD 與驗證

同一離線命令：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover \
  -s experiments/E016/github-pat-dpk-storage/Tests -p test_probe.py -v
```

1. 先新增 native profile Name fixture、private pins、CLI 與實際 `build()` 控制路徑 mock tests，runner 未修時 Red：exit 1，36 tests，8 failures＋2 errors。
2. 最小修正後 36 tests green；補一個 cached asset command failure 不 retry／不 inspect／不 copy／不發成功 proof 的負例，最終 exit 0，37 tests 全通過。
3. 本次 runner／tests／README 的 `git diff --check` exit 0。

測試直接走實際 `build()`，只 mock xcodebuild／inspect／active-host 探測；synthetic app 真 copy、run／attempt／identity／proof 真檔案操作均在每個測試自建的 scratch。驗證 default manual、automatic 精確 argv、SHA-1 大小寫相容、兩模式各三種 team／profile／certificate 不符時零 copy／零 identity／零成功 build proof，以及缺 cached assets 一次失敗就停止。沒有 native xcodebuild、codesign、Security、app Run 或 DPK 呼叫。

## 修後 SHA-256

| 相對路徑 | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `f0d873220e163014d8dd6e469f7a7e43996d9cb82203da84f1df9beae0e20dae` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `f2c23ab44a308e5dac2ca926f13b8ed29231f07553b18bcf57bae4e7f63c1362` |
| `experiments/E016/github-pat-dpk-storage/README.md` | `928b80e8a6d267f7a221410654113c9823ce8c16546801dbf7510e18188f0329` |

這是 Implementer 完成交接，仍需獨立 Tester／Reviewer。離線綠燈不等同新正式 build／native postverify 或 P06 通過；原 unknown／Human 全程 0 歷史不變，真 DPK／跨程序／重建／runtime 提示／owned cleanup 與 topic 最終完成仍待相應證據。
