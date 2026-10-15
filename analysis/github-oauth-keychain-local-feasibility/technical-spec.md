# Keychain 本機 OAuth 憑證保存可行性：技術規格

- Topic：`github-oauth-keychain-local-feasibility`
- 日期：2026-10-15
- [需求](requirements.md)／[執行契約](../../plan/github-oauth-keychain-local-feasibility/github-oauth-keychain-local-feasibility.plan.md)／[狀態帳本](../../plan/github-oauth-keychain-local-feasibility/github-oauth-keychain-local-feasibility.step.md)

## 文件優先與候選 preflight

先讀既有原始碼及 Apple 官方文件；若文件足以回答某項前提即保存來源、條件與限制，不用實驗冒充資格確認。跨程序、真重建及提示行為仍需要本機實證。

DPK 優先，檢查登入使用者情境、app-like host、main executable 的 entitlement、所需有效嵌入 profile 與免費資格來源；library entitlement 不代替 host。只檢查本輪 host，不盤點個人 identity inventory。既有付費 profile／簽章不能作免費成功前提。

若無法證實免費 DPK 前提，可在首次 Keychain 寫入前選 legacy 為唯一候選，於 README 固定機制與原因。測量失敗後不得換機制或默默 fallback。所選候選仍無法確認免費來源或可比較的重建身分時，記前提不足／無法判定；不得把缺前提當作機制失敗或必須付費。

DPK 所有查詢明設 `kSecUseDataProtectionKeychain=true`，legacy 明設 `false`；皆明設 `kSecAttrSynchronizable=false`。使用相同已選 backend 作寫入、讀取、替換、負向操作及清理。

## Host、單 item 與完整 bundle

建立獨立最小 Swift host，不改 root manifests、production Sources／Tests 或 public API。主要 generic-password item 使用本輪 UUID namespace、精確 service／account／backend。完整私有 DTO 編為單一 `Data`，以整筆更新替換，不分拆 token 或日期欄位，不改既有 production Keychain identity／ACL。

DTO 對應既有 `GitHubOAuthCredentialBundle` 六欄，不改該型別：

| 欄位 | 保存／比較語意 |
| --- | --- |
| `accessToken` | 固定假 token，還原後逐欄比較。 |
| `refreshToken` | 固定假 token，還原後逐欄比較。 |
| `accessTokenExpiresAt` | `Date`，非相對有效秒數。 |
| `refreshTokenExpiresAt` | `Date`，非相對有效秒數。 |
| `tokenType` | A／B 均為 bearer。 |
| `grantedScopes` | 原字串還原比較。 |

A／B 的兩個 token、兩個 expiry 與 scope 均不同；資料固定且全為假值。host 模式為 `write-a`、`read-a`、`replace-b`、`read-b`、`write-invalid`、`read-invalid`、`delete`、`read-absent`。不新增 production `OAuthCredentialStore` delete requirement，不驅動 provider runtime。

## Fresh process、真正重建與提示

T02 writer 完整結束後，兩個獨立 fresh reader 逐欄比較 A。T03 改 build marker 並真正重建，證明 binary hash 不同，不只重跑舊 binary。維持固定 host 路徑、bundle ID、簽章方式及候選；檢查 designated requirement／entitlements／access groups 一致性，只保存一致性布林值，不輸出個人簽章識別資訊。無免費穩定身分時不能宣稱 T03 完成。

主要正常流程所有系統提示如實記錄，對應首次最多一次、正常後續與同身分重建零提示。不能把主要流程重複提示排除 UX 計數。T04 整筆換 B，新程序確認六欄全 B、無混合。

## 負向與整輪實驗退出清理

先完成 T02–T04 正常流程，再做 T05。沒有項目回 nil；malformed data 為 decode failure；非 `errSecItemNotFound` 的 Security status 不得回 nil。真 denial 只在本輪獨立負向項目自然可觀察時驗證；不改主要 host 身分、ACL 或安全設定製造提示。無自然 denial 即保留缺口，可明標 synthetic 注入驗證分類，不能當真 Keychain 拒絕證據。

統一 cleanup 屬於整輪 experiment 的退出路徑，不屬於每個 writer／reader 子程序的退出路徑。writer／reader 正常結束必須保留 item，供 T02 跨程序、T03 真重建及 T04 替換測量使用。任一寫入嘗試後，整輪正常完成、失敗、停止或例外退出時，才由整輪退出路徑嘗試清理全部本輪主要／負向項目，依精確 UUID namespace／service／account／backend 刪除並確認不存在。不刪 production 或歷史項目。無法清理時保存殘留非秘密 UUID 識別、原因與待處理操作；本輪驗證任務完成為否。不放寬安全設定解除清理障礙。

