# 獨立 Planning Review

- Topic：`github-oauth-credential-persistence`
- Role：Plan-Reviewer
- 日期：2026-10-20
- Verdict：`approved`
- Required fixes：無。

## 受審範圍

唯讀核對本 topic 的 requirements、technical-spec、plan、step 四份正式 artifacts，並依 README、設計原則與 Plan-Reviewer skill 檢查範圍、公開契約、九欄 manifest、測試可執行性及角色界線。本次不審查、修改或採用他人的 persistent-connection／E007 產出。

## 審查結果

- 使用者的獨立 topic scope override 已記錄；本 topic 的程式、fake tests 與 Draft PR 不依賴他人的 renewal／live gate，亦不宣稱真 DPK、跨程序、簽章或提示 UX 已驗證。
- Additive configuration／兩 item stores、clientID-bound adapter、strict codec 與有限錯誤可在所列 source／tests leaves 交付；既有 ports、provider、clients、package 與他人 artifacts 保持唯讀。
- Bound save 的 read-check-write 及 update-add-update 均由同一 actor 的同步 operation 保護。T04 的 shared actor 驗證依 technical-spec §2 限定同一 stores facade 內的 configuration store、inspect 與各 bound stores；不同 stores facade／程序不承諾協調。
- T01–T06 可透過 internal fake Security seam、既有 provider 與可注入時鐘執行；不需新增 live Security 操作、provider policy 或 public transport injection。
- 九欄與精確 manifest 涵蓋程式、consumer test、長期文件、單張 storage sequence 及角色 evidence；審查者只寫自身 evidence／S02 結果，不代寫受審設計或實作。
- Archify 為必要文件交付；PR Lens／Graphify 的 bounded 使用、外部 scratch 與具體 fallback 不新增 gate。Human 圖面觀察未取得時保持 pending，不能冒稱接受。
- Branch、base／PR target、獨立 Tester／Reviewer 與已授權 commit／push／Draft PR 邊界一致；不包含 merge。

## 限制

本 verdict 僅核准四份 artifacts 所界定的受限執行契約，不代表實作、測試、圖交付、真系統保存或產品流程已通過。本 reviewer 未執行測試、Git、Security、簽章、產圖或發佈。


## Bounded amendment review：靜態隔離 allowlist（2026-10-20）

- Role：Plan-Reviewer
- Verdict：`approved`
- Required fixes：無。
- 僅回查 plan 的 M01／ReadOnly amendment 與既有 StaticIsolationTests 的對應檢查位置，不重審整個 topic、不改受審測試。
- M01 新增的唯一既有 test leaf 為 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`；只准 expectedPaths 加入 `Contracts/GitHubOAuthAppConfiguration.swift`、`Stores/GitHubOAuthDataProtectionStores.swift`，並只為後者增加 Security import 例外。保留既有 legacy Keychain 例外及其他 import／source-path／package／provider 邊界檢查。
- ReadOnly 對 M01 的兩個精確 test leaves 已明列例外，沒有讀寫範圍重疊；本修訂容納已核准 adapter 必要的 allowlist 機械更新，不新增產品能力、測試豁免或 gate。
- 本 reviewer 未執行測試；呼叫端回報的測試結果不作為本次獨立測試證據。既有 review 段落保留，本次只追加本 bounded 判讀。
