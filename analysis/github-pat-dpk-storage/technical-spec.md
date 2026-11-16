# PAT DPK 儲存：技術規格

需求見 [requirements](requirements.md)，執行與追蹤見 [plan](../../plan/github-pat-dpk-storage/github-pat-dpk-storage.plan.md)／[step](../../plan/github-pat-dpk-storage/github-pat-dpk-storage.step.md)。基準與分支沿用 requirements，不新增 BC、target、product 或 dependency。

## 公開契約

新增單一公開 actor，不新增無使用需求的 protocol，也不 conform 既有同步 `GitHubTokenStore`：

```swift
public enum GitHubPATDataProtectionStoreError: Error, Sendable {
  case denied
  case unavailable
  case corrupt
  case invalidConfiguration
}

public actor GitHubPATDataProtectionStore {
  public init(
    accessGroup: String,
    service: String = "local.rivet.github.pat.v1"
  ) throws(GitHubPATDataProtectionStoreError)

  public func load() async
    throws(GitHubPATDataProtectionStoreError) -> PersonalAccessToken?

  public func save(_ token: PersonalAccessToken) async
    throws(GitHubPATDataProtectionStoreError)
}
```

Caller 提供 explicit access group；空字串或純空白 group／service、含 wildcard 的 group 回 invalidConfiguration。檢查空白不改寫 caller 的 namespace。Constructor 不呼叫 Security。Actor 的 internal Security injection seam 僅供受控測試，與公開 actor／錯誤／private payload 放在同一新 store 檔案，不改 OAuth backend 或抽取共通 framework。

## Query、格式與失敗

- 固定 generic-password、account=`pat`；每次 query 指定 group／service／account、`kSecUseDataProtectionKeychain=true`、`kSecAttrSynchronizable=false`。讀取限一筆並取 Data。新增採 `AfterFirstUnlockThisDeviceOnly`。預設 service=`local.rivet.github.pat.v1`；允許 caller 指定隔離 service。
- 即使 caller 選與 OAuth 相同 service，PAT account 仍與 OAuth `configuration`／`credential` 不同；legacy service／account 與 DPK selector 不被採用。不保存 GitHub account ID、OAuth clientID、scope 或 expiry，不引入 identityMismatch。
- Private Codable JSON 僅 `schemaVersion: Int` 與 `token: String`，版本固定 1。缺欄、錯誤型別、無效 JSON、未知版本、空 token 或既有 `PersonalAccessToken` 建構後 rawValue 不等於 stored token，皆回 corrupt；不 trim 修復壞資料，不改公開 VO 為 Codable。
- 只有 errSecItemNotFound 表示 nil；成功但缺 Data 為 corrupt。errSecAuthFailed／errSecUserCanceled 為 denied，errSecDecode 為 corrupt，其餘系統失敗（包含 interaction-not-allowed／missing entitlement）為 unavailable。編解碼失敗映射 corrupt，公開錯誤沒有 underlying NSError、userInfo 或任意訊息。
- 每次 save 先 load／嚴格校驗既存資料；corrupt／denied／unavailable 時零寫入。以完整 Data update；item-not-found 才 add；add duplicate 最多再 update 一次，任何剩餘失敗回有限錯誤。不 delete 舊 item、不補寫舊值、不宣稱系統原子性。
- 同 actor 的每個 read-check-write 在同步 Security calls 間無 suspension，不以 Task 分拆寫入。只保證同實例序列化，不承諾跨實例／跨程序寫入交易或斷電 durability。
- PAT 沿用固定 description／debugDescription／customMirror 遮蔽。新 store、private payload、錯誤與 runner 不輸出 token／payload、片段、長度、雜湊或原始 error；公開 evidence 僅有限結果。明確讀 rawValue 仍取得敏感值，不宣稱 debugger／記憶體防護。

## ReadOnly／Written／Deleted／Modify

以下是受限變更集合；ReadOnly 為允許讀取、不允許修改，Written 為新增檔，Modify 為既有檔的受限修改。四份 planning artifacts 建立後仍允許由其 owner 維護本 topic 的契約與狀態。

