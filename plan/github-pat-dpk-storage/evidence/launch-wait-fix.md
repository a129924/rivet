# E016 一般 open 等待與唯讀 absence recovery

日期：2026-11-16。分支 `feat/github-pat-dpk-storage`，基準 `55aa57ae2a9b466baca3b7968e7a4419e996a646`。本段為未提交 bounded tooling fix 的 Implementer 交接。

## 已知事實與界線

[原 live-validation](live-validation.md)保留 save A accepted／Human 0，以及 read A／cleanup 的 open rc=1、raw host completed、runnerAccepted=false、unknown／Human 0。新有限診斷定位 `open -W` wait kevent 初始化失敗；本次不重跑原 commands、不將推論補成舊根因、不改舊 receipts、source proof 或 namespace。

已讀本機 `man 1 open`、`man 2 kill`：一般 open 不具 `-W` 等待語義；signal 0 只作權限／存在檢查，不送訊號。ESRCH 表示無該程序，EPERM 不能作退出證據。本次沒有對任何 native PID／app 發命令；下列行為只在 offline fakes 驗證。

## 最小受限實作

- 正常 launch 使用固定 `open -a`，不帶 `-W`／`-n`／raw live binary；open 仍須 rc=0，即使 raw completed 也不能繞過。
- Secure receipt 以 O_NOFOLLOW／O_NONBLOCK 開啟，fstat 核 owner、0600、regular file 與大小；FIFO 不會阻塞 deadline。只有缺檔／JSON 尚未完整可節流重讀，其餘安全／讀取錯誤立即拒絕。
- Monotonic deadline 內核 run／phase、來源、identity、binary／variant、新 OS instance 及 exact int>0 PID；只用 `os.kill(pid, 0)` 等待 ESRCH／ProcessLookupError，不以 sleep、EPERM、其他 error 或 reused live PID 當退出證據。退出前後及最終 identity guard 後 receipt 都要完整校驗、SHA 穩定，才獨占發布 acceptance。
- `recover-absence` 是獨立命令，需 fresh Human ready、原 root 與新 source 正式 build host root。先核原 namespace、owned markers、recorded Git commit blobs 與 source hashes、原 identity／binary，以及新 host context／同完整 identity。只新增原 root 下唯一 0700 recovery 子目錄，不重綁或更改舊 source。
- Recovery 子目錄包含新 controller／source／immutable amendment、原 run namespace／verified markers、新 host／build proof；新 record 額外帶 recoveryID，acceptance 綁 amendment／controller／attempt。原已存在 proof／receipt hashes 前後保持。
- Swift host 的實際 admission 在建立 LiveStore／任何 Security 操作前完成：任一 recovery 痕跡都 fail closed；只有有效 recoveryID／source purpose／amendment／controller／attempt／ownership 的 verify-absence 可進入。該分支只正式 load==nil；有值／load error 都失敗，沒有 save／delete。
- Python 普通 build／run 也拒絕任一 recovery 痕跡；正常 PHASES 未加入可寫 recovery stage。observe／export 只提供新 readonly 結果及 Human 綁定，不將舊 unknown 提升為成功。

## TDD 與已執行驗證

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover \
  -s experiments/E016/github-pat-dpk-storage/Tests -p test_probe.py -v
```

1. 先新增 wait／normal-open／recovery helper 與 CLI 回歸，runner 未修時 Red：exit 1，47 tests，2 failures＋17 errors。
2. 實作後初始 47 tests green；追加 final-guard receipt 變更、read errors、recovery IDs、namespace／source mutation 等負例後 52 tests green。
3. Reviewer 指出 FIFO 可在 fstat 前阻塞，補 O_NONBLOCK 與真 scratch FIFO 立即拒絕／zero kill／zero acceptance 回歸；另補 normal runner 任一 recovery trace 拒絕。最終 exit 0，54 tests 全通過。
4. Swift host 的 strict format 與 strict SwiftLint exit 0。新增實際 admission 的 fake-only控制測試，以及 nil 接受／有值或 load error 拒絕且 zero save／delete；本 Implementer 未編譯或執行 host，留獨立 Tester unsigned compile／明確 self-test 分支驗證。

Python 測試走實際 launch／recover-absence 控制路徑，原生 command／inspect／kill 皆 fakes；只有各測試自建 scratch 的檔案／FIFO操作。涵蓋 delayed／partial receipt、live PID→ESRCH、EPERM／其他錯誤／deadline、非法 PID、open nonzero、receipt 前後變動、owned journal／Git source／namespace／identity 阻擋、新 readonly recovery 成功與原檔 hash 不變。未操作舊 private roots、真 Keychain、簽章、build、Run 或重試 cleanup。

## 最終來源 SHA-256

| 相對路徑 | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `43d27401de07cbfbb7495d3519ac761da8b95a34d969047d9034d4667bf3505a` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `23bc597cc6ec0f73ed0c633382f9150459d291aea6e9f620632356cf1750d6fa` |
| `experiments/E016/github-pat-dpk-storage/Sources/main.swift` | `5d9683aa713161cb7b340acb0e39986d159478a407693a9dcc8817d010691c27` |

尚待獨立 Tester／Reviewer，不宣稱本段新 native build／recovery、Human 提示、P06 或 topic 完成。之後仍須新 source、新 round 與當段 Human ready；原 unknown／Human 觀察歷史全部保留。
