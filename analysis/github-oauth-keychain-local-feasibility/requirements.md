# Keychain 本機 OAuth 憑證保存可行性：需求

- Topic：`github-oauth-keychain-local-feasibility`
- 日期：2026-10-15
- 性質：受限可行性實驗；實驗成功不核准正式採用。
- 執行契約：[plan](../../plan/github-oauth-keychain-local-feasibility/github-oauth-keychain-local-feasibility.plan.md)、[step](../../plan/github-oauth-keychain-local-feasibility/github-oauth-keychain-local-feasibility.step.md)
- 技術設計：[technical-spec](technical-spec.md)

## 主問題與使用情境

Rivet 能否在完全不依賴付費 Apple Developer 資格的個人本機條件下，以 macOS Keychain 保存完整 OAuth 憑證，並於 fresh process 及相同身分的 app 真正重新建置後可靠讀回？既有付費簽章或 profile 也不得作為成功前提。目標是個人本機開發與使用，不包含公開分發。

主要假設：存在符合上述免費條件的單一 Keychain 候選路徑，可保存完整假 OAuth bundle，且不需每次啟動重新授權。首次最多一次明確系統授權；正常後續啟動及同身分重新建置必須零提示。主要正常流程的全部提示皆計入 UX，不得事後改稱負向觀察而排除。

## 已鎖定邊界

責任維持既有 non-BC `GitHubIntegration`，不新增 Auth BC、不新增 public API、不改變 `OAuthTokenProvider` lifecycle ownership 或既定架構。僅以假資料驗證 host、存取、持久化與授權提示；不重測完整 refresh runtime。

範圍包含單一候選最小 host、完整假 A／B、fresh process、真正重建、整筆替換、錯誤分類、隔離清理、必要 workflow 圖與受限本地程式理解。排除真 token、GitHub OAuth、產品登入／UI、正式 adapter、SQLite migration、跨程序 refresh 協調、付費資格、公開分發／notarization、新增帳號、未經限定授權的建立／匯入憑證、安全設定／既有 ACL 變更及發布。僅下節明列的實驗自簽 Code Signing 憑證／private key 為建立／匯入例外。

## 事前判準

| 分類 | 可觀察條件 |
| --- | --- |
| 成功 | 所選候選的免費前提成立；完整保存／還原、真正重建、整筆替換及清理成立，正常流程授權提示符合首次最多一次、後續與同身分重建零提示。 |
| 失敗 | 前提已滿足的測量條件下，可重現資料不完整、無法恢復或反覆提示而不符合 UX。 |
| 無法判定 | 必要 host／免費來源／簽章／profile／穩定身分未確認、系統互動不可觀察或關鍵操作受限制。 |

機制讀寫成功而 UX 失敗時，兩者分列。未嘗試為「未執行」；已嘗試但前提或觀察不足為「無法判定」，不得冒充假設失敗。真 denial 無自然觀察機會時可保留缺口；明標 synthetic 僅支持分類，其他完整證據仍可支持受限成功。

實驗四狀態與「本輪驗證任務完成：是／否」分開。清理失敗則任務完成為否；工具交付狀態不改寫測量事實。假設失敗仍可能完成驗證；無法判定須明列原因、缺少證據與決策限制，不因紀錄完成而推進受阻採用。

## 已知依據與限制

