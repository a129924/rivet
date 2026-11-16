# E016 requirement stream：獨立補驗

日期：2026-11-16。角色：獨立 Tester `/root/tester`，非本次修補作者。基準 `e928d7d`；本證據針對 feature worktree 尚未提交的 bounded fix，修後來源以下列 SHA-256 綁定。

## 親跑結果

- `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s experiments/E016/github-pat-dpk-storage/Tests -v`：exit 0，**22 tests 通過**。
- 實際 `inspect()` fixture 使用 native 通道形狀：stdout 為唯一 `designated =>`，stderr 僅 Executable。stdout 正常格式接受、stderr-only requirement 拒絕，沒有增加 stderr fallback。
- Tester 額外唯讀執行 `codesign -d -r- /bin/ls`：exit 0；designatedRequirementOnStdout=true、designatedRequirementOnStderr=false。只檢查系統既有 binary，未保存或輸出 requirement 原文，未讀使用者簽章資產。
- Runner／tests 的 SHA-256 與 Implementer 的 [交接](requirement-stream-fix.md)一致。

| 來源 | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `9c523fd59a3d5ba2f24201827c214169da33fe1b9d7041d01356d6a8bb1dc5f3` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `03970a2d3274ba2798c02993eaff1a9d0004618496b1fda3ad830dbb1f9f379f` |

Swift／project 未改，因此未重跑 Swift suite 或 unsigned builds。本輪沒有簽章、private-key 查詢、signed build、App launch、真 Keychain 或 live stage。22 tests 是本次補驗數，不與先前 17／20 tests 相加；先前證據保持歷史。

本補驗只支持 requirement 輸出通道修補。P06 的有效 E016 profile／explicit private group、私鑰可用性、真人觀察及真 DPK 仍各自需要當次證據；不因 stream fix 綠而提升。交獨立 Reviewer 判讀，不自行宣稱 live readiness 或整題完成。