| 類別 | 路徑與限制 |
| --- | --- |
| ReadOnly | `Package.swift`、`Tests/GitHubIntegrationConsumer/Package.swift`；`Sources/BoundedContexts/GitHubIntegration/Contracts/**`、`Composition/**`、`Providers/**`、`OAuth/**`；既有 `Stores/GitHubOAuthDataProtectionStores.swift`、`Stores/KeychainTokenStore.swift`（以上省略的前綴均為 `Sources/BoundedContexts/GitHubIntegration/`）；既有 OAuth／PAT 測試（下列 Modify 檔除外）；`docs/architecture/github-oauth-credential-persistence.md`、`docs/architecture/github-dual-login-contract.md`；E006／E007／E015 相關來源與歷史證據；使用到的 SKILL／設定檔。 |
| Written | `Sources/BoundedContexts/GitHubIntegration/Stores/GitHubPATDataProtectionStore.swift`；`Tests/GitHubIntegrationTests/GitHubPATDataProtectionStoreTests.swift`；`Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PATStorageContractTests.swift`。 |
| Written | `experiments/E017/github-pat-dpk-storage/**`，現行工具位置由本次受限移轉建立；原 P 階段為 E016，限本 topic 的 Xcode project／schemes、Swift host、Info／entitlements 範本、runner、專屬測試與 README；不新增 root target 或相依。 |
| Written | `docs/architecture/github-pat-dpk-storage.md`；`docs/architecture/diagrams/github-pat-dpk-storage/**`，限保存還原 sequence 的 JSON／HTML、skill 產生 snapshot／receipts／截圖及視覺證據。 |
| Written | `analysis/github-pat-dpk-storage/requirements.md`、`analysis/github-pat-dpk-storage/technical-spec.md`、`plan/github-pat-dpk-storage/github-pat-dpk-storage.plan.md`、`plan/github-pat-dpk-storage/github-pat-dpk-storage.step.md`、`plan/github-pat-dpk-storage/evidence/**`，限本 topic 的 implementation／tests／review／工具與 live 證據。 |
| Modify | `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：expectedPaths 與 securityFiles 各加入新 store，不放寬其他 dependency 或 import 限制。 |
| Modify | `README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、`experiments/README.md`：只同步本題能力、導覽、現行 E017 歸屬與原 E016 驗收證據限制。 |
| Deleted | 原 P 階段無檔案刪除；本次僅將舊 E016 tracked inventory 與新 E017 路徑成對移轉，不刪功能／歷史證據。owned DPK item 清理不屬本次操作。 |

原 P 階段採 E016 的規劃／實作／真人驗收歷史保留。本次 Human 明確決定 PAT 工具移至 E017、PR #72 保留 E016；Explorer 已核 E017 available。正式搬移前核 target 仍不存在；若出現占用或必要行為／簽章契約變更，停止回報，不臨場換號或擴 scope。其他分支／worktree 不在寫入範圍。

## TestCase

| ID | 情境與必要結果 | AC |
| --- | --- | --- |
| TC01 | 一般 import consumer typecheck init／load／save 的公開 API、Sendable 與有限 error；可測無 Security 的 constructor validation，不執行真 Security。fake Security 驗證 PAT 往返。 | AC1 |
| TC02 | 缺值 nil；有效 A→完整 B；缺 Data／JSON／欄位／型別／版本／空 token／非 canonical token 為 corrupt；拒絕／不可用／編解碼與保存失敗分類；讀取異常零 update／add。 | AC1、5、6 |
| TC03 | 精確 read／update／add query、accessibility、sync=false；相同 service 下 PAT／OAuth account 隔離；legacy selector 不被操作。 | AC4 |
| TC04 | continuation／barrier 或同步 fake 觀察同 actor 操作完整序列，不用 sleep 推測；update→notFound→add→duplicate→一次 update，各失敗不假報成功；PAT／錯誤／runner 遮蔽；受影響既有 OAuth 測試回歸。 | AC6、7、8 |
| TC05 | E016 真 DPK：save A→writer 結束→fresh A→replace B→fresh B→真正 clean/build→rebuilt fresh B→exact owned cleanup→正式 load=nil；獨立記來源／產物／Human 提示。原先 deferred；Human 續行後，source `5465d3c`／run `39c22b57` 已完成並經 P07 approved，見 live 證據。 | AC2、3、8、9、10 |

## 獨立驗證 host 與 ownership

正式 adapter 留 production；E016 只用 public import，不複製 PAT 儲存實作。選擇性採用 E015 必要的純控制／程序／ownership／脫敏收據機制，保留來源映射，不搬入整套歷史流程、不承接 OAuth 的 ready／額度／結果／清理權限。