- 既有 `KeychainTokenStore` 是 legacy file-based Keychain，只保存單一 access token。歷史帳本記錄八個真實 Keychain 測試通過，包含跨程序；本輪未重跑，不能據此宣稱本輪或 DPK 成功。
- 完整 OAuth Keychain adapter 尚未交付。E004 支持受限 SQLite 儲存與 provider lifecycle，不驗證 Keychain。
- [Apple TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains) 用於區分 Keychain 機制；[Apple TN3125](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles) 用於檢查 profile 前提。來源作設計依據，實際 host 免費前提仍須 preflight。
- [Apple DTS](https://developer.apple.com/forums/thread/845980) 指出 file-based Keychain effectively deprecated；legacy 成功僅支持本次本機條件，不構成未來 macOS 或公開分發保證。
- 免費 Keychain Sharing 適用條件未由既有資料確證；不得從此推論必須付費。

## 投入與人類邊界

原授權窗（歷史）：90 分鐘總額涵蓋 preflight、host、測量、工具、清理與紀錄。後續只有本檔末節 Human 明確授權的新 30 分鐘窗適用於限定 trust 補測，不是默認延長。2026-10-15 02:41:28 UTC 起算，03:56:28 UTC 停止新增測量與圖作業，04:11:28 UTC 到總上限；最後十五分鐘優先清理與紀錄，不自動延長。

需要新增帳號、超出下節限定例外的憑證操作、付費、安全設定變更、所選免費來源不明或時限到達時停止依賴操作，並進入本輪精確清理／紀錄。正式採用交回人類。使用者已授權本 topic 在 feature worktree 實現、直接 commit、push 並開 Draft PR 供 human review；此授權不包含 merge、release、發布或解除上述限制。

## E005 返回的決策結果

2026-10-15 [E005](../../experiments/E005/README.md) 的主假設為無法判定；legacy ad-hoc 原 binary 的完整六欄跨程序保存／替換成立，但真重建 designated requirement 改變，沒有 T03 acceptance read，提示觀察為 null。DPK 免費前提仍未證實，不能推論付費必要性。全部本輪真實項目已清理；驗證任務完成與未解的採用決策分開。獨立 Reviewer 明示成果 approved 僅核可證據及限制的交付，未核准正式採用。

### 後續 Human 補測

2026-10-15 03:16:56–03:17:01 UTC，獨立 Tester 依原條件以新 UUID 執行，Human 明確回報全程觀察 0 次提示。保存獨立 human-observation.json 綁定該輪 machine receipt，不覆寫原 null 或歷史證據。僅支持實際原 binary 身分操作的 UX；T03 acceptance read 未執行、DPK／真 denial 未驗證，主要假設仍無法判定。獨立 Reviewer 明示 approved，僅核可本輪觀察與條件化交付，不核准採用。


## 後續窄範圍授權：實驗自簽 Code Signing 身分補 T03

使用者明確授權新增一張實驗專用、自簽 Code Signing certificate 及其 private key，僅建立／匯入本輪獨立實驗 Keychain，用於 E005 同一 legacy backend、相同假六欄的 T03 補測。這是原「不得建立／匯入憑證」的唯一限定例外，不授權帳號、付費或其他憑證操作。

不得改既有 ACL、系統信任、預設 Keychain 或全域 Keychain search-list；任何步驟需要上述變更即停。秘密素材不得進 repository、證據或診斷輸出。先完成兩次真正重建／DR 預檢，保留 first／second binaries，保存並核對兩者不同 hash、designated requirement 相等。然後在固定 host 路徑還原第一次 build 作 writer 寫入本次新 UUID OAuth item，再換第二次 build 作 fresh reader 讀回；writer／reader 不得都用第二次 build。未達同身分前提不得作 acceptance read 或宣稱 T03 成立。

專用憑證 Keychain、private key、匯入／秘密素材均在 repository 外精確隔離。整輪補測退出時清理本輪 OAuth 項目、專用 Keychain 與秘密素材，保留非秘密清理結果；不得刪既有 Keychain 或歷史證據。清理不完整時任務完成為否。

原截止不變：03:56:28 UTC 停止新增測量，04:11:28 UTC 總上限。舊 ad-hoc／Human receipts 及原無法判定結果保持原樣；T03 acceptance 目前未執行；兩輪簽章 preflight 結果見 E005，不預先改寫主要假設結論。

## 自簽身分補測結果（2026-10-15）

使用者明確允許限定自簽憑證／獨立 Keychain 例外後，獨立 Plan-Reviewer 已核准 first writer／second reader 的補測計畫。兩輪僅簽章預檢：PKCS12 停於匯入 exit1；一次 PEM 相容性檢查成功匯入憑證／私鑰後，首次簽章 exit1，沒有兩版有效簽章或 DR 比較。零 OAuth 寫入，T03 acceptance 未執行；主假設仍無法判定。已知錯誤分類不足以指出根因，不推論信任錯誤、付費必要性或方案普遍不可用。兩輪專用 Keychain／秘密暫存完整清理，預設 Keychain／全域 search-list 前後一致。原 ad-hoc host 的 Human 零提示證據保留；不能外推尚未建立的自簽 host。詳細指令、時間、source hash 與 receipt 見 [E005](../../experiments/E005/README.md)。

使用者續行授權（2026-10-15）：同一 PEM／自簽候選只補失敗診斷，保存公開已知錯誤片語與本輪專用 Keychain identity 數量，不保留個人識別／raw stderr、不掃全域。無 OAuth 寫入，不增加簽章變體或安全設定變更；原 03:56:28 UTC 新測量截止不變，診斷後若需禁止操作即停。

同一候選新診斷（03:46:15–19 UTC）：僅本輪私有 Keychain 身分查詢回 1 matching／0 valid、`CSSMERR_TP_NOT_TRUSTED`；codesign 首次簽章回 `no identity found`。本次可具體指出可用簽章身分前提不成立；舊兩輪無診斷紀錄保留，不倒填根因。零 OAuth 寫入／T03 acceptance 未執行、清理完整、全域設定一致。若需信任調整須 Human 新授權，不自動執行；不推論必須付費。詳見 E005 診斷收據。


## Human 新授權：僅實驗憑證的使用者範圍 Code Signing trust

本次為明確新授權，唯一 trust 例外只限本輪新建自簽 cert、user domain、Code Signing policy。不得使用 admin domain／`-d`、SSL policy、broad trust，也不得改既有 ACL、partition-list、預設 Keychain、全域 search-list、既有憑證或信任設定。系統密碼／approval 全由 Human 操作，不得自填或放寬設定。

先證明 exact cert 原本沒有 user trust，再新增唯一 codeSign／user-domain trust，讀回確認僅該 domain／policy；不能確認即停。trust 與兩次 build／DR 預檢全程零 OAuth 寫入。成功後先確認 CUA 連線並等待 Human 明確 ready，再用同 cert、固定 active host 路徑、first writer／second reader 作 T03，保存不同 hash 與全部提示。

finally／受控 signal／trust failed／timeout 等整輪退出，只有三 domain baseline absence 已確認且本輪 add 已嘗試，才可精確撤回本次 exact-cert user trust，讀回核對無 user trust後才刪專用 Keychain／cert／秘密；baseline 已有 trust／查證失敗／未 add 時只清自建素材，絕不撤原有 trust；不能因 cert 刪除便假設 trust 消失。撤回或核對失敗須明列殘留與原因，不能宣稱完整清理／任務完成。秘密不進 repository，歷史 receipts 不覆寫；T03 目前仍無法判定。

新 30 分鐘窗：2026-10-15 03:54:20 UTC 起，04:19:20 UTC 停止新增測量，04:24:20 UTC 總上限；最後五分鐘優先撤 trust、清理與紀錄。此為 Human 額外明確授權，原 90 分鐘窗及結果作歷史保留，不暗中延長。等待 Human ready 不延長本窗。


### TrustProbe 與兩次 Human ready

本窗 trust 操作前另須 Human 明確 ready 留意桌面並自行處理 add／remove authentication；目前尚未收到此 ready，只允許 code preparation，不執行需互動 trust。兩版簽章／DR 預檢成功後，T03 桌面觀察仍須另行確認 CUA 及 Human ready，不沿用前一 ready。

只接受本輪 `Rivet-E005-UUID` 實驗 cert，新增前 exact-cert user／admin／system 三 domain 均須嚴格 absence。absence 僅 `errSecItemNotFound`；空 array 是 broad AlwaysTrust，不算 absence 或限定 trust。新增後只允許 user domain 的恰一筆 codeSigning／trustRoot，admin／system 必須仍 absent；其他形狀即停止。撤回僅在三 domain baseline absence 成立且本輪 add 已嘗試時，對 exact cert user trust 執行，核對 absent 後才刪 Keychain／秘密；否則不得 remove，只清自建素材；撤回失敗保留 cert DER、private Keychain 及 recovery 資料供 Human，不輸出路徑或秘密。

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
