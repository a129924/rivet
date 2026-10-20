# Reviewer 獨立成果審查

- 日期：2026-10-20；Role：Reviewer。
- Topic：`github-oauth-credential-persistence`。
- Verdict：**approved**。
- Required fixes：[]。

## 範圍與來源

核對本 topic 四份 artifacts、Implementer／Tester 交接，以及最終兩個新增 source、新 fake Security tests、consumer／static-isolation 精確 diff、長期文件與 storage sequence。新增 source 尚未 tracked，已直接閱讀，沒有僅依 tracked diff 判讀。五個 Swift source／test 檔的實際 SHA-256 均與 `evidence/tests.md` 的驗證快照相符。

本 reviewer 沒有實作或修改受審 source／test，沒有執行測試、live Security、簽章、產圖或發佈。本次只產生自身 review evidence 及記錄 S06 結果。

## 判讀

- Public configuration／stores 為 additive；既有 bundle、ports、provider、clients 與 package graph 未改。新增 source／consumer／isolation／文件 leaves 符合 manifest，static isolation amendment 只加兩個 source paths 與 DPK adapter 的 Security import 例外。
- Configuration、stored credential wrappers 的 description／debugDescription／customMirror 脫敏；有限錯誤不攜帶原始 status、payload 或 underlying error。資料 codec 的原始解碼錯誤均收斂為 corrupt。未發現新增 logs 或交付文字外露實際秘密／本機絕對路徑。
- 每次 copy／update／add 皆包含 explicit generic-password class、private group、service、account、DPK=true 與 synchronizable=false；copy／add flags 與保護等級符合契約。Construction 與無效 binding 不呼叫 Security。
- Inspect／bound load 共用完整 strict decoder；schema、必要欄位、非空 ID／tokens、bearer 與有限日期均 fail closed，允許過期日期及空 scope。Bound save 先驗證／encode，再在同一 actor operation 讀取完整既存身分；mismatch、corrupt、denied、unavailable 都不進入寫入。
- 同一 facade 的所有 store views 共用唯一 actor，read-check-write 與 update-add-update 中沒有 suspension point。完整 value update、missing 才 add、duplicate 僅再 update 一次；沒有 delete、補寫舊值或 lifecycle retry。不同 facade／程序未承諾協調，兩 items 未宣稱 transaction。
- Provider 整合保持既有先保存完整 rotation 再發布的 ownership；accepted rotation 保存失敗沿用 terminal persist，後續沒有額外 refresh／save。保留 fake 舊 item 只表示本地已提交資料仍在，不被解讀成遠端 token 有效。
- Fake suite 的 round trip、identity／corrupt／access-denial guards、完整替換失敗、query flags、同 facade 並行 views、configuration-first partial save 及 provider restore／persist-stop 支持本次 bounded 能力。Consumer construction 不執行 live operation；既有 provider／client 期望未修改配合新 policy。
- 文件與 sequence 保留相同責任，明確揭露 fake-only、live／跨程序／簽章／提示未驗證。Archify receipt 與 Tester 的 spec／HTML SHA 核對一致；9/9、四尺寸 containment／四張 screenshots 的證據保持可追溯，Agent 看圖與 Human pending 分開記錄。本 reviewer 未冒稱重新執行 Archify 或 Human 視覺接受。

## 驗證依據與剩餘限制

採用獨立 Tester 的實際結果：269 non-live tests／31 suites、fresh consumer 13 tests／3 suites、strict format／SwiftLint 122 files 零違規，以及格式修正後 29 static-isolation tests。五份 Swift 來源快照已由本 reviewer 靜態重算確認相符，沒有把本次 review 描述成再次測試。

Consumer 的唯讀基線 Sendable compiler warnings 已揭露；不宣稱 build 零 warning。Legacy Keychain live suite 本輪明確跳過，未宣稱通過。

PR Lens 真 committed diff／local map 與 publication 證據按既有計畫在實際 source commit 後補齊；目前 pending 不誤作 code correctness 缺口。Graphify 無圖的 source fallback 已記錄。Human 圖面接受仍 pending，交 Draft PR review；不包含 merge。

真 DPK、程序終止後 durability、重建、signing／entitlements、系統提示與真 OAuth 未經本 topic 驗證，也不依賴他人的 E007／renewal gate。本 approval 僅涵蓋已授權的 adapter、fake-only 驗證與文件交付，不代替上述 live／Human acceptance。
