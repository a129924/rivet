# 本地登出與 OAuth 憑證清除：技術契約

## 固定公開介面

新增 public `OAuthCredentialClearingStore: OAuthCredentialStore`，要求 `clear() async throws(any Error & Sendable)`；不存在視為成功，沒有預設 no-op。正式 DPK `credentialStore(clientID:)` 回傳此 refinement。既有 provider initializer 不變，舊 conformers 無需新增能力。

新增 `OAuthTokenProvider.signOut() async throws(OAuthSignOutError)`；public `OAuthSignOutError: Error, Sendable` 包含 `.unsupportedStore`、`.clear(underlying: any Error & Sendable)`。

`OAuthTokenProviderError` 新增 `.signedOut`。REST／GraphQL／scope 映射成既有 `.authenticationRequired`；其本身不是 cancellation。不新增 client error 類型。新 enum case 對下游 exhaustive switches 的 source compatibility 影響必須記錄。

## Actor lifecycle 與 ordering

1. `signOut()` 進入 actor 後，先不可逆退休，清空 provider 的 credential／snapshot references。檢查實際 store 的 clearing refinement；不支援時仍永久退休，回報 unsupportedStore。
2. 所有 token 入口、shared task 返回，以及 load／refresh／save suspension point 後都先檢查退休。退休優先於晚到技術錯誤，不能新 save、publish 或由錯誤處理覆寫退休狀態。
3. 每次 save 開始前登記獨立 pending-write task。登出等待已登記 write 真正 settle，再 clear；write 成功或失敗都不略過 clear。安全性不依賴 Task.cancel。
4. 不等待可能長期阻塞的 load／refresh；晚到結果由退休檢查丟棄。已等候 token 的 caller 最終不能取得成功 snapshot。
5. 同時 signOut 共用一次清除工作；成功後重複呼叫成功。失敗保留退休，下一次明確呼叫只重試 clear。
6. signOut caller 取消不取消清除、不提前宣稱成功，等待並回傳實際清除結果。snapshot caller cancellation 原契約維持。
7. 新登入只能在清除成功後建立新 provider。既有 token 副本／已送出 request 無法收回，清空 references 不等於安全抹除。

## 精確 DPK 刪除

正式 Security seam 增加同步 delete，live adapter 呼叫 SecItemDelete。selector 沿用 class、explicit access group、service、credential account、DPK=true、synchronizable=false；不加 return-data 或 broad selector。

clientID-bound 讀取／驗證與 delete 在同一 storage actor 操作內完成，中間無 suspension。不存在冪等成功；clientID mismatch／corrupt 回報既有有限 store error 並保留 item。errSecItemNotFound 成功，其餘沿用既有 Security status 分類。configuration 與相鄰 namespace 不變。不同 facade／程序不協調，不新增 persistent fencing。

## feasibility-validation：文件優先結果

來源基線 `2973150b2789d63c10226b57150073ccc793c509`：

- `Sources/BoundedContexts/GitHubIntegration/Contracts/OAuthCredentialStore.swift`：只有 load/save。
- 同 target `Providers/OAuthTokenProvider.swift`：runRestore／refreshAndPublish 的 await 後未退休檢查；save 後發布。
- 同 target `Stores/GitHubOAuthDataProtectionStores.swift`：精確 selector、clientID binding、同 facade actor；copy/update/add seam 無 delete。
- 同 target `Composition/GitHubClientScope.swift`：scope 強持有原 provider。
- `docs/architecture/github-oauth-dual-client.md` 與 `github-oauth-credential-persistence.md`：現有取消、rotation persistence、actor ownership 及跨 facade 限制。