Host 提供非機密 A／B 與上述受限序列。離線可驗 runner 的實際控制路徑及 unsigned compile，不以另一套平行假流程冒稱 host 接入成功。移除 E016 不影響正式 target 的建置。每 run 唯一 service；先耐久記 absence，再記 write-attempt ownership，才呼正式 save。失敗或可能提交後保留 marker／同 run，不換新 service 掩蓋。

Cleanup 僅限有 ownership 的 exact DPK group／service／pat account，由驗證工具刪除，接著正式 load=nil。無 proof 不猜測刪除；未知或仍活 child 不啟動後續依賴。清理失敗保留恢復交接，不刪 OAuth 歷史項目或 Apple signing assets。

每次 live preflight 核對當次有效 profile／certificate、entitlements、App ID／group、DR 與固定啟動位置；同身分重建僅相對 PAT host 本身，不要求與 OAuth host 同 App ID。每段前一程序已結束，新程序有獨立 proof；重建需真正 clean/build、不同產物及相同身分證據，不只重啟舊 binary。Human 全段觀察 save A ≤1 次，其餘 replace B／fresh A／fresh B／rebuilt B 各 0 次；build／sign 提示另列，缺觀察不是 0。

收據綁定本題來源、正式 adapter、產物、run、操作與 Human 實際觀察；公開投影不帶私人 identifiers／本機絕對路徑／PAT／原始錯誤。unknown／failure 保留，停止依賴段。初次 Human 要求先跳過 live；後續另經明確授權，已完成指定來源／run 的正式序列與 P07 approved，詳見 [live-validation](../../plan/github-pat-dpk-storage/evidence/live-validation.md)／[live-review](../../plan/github-pat-dpk-storage/evidence/live-review.md)。本次 metadata 回寫不授權新 signing assets、額外 signed host 或 Keychain 操作。

## 採用映射

| 來源 | 本題採用 | 新證據 |
| --- | --- | --- |
| 正式 OAuth DPK store／長期契約 | explicit query、accessibility、有限錯誤、read-check-write、完整替換 | PAT 專屬 TC02–04，不引用 OAuth 舊結果當通過 |
| 雙登入契約／PersonalAccessToken | trim／空值語義及診斷遮蔽 | PAT roundtrip、strict restore 與診斷測試 |
| E015 正式 adapter host | 必要接線、程序／重建、ownership、有限收據 | E016 離線控制與未來 TC05 |
| 本題新增 | PAT actor、private schema、一般 import consumer | implementation／tests／review 證據 |

## E016 簽章建置模式補充

工具明確提供 manual／automatic（預設 manual）。Automatic 僅使用已準備的 cached signing assets，不加 provisioning 更新旗標；三欄私人 settings 的 identity 為 selected certificate 的 40-hex SHA1。產物在安裝／發布成功 proof 前須核對 selected Team、profile Name、certificate SHA1 與既有 group／App ID 條件；兩種模式都不得默默替換身分。此為驗證 host 的環境相容選項，不改正式 PAT 儲存介面。來源變更後另建有界 round、保留原失敗與 Human 觀察，並取得新階段 ready。

## E016 等待與只讀 recovery 補充

正常 launch 使用固定 `open -a`，不帶 `-W`／`-n` 或 raw live binary，仍要求 native rc=0。Secure receipt 有界等待與完整校驗後，只對已驗正整數 PID 以 signal 0 等待 ESRCH；權限／其他錯誤或 timeout 拒絕，退出後 receipt 穩定才發布 acceptance。這替換有 kevent 失敗證據的等待實作，不弱化前一程序結束或新程序證據。

只讀 recover-absence 另建 immutable amendment／controller，綁原 Git source／namespace／ownership 與新正式 host 身分／來源；不改原 proofs。Runner 與 Swift host 皆在 Security 前將 recovery 限為 verify-absence，僅正式 load=nil，不能 save／delete 或進普通 phases。新觀察不借用舊 0 次提示，不把原 unknown 改判。

## R 階段現行路徑與變更集合

本節是本次 relocation 的唯一寫入授權，覆蓋上方已完成 P 階段的廣泛 Written／Modify 清單；不重新授權改產品程式。以 `98521e3` 的 `git ls-files` 完整 inventory 做一對一移轉：

