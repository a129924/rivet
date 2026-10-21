# 獨立驗證 host amendment 證據

- 日期：2026-10-20；基線 `e63eeb21b4774adafc5f8a822ac474df7e0bdc22`，原 feature branch／worktree／Draft PR #61。
- A02 外部 verdict：獨立 Plan-Reviewer approved，無required fix；四artifacts一致，16rename/delete與圖revision/AT01–05足以驗證。
- Implementer：16筆rename已完成，共用UI及其測試收納App；無正式OAuth/lifecycle/PRInbox/rootPackage source diff。九欄與精確manifest見plan/step。
- A04 獨立 Tester 已完成以下親跑與隔離核對；不代表 A05 Reviewer approved。
- 圖：Archify v3九checks、零errors/warnings，4viewport與4截圖實看；canvas v2 validate/build零errors/warnings，互動視覺Human pending。舊frozen圖指紋未變，工具收據見相應docs。
- 舊正常OAuth與再次API證據屬e63eeb2舊host；2026-10-21已另取得e941d88新host正常授權與同程序再次API的實際觀察，見A07。反向PKCE與其他未驗證遠端項目仍Human pending。
- Graphify 0.9.73無圖、source fallback；PRLens local真commit diff待交付。未讀取或保存先前callback/code/state/secret。

## A04 獨立 Tester 實際驗證

2026-10-20。基線 HEAD `e63eeb21b4774adafc5f8a822ac474df7e0bdc22`；受驗為同 branch dirty amendment，非已提交的新 head。Changed/new/deleted source/project/test 指紋：`e217713dc453620560253023448f79810e66b5b35c4c0d73e32d017137f554d8`。範圍為 git diff 與 untracked 聯集中的 Sources、Tests、apps 相對路徑，排序後串接 path、NUL、bytes（刪除用 `<deleted>`）、NUL 計算 SHA-256；排除 ignored build outputs。

| 親跑命令 | 實際結果 |
|---|---|
| `swift test` | exit0；275 tests／34 suites passed |
| `scripts/check-github-integration-consumer.sh` | exit0；13 tests／3 suites passed |
| `scripts/check-swift-format.sh` | exit0 |
| `scripts/check-swiftlint.sh` | exit0；127 files，0 violations |
| `swift format lint --strict --recursive apps/GitHubSignInVerification/Sources apps/GitHubSignInVerification/Tests` | exit0 |
| `swiftlint lint --strict apps/GitHubSignInVerification/Sources apps/GitHubSignInVerification/Tests` | exit0；12 files，0 violations |
| `xcodebuild -project apps/GitHubSignInVerification/GitHubSignInVerification.xcodeproj -scheme GitHubSignInVerification -destination 'platform=macOS' -derivedDataPath .build/github-first-sign-in/VerificationHostDerivedData CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES build test` | exit0；TEST SUCCEEDED；9 tests／5 suites passed |
| `node <archify-skill>/bin/archify.mjs validate sequence docs/architecture/diagrams/github-first-sign-in/authorization-sequence-v3.json --quality showcase --json` | exit0；9 checks，0 composition errors／warnings |

Root 減少一項 Presentation test、驗證 App 增加一項 app-local Presentation test，符合搬移；非刪除測試能力。所有執行測試的命令均在指定 feature worktree 執行，需寫 build/cache 時以既有授權升權；未更動產品程式。Shell logs 以 `rivet-verification-host-tester-*` 命名保存於外部 scratch，不加入版控；xcresult 在 ignored VerificationHostDerivedData。

### AT 對照

- AT01：舊 apps/Rivet 不存在；新 project/scheme/entry/target/product/module/test host 一致使用 GitHubSignInVerification。Bundle 為 local.rivet.github-sign-in-verification；新 build/test 成功。
- AT02：scheme 與 entry 同用 `GITHUB_SIGN_IN_VERIFICATION_UNIT_TEST_MODE=1`；entry 在建立依賴前選 disabled。Hosted tests 的 fake counter／真 loopback local 測試通過，不輸入個人 OAuth 配置、不發起真 OAuth。原 coordinator 四項含 gatedrefresh settlement 與 app-local Presentation 一起通過。
- AT03：UI 型別不再 public；UI 與測試位於 App。`rg` 核對 Sources/Presentation 與 Tests/RivetPresentationTests 無 GitHubConnection／GitHubSignInVerification；新 project 無 RivetPresentation dependency。PRInbox source/tests 與 root Package.swift/Package.resolved 相對基線 diff 為空。
- AT04：GitHubIntegration source/tests、consumer、PRInbox、root package diff 為空。App 搬後 Package.resolved bytes 與基線舊 app lock 完全一致；root/consumer 全套與適用 strict checks 通過。
- AT05：親跑 Archify v3 showcase validate，核對 delivery spec/artifact SHA 與檔案一致；12 個舊 frozen diagram 檔案逐檔 bytes 與基線相同。v3 visual-check receipt 顯示四 viewport containment pass；四截圖實看屬 Implementer／主 agent 的明示紀錄，本 Tester 未重截或代稱親看。Canvas v2 validate/build 依交接紀錄，互動仍 Human pending；未繞過 URL policy。Graphify 無可用圖採 source fallback，未建圖。PR Lens 待 A06 真 commit diff。

