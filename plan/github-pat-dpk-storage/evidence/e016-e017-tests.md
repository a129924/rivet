# R04 — E016→E017 獨立 Tester

日期：2026-11-16。基準 HEAD `98521e342b63eb6391e7d538882e984fcb8d39f2`；以下為搬移後、尚未提交的 feature worktree 實測。依 R02 approved／R03 交接執行，Tester 結果 **全部必要離線檢查通過**，交 R05 獨立 Reviewer；不代判 Reviewer gate。

| TestCase | 親跑結果 |
| --- | --- |
| TC-R01 | 原 HEAD E016 完整十檔逐一對應 E017，十個原 tracked paths 移出；十檔 mode 均保持。Project、Package.resolved、兩 schemes、Info、entitlements、Swift host、Python tests 共八檔 byte-identical；runner 精確只改 docstring／HOST 兩字串；README 差異限 current paths／歸屬與歷史說明。 |
| TC-R01 邊界 | Production Sources／Tests／root與package manifests 無 diff；相對 package `../../..` 正確指 root。Identity、bundle ID、namespace／markers／schema／gates 未改，無新設定。 |
| TC-R02 | 四份 current／mapping 文件中 45 個相對 links 存在，28 個固定 full-commit links 的 Git objects 存在；current index／PAT doc 指 E017。原 P 歷史、既有 evidence／export keys 與 frozen 圖的 E016 為明列 historical exceptions，mapping 保留原 `5465d3c`／`98521e3` 及兩條採用／驗收鏈。全部34份既有 evidence／圖在建置前後逐 bytes 同 HEAD。 |
| TC-R03 | `PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s experiments/E017/github-pat-dpk-storage/Tests -v`：54 tests／0.437s／exit 0。未建立 bytecode cache。 |
| TC-R04 | 實際 E017 project，Debug／Rebuilt 各自全新獨立 DerivedData／SourcePackages：兩 build 均 exit 0／BUILD SUCCEEDED。兩 unsigned binary 僅執行明確 `--self-test`，各113 fake-only checks passed／exit 0／stderr 空。Binary 不同，Rebuilt compiler `PAT_STORAGE_REBUILT` 生效。 |
| TC-R05 | 對搬後 Swift host 各自親跑 `swift format lint --strict`、`swiftlint lint --strict --quiet`，以及 `git diff --check`：各 exit 0、無診斷。原 commit hooks 留 R06 正常執行，不在此宣稱通過。 |

Unsigned build 指令以搬後 project 配合 scheme／configuration `PATStorageProbe/Debug`、`PATStorageProbeRebuilt/Rebuilt`，各指定新的 `-derivedDataPath`／`-clonedSourcePackagesDirPath`，使用 `-disableAutomaticPackageResolution -onlyUsePackageVersionsFromResolvedFile -skipPackageUpdates CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=`。兩 build logs 均無 CodeSign step／provisioning flags。原兩處 private .swiftpm 僅 stat，12 entries 前後一致；原 signed 副本／runs／receipts 未操作。舊 E016 ignored cache 未讀寫／刪除。搬後 inventory 仍僅十檔。

| 來源／產物 | SHA-256 |
| --- | --- |
| E017 runner | `391be0ce975daacf42a9e499063f7d1704be31206b2c440f700b7c176de97023` |
| Swift host | `5d9683aa713161cb7b340acb0e39986d159478a407693a9dcc8817d010691c27` |
| Debug unsigned binary | `8e02e9030b59dfd8be9ceda558a420602a88a1f21a63687225f95e02f1fe7673` |
| Rebuilt unsigned binary | `a8dd5f17fe2c9e70720ae3850fe752ed365f56d1445ad2d75f7aaf35b9038180` |

完整十檔 hashes 親核與 [R03 mapping](e016-e017-relocation.md) 相符。原始 build logs／stat／inventory 只留本次新私有 scratch，安全定位交 Reviewer，不把私人路徑或內容寫入此文件。未重跑無受影響 root324／consumer18；未 sign／provision／live Run／DPK／Human 重驗。既有真人成功、unknown、Human 觀察、HC04／HC05 pending 不改；本次離線通過不冒稱 E017 新來源真人驗收通過。
