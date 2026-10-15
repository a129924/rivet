# Keychain 本機 OAuth 憑證保存可行性計畫

- Topic：`github-oauth-keychain-local-feasibility`
- 日期：2026-10-15
- [需求](../../analysis/github-oauth-keychain-local-feasibility/requirements.md)／[技術規格](../../analysis/github-oauth-keychain-local-feasibility/technical-spec.md)／[狀態帳本](github-oauth-keychain-local-feasibility.step.md)

## 目標與固定條件

驗證完全不依賴付費資格的本機 Keychain 完整 OAuth bundle 保存、fresh-process、真正同身分重建及 UX。既有付費 profile／簽章也不得作成功前提。首次最多一次明確系統授權；正常後續啟動及同身分重建零提示。責任維持 non-BC GitHubIntegration，不新增 public API、不改 provider ownership／既定架構。

DPK 優先檢查免費 host 前提，無法證實時只允許首次寫入前選 legacy 為唯一候選，不得測量失敗後 fallback；所選前提不足則無法判定。完整設計與官方來源見 technical-spec。歷史 legacy 八個測試與 E004 僅為背景，本輪不重跑整套 baseline 或 refresh runtime。

## swift-implementation：後續受限 Swift 實驗階段

此為階段名稱；未找到同名 skill，不宣稱使用該 skill。

| 欄名 | 受限契約 |
| --- | --- |
| **Goal** | 免費本機完整憑證的 fresh-process、真重建與提示 UX 可行性。 |
| **In-Scope** | 單一候選最小 Swift host、私有編碼器、固定假 A／B、T01–T06、遮蔽證據、精確清理、必要 workflow 與受限本地理解。 |
| **Out-Of-Scope** | 真 token／GitHub OAuth／登入 UI、正式 adapter、SQLite migration、跨程序 refresh、公開分發／notarization、新增帳號、超出下節窄範圍例外的建立／匯入憑證、付費、超出新授權 user-domain codeSign trust 例外的安全設定／既有 ACL 變更、發布。 |
| **ReadOnly** | production Sources／Tests、root manifests、歷史 topics／E001–E004、技能與 tool configs；架構文件作依據，唯一後續回寫目標除外。 |
| **Written** | 本 topic requirements／technical-spec／plan／step 四檔，新 experiment 的 host、八段 README、evidence、Archify spec／HTML／receipts／captures；PR Lens 僅 repository 外 topic scratch；限定自簽憑證／private key、匯入素材與專用實驗 Keychain 僅在 repository 外隔離 scratch，不進 repository 或輸出秘密；僅本輪新 cert 的 user-domain codeSign trust 依末節建立／讀回／撤回，證據只留非秘密判斷。 |
| **Deleted** | 不刪既有 repository 檔案；僅本輪精確 UUID Keychain 項目、限定憑證的專用實驗 Keychain／repository 外秘密素材及確認屬本輪的 build 暫存，不刪證據或既有 Keychain；只有 baseline 三 domain absence 已確認且本輪 add 已嘗試才撤回 exact-cert user trust並驗證無 trust，不能以刪 cert 代替；baseline 失敗／已有 trust／未 add 不得 remove。 |
| **Modify** | 本 topic 新檔後續更新；經實證與獨立 review 後，只於 `docs/architecture/github-oauth-dual-client.md` 回寫有條件結論，不核准採用、不擴其他 docs。 |
| **Non-Goal** | 不改 API、provider ownership、既定架構或歷史 topic，不以工具／build green 代替驗證。 |
| **TestCase** | 下列 T01–T06，正常完成後獨立負向；整輪 experiment 的所有退出路徑精確清理，writer／reader 正常結束保留 item。 |

主要 item 為 UUID 隔離 generic-password，單 `Data` 私有 DTO 整筆更新。六欄為 accessToken、refreshToken、accessTokenExpiresAt、refreshTokenExpiresAt、tokenType、grantedScopes；expiry 為 Date，A／B 的兩 token、兩 expiry、scope 均不同且 tokenType 均 bearer。DPK query 明設 true、legacy false，皆 synchronizable false。所有輸出遵守遮蔽限制。

## 分支與檔案影響