### 限制與結果分層

A04當時沒有 required test failure。當時舊正常授權及再次 API 僅為 e63eeb2 舊 host 證據，新 host live 仍未驗證；2026-10-21的新host結果另記A07。反向 PKCE、canvas 互動、完整遠端 refresh/401、持久化仍未驗證。本輪未操作舊 live app、讀取真 secret 或保存 callback。全部受控 pass 不代表 Human 接受或獨立 Reviewer approved。

### 九欄完成交接（Tester）

- In-Scope：A04／AT01–AT05 受控測試、source isolation、圖 receipt/hash/validate。
- Out-Of-Scope：實作、Git mutation、PR、live OAuth、遠端設定與其他worktree。
- ReadOnly：四planning、正式source、搬移app/tests、舊frozen圖與工具證據。
- Written：無新repository檔案；只有ignored build/cache及外部scratch logs。
- Deleted：無。
- Modify：本 evidence 與 `plan/github-first-sign-in/github-first-sign-in.step.md` 的A04實際事實；不改舊歷史測試結果。
- Goal：交獨立Reviewer可核對的實際命令、source指紋、AT結果與限制。
- Non-Goal：不替A05核准或宣稱新host真GitHub已驗收。
- TestCase：275 root＋13 consumer＋9 app passed；root/app format/lint passed；AT05受限項目如上。

## A05 獨立 Reviewer 明示結果

2026-10-20，獨立 Reviewer `/root/plan_review` 唯讀審查，主 agent 依明示回覆轉錄：**approved，無 required fix**。逐一比較16搬移檔，變更限於識別、app-local存取、引用／依賴及核准文字；正式OAuth/lifecycle/PRInbox未變。文件與新圖區分正式能力、驗證host、未交付產品UI，歷史證據標基線；Tester275/13/9與checks一致。允許依授權commit/push更新原DraftPR61，保留Human pending且不merge。

## A06 發布記錄

回修commit `81fe01f3377abbf7e7382d2c77fc756034c4fffc` 已push原feature branch；原[Draft PR #61](https://github.com/a129924/rivet/pull/61)標題與描述已更新。全部pre-commit hooks通過；本交付記錄只改文件。真base/head的PRLens本機map於最終head後產生，結果在PR與交付回報。仍停Human review，未merge，所有Human pending不變。

## A07：2026-10-21 新驗證 App 真人協助驗收

來源版本：`e941d88`。使用既有 `.build/github-first-sign-in/VerificationHostDerivedData` 測試後 build，產品 source 與該版本一致；本次沒有重建新 build，以正常模式執行。

Human 自行輸入 OAuth App 配置並完成瀏覽器授權，只回報靜態 callback 頁文字。主 agent 以 CUA 觀察獨立 GitHubSignInVerification 視窗：初次真實 `/user` 查詢成功，身分欄位有效；主 agent 再操作「再次查詢」，完成後 AX 確認 `apiSuccess=true`、`busy=false`、`knownFailure=false`，未重新授權。Tester 依 Human 與主 agent 明示觀察記錄，沒有另操作 live app 或重跑測試。

- 新 host 正常授權 → 真實 `/user`：observed passed。
- 同程序再次查詢：observed passed，身分欄位有效；本紀錄不保存其值。
- 反向 PKCE、完整遠端 refresh／401、canvas 互動視覺：仍 pending／未驗證。
- 全部 Human review、merge 或 topic 完成：未宣稱通過。

本次只更新本 evidence 與 step 的 A07 事實，不新增實作、manifest 或 gate，不更改歷史測試與審查結果；未執行測試、build、Git mutation，不保存帳號、Client ID、secret、callback URL、code、state、token 或 screenshot。
