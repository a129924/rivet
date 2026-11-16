# E016 profile claims：獨立 bounded 補驗

日期：2026-11-16。角色：獨立 Tester `/root/tester`，非本次 Implementer。分支 `feat/github-pat-dpk-storage`，基準 `e928d7d`；修後未提交來源以下列 SHA-256 綁定，不將基準當作已含修正的版本。

## 親跑結果

`PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s experiments/E016/github-pat-dpk-storage/Tests -v`：**exit 0，29 tests 通過**。

抽查實際 `inspect()` 與新 helper／fixture 的接線，結果支持本次受限契約：

- Caller group 必須為明確、非空白、不含 `*` 的字串；signed claims 仍恰為 `[group]`，不能以 profile prefix allowance 放寬 signed wildcard／多 group。
- Profile allowance 支持 exact 或唯一 wildcard 位於末尾 `.*` 的 matching prefix。錯 prefix、`test*`、單獨 `*`、中間 wildcard、多 wildcard 等測試拒絕。
- Signed／profile 的 application identifier 皆接受 canonical 或 fallback key；雙 key 同出須一致。缺值、空值、非字串、wildcard、衝突或錯誤固定 App ID 都拒絕；兩端同時缺值不能通過。
- 兩端有效 identifier 皆等於已驗 Team 加固定 E016 bundle identifier。Canonical／fallback／相同雙 key 的 3×3 組合均有受控接受情境。
- 先前 designated requirement stdout 接受、stderr-only 拒絕的回歸仍在本次 29 tests 內通過。

| 修後來源 | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `0ae98d793bede24c63dc134d68d176fa02d7e2eb811fddb9f9dd77c29b65ac6e` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `b0db00df1579d45e734716569066a9f948cc06b8d791ed0a7805c07f7c8f4f07` |

兩個 hash 均與 [Implementer 交接](profile-claims-fix.md)一致。先前 [22 tests stream 證據](requirement-stream-tests.md)及其當時來源 hash 原樣保留，不將兩輪測試數累加。

本次只執行 mock subprocess 的離線控制測試；沒有 Security 原生命令、私鑰查詢、簽章、Swift／Xcode build、App launch 或真 Keychain。未修改 source、generated `.swiftpm`／plist，也未 stage。本證據只支持工具 claims 修正，交獨立 Reviewer 判讀。

先前兩份現有 profile 不匹配 E016 App ID 的事實沒有因此改變；profile 的 wildcard allowance 與 signed app 的明確 group 是不同條件。Human 正在私有 copy 準備的結果尚未由本次測試驗證，P06／live readiness／提示與清理仍需要當次證據，不能以離線 29 tests 宣稱通過。