| 舊 E016／新 E017 共用 suffix | 搬移後內容要求 |
| --- | --- |
| `PATStorageProbe.xcodeproj/project.pbxproj` | byte-identical；相對 package `../../..` 層級不變 |
| `PATStorageProbe.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | byte-identical，固定版本不變 |
| `PATStorageProbe.xcodeproj/xcshareddata/xcschemes/PATStorageProbe.xcscheme`、`PATStorageProbeRebuilt.xcscheme` | 兩個 schemes 各 byte-identical |
| `Resources/Info.plist`、`Resources/PATStorageProbe.entitlements`、`Sources/main.swift`、`Tests/test_probe.py` | 四檔各 byte-identical |
| `scripts/pat_storage_probe.py` | 只改 docstring 的 E 編號及 HOST 常數 `E016`→`E017`；其餘 bytes 不變 |
| `README.md` | 只改現行操作路徑／編號、補新舊歸屬及固定歷史 links；不重寫原驗收結果 |

Bundle ID `local.rivet.pat-storage-probe`、Team／certificate／profile／group、namespace／markers、controller／gates／schema 不變。新位置不沿用原私有 signed setup root 或修改其 package reference。

| 欄位 | 本次 R 階段限制 |
| --- | --- |
| ReadOnly | 所有 production `Sources/**`、`Tests/**`、root／package manifests；上述 host 除 runner／README 外八檔內容；所有既有 `plan/github-pat-dpk-storage/evidence/**`、圖 bytes 與其他 topic／PR72；兩處原 private `.swiftpm`、私有 Xcode 副本／runs／signed artifacts／receipts／Human 觀察不操作。 |
| Written | `experiments/E017/github-pat-dpk-storage/**` 只接收上述十檔；新 evidence 僅 `e016-e017-relocation.md`、`e016-e017-planning-review.md`、`e016-e017-tests.md`、`e016-e017-review.md`，皆位於本題 evidence 目錄。 |
| Modify | 四份 planning artifacts；搬後 runner／README 的上述最小差異；`README.md`、`docs/design-principles.md`、`docs/architecture/README.md`、`docs/architecture/github-pat-dpk-storage.md`、`experiments/README.md` 只同步現行歸屬／links與歷史界線。 |
| Deleted | 只移除舊 `experiments/E016/github-pat-dpk-storage/` 十個 tracked 路徑，必須各有新位置對應；不額外刪檔，不清 private assets 或 DPK item。 |
| TestCase | TC-R01 完整 inventory／rename／八檔 bytes／runner 僅兩字串差異／相對 package／settings／身分 namespace 不變；TC-R02 現行 paths／links 與 historical exceptions；TC-R03 新 E017 Python 54 tests；TC-R04 Debug／Rebuilt unsigned compile 與各 113 fake-only checks；TC-R05 strict format／lint／diff 與原 commit hooks。 |

TC-R04 各 variant 使用本次全新 scratch DerivedData／SourcePackages，明確 `CODE_SIGNING_ALLOWED=NO`、`CODE_SIGNING_REQUIRED=NO`、`CODE_SIGN_IDENTITY=`；禁止 provisioning updates／device registration／簽章／live app Run。只允許 unsigned binary 明確 `--self-test` fake-only 分支，不呼 DPK。不得使用或修改原 signed setup roots、Xcode 副本或既有 private package metadata；若 build 必須改動這些狀態，停止回報限制。Root 324／consumer 18 不另重跑，原 hooks 自行要求的檢查照常。

移轉證據記完整 mapping／內容 hash、原 `5465d3c` 與 `98521e3` 固定 GitHub links、新舊兩條採用／驗收鏈。既有 evidence 的舊 E016 keys／argv／links、原 P03／TC05 歷史與 frozen 圖為明列 historical exceptions，保持 bytes；不能全域替換舊路徑。Current docs 改指 E017，歷史來源改以新 mapping 的固定 commit links 解釋，不修改原證據。

R 階段現況（2026-11-16）：R04 [獨立測試](../../plan/github-pat-dpk-storage/evidence/e016-e017-tests.md)完成、R05 [獨立審查](../../plan/github-pat-dpk-storage/evidence/e016-e017-review.md) approved／required fixes 0；R06 publication 進行中，實際結果依帳本與 Git／Draft PR #73 記錄，不預填推送成功。HC04／HC05 仍 pending，topic 不標 complete。