唯一 branch：`chore/github-oauth-keychain-local-feasibility`，base 為 `dev`；實際 feature worktree 已由主工作 session 建立，起點 `origin/dev` 的 `913c063`。不加入無既定慣例的 owner；規劃時 local／remote-tracking 未見衝突，fresh remote 未查，不冒稱遠端新查證。

僅在已建立的 feature worktree 寫入，不改 dev 工作樹。新實驗建檔前重新查 `experiments/` 編號；E001–E004 已占用，E005 僅規劃時可用。使用未占用編號，不覆寫歷史。產物只在 Written 範圍，長期結論只回寫 Modify 指定文件。

## T01–T06 與驗收

| 案例 | 必要操作與證據 |
| --- | --- |
| T01 前提 | 記錄日期、OS／Swift、host、backend、簽章／profile、免費來源與未知項；首次寫入前固定候選與判準。 |
| T02 完整還原 | writer 保存 A 後結束；兩個 fresh reader 各逐欄比較六欄，記錄所有提示。 |
| T03 真重建 | 改 build marker、重建並證明 hash 不同；固定 host 路徑／bundle ID／簽章方式／backend，記 designated requirement／entitlements／access groups 一致性布林值，新程序讀 A。無免費穩定身分不能說完成。 |
| T04 完整替換 | 整筆替換 B，新程序讀回全 B，沒有新舊欄位混合。 |
| T05 失敗邊界 | T02–T04 正常完成後才負向。absent→nil；malformed→decode failure；非 errSecItemNotFound 不得 nil。真 denial 僅獨立項目自然觀察，不改主要 host 身分／ACL／安全設定製造提示。無自然 denial 保留缺口，synthetic 分類證據明標；正常流程全部提示計入 UX，不可轉分類排除。 |
| T06 清理 | 整輪實驗結束時，以精確 namespace／service／account／backend 清理主要與負向項目並確認不存在，逐項保存結果；不於 writer／reader 正常結束時刪除。 |

成功需免費前提、完整還原、真重建、替換、清理及 UX 達標；真 denial 缺口可保留並支持其餘完整證據下的受限成功。前提滿足時可重現不完整／無法恢復／反覆提示為失敗；機制成功與 UX 失敗分開。沒跑或前提不足不能稱假設失敗。

## 工具使用時點、產物與失敗處理

所有工具共用本輪總額。不安裝／更新、不啟動服務、不改設定、不發布，不以工具結果取代實驗證據。

### Graphify 0.9.73

程式理解時先查既有 graph／revision，query budget 1500，再 source verify。每次 CLI 明設 `GRAPHIFY_NO_AUTO_REFRESH=1`。規劃時 repository 未見 graphify-out，外部未全面查；無圖或 runtime failure 即 rg fallback。不自建／refresh graph、不 install／改 config／啟動 watcher／配置 semantic provider。保留 revision、query 與 source 核對／fallback 紀錄。

### PR Lens 0.11.0

有真實 bounded diff 與非捏造 provenance 才用 pinned CLI validate／render，涵蓋 changed、unchanged 鄰近內容及 references，產物只在 repository 外 topic scratch。無可代表變更的 base／head 時 deferred、使用 direct diff；相同 commit 不假造 diff，不為工具 commit。有既有 overlay 則唯讀使用，無 overlay 則 scratch no-config。不 commit／create PR／upload／server／install／改 config。topic commit／Draft PR 僅依下節已授權交付流程，不由 PR Lens 工具代做。

### Archify 2.16

host 與整輪實驗退出行為明確後，產出一張繁中 static classic workflow，涵蓋成功、停止／例外及整輪 exact cleanup；writer／reader 正常退出保留 item。不新增 architecture 圖、不加 animation、不發布 artifact.cafe。省略 meta.locale，不誤用 zh-CN；揭露固定 Viewer UI／HTML lang fallback English。

保存 spec、HTML、showcase／deliver receipts 與 captures。showcase 九項 checks 零 error／warning，依序 deliver、visual-check 四個桌面尺寸並實際查看 captures。receipt 的 `visualReview: pending` 原樣保留，另記人工視覺檢查狀態。兩次連續修圖未改善即停並列未完成項。

