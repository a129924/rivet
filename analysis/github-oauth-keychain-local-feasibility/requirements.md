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

範圍包含單一候選最小 host、完整假 A／B、fresh process、真正重建、整筆替換、錯誤分類、隔離清理、必要 workflow 圖與受限本地程式理解。排除真 token、GitHub OAuth、產品登入／UI、正式 adapter、SQLite migration、跨程序 refresh 協調、付費資格、公開分發／notarization、新增帳號、建立／匯入憑證、安全設定／ACL 變更及發布。

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

90 分鐘總額涵蓋 preflight、host、測量、工具、清理與紀錄。2026-10-15 02:41:28 UTC 起算，03:56:28 UTC 停止新增測量與圖作業，04:11:28 UTC 到總上限；最後十五分鐘優先清理與紀錄，不自動延長。

需要新增帳號、憑證操作、付費、安全設定變更、所選免費來源不明或時限到達時停止依賴操作，並進入本輪精確清理／紀錄。正式採用交回人類。使用者已授權本 topic 在 feature worktree 實現、直接 commit、push 並開 Draft PR 供 human review；此授權不包含 merge、release、發布或解除上述限制。

## E005 返回的決策結果

2026-10-15 [E005](../../experiments/E005/README.md) 的主假設為無法判定；legacy ad-hoc 原 binary 的完整六欄跨程序保存／替換成立，但真重建 designated requirement 改變，沒有 T03 acceptance read，提示觀察為 null。DPK 免費前提仍未證實，不能推論付費必要性。全部本輪真實項目已清理；驗證任務完成與未解的採用決策分開。獨立 Reviewer 明示成果 approved 僅核可證據及限制的交付，未核准正式採用。

### 後續 Human 補測

2026-10-15 03:16:56–03:17:01 UTC，獨立 Tester 依原條件以新 UUID 執行，Human 明確回報全程觀察 0 次提示。保存獨立 human-observation.json 綁定該輪 machine receipt，不覆寫原 null 或歷史證據。僅支持實際原 binary 身分操作的 UX；T03 acceptance read 未執行、DPK／真 denial 未驗證，主要假設仍無法判定。獨立 Reviewer 明示 approved，僅核可本輪觀察與條件化交付，不核准採用。
