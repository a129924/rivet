# E016 designated requirement 輸出串流修正

日期：2026-11-16。基準 `e928d7d`；分支 `feat/github-pat-dpk-storage`。本記錄對應 feature worktree 的未提交 bounded fix，不將基準 SHA 當作修後版本。

## 根因與範圍

Root 的唯讀原生命令觀察：`codesign -d -r- <system-binary>` exit 0，`designatedRequirementOnStdout=true`、`designatedRequirementOnStderr=false`。未保存原文或私人簽章 identifiers。這只是系統既有 binary 的輸出通道觀察，不是 PAT host 簽章或 DPK 存取證據。

E016 `inspect()` 原先由 stderr 擷取 `designated =>`，offline signing fixture 也把 requirement 放在 stderr，因而未捕捉真實格式不相容。修正只有：

- Runner 的指定 requirement 改讀 `stdout`；其餘 codesign metadata、profile、certificate、唯一指定 requirement 及 identity guards 不變，不增加 stderr fallback。
- Fixture 模擬 native 格式：stdout 為 designated requirement，stderr 僅 Executable；新增 stdout 接受與 stderr-only 拒絕兩個回歸。
- 未改 Swift／公開 API，未建置、簽章、存取私鑰、操作真 Keychain 或執行 live stage。

## Red／Green

同一離線命令：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover \
  -s experiments/E016/github-pat-dpk-storage/Tests -p test_probe.py -v
```

1. 先只改 fixture／新增測試：exit 1，22 tests，2 errors＋1 failure。stdout 正常格式被舊 runner 拒絕；stderr-only 被舊 runner 接受，均可歸因於讀錯輸出串流。
2. 將 runner 改讀 stdout 後：exit 0，22 tests 全部通過。測試以 mock command 走實際 `inspect()` 控制路徑，沒有簽章／profile／Security 原生命令。

## 修後來源 SHA-256

| 相對路徑 | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `9c523fd59a3d5ba2f24201827c214169da33fe1b9d7041d01356d6a8bb1dc5f3` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `03970a2d3274ba2798c02993eaff1a9d0004618496b1fda3ad830dbb1f9f379f` |

修前 runner SHA-256 為 `7a99371c838c0b3d6e9b01b0d6f549ba48a84e58d6ed7dffca20fce6a934b205`。本段是 Implementer 交接，尚待獨立 Tester／Reviewer；不宣稱有效 PAT profile、live preflight、簽章、真 DPK／提示或整題完成。