工具 deferred／fallback／失敗與實驗四狀態分開。必要圖作業未完成標 INCOMPLETE，不宣稱整包完整；不自動延長時間。

## 時間、清理與停止

原授權窗（歷史，後續限定 trust 補測另見末節明確 Human 新窗）：2026-10-15 02:41:28 UTC 起算，總額 90 分鐘；03:56:28 UTC（75 分鐘）停止新增測量／圖作業，04:11:28 UTC（90 分鐘）到總上限。最後十五分鐘優先清理、保存證據與八段紀錄。PR 提交交接不當作 Keychain 測量，不杜撰額外測量時間或結果。

統一 cleanup 是整輪 experiment 的退出路徑：writer／reader 子程序正常結束保留 item，供 T02 跨程序、T03 真重建、T04 替換使用。任一寫入嘗試後，整輪正常完成／失敗／停止／例外退出時才嘗試精確清理全部本輪主要及負向項目。殘留時記非秘密 UUID 識別、原因、待處理操作，驗證任務完成為否。需要新增帳號／超出限定例外的憑證操作／付費／安全設定變更、所選免費來源不明或時限到達即停止依賴操作並清理紀錄。

## 結果、角色與交付

八段 README 擇一記「未執行／成功／失敗／無法判定」，另記本輪驗證任務完成與理由。設計／執行日期、真實／synthetic、觀察／推論、適用限制及 cleanup 狀態分開。只支持本次 OS／host／身分與候選，不外推所有 macOS、簽章方式、新版本或公開分發。

四檔建立後先交獨立 Plan-Reviewer；正式明示 approved 後由 Implementer 做 host，Tester 獨立驗證、Reviewer 獨立審查證據。這是既有專案流程，不為工具新增 gate。完成後由 Implementer 回寫指定長期文件、依 staged diff 檢查語意邊界並提出 commit message、按 topic commit／push／開 Draft PR，交 Human review。使用者已明確授權直接 commit，不新增等待 commit 批准；不授權 merge／release／發布。實驗完成不核准正式採用。


## E005 T03 窄範圍補測授權

使用者已明確授權新增一張實驗專用自簽 Code Signing cert／private key，僅在 repository 外獨立實驗 Keychain 建立／匯入及精確清理，用於同一 legacy backend、相同假六欄的 T03 補測。這是 Out-Of-Scope 憑證操作的唯一例外，不改其他 scope、免費／UX 判準或 production contract。

在新 UUID OAuth item 首次寫入前，先完成兩次真正重建／同身分簽署與 DR 預檢，保留 first／second binaries，保存並核對不同 hash、designated requirement 相等及原身分條件一致。未成立即停，不用舊 ad-hoc 結果或只重跑 binary 代替 T03。成立後於固定 host 路徑還原 first（第一次 build）作 writer 保存 A，結束後換成 second（第二次 build）作 fresh reader 逐欄 acceptance read；保存並核對實際 writer／reader hash，兩端不得都用 second。所有提示如實記錄。

不得改既有 ACL、系統信任、預設 Keychain、全域 search-list，不新增帳號或付費；需要任一禁止改動即停。private key、密碼及匯入素材只在 repository 外隔離 scratch，不進 repo／證據／log。整輪退出 cleanup 除精確 OAuth 項目外，亦涵蓋本次專用 cert Keychain 與秘密素材，分開確認不存在；保留 receipts，不刪歷史或既有 Keychain。無法清理則記非秘密 UUID／原因，任務完成為否。

原 90 分鐘不延長：03:56:28 UTC 停止新增測量，最後十五分鐘優先清理紀錄，04:11:28 UTC 總上限。四檔修訂先交獨立 Plan-Reviewer，通過後依既有 Implementer→Tester→Reviewer 流程補測，不新增工具 gate；新結果獨立保存，歷史及其審查結論不覆寫。T03 acceptance 目前未執行；兩輪簽章 preflight 結果見 E005，不預先宣稱 T03 或主假設成功。

使用者續行授權（2026-10-15）：同一 PEM／自簽候選只補失敗診斷，保存公開已知錯誤片語與本輪專用 Keychain identity 數量，不保留個人識別／raw stderr、不掃全域。無 OAuth 寫入，不增加簽章變體或安全設定變更；原 03:56:28 UTC 新測量截止不變，診斷後若需禁止操作即停。


