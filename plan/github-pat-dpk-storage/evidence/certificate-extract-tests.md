# E016 certificate extraction：獨立補驗

2026-11-16，獨立 Tester `/root/tester` 親跑 `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s experiments/E016/github-pat-dpk-storage/Tests -v`：**exit 0，30 tests 通過**。

抽查實際 inspect 接線與專屬回歸：certificate extraction 為四個 argv 元素、恰一個 `--extract-certificates=<prefix>` option 與唯一 app operand；fixture 只產出 equals 形式的 certificate。既有 stdout requirement／profile claims／runner acceptance 案例仍通過。沒有新增 fallback、改 Swift／API／project 或放寬驗證。

| 來源 | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `67b250f8ed1972086d96c69603d14ef1b812ffc90f45cd6c4491a69385ec1c0d` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `2d3468c5e3c9f829160d682af36dcca783772765eb54f44d706ded511b8f7109` |

兩個 hash 與 [Implementer 交接](certificate-extract-fix.md)一致。30 tests 為當次完整離線 suite 數，不與先前 22／29 相加；原結果與來源 hashes 保留歷史。未重跑 Swift／build。

本節只記錄 fake subprocess 的離線補驗，未執行使用者 app 的 native 命令。新的當次 exact-app 唯讀 preflight 由 Root 另授權並另記 [live-preflight](live-preflight.md)，不追補前兩次 unknown／診斷為原成功。本測試結果本身不證明簽章、profile、P06 或真 DPK 通過，仍交獨立 Reviewer 判讀。