## 證據與工具

輸出僅含必要狀態、逐欄比較布林值、提示觀察、遮蔽身分比較與清理結果；不輸出 token、個人簽章識別資訊、秘密或非公開資料。新實驗八段 README 分開設計與實際執行、日期、版本、命令、真實／synthetic、觀察／推論及限制。

工具版本、範圍、預算與失敗處理依執行契約，不以工具代替本機證據。Archify 只描述實驗 workflow，不新增架構決策或 architecture canvas。對長期文件只可在獨立證據審查後回寫有條件結論，不宣稱正式 adapter／產品登入交付或核准採用。

## 依據

- [TN3137：On Mac keychain APIs and implementations](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)
- [TN3125：Inside Code Signing: Provisioning Profiles](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)
- [Apple DTS：file-based Keychain 限制](https://developer.apple.com/forums/thread/845980)
- `docs/architecture/github-oauth-dual-client.md`
- `Sources/BoundedContexts/GitHubIntegration/Stores/KeychainTokenStore.swift`
- `Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthCredentialBundle.swift`
- `Tests/GitHubIntegrationTests/KeychainTokenStoreTests.swift`
- `plan/github-keychain-token-store/github-keychain-token-store.step.md`

上述是依據位置；本規劃不把尚未執行的 preflight、測量或圖驗證寫成結果。

## 實際候選與證據限制

E005 在首次寫入前明確選 legacy，無 profile 的 ad-hoc host 不依賴付費資格；未嘗試 DPK。T02／T04／真 absent／malformed 與精確清理成立；T03 真重建產生不同 designated requirement，沒有 acceptance read。正常 UX 提示沒有人工觀察，整體無法判定。受控 SIGINT／SIGTERM 與清理期間重複訊號的 fake harness 不當真 Keychain／UX 證據；真寫入後受控例外清理有獨立新 UUID receipt。完整結果見 E005 八段 README，既定 production contract 不變。

### Human 觀察的獨立保存

同環境／同判準 E005 後續補測使用新 UUID，machine promptCount 原樣為 null；Human 另明確回報整輪全程觀察 0 提示，以獨立 JSON 的 machine receipt SHA-256 綁定時窗。此為 Human 陳述的實際桌面觀察，不是程式 exit code 推論，也不改寫初輪證據。T02／T04 本輪原 binary 的零提示可採為受限 UX 證據；不涵蓋 T03 未執行的 acceptance read 或其他 host。整體無法判定與正式 adapter deferred 保持。


## T03 補測限定設計：實驗自簽身分

本節記錄使用者後續明確授權，不覆寫上方歷史 E005 ad-hoc 結果。只允許新增一張實驗專用自簽 Code Signing cert／private key，放在 repository 外新 UUID 隔離的專用實驗 Keychain；不依賴付費資格、既有個人憑證或 profile。授權涵蓋該專用 Keychain 的建立、限定 cert／key 匯入與精確刪除，不涵蓋既有 ACL、系統信任、預設 Keychain 或全域 search-list 改動。需要任一禁止操作即停並清理。

補測維持同一 legacy backend 與固定假六欄，不切 DPK，也不重新定義主要判準。順序如下：

1. 建立隔離專用 Keychain 及唯一實驗 cert／private key；所有 private key、密碼與匯入素材僅留 repository 外隔離 scratch，不進 repository、log 或公開證據。
2. 以同一實驗身分簽署兩次真正重建的 host，維持原 host 路徑、bundle ID、簽章方式、entitlements／access groups。改 build marker，保存並核對 first／second 的不同 binary hash；先記 designated requirement 相等及其他身分條件一致性布林值。兩次 build／DR 預檢完成後保留 first／second binaries。未相等即停止，不寫入本次 OAuth item。
3. 同身分前提成立後，於固定 host 路徑還原 first（第一次 build）作 writer，寫入新 UUID OAuth item 的固定假 A 並結束；再於同一路徑換成 second（第二次 build），以 fresh reader 逐欄讀回。保存／核對每次實際執行 binary 的 hash，證明 writer=first、reader=second 且兩者不同；不得 writer／reader 都使用 second。子程序正常退出保留 item。記錄真正 T03 acceptance read 及全部提示，正常 UX 判準不變。
4. 任一專用 Keychain／秘密素材建立後，整輪正常完成、失敗、停止或例外退出皆嘗試精確清理本輪 OAuth 項目、專用 cert Keychain（含 cert／private key）及 repository 外秘密／匯入素材；分開保存 OAuth item absence、專用 Keychain／素材不存在的非秘密結果。不得刪既有 Keychain、改預設／search-list 或放寬安全設定換取清理成功。

只保存新補測的獨立 receipt／非秘密證據，歷史 receipts 不覆寫。若尚未執行為未執行；已嘗試但 DR／信任／權限或時限不足為無法判定，不稱免費 Keychain 假設失敗。清理狀態與四狀態分開，殘留只記非秘密 UUID／原因，任務完成為否。截止仍為 03:56:28 UTC 新測量、04:11:28 UTC 總額。

## 自簽身分補測結果（2026-10-15）

使用者明確允許限定自簽憑證／獨立 Keychain 例外後，獨立 Plan-Reviewer 已核准 first writer／second reader 的補測計畫。兩輪僅簽章預檢：PKCS12 停於匯入 exit1；一次 PEM 相容性檢查成功匯入憑證／私鑰後，首次簽章 exit1，沒有兩版有效簽章或 DR 比較。零 OAuth 寫入，T03 acceptance 未執行；主假設仍無法判定。已知錯誤分類不足以指出根因，不推論信任錯誤、付費必要性或方案普遍不可用。兩輪專用 Keychain／秘密暫存完整清理，預設 Keychain／全域 search-list 前後一致。原 ad-hoc host 的 Human 零提示證據保留；不能外推尚未建立的自簽 host。詳細指令、時間、source hash 與 receipt 見 [E005](../../experiments/E005/README.md)。

使用者續行授權（2026-10-15）：同一 PEM／自簽候選只補失敗診斷，保存公開已知錯誤片語與本輪專用 Keychain identity 數量，不保留個人識別／raw stderr、不掃全域。無 OAuth 寫入，不增加簽章變體或安全設定變更；原 03:56:28 UTC 新測量截止不變，診斷後若需禁止操作即停。

同一候選新診斷（03:46:15–19 UTC）：僅本輪私有 Keychain 身分查詢回 1 matching／0 valid、`CSSMERR_TP_NOT_TRUSTED`；codesign 首次簽章回 `no identity found`。本次可具體指出可用簽章身分前提不成立；舊兩輪無診斷紀錄保留，不倒填根因。零 OAuth 寫入／T03 acceptance 未執行、清理完整、全域設定一致。若需信任調整須 Human 新授權，不自動執行；不推論必須付費。詳見 E005 診斷收據。


## 新窗限定 trust 補測：操作與退出順序

唯一新增安全操作是本輪新自簽 cert 的 user-domain codeSign trust。不得使用 `-d`／admin domain、SSL、broad trust，不改既有 ACL／partition-list／default Keychain／全域 search-list；不改其他 cert 或其 trust。需要超出例外即停。password／系統 approval 由 Human 操作，agent 不讀取、自填或記錄密碼。

1. 建立本輪新 UUID cert／專用 Keychain 與 repository 外秘密素材；鎖定 exact cert。先查證該 cert 原本無 user trust；若已有 trust 或無法確認，不新增或覆寫 trust，停止並保存缺口。
2. 僅新增該 exact cert 的 user-domain Code Signing policy trust；立即讀回，證明僅該 domain／policy，沒有 SSL／broad trust。讀回不符或失敗即進退出 cleanup，不擴大 trust 重試。
3. 同 cert 完成 first／second 真重建，保存不同 binary hash、DR 相等及身分一致性。此階段含 trust／兩 build 預檢全程零 OAuth 寫入。前提不成立即停，不能用 build green 取代 DR／T03 證據。
4. 前提成功後確認 CUA 連線可用，等待 Human 明確 ready；未 ready／連線失敗／到停止時點，不寫 OAuth item，進 cleanup。ready 後固定 active host 路徑還原 first 作 writer，再換 second 作 fresh reader；同 cert、legacy backend、假六欄與 UX 判準維持，保存實際兩端不同 hash，記錄 Human 全程提示觀察，不能兩端都 second。
5. finally 與受控 signal 路徑在正常完成、trust 新增失敗、DR 失敗、timeout、停止／例外均執行精確 cleanup：先清本輪 OAuth 項目（若曾寫入）；只有三 domain baseline absence 已確認且本輪 add 已嘗試（trustOwnedAttempt=true）時，才撤回 exact-cert user trust、讀回核對該 cert 無 user trust，再刪專用 Keychain／cert 及秘密素材。add 失敗也須處理可能的部分新增並核對 absence。baseline 已有 trust／查證失敗／未 add 時 trustOwnedAttempt=false，只清自建素材，絕不 remove 原有 trust。不得藉刪 cert 或 Keychain 推論 trust 已撤回。撤回／核對失敗保留辨識 exact cert 所需的非秘密材料與殘留原因，不先刪除而失去撤回依據；標清理未完成／任務否。不可捕捉停止的限制與殘留處理仍明列，不保證 SIGKILL 自動 finally。

只保存本次獨立非秘密 receipt，分列 baseline-no-user-trust、新增／讀回 policy/domain、DR／hash、Human ready、T03、撤回／absence 及秘密清理；不覆寫舊 receipts，不把尚未做的結果寫成成功。實驗四狀態與任務／清理完成分開，T03 目前仍無法判定。

Human 新窗為 03:54:20–04:24:20 UTC；04:19:20 UTC 停新測量，最後五分鐘優先撤 trust／清理／紀錄。不沿用原 90 分鐘窗延伸，不因等 ready 延長，也不增加 trust 變體。


### TrustProbe 精確介面與互動前提

新增受限 Swift `TrustProbe` helper，只處理本輪 cert DER，拒絕非 `Rivet-E005-UUID` 實驗 cert。不盤點個人 trust；`SecTrustSettingsCopyTrustSettings` 僅查 exact cert 的 `.user`／`.admin`／`.system`，輸出 status、absent、entryCount、codeSigningOnly 等非秘密判斷。新增前三 domain 均須 `errSecItemNotFound`；其他錯誤不足以證明 absence，空 array 代表 AlwaysTrust，必須拒絕。

僅用 `SecTrustSettingsSetTrustSettings(cert, .user, ...)` 設定一筆 `SecPolicyCreateWithProperties(kSecPolicyAppleCodeSigning, nil)`／trustRoot。讀回須恰一 entry，必需 Policy／Result；Policy 必須為 SecPolicy runtime type、OID AppleCodeSigning，Result 必須 trustRoot。唯一可選 metadata 為 kSecTrustSettingsPolicyName，若有必須 String 且精確等於 Apple OSS 明定的 String literal `CodeSigning`；admin／system 仍 absent。空 array、SSL、broad、multirow、allowedError 或任何其他 unknown keys 全拒絕，不使用 admin／`-d`、broadAlwaysTrust 或 partition-list 放寬。

trustOwnedAttempt 初始 false，僅三 domain baseline absence 已確認後，在呼叫本輪 add 前設 true；其他分支不得設 true。finally 僅該 flag=true 才 remove exact cert `.user` 並 readback 嚴格驗證 absent，再刪本輪 Keychain／秘密。flag=false（baseline 已有 trust／查證失敗／未 add）只清自建素材，不撤任何原有 trust；flag=true 的 add failure 也處理部分新增並 readback absence。若 remove／readback 失敗，保留 cert DER、private Keychain 與必要 recovery 資料，不輸出其路徑／秘密，明列殘留並交 Human；不得因 cert 刪除推論 trust 消失。

Native API 可能要求 Human authentication。目前尚未收到 trust 互動 ready，code preparation 可先做，但不得執行需互動 add／remove；須 Human 明確 ready 後，由 Human 自行處理密碼／approval。兩版預檢通過後的 T03 仍另確認 CUA／Human ready，之後 first writer／second reader 才寫／讀 OAuth。兩個 ready 時點分開記錄，不延長新窗。

目前有效優先規則：本次 Human 新授權的 30 分鐘窗與 exact-cert user-domain codeSign trust 例外，優先於前版一律禁止 trust 及原 90 分鐘截止的敘述；前版限制／收據僅保留為歷史。此優先只開放本次新 cert 的 user/codeSign，不開放 system/admin domain 或其他政策；其餘 scope、安全／UX／cleanup 限制保持有效。


## 最新有效 Human-start 窗與 trust-ready（2026-10-15）

Human 本 turn 明確回覆「可以開始」，trust authentication ready 已收到；此 ready 授權在既定範圍開始本輪，不重問 scope／trust-ready。主工作 session 已向 Human 明說以此次實際 start 另起相同最多 30 分鐘的一輪。

- 本輪起算：2026-10-15 05:42:19 UTC。
- 停止新增測量：2026-10-15 06:07:19 UTC。
- 總上限：2026-10-15 06:12:19 UTC；最後五分鐘優先撤 trust、精確清理與紀錄，不自動延長。
- 本節為最新 active 時間／trust-ready 契約，優先於前述 03:54:20–04:24:20 窗、04:19:20 停測時間及尚未收到 trust-ready 的敘述；那些內容保留為歷史。此為 Human 明確 start 後的新一輪，不暗延長舊窗。主工作 session 交接確認前窗零 trust／OAuth mutation、無殘留；本次修訂不將舊窗寫成已執行。
- 其餘 scope、既有準備 approval、user-only codeSign policy、exact cert、cleanup ownership 及 same-process gate 均保持，不因新時間窗放寬。只有 baseline 三 domain absence 確認且本輪 add 已嘗試才可 remove；既有 trust 不得撤回。密碼／系統 approval 仍由 Human 操作。
- 本次 start 僅滿足 trust-ready。兩版簽章／DR 預檢成功後，T03 仍須確認 CUA 連線並另行取得 Human 的 T03 觀察 ready，不能沿用本次 trust-ready；保持固定 active host path、first writer／second reader、不同 hash 及完整假六欄。
- 本次僅時間與 trust-ready 修訂，交獨立 Plan-Reviewer 快核這兩項；不撤銷既有準備審查，不新增政策／實作決策，不預報 trust 或 T03 成功。


## Readback checker false-negative 窄修：OSS CodeSigning policyName metadata

`limited-trust-shape-run.json` 的交接實證為 user 恰一 entry，keys 為 policy／policyName／result，SecPolicy object、AppleCodeSigning OID 與 trustRoot 均符合；先前 exact-two-keys checker 因回傳 metadata 誤拒。Apple OSS [TrustSettings.cpp](https://github.com/apple-oss-distributions/Security/blob/main/OSX/libsecurity_keychain/lib/TrustSettings.cpp) 的 copyTrustSettings 會附加 policyName。本修正僅正規化 readback metadata，不改 trust policy、主假設或通過標準，不回寫舊 code／receipt。

目前有效 readback 契約：恰一 entry，必需 kSecTrustSettingsPolicy／kSecTrustSettingsResult；Policy 必須 SecPolicy runtime type 且 OID AppleCodeSigning，Result 必須 trustRoot。唯一可選 key 為 kSecTrustSettingsPolicyName；若有，其值必須 String 且精確等於 Apple OSS `SecPolicy.list` 明定的 literal `CodeSigning`。metadata 不符即拒絕；不宣稱公開 `SecPolicyCopyProperties` 的 `kSecPolicyName` 可取得此 friendly label，不呼叫私有 API，不以 label 取代實際 SecPolicy type／OID 的政策資格判斷。admin／system 仍必須 absent。

set 維持僅 Policy／Result 兩 keys、user-only；unknown keys、allowedError、SSL、broad trust／空 array、multi-entry 一律拒絕。只接受本輪 exact cert，baseline absence／cleanup ownership／same-process gate 不變；舊程式與 receipts 保留。此節優先於前文 readback 必須恰兩 keys 的描述，其他限制保持有效。

Human trust-ready／Touch ID 授權已收到；T03 仍須預檢成功後另確認 CUA／Human ready。active 時限不變：06:07:19 UTC 停新測量、06:12:19 UTC 總上限；主六欄／UX／授權 scope 不變。T03 尚未成立，本次只 planning 窄修，交獨立 Plan-Reviewer 快核後才實作，不 commit。


### policyName 來源更正（不改政策語意）

公開 `SecPolicyCopyProperties` 對標準 codeSign policy 的 `kSecPolicyName` 為 missing；該 key 用於 SSL 等 policy-specific name，不能作為取得 friendly label 的途徑。唯一 optional metadata `kSecTrustSettingsPolicyName` 必須 String 且精確等於 `CodeSigning`，依據為 Apple OSS [SecPolicy.list 第 25 行](https://github.com/apple-oss-distributions/Security/blob/main/OSX/sec/Security/SecPolicy.list#L25) 的 CodeSigning policy 定義。TrustSettings.cpp 以內部名稱附回此 metadata；本實驗不呼叫私有 `SecPolicyGetName`。

仍以實際 SecPolicy runtime type／AppleCodeSigning OID、trustRoot、user-only、exact-one-entry 及 admin／system absent 作政策資格判斷，metadata 只作一致性檢查；unknown keys／allowedError／SSL／broad／multi-entry 仍拒絕。set 仍兩 keys，cleanup ownership／same-process gate／first writer-second reader／UX／scope／06:07:19 停測與06:12:19總上限全不變。此為 checker API 來源更正，不擴 semantic 或改主假設成功標準；舊 code／receipt 保留，本修訂交獨立 Plan-Reviewer。

## 最新限定 trust 實證與停止結果

Human-start 新窗內四輪 receipts 已保存於 E005：前兩輪辨識 readback policyName metadata 誤拒；經獨立核准的 checker 正規化後，user-only codeSign／trustRoot 讀回成立，target private Keychain 為 1 matching／1 valid identity。名稱及 exact DER SHA-1 selector 的 codesign 首次簽章仍回 no identity found；最後一輪已停止，不再試其他變體。零 OAuth 寫入、無兩版有效簽章／DR／T03，主假設仍無法判定；四輪 trust 精確移除、三 domain absence、Keychain／秘密不存在及 default／search-list 一致皆確認，無已知殘留。

本機 Apple man codesign SIGNING IDENTITIES 指出 identity 所在 Keychain 須在使用者 search-list；這是下一個待測前提，不稱唯一根因。既定 scope 禁止修改 search-list，必須另獲 Human 授權才可介入，不自動擴安全／時間範圍。免費 cert／限定 trust 前提的局部成功不代替 T03 或正式採用。詳見 [E005](../../experiments/E005/README.md)。


## 最新 Execution Authorized：暫時 user search-list 受限例外

Human 已明確授權本輪 freshly-created 專用實驗 Keychain 暫時 append 至使用者搜尋清單。此為唯一新例外，不改 default Keychain、既有 ACL／partition-list、admin／system trust、SSL／broad trust 或其他設定；trust 仍限同一新 cert 的既有 user/codeSign 授權及 ownership guard。單一 legacy 候選、單一真實 run，不增加 backend fallback／簽章變體。原 receipts／code snapshots 保留。

### 最新時間與 readiness

新 30 分鐘窗為 2026-10-15 06:09:51–06:39:51 UTC，06:34:51 UTC 停新測量，最後五分鐘優先撤 trust、還原 search-list、清理與紀錄，不自動延長。本節的時間及 exact-own-Keychain user search-list 例外優先於所有前版時窗／全面 search-list 禁令；舊記錄保留為歷史，其他 scope／主六欄／UX 判準不變。

同 run trust setup 的 Human 授權已收到，可由 Human 自行處理系統 approval／密碼，agent 不自填。T03 必須於 trust、同 cert 兩版簽章／DR 預檢成功後，重新確認 CUA 連線與 Human 全程觀察 ready；未 ready／連線不足／到停測點不得寫 OAuth。CUA 能列 apps 不等於能觀察 SecurityAgent，系統提示仍由 Human 觀察。固定 active host path、first writer／second reader 及不同 hash 證據維持。

### Search-list mutation ownership 與核對

只以 `security list-keychains -d user` 讀、`security list-keychains -d user -s` 寫 user-domain search-list；不得改 domain 或 default。原完整有序清單及 default snapshot 僅在記憶體，quote 以 shlex 解析；輸出僅 bool／count，不保存私人 path／raw list。own identity 僅以 resolve 與該已知 `.keychain`／`.keychain-db` suffix 等價核對，不能 substring 模糊匹配。

新增 opt-in `--temporary-user-search-list`，必須已有 trust＋diagnose＋certSHA1 guards 及 UTC deadline；missing guard 在 Security 初始化前失敗，不產生副作用。

1. 確認 own Keychain 是本輪 freshly-created、精確隔離且 baseline 無此 membership；讀取 baseline user search-list 有序序列及 default。
2. mutation 前再次讀 current 與 default，要求原序列及 default 完全一致；不一致即停止，不覆寫、不 append，清自建素材。確認後在 write 前登記本輪 search-list ownership／attempt，再只寫 baseline + [ownKC]；add failure 亦須考慮部分新增。
3. 立即讀回，核對 exact baseline + [ownKC] 順序／count 及 default 不變；不符即停新測量並進 cleanup。不以寫入 exit0 代替讀回證據。

### 整輪退出還原與殘留

所有正常、失敗、timeout、受控 signal／例外退出皆依 ownership cleanup。先清本輪 OAuth 項目（若有），處理既定 exact-cert trust 撤回／absence 核對，再在 delete Keychain 前撤回自己新增的 user search-list membership；trust cleanup 失敗亦記錄並嘗試自己的 search-list cleanup，不能省略已擁有的副作用。

若 search-list ownership／attempt 未登記，絕不寫回清單。已登記時重新讀 current，只移 ownKC，保留所有 foreign entries 及其順序；不能把舊 baseline 直接覆寫 current。無並發修改時，核對原 baseline 有序序列已恢復且 default 不變，之後才刪專用 Keychain／秘密。

若 current 有其他並發修改，保留 foreign entries／order、只移 ownKC，立即核對 own membership absence 與 foreign sequence 保留，明列 baseline 不一致及 recovery；不得為恢復 baseline 撤銷別人的修改。若原序列未恢復、移除／核對失敗或 trust absence 未成立，保留專用 Keychain／必要非秘密 recovery 依據，明列殘留／原因、任務否，不先刪 Keychain 掩蓋 membership 或 trust。所有路徑不輸出私人 path／秘密，不因刪 cert 推論 trust 消失。

### 實作與交付邊界

只修改 E005 runner、必要最小 synthetic ownership／concurrency／exit 測試、新獨立收據及八段 README，不改 production。synthetic 須明標；必要案例包括 baseline conflict 零 mutation、部分 write failure cleanup、foreign order 保留及受控退出還原，不能冒充真 Keychain 證據。真實 run 僅一輪，不在失敗後追加變體。

四狀態／任務完成／cleanup／recovery 分開。先前 T03 仍無法判定；本節只新增窄授權契約，不預報本輪成功。此為規劃當時狀態：四檔具備獨立審查內容、正式 verdict 待審；其後已獲 Plan-Reviewer approved，後續實測結果另記。


### 新授權單輪實測結果（資料／清理已確認，UX 無法判定）

Human 授權 exact-own-Keychain user search-list 例外後，唯一 [user-search-list-run](../../experiments/E005/evidence/user-search-list-run.json) 於 06:16:17–06:21:03 UTC 完成；setup 授權由 Human 處理，預檢通過、CUA 重新連線及 Human 明確全程 ready 後才接受 gate。first writer／兩 fresh readers、不同 hash 的 rebuilt second reader 均逐欄六欄 true，DR 相同且兩版 cert-backed signature 有效、path／bundle／entitlements 一致，沒有 profile；second 完整替換 B／fresh read B、真 absent／malformed 分類也成立。沒有付費或既有 identity 依賴，legacy 固定。

全部13操作 exit0，兩 OAuth 項目、exact-cert user trust、own search-list membership、專用 Keychain／秘密已精確清理，原有序清單／default 恢復；無 recovery。獨立 Tester／Reviewer 核對機制與清理 approved。machine validationTaskComplete=true 僅表示這些測量完成；experimentStatus unknown／prompt null 保留，Human 全程觀察後回報兩次授權，第一次輸入密碼並選「永遠允許」、第二次指紋，但無法分辨 runtime／撤 trust 階段；[人工收據](../../experiments/E005/evidence/user-search-list-human-observation.json) 另綁 machine SHA。runtime promptCount 仍 null，UX 無法判定，不能從 exit0／操作耗時猜階段，也不把「永遠允許」當作未測下一次重建的證明。

這已補足本輪 T03 資料機制，不宣稱唯一根因、DPK、其他 macOS、長期保留身分 reuse 或正式採用。cert 隨實驗刪除；真 denial 仍未觀察，production adapter／provider lifecycle 不變。

本輪受限驗證／紀錄任務完成，主假設仍無法判定，缺口為 UX 提示階段而非 T03 資料機制；不追加真實 run、不核准採用。


## 最新有效授權：E005 分段 UX 聚焦單輪

Human 明確授權以同一主要問題補新一輪 UX 證據；沿用 E005，新增 `ux-segmented-*` 獨立證據，不覆寫任何舊 receipt／Human sidecar／code snapshot。實作前保存既有 runner 的 SHA-256 與對應舊 source snapshot。先前 T03 資料證據成立而 UX 無法判定的結果、closure approved 與 Draft PR #58 均保留為歷史，不倒填本輪觀察。

### 本輪範圍與時間

僅假 A 六欄、同一 legacy backend、新本輪 own self-signed cert、既有 exact-cert user/codeSign trust 及暫時 user search-list 例外。保留 trust／search-list ownership、只清 own 副作用、foreign entries／order 與 default 不變的契約。禁止 production 改動、既有 ACL／partition-list、付費／帳號、admin／system／SSL／broad trust 或其他安全政策變更。只 UX 聚焦，不跑 B／negative／refresh，不 rerun，不以新結果改判準；自然 denial 維持歷史 gap。

新窗：2026-10-15 07:34:33 UTC 起，07:59:33 UTC 停新增測量，08:04:33 UTC 總上限；最後五分鐘優先 cleanup／closure，不自動延長。本節優先於前版時窗及不分段量測安排，其他 scope／安全／UX 判準不變。

### 分段與 Human ready

每段開始前均先 fresh CUA 連線核對，再取得明確 Human ready，不能沿用舊輪或前段 ready。CUA 連線不代表看得到 SecurityAgent，prompt 仍由 Human 全程觀察；系統密碼／approval 只由 Human 操作。

| 段落 | 操作與停點 |
| --- | --- |
| Stage 0 setup | fresh CUA＋Human ready 後才 run setup／trust／build；同 cert 預檢 first／second 兩版不同 hash、DR 相等。零 OAuth write。setup 提示與授權獨立記錄，不混入首次憑證存取提示。完成後停，取得本段 Human 觀察。 |
| Phase 1 首次保存／存取 | 固定 active host path 的 first binary：write A＋read A，逐欄比較六欄。完成立刻停，取得本段 prompt count／purpose／Human action 與全程觀察是否完整；不得預填 0。 |
| Phase 2 同身分 fresh reader | 同 first binary 的新 reader process 讀 A、逐欄比較。完成停，取得本段完整 Human 觀察；不重寫資料。 |
| Phase 3 真重建 reader | 同 active host path 換成保留的 second binary，核對 hash 確實不同且 DR 相等，fresh reader 讀 A、逐欄比較。完成停，取得本段完整 Human 觀察。writer 仍 first，不能兩端都 second。 |
| Phase 4 cleanup | 正常啟動 cleanup 前另 fresh CUA＋Human ready，處理 own OAuth item、owned trust 撤回／absence、owned search-list 移除／恢復及專用 Keychain／秘密清理。完成停，取得本段 Human cleanup 觀察；撤 trust 的 authentication 另記，不併入正常讀取 UX。 |

### 每段證據與下一段 gate

每段完成即保存獨立、不可覆寫 machine stage receipt，記實際 namespace、phase、開始／結束時間、執行 binary hash 及該段六欄比較；setup／cleanup 未執行六欄比較須明記不適用／未執行，不預填成功。Human sidecar 以該 receipt SHA-256 綁定，記 prompt count、purpose、action、觀察時窗及是否全程完整；未知即 unknown，不由 exit0 或 CUA 連線推定 0。

下一個正常測量段開始前，gate 必須核對同 run namespace、預期 phase、前段不可覆寫 receipt 的 SHA-256，以及其完整 Human 觀察已記錄；再 fresh CUA＋取得本段明確 ready。namespace／phase／SHA 不符、缺觀察或未 ready，不得進下一測量段。setup 授權與 Phase 1 首次保存／存取授權分開。

正常 cleanup 也需上述觀察／ready；但任何 abort、deadline、受控 signal、失敗或 gate 不足時，必須直接退出測量並清楚 announce 異常 cleanup，不得讓等待 Human、gate 或 deadline 阻塞清理。異常 cleanup 的 prompt 若無完整觀察即 unknown，不冒充 UX。不可捕捉停止限制及非秘密 recovery 仍明列。

### 判準、實作與交付

本輪 UX 成功需 Phase 1 首次保存／存取最多一次明確系統授權、Phase 2 fresh reader 與 Phase 3 真重建 reader 各零提示，且六欄資料／身分前提及 cleanup 成立。任何 phase 觀察缺失／unknown 為無法判定；資料成功不能外推 UX 成功。完整前提下明確超出提示判準則失敗，不 rerun 換結果。setup／cleanup 提示分開揭露，不能將正常測量重複提示移至其他分類排除。

沿 E005 同條件補 UX 缺口，無需新 experiment 編號。允許新增 `experiments/E005/scripts/ux_stages.py` 小型 protocol helper（immutable phase machine／Human SHA、external notices／gates），以及 `experiments/E005/Tests/test_ux_stages.py` 必要 synthetic 測試；既有 `run_self_signed_probe.py` 僅加 `--segmented-ux`、`--ux-control-dir`／`--ux-evidence-dir` 明確 opt-in 及 freshness／前提 early guards，另存舊 runner 的完整 SHA-256／source snapshot。允許獨立 stage receipts／Human sidecars 與八段 README 更新；不改 Swift host、TrustProbe、build 或 production。phase scratch／秘密在 repository 外隔離，repo evidence 僅非秘密相對位置及 bool／count，不輸出個人 path／secret。既有工具 scratch 維持本機，不為本輪重跑無關工具或擴範圍。

synthetic 必須驗證錯 namespace／phase／receipt SHA、缺 Human 觀察與未 ready 都阻擋下一測量段，且 deadline／abort／受控 signal 不阻塞 cleanup；只代表控制流程，不冒充真 Keychain／Human prompt 證據。四狀態／驗證任務完成／cleanup／recovery 分開。四檔修訂交獨立 Plan-Reviewer，不自行 approve；本輪尚未實作或執行，不預報成功。

最新分段準備已經獨立 Plan-Reviewer、Tester／Reviewer 核准；原生 CUA desktop preflight 失敗，尚未收到 setup-ready、未啟動真人 run、零實驗 mutation。新 UX 實驗未執行，真人驗證任務未完成，歷史資料機制與 UX unknown 保留；連線恢復前不得開始，原時限不延長。詳見 E005 新獨立 desktop preflight／準備收據。