## Human 額外 30 分鐘窗：user-domain codeSign trust 唯一例外

使用者明確授權僅本輪新自簽 cert、使用者範圍、Code Signing 用途的 trust；這是原安全設定禁令的唯一新增例外。禁止 admin／`-d`、SSL／broad trust、既有 ACL／partition-list、預設 Keychain／全域 search-list 變更。系統密碼／approval 由 Human 操作，agent 不自填、不保存。

執行順序固定：證明 exact cert 原本無 user trust → 新增唯一 user-domain codeSign trust → 讀回驗證僅此 domain／policy → 同 cert 兩 build 真重建及 DR 相等／hash 不同預檢（至此零 OAuth write）→ 確認 CUA 連線 → 等 Human 明確 ready → 固定 active host 路徑 first writer／second reader T03。前提、CUA 或 ready 不足／超時則無 OAuth write 並 cleanup，不增加 trust 變體。

所有整輪退出（包括 trustfailed、timeout、受控 signal、正常／失敗／例外）皆 finally cleanup；只有三 domain baseline absence 已確認 AND 本輪 add 已嘗試，才可 remove 本次 exact-cert user trust，核對無 user trust後才刪專用 Keychain／cert／秘密。baseline 已有 trust／查證失敗／未 add 只清自建素材，絕不撤原有 trust。不得以刪 cert 假設 trust 消失；部分新增也需撤回核對。失敗保留非秘密 exact-cert 撤回依據／殘留原因、標任務否，不先毀掉撤回依據；不輸出秘密或改其他設定。

新窗 2026-10-15 03:54:20 UTC 起，04:19:20 UTC 停新測量，04:24:20 UTC 總上限，最後五分鐘優先撤 trust／清理紀錄。這是 Human 明確新授權，原 90 分鐘窗及所有 receipts 作歷史保留，不暗延長。新四檔修訂交獨立 Plan-Reviewer，再依既有 Implementer／Tester／Reviewer 分工；T03 仍無法判定，不預報成功，不覆寫舊 evidence。


### 本窗精確 trust 與互動約束

只新增 experiment-local Swift TrustProbe，接受本輪 `Rivet-E005-UUID` cert DER，exact-cert CopyTrustSettings 查 user／admin／system。三 domain baseline 均須 `errSecItemNotFound`，空 array／錯誤不算 absence。set 僅 user／SecPolicyCreateWithProperties(kSecPolicyAppleCodeSigning, nil)／trustRoot；readback 恰一 entry、必需 Policy／Result，Policy 為 SecPolicy runtime type／OID AppleCodeSigning、Result trustRoot；唯一可選 kSecTrustSettingsPolicyName metadata 必須 String 且精確等於 Apple OSS 明定的 String literal `CodeSigning`。admin／system absent；SSL／broad／空array／multirow／allowedError／其他 unknown keys 拒絕。

trust 互動 ready 尚未收到：先 code preparation，不執行需互動 trust。收到 Human 明確 ready 後才 add，authentication 全由 Human；兩版預檢成功後再確認 CUA／T03 Human ready，不能沿用 trust-ready。trustOwnedAttempt 初始 false，只在三 domain baseline absence 確認後、呼叫 add 前設 true；finally 只有 true 才 remove exact-cert user trust並嚴格 readback absent，再刪 Keychain／秘密。add failure 仍處理可能部分新增；false 分支只清自建素材，絕不 remove 原有 trust；失敗保留 cert DER／private Keychain／recovery 資料供 Human，明列殘留，不輸出路徑／秘密，不改 partition-list。新窗截止不變。

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


## 最新有效窄授權：Human-only 逐段真人觀察

Human 已明確授權：「允許改為完全由我逐段真人觀察，免除桌面工具連線前提。其餘範圍、逐段停點與判準不變；每段等我回報觀察後再繼續，請開始。」本節僅解除本輪 CUA／桌面工具連線前提，絕不降低真人觀察、完整回報或 UX 判準；native 模式預設行為維持。

### 時間、目前 ready 與證據隔離

