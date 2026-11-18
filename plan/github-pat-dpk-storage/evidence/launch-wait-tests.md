# E016 launch wait／唯讀 recovery：獨立 bounded 驗證

日期：2026-11-16。角色：獨立 Tester `/root/tester`，非本次 Implementer。分支 `feat/github-pat-dpk-storage`；基準 `55aa57ae2a9b466baca3b7968e7a4419e996a646`，新工具尚未提交，以下列 source hashes 綁定。原 source55 run／unknown／Human 觀察均保持歷史。

## Python 離線控制

親跑 `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s experiments/E016/github-pat-dpk-storage/Tests -v`：**exit 0，54 tests 通過**。

抽查實際 launch／wait／recovery 接線與對應 cases：

- Normal open argv 沒有 `-W`／`-n`／raw binary；仍要求 open rc=0，不以 raw completed 繞過非零。
- Secure receipt 使用 O_NOFOLLOW／O_NONBLOCK，fstat 核 regular file、owner、0600 與大小；真 scratch FIFO case 快速拒絕，沒有 PID check 或 acceptance。只有缺檔／partial JSON 在 monotonic deadline 內節流重讀。
- Delayed receipt、live PID→ESRCH 的正常路徑通過；非法 PID、EPERM、其他 existence error、deadline／live或reused PID、receipt 前後或 final identity guard 期間改變均拒絕，不發布 acceptance。
- Normal runner 任一 recovery trace 在 native calls 前拒絕。Readonly recovery 需要 fresh ready、原 ownership／committed source／namespace／identity、新 source 與 immutable amendment／controller／attempt bindings；缺值／錯 recovery ID、來源或 namespace 改變均拒絕。
- Readonly recovery 成功 fixture 只走 verify-absence，原 proof hashes 不變；沒有將舊 source proof 重綁或將舊 unknown 提升。所有 command／inspect／kill 為 fakes，檔案／FIFO 僅在 synthetic scratch。

54 是當次完整 suite 數，不與先前 30／37 或中途 52 累加。

## 新 Swift host unsigned 驗證

Tester 使用兩個新的獨立 DerivedData scratch，分別執行 Debug／Rebuilt 的 `xcodebuild ... build`，均指定 `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=`：**各 exit 0、BUILD SUCCEEDED**。未覆寫舊 unsigned 產物或任何 signed current app。

兩個新 unsigned binary 都只執行明確 `--self-test`：**各 exit 0，mode=fake-only、checks=113、passed=true**。測試實際呼用 live 入口也採用的 admission／Probe.perform：recovery trace fail-closed、有效 readonly admission、nil 接受、有值／load error 拒絕，以及 readonly 操作 zero save／delete。沒有建構 LiveStore 或呼 Security。

| Unsigned variant | Binary SHA-256 |
| --- | --- |
| Debug | `ab3cecdd6dc178535ebb2312be35acb44645b2b1eb6e9dc0ea94dae9386017a6` |
| Rebuilt | `9d2eb14afc67dcfa701bfa19df91eb0849d518ba98d5b7ce480f705472db8bdf` |

Binary 不同，且實際 Rebuilt compiler log 含 `-DPAT_STORAGE_REBUILT`；不以 hash 不同單獨宣稱真人同身分重建。新 Swift source 的 strict format／strict SwiftLint 各 exit 0。E016 bounded diff whitespace 檢查 exit 0。

## 一次 native transport smoke：舊 source55 signed binary 的純 fake 分支

Root 另明確授權一次不含 DPK 的 native smoke。Tester 對原 source55 run 的已簽 app 先唯讀 verify identity／profile／binary，與既有 identity／build proof 相符；stdout／stderr 指向新 owned private scratch。

只執行一次 normal `open -a` 並帶明確 `--self-test`，沒有 `-W`／`-n`／raw executable。Native open rc=0；bounded capture 精確為舊 binary 的 fake-only、7 checks、passed=true。未重 launch、未讀原 DPK／markers、未實際 recovery 或保存／刪除；公開結果不包含 private paths／identifiers。

Smoke 前後比較原 root 既有 JSON proofs 與 current binary／embedded profile／CodeResources，共 31 檔的 hash，全部不變。原 source55 的 save A／read A／cleanup receipts、observations、unknown／accepted=false 等歷史沒有被更改。

這項 native smoke 只支持**舊 signed binary 的 normal-open transport 與 memory fake 分支**；新 Swift host 的 admission 是另一組 unsigned raw fake 驗證，兩者不能合併宣稱新 full runtime、實際 readonly recovery 或真 DPK 通過。

## 最終已核來源

| Source | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `43d27401de07cbfbb7495d3519ac761da8b95a34d969047d9034d4667bf3505a` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `23bc597cc6ec0f73ed0c633382f9150459d291aea6e9f620632356cf1750d6fa` |
| `experiments/E016/github-pat-dpk-storage/Sources/main.swift` | `5d9683aa713161cb7b340acb0e39986d159478a407693a9dcc8817d010691c27` |

三個 hash 與 [Implementer 交接](launch-wait-fix.md)一致。Tester 沒有改 critical source、舊 run／current、Apple signing assets，也沒有 stage、sign、新 round prepare 或實際 recover／load old namespace／保存／刪除。

本結果交獨立 Reviewer 判讀。若之後執行新正式 build／readonly absence recovery／新完整 PAT round，仍須新 source freeze、適用的明確授權與當段 Human ready。沒有以離線綠燈或 native fake smoke 代替 P06／真人／清理或 topic 完成。