官方依據：[Swift cancellation](https://docs.swift.org/latest/documentation/swift/task/cancel%28%29/)、[Actor reentrancy](https://developer.apple.com/videos/play/wwdc2021/10133/)、[SecItemDelete](https://developer.apple.com/documentation/security/secitemdelete(_:))、[更新及刪除 Keychain items](https://developer.apple.com/documentation/security/updating-and-deleting-keychain-items)。合作式取消與 actor reentrancy 不自動防止晚到寫回；此設計以 retirement／write barrier 解決。這是來源判讀，不是已執行測試結果。

文件足以支持 concurrency 實作方向，不建立另一套 concurrency experiment；正式 gated tests 驗證實作。指定簽章環境的提示、精確刪除及 fresh-process absence 不能由文件證明，原規劃另按 plan 的 E016 實驗驗證。規劃時未執行，現行有限成功與限制見本文件末段；不外推其他環境或斷電 durability。

## 工具限制

Graphify 只用既有 graph bounded query 並核對 revision／source，所有 CLI 設 GRAPHIFY_NO_AUTO_REFRESH=1；缺 graph 則 rg，未授權不 build。Archify 只產必要一圖，依 skill validation／delivery／visual-check。PR Lens 只映射實際 bounded diff，外部 local-only 產物，不是 correctness review。詳細契約見 execution plan。

## 連結

[需求](requirements.md) · [執行計畫](../../plan/github-oauth-local-sign-out/github-oauth-local-sign-out.plan.md) · [狀態帳本](../../plan/github-oauth-local-sign-out/github-oauth-local-sign-out.step.md)

## 2026-11-16：T09 獨立 harness 補充契約

本節只具體化既定 T09，不改正式 API。Explorer 於 2026-11-16 查得既有資產，主 session 已選用較晚到期的一組；找到資產不代表 E016 已完成簽章／啟動／DPK 存取。

### 簽章與 host

- 重用 exact application-identifier `4Q76YL5UQ5.local.rivet.dpkcontinuity.b90f5f16d3c8452faf9186b88d6dc64e`；CFBundleIdentifier 為移除 team prefix 後的 `local.rivet.dpkcontinuity.b90f5f16d3c8452faf9186b88d6dc64e`；唯一 exact keychain-access-group 等於完整 application-identifier，不使用 wildcard group。
- 既有 Apple Development identity SHA-1 `59E8ED4B0CCD45ED27129C7A3C6CC1EC510B87E9`，公開 certificate SHA-256 `5c267546d016f41f0901e535847a0ab44f81382f7aaadffbbb56a09941139440`。重用 profile UUID `b6dca18c-18aa-438b-b2d9-0fcf6f577399`，expiry `2026-11-17T07:28:08Z`（台北 15:28:08）；每段啟動前都須仍有效，過期停止，不借 certificate 效期延長。
- E016 新 macOS application target `E016LogoutProbe`，直接連結此 feature worktree root package 的 public GitHubIntegration；non-sandbox、ENABLE_DEBUG_DYLIB=NO、單一 exact group。參照 E015 project/entitlements 形狀，不複製其 live runner 契約、stage 額度、namespace、ready 或舊 receipt。
- 只新增 E016 host/project/Resources、最小 runner 與 fake checks；不修改 root package/Sources/Tests、不導入 production 控制開關。E016 專用 private build/output/DerivedData；不覆蓋原 E010/E015 app。
- manual signing 指定原 identity/profile；禁止 automatic provisioning、register device、新資產、trust/ACL 變更。unsigned/fake checks 與獨立審查先完成，再簽章 preflight，最後才 Human 完整觀察的唯一 run。

### 資料與兩程序協定

- 每 run 僅一個新 UUID，主 service `local.rivet.experiment.e016.logout.<UUID>`，sentinel service 為主 service 加 `.sentinel`；同 exact group。主 service 經正式 stores 保存 fake configuration 與完整 credential，sentinel 經另一正式 stores 的 credential account 保存完整不同 fake bundle。
- clientID/clientSecret/accessToken/refreshToken、scope、expiry 均為固定合成 fixture，expiry 選未到期；fixture 在 unsigned 階段凍結。收據只記逐欄相符布林／hash，不輸出任何 payload。刷新 fetcher 被呼叫即 fail，不建立任何網路 transport；in-flight refresh 保證只沿既有受控測試，不冒稱本序列重驗。
- first 程序先讀三者均 absent，錯誤或存在立即停止且不覆寫；逐一 seed/readback 成功後，建立 caller-owned 正式 provider，僅呼叫 provider.signOut；驗主 credential absent、configuration/sentinel intact，寫一次 receipt 後正常退出。不得直接以 adapter.clear 代替正式入口。
- fresh 程序只讀相同 service/run UUID；同一份 signed binary/source/profile，不 rebuild/resign，驗 credential absent、configuration/sentinel intact。沒有 seed/save/delete/retry/cleanup 分支。
- 兩段均以完整 App path 的 bundle launch；不以 bundle ID lookup、不用 open -n 或 raw GUI executable。runner 必須核 actual PID/start time/executable path/binary hash；若 LaunchServices 導向舊 E010 app，停止且不讀寫 Keychain。先確認相關舊 app 已退出，fresh 前另確認 first 的 exact process 已實際退出；未知不 kill、不假設退出。
- App 在任何 DPK 操作前自行核 bundle/executable 與 frozen source/binary/profile identity、phase 與 run UUID；runner 核對 actual process。此 guard 只在 E016，不能增加 production 驗證 API。

### 最小實作與收據

可重現入口固定 E016 下 `E016LogoutProbe.xcodeproj`（shared scheme E016LogoutProbe）、`Sources/main.swift`、`Resources/Info.plist`、`Resources/E016LogoutProbe.entitlements`、`scripts/e016_live.py`、`Tests/test_e016_protocol.py`。runner 只提供 preflight/first/fresh 三個有限命令，不建立通用任務引擎；build/sign 使用明確 xcodebuild/codesign 準備命令，實際完整參數由 Implementer 在 unsigned review handoff 凍結。

來源凍結 manifest 包含當前 commit、dirty source 的逐檔 hash、root Package.swift/Package.resolved、實際使用的 package source、E016 host/project/resources/runner；簽章後綁 Mach-O/app bundle/embedded profile hash、cert fingerprint、工具版本及 signature verification 結果。兩段 source/binary/profile 必須相同。private run root owner-only；本機路徑、raw identity/group/profile、實際 PID/start time 只留私有 provenance，不進公開 projection。

公開 receipt 僅 allowlisted booleans/enums/SHA-256：schema/phase/outcome/failureKind enums、run/process/provenance hashes、seed_absent/seed_readback/signout_returned/same_process_absent/configuration_intact/sentinel_intact/fresh_read_verified/previous_process_terminated/launch_identity_verified、source/binary/profile hashes。任意 error 原文與 payload 禁止。各寫入前保存 write_attempted 布林；中斷保留可能已寫入狀態，不用新 UUID 掩蓋。

Human 每段完整觀察與實際 prompt count 綁 machine receipt hash；private attestation 保存實際數字，公開只出 `zero/nonzero/unknown` enum 與 observation_complete 布林／attestation hash，未知不得填 zero。提示數不是預設 0，也不是以舊 E015 觀察推得。

任一中斷、不相符、超時、簽章/profile/程序歸屬前提不足皆停止，不自動重試、不清理殘留。唯一 run 的 first 一旦啟動就消耗序列，即使未產生完整 receipt 仍記錄。fresh 只可在 first 成功且退出已證明後執行一次。T09 判準與 E016 八段 README 一致。

## 現行系統證據（2026-11-16）

E016來源bb6752aa483a68043174723a6b3ff2653abe79ce已完成本次first/fresh有限驗證，獨立Reviewer approved。[證據與收據綁定](../../plan/github-oauth-local-sign-out/evidence/e016-live.md)包含同signedbinary/profile/source、兩個actualexactprocess歸屬／退出，以及Human各完整觀察zero。結果支持正式signOut後credential absent、configuration/sentinel保持；適用當次同機／GUI使用者／既有signer與有效profile／exactgroup／synthetic／uniquewriter。原晚到refresh保證仍由受控tests支持，沒有live refresh或真OAuth／產品UI／跨writer／其他profile／durability結論。

ff672c7舊無法判定與已耗first不改；新增bb6752a序列也已耗first/fresh，不再執行或cleanup。原public Human unknown/false保留，由獨立attestation綁SHA補充。後續文件變更不是受測來源，不影響已完成歷史run；Human最終topicreview仍pending。公開API及locked decisions維持。