依 Human 08:03:06 UTC 的重新開始授權，新窗為 2026-10-15 08:03:06–08:33:06 UTC；08:28:06 UTC 停新增測量，最後五分鐘優先 cleanup／closure，不自動延長。本節時間及 human-only 連線豁免優先於所有前版時窗／CUA prerequisite 敘述，舊契約與 receipts 保留為歷史。

Human 當前「請開始」可作本輪 Stage 0 setup 的明確 ready；不能沿用於 Phase 1–4。各後續段仍須前段完整 Human 觀察已記錄，再取得該段 fresh Human ready，逐次停止／等待回報後才繼續。依主工作 session 交接，目前尚無本輪真 UX run／實驗 mutation，不預填結果。

沿用 E005，新增 prefix `ux-human-only-20261015T080306Z` 的不可覆寫準備／stage／Human 證據，不覆前輪 preflight-false 或其他歷史紀錄。改程式前保存舊 runner／helper 的完整 SHA-256 及 source snapshots；本輪準備收據綁定改後新 source hashes，交獨立 Reviewer 核對。

### 明確 opt-in 與 mode gate

新增 `--human-only-observation` 明確 opt-in，必須同時有 `--segmented-ux`；缺 guard 在 Security 初始化／任何實驗副作用前失敗。既有 trust、diagnose、cert、UTC deadline、ownership 等 guards 維持。`UXStages` 預設 native 模式不變；只有顯式 human-only 模式可跳過 desktop connection gate。

human-only 模式的正常段 gate 必須要求 `observationMode='human-only'`，且 machine／Human receipt 皆明列相同 mode；不得以 desktopConnected=true 冒充連線。desktopConnected 依實際情況保留 false／null，不能偽填或作 Human 觀察完整性的替代。namespace、phase、前段 immutable receipt SHA-256、完整 Human count／purpose／action 與全程觀察、fresh Human ready 的 gate 全保留；錯 mode／不一致／缺 Human 觀察不得進下一測量段，不能預填零提示。

Stage 0 setup 與 Phase 1 first write A＋read A、Phase 2 同 first fresh reader、Phase 3 不同 hash／同 DR second reader、Phase 4 cleanup 的順序與逐段停點維持。setup 授權獨立於首次憑證存取，trust add／remove authentication 仍由 Human 自行操作。Phase 1 首次最多一次提示、Phase 2／3 各零才支持成功；缺完整觀察／unknown 仍無法判定，不 rerun、不改判準。

### 退出、安全與最小變更

正常 cleanup 前仍須該段 Human ready；異常／abort／deadline／受控 signal 直接清楚 announce cleanup，不得被等 Human、phase gate 或桌面連線阻塞。異常 cleanup prompt 未完整觀察即 unknown。trust／user search-list cleanup ownership、exact own cert／Keychain、foreign entries／order、default 保護、殘留 recovery 全維持。

仍只假六欄、同 legacy、新 own self-signed cert、user codeSign trust、temporary user search-list 的既有授權；禁止 production、既有 ACL／partition-list、付費、admin／system／SSL／broad trust。不得新增安全操作、B／negative／refresh 或其他實驗變體。

只做必要 human-only mode-gate／early guards 測試及 source-hash Reviewer 核對，不重跑十五項無關 suite、不加圖或 baseline。以上為窄修規劃當時內容；其後已獲獨立 Plan-Reviewer、Tester／Reviewer 準備 approved，唯一真人輪結果見 E005 最新分段紀錄，不以準備 approval 當 UX 成功。

最新 Human-only 唯一輪已逐段完成：setup 1次設定指紋；首次保存／存取0次、同binary fresh reader0次、不同hash／同DR rebuilt reader1次憑證提示（密碼＋允許）；cleanup1次撤trust設定指紋另記。每段六欄資料一致、前觀察SHA＋freshready後才前進，全部隔離資料／trust／search-list／秘密清理完整。依事前判準此候選 UX 失敗、資料機制成功，不再是階段無法辨識；本次選「允許」，不混作前輪「永遠允許」或外推其他選項。不重跑、不推論所有免費路徑失敗／必須付費，正式採用不核准。結果與任務完成判斷交獨立 Tester／Reviewer。
