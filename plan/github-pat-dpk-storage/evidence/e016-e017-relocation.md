# E016 → E017：PAT 驗收工具移轉

日期：2026-11-16。Topic `github-pat-dpk-storage`、branch `feat/github-pat-dpk-storage`／Draft PR #73 不變。搬移基準 `98521e342b63eb6391e7d538882e984fcb8d39f2`；本段為 R03 實作交接，尚未 commit，不預填 Tester／Reviewer 通過。

## 現行歸屬與移轉範圍

完整 `git ls-files experiments/E016/github-pat-dpk-storage` inventory 為十檔（含 project Package.resolved），逐一 filesystem rename 到 `experiments/E017/github-pat-dpk-storage/`，mode 保持。舊十個 tracked 路徑均移出、新位置十檔完整；既有 ignored generated cache 未讀寫／移動／刪除，不把它當 source，也不宣稱舊實體父目錄全空。E017 建立前不存在，E016 編號保留給 [PR #72](https://github.com/a129924/rivet/pull/72)，該 worktree／staged 內容未操作。

八檔 byte-identical；runner 僅 docstring 編號及 HOST 常數兩字串 E016→E017，README 僅現行編號／路徑與原來源解釋，必要 current docs／index 更新。相對 package `../../..`、lockfile、schemes、bundle ID `local.rivet.pat-storage-probe`、Team／certificate／profile／group、namespace／markers／controller／gates／schema 均未改。

| 舊／新共同 suffix（舊 prefix E016，新 prefix E017） | 搬前 SHA-256 | 搬後 SHA-256 |
| --- | --- | --- |
| `PATStorageProbe.xcodeproj/project.pbxproj` | `9d94344996f070c170ab82c84d388b7909f72774f2bd495ec09df30a8d176bb5` | `9d94344996f070c170ab82c84d388b7909f72774f2bd495ec09df30a8d176bb5` |
| `PATStorageProbe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | `d830a0a546187d1a1d45339ccc324fe67b2a904e2d434a8aa34adf8a6784c52b` | `d830a0a546187d1a1d45339ccc324fe67b2a904e2d434a8aa34adf8a6784c52b` |
| `PATStorageProbe.xcodeproj/xcshareddata/xcschemes/PATStorageProbe.xcscheme` | `9ce1580cf35f394eb5947e299fd278f1fb4b524aa1c1d5f0676cd97f1f9f4ca2` | `9ce1580cf35f394eb5947e299fd278f1fb4b524aa1c1d5f0676cd97f1f9f4ca2` |
| `PATStorageProbe.xcodeproj/xcshareddata/xcschemes/PATStorageProbeRebuilt.xcscheme` | `9ec3af495a2081cb6234151c701bcbe857c1178e99e314fa34771860e4a5a42a` | `9ec3af495a2081cb6234151c701bcbe857c1178e99e314fa34771860e4a5a42a` |
| `README.md` | `6a34f0a1681f584f27975a3f89a8cebfb0c52225d8378ce095124a5e25b7fc85` | `3753e30f1282b961ed7f6dbc910fc890a971f7ad891d73cb6b2bc8308c1c2162` |
| `Resources/Info.plist` | `aed79b751eae3e3063adbf01ac23127c91860a5c59737d5c6cbcbb635123ea65` | `aed79b751eae3e3063adbf01ac23127c91860a5c59737d5c6cbcbb635123ea65` |
| `Resources/PATStorageProbe.entitlements` | `27607271f3a3f37ce30a6f07757ccd0187ae211f2f5c33bda3752c9d6b4f0cb0` | `27607271f3a3f37ce30a6f07757ccd0187ae211f2f5c33bda3752c9d6b4f0cb0` |
| `Sources/main.swift` | `5d9683aa713161cb7b340acb0e39986d159478a407693a9dcc8817d010691c27` | `5d9683aa713161cb7b340acb0e39986d159478a407693a9dcc8817d010691c27` |
| `Tests/test_probe.py` | `23bc597cc6ec0f73ed0c633382f9150459d291aea6e9f620632356cf1750d6fa` | `23bc597cc6ec0f73ed0c633382f9150459d291aea6e9f620632356cf1750d6fa` |
| `scripts/pat_storage_probe.py` | `43d27401de07cbfbb7495d3519ac761da8b95a34d969047d9034d4667bf3505a` | `391be0ce975daacf42a9e499063f7d1704be31206b2c440f700b7c176de97023` |

## 兩條證據鏈與固定來源

1. [E006 既有結果](https://github.com/a129924/rivet/blob/98521e342b63eb6391e7d538882e984fcb8d39f2/experiments/E006/README.md)、[E007 未知限制](https://github.com/a129924/rivet/blob/98521e342b63eb6391e7d538882e984fcb8d39f2/experiments/E007/README.md)與 [E015 機制／真人證據](https://github.com/a129924/rivet/blob/98521e342b63eb6391e7d538882e984fcb8d39f2/experiments/E015/github-oauth-credential-persistence/README.md) → 既有 OAuth DPK 機制與 PAT 值語義被選擇性採用到[正式 PAT adapter](https://github.com/a129924/rivet/blob/5465d3c7308e74bc2b3b51878acd190d4f2babda/Sources/BoundedContexts/GitHubIntegration/Stores/GitHubPATDataProtectionStore.swift) → [原 E016 host](https://github.com/a129924/rivet/blob/5465d3c7308e74bc2b3b51878acd190d4f2babda/experiments/E016/github-pat-dpk-storage/Sources/main.swift)／[原 runner](https://github.com/a129924/rivet/blob/5465d3c7308e74bc2b3b51878acd190d4f2babda/experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py)的指定環境實機驗收。E007 renewal 的無法判定與 Human 接受限制原樣保留。
2. 原驗收工具的[搬前完整位置](https://github.com/a129924/rivet/tree/98521e342b63eb6391e7d538882e984fcb8d39f2/experiments/E016/github-pat-dpk-storage) → [現行 E017 工具](../../../experiments/E017/github-pat-dpk-storage/README.md)。這條是工具歸屬／路徑鏈，不是重新簽章或 live 成功鏈；搬後新來源未做 signed build／Run／DPK／Human 重驗。

原 source `5465d3c7308e74bc2b3b51878acd190d4f2babda`、run `39c22b57-de4f-463c-aa4b-8de277c1f60a` 的[真人紀錄](https://github.com/a129924/rivet/blob/98521e342b63eb6391e7d538882e984fcb8d39f2/plan/github-pat-dpk-storage/evidence/live-validation.md)、[公開 export](https://github.com/a129924/rivet/blob/98521e342b63eb6391e7d538882e984fcb8d39f2/plan/github-pat-dpk-storage/evidence/live-run-39c22b57.json)與 [P07 review](https://github.com/a129924/rivet/blob/98521e342b63eb6391e7d538882e984fcb8d39f2/plan/github-pat-dpk-storage/evidence/live-review.md)固定其原 E016 路徑／九項 source proof keys／hash，不重算、不改寫。原 source0b setup／source55 read A及cleanup unknown、readonly qualified absence 與各次 Human 觀察保持，E017 不追補為新版本通過。

## R03 已檢查與待驗

- 實際十檔 inventory／mode／八檔 bytes 比對及 runner 兩字串精確差異完成；本題所有既有 tracked evidence 與圖 bytes 的前後 SHA-256 相同。Production Sources／Tests／Package 等未改；私有 Xcode／.swiftpm／原 runs／signed artifacts／receipts 未操作。
- 新／舊路徑 mapping、current docs links 與歷史例外明確：既有 evidence、原 P03／TC05、frozen 圖中的 E016 是原版本歷史，不能全域替換；新紀錄以固定 GitHub commit links 保持可追溯。
- R04 待獨立 Tester 親跑新 E017 Python54、全新 scratch DerivedData／SourcePackages 的 Debug／Rebuilt unsigned compile與各113 fake checks、format／lint／links；R05 待獨立 Reviewer。R03 不自行跑這些完整檢查、不發 approval。
- 不另重跑無受影響 root／consumer；原 commit hooks 的必要檢查留 R06。HC04／HC05 pending、topic 不標 complete，無 merge／ready。

## R06 publication 前追加 snapshot

R04 [獨立測試](e016-e017-tests.md) completed，R05 [獨立 review](e016-e017-review.md) approved／required fixes 0；以下是 publication 前唯讀重查，不取代原 Explorer 當時 snapshot。PR72 已由其他工作線合併，原 head `641789fad88d2a3ad7e3fe990fa56d1c0e540fe3`，merge／remote dev 為 `88ec4a0e13bf68fb489fd9b06895591a0663ba53`；該新 tree 無 `experiments/E017` 或獨立 E017 編號宣告。其 worktree 當時已 clean，未由本工作修改。

其餘 remote heads 為 docs `82b64bbb8076f0128074ed559f0302c8594d88dd`、本 feature `98521e342b63eb6391e7d538882e984fcb8d39f2`、main `3ec3042bc9ab9b4604c89117e1369b0815ddd414`，均與原 snapshot 相同；open PR 僅未變的 #68 與本題 #73。本題已核准的新 E017 目錄不算其他 topic 占用。沒有 fetch、改別 worktree、重選編號或改原 live 來源。R06 staged semantic review／原 hooks／commit／push／PR73 回讀尚待本次實際執行，後續以本題 Git history 與帳本記錄。

## R06 實際 publication 與停點

搬移 commit [`831b0f12e33d28d722c6584a2e0948851be0ffbc`](https://github.com/a129924/rivet/commit/831b0f12e33d28d722c6584a2e0948851be0ffbc) 已完成 staged semantic review：僅十檔 rename、六份 current metadata 與四份本次新 evidence；八檔 bytes／十檔 modes 不變、runner 僅兩字串，production／舊 evidence／圖零差異，無私人值或本機絕對路徑。原六 hooks（whitespace、EOF、Swift format、consumer contract、SwiftLint、renderer）全部 Passed，沒有 skip。

已 push 既有 `feat/github-pat-dpk-storage`，remote HEAD 與該 commit 一致；[原 Draft PR #73](https://github.com/a129924/rivet/pull/73) 更新後讀回 body 完全一致，head 同該 commit、base `dev`、Draft=true、merged=false。PR 說明區分正式 Sources 實作、原 source5465／E016 實機驗收與 E017 離線搬移結果，保留原成功／unknown、PR Lens 初始範圍與 Graphify 限制。

本節及帳本為其後最小 publication metadata 收尾，該 commit／push 由本題 Git history 定位，避免自我 SHA 引用；沒有重跑 runtime／DPK、改舊收據、原 source keys／hash 或私人資產。R06 completed，HC04／HC05 仍 pending，保留 Draft 並停 Human review，不 merge／ready／標 topic complete。
