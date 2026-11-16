# E016 profile claims：bounded fix 交接

日期：2026-11-16。分支 `feat/github-pat-dpk-storage`，基準 `e928d7d`。這是 feature worktree 尚未提交的工具修正；不將基準 SHA 當作修後來源版本。

## Finding 與採用來源

獨立 Reviewer 指出兩個 live preflight 缺口：profile 的 group allowance 原只接受 exact，沒有沿用既有末尾 wildcard 能力；application identifier 原只比較單一 key，雙方缺值也可能因 `None == None` 被接受。

選擇性採用 `experiments/E015/github-oauth-credential-persistence/scripts/credential_storage_live.py` 第 544–551 行的 profile application-identifier fallback 與 allowed-group prefix 機制，不修改 E015 或繼承其 live 結果。E016 另外保留本題必要的嚴格值驗證：

- Caller group 必須為非空白字串且不含 wildcard，namespace 不改寫。
- Signed app 的 `keychain-access-groups` 仍必須恰為 `[group]`；profile wildcard 不放寬 signed claims 或多 group。
- Profile allowance 接受 exact，或恰有一個 wildcard 且位於末尾 `.*`、prefix 能匹配 caller group 的條目。錯 prefix／其他 wildcard 形式不能提供授權。
- Signed claims 與 profile entitlements 都接受 `com.apple.application-identifier` 或 `application-identifier`；至少存在一個非空、無 wildcard 的字串。雙 key 同時存在必須相同；兩端 identifier 都必須等於已驗 Team 加上固定 E016 bundle identifier。
- 不新增一般 framework、簽章設定、profile fallback 路徑或 live 自動化權限。

這個修正不改變 Root 已觀察的兩個現有 profile 與 E016 App ID 不相符之結論，不表示當前簽章環境可用。

## TDD 與實際結果

命令：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover \
  -s experiments/E016/github-pat-dpk-storage/Tests -p test_probe.py -v
```

1. 先更新 native-format fixture，分離 signed claims／profile entitlements，新增七個測試方法及其 subcases；保持 runner 未修。Red：exit 1，29 tests，8 failures＋7 errors，暴露匹配 prefix／fallback 應接受卻拒絕、以及缺值／衝突／錯 App ID 應拒絕卻接受等情境。
2. 最小修正 runner 後，Green：exit 0，29 tests 全部通過。包含先前 requirement stdout 接受／stderr-only 拒絕與既有 22 tests，不改寫其先前結果或 hash。
3. `git diff --check` 對本次 runner／test 變更 exit 0。

新增涵蓋 exact／matching prefix、錯 prefix／非法 wildcard、signed wildcard／多 group、caller 空值／wildcard、canonical／fallback／相同雙 key 的交叉組合，以及任一端缺 key／空值／非字串／衝突／錯值與雙方同時缺值等拒絕情境。所有 subprocess 都由 fake command 截取，走實際 `inspect()` 控制路徑；沒有簽章、profile 資產操作、私鑰存取、Swift build 或真 Keychain／live stage。

## 修後 SHA-256

| 相對路徑 | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `0ae98d793bede24c63dc134d68d176fa02d7e2eb811fddb9f9dd77c29b65ac6e` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `b0db00df1579d45e734716569066a9f948cc06b8d791ed0a7805c07f7c8f4f07` |

先前 stdout 修正與獨立 Tester 的 22 tests 證據保留於原檔，不覆寫歷史 hash。本段是 Implementer 完成交接，尚待獨立 Tester／Reviewer，不代表 P06、有效 profile、Human 提示或完整 topic 通過。
