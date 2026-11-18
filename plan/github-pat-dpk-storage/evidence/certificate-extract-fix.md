# E016 公開 certificate extraction CLI 格式修正

日期：2026-11-16。分支 `feat/github-pat-dpk-storage`，基準 `e928d7d`；本段是 feature worktree 未提交工具變更的 Implementer 交接。

## 發現、來源與界線

Root／Tester 的當次 exact-app 唯讀 preflight 診斷記錄：claims、profile expiry、Team、group prefix、App ID guards 已通過；公開 certificate extraction 的原生命令 exit 1，未到 certificate 內容／designated requirement 判讀。本次不重跑用戶 app 的 native 診斷；原 metadata unknown 與後續診斷各自保留，不將本修正追補為舊 unknown 的已證根因。

既有 primary source `experiments/E015/github-oauth-credential-persistence/scripts/credential_storage_live.py` 第 605／2101 行使用 `--extract-certificates=<prefix>`。E016 原把 optional argument 拆成 `--extract-certificates`、`<prefix>`，可能將 prefix 當作額外 operand。只將 E016 改為既有 equals 形式，保留唯一 app operand、原 certificate guards 與其他已審查流程。沒有新增 fallback、profile 選擇或簽章設定。

## TDD

先修改實際 `inspect()` 使用的 mock fixture，只接受 equals 格式；新增專屬回歸確認命令為 `codesign -d --extract-certificates=<prefix> <app>`，只有四個 argv 元素、恰一個 extraction option 與唯一 app operand。

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover \
  -s experiments/E016/github-pat-dpk-storage/Tests -p test_probe.py -v
```

- Red：runner 未改時 exit 1，30 tests，1 failure＋15 errors；專屬回歸明確顯示舊命令 `5 != 4`，正常 fixture 也因沒有 equals extraction 產物而拒絕。
- Green：僅將 runner 該命令改為單一 equals 旗標後 exit 0，30 tests 全通過。
- 本次 runner／test 的 `git diff --check` exit 0。

測試全部離線 fake，沒有呼叫原生 certificate extraction、私鑰、簽章、build、Run、真 Keychain 或 live stage；不改 Swift／公開 API，也不修改先前 stream／profile claims 證據或 hash。

## 修後來源 SHA-256

| 相對路徑 | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `67b250f8ed1972086d96c69603d14ef1b812ffc90f45cd6c4491a69385ec1c0d` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `2d3468c5e3c9f829160d682af36dcca783772765eb54f44d706ded511b8f7109` |

尚待獨立 Tester／Reviewer。修正完成不代表 native preflight、有效 profile、P06、真 DPK／提示或整題完成；下一次 exact-app preflight 仍須由 Root 明確派遣。
