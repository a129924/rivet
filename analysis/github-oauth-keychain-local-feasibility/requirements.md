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
