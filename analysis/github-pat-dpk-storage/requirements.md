# PAT DPK 儲存：需求

Topic：`github-pat-dpk-storage`。基準：`origin/dev` 的 `5713025e3312c0fbc9a7b02a222db0b91d6e1b58`。工作分支：`feat/github-pat-dpk-storage`。本文件記錄 Human 已接受的範圍；執行設計見 [technical-spec](technical-spec.md)，執行契約與狀態見 [plan](../../plan/github-pat-dpk-storage/github-pat-dpk-storage.plan.md)／[step](../../plan/github-pat-dpk-storage/github-pat-dpk-storage.step.md)。

## Goal

讓保存及讀取憑證的呼叫端，在具有效存取條件的 macOS 主機上，透過既有 non-BC `GitHubIntegration` 的正式 DPK adapter 保存、讀回及整筆替換 GitHub.com 的單一 PAT，並以真正新程序及同身分真正重建確認還原。

正式接入以一般 `import GitHubIntegration` consumer 與獨立簽章驗證 host 直接使用正式 adapter 證明。範圍從儲存公開入口開始，到資料還原或有限錯誤回傳結束，獨立於登入 runtime 驗收。

## Non-Goal

不交付產品登入流程，不把本地可建構或保存 PAT 當成 GitHub 接受、帳號有效或具備遠端權限的證據。

## In-Scope

- PAT 專用 async load／save 公開入口、必要格式與嚴格完整性檢查。
- 明確 DPK namespace、存取身分、OAuth／legacy 項目隔離、保存／讀回／完整替換。
- 缺值、壞資料、拒絕、不可用與保存失敗的有限語義。
- 同實例操作協調、duplicate 邊界、診斷遮蔽。
- 受控測試、一般 import consumer、獨立驗證 host、真 DPK 補驗與 owned item 清理。
- 來源能力、正式採用與本題新證據之間的映射及長期契約。

## Out-Of-Scope

OAuth／PAT 登入 runtime、登入 UI 與畫面驗收、遠端帳號驗證、session／provider／clients 交接；legacy 遷移或舊 store 移除；OAuth 公開契約及既有格式重設；通用 Keychain framework；產品 delete、登出、撤銷、多帳號、同步；profile renewal、certificate rotation、公開分發及斷電 durability。

## 已鎖定 Human 決策

1. PAT 專用 async load／save 使用 `PersonalAccessToken`，missing 以 nil 表示；不適配同步且要求 delete 的 `GitHubTokenStore`，不新增產品 delete。
2. 真 DPK runtime 提示：save A 最多一次；replace B、fresh A、fresh B、rebuilt B 各零次，由 Human 全段觀察。建置／簽章提示另行記錄。
3. 主機條件不足時，受控成果可先交付，live AC 維持 pending；整個 topic 不宣稱完成。
4. 最新執行授權允許在唯一 feature worktree 實現、topic commit／push／Draft PR；本輪先跳過 Human live 觀察，不啟動真 DPK runtime，live 與最終 Human 接受維持 pending。此 defer 不移除任何 AC。
5. Topic commit 仍從 staged diff 依 git-commit-convention 檢查語意邊界並提出 message；Human 已明示直接 commit，無須再次詢問 message。未授權 merge、release 或 tag。

## Acceptance Criteria

| AC | 完成條件 | 驗證 |
| --- | --- | --- |
| AC1 | 正式公開入口保存、讀回及替換 PAT。 | TC01、TC02 |
| AC2 | 保存後由真正新程序讀回完整 A／B。 | TC05 |
| AC3 | 同身分真正 clean/build 後的新程序完整讀回 B。 | TC05 |
| AC4 | PAT 與既有 OAuth／legacy 項目具備隔離證據。 | TC03 |
| AC5 | 缺值與壞資料明確區辨，壞資料不被 save 覆寫。 | TC02 |
| AC6 | 存取與保存失敗符合有限錯誤契約，不假報成功。 | TC02、TC04 |
| AC7 | 同實例協調、duplicate 與保存失敗具受控測試。 | TC04 |
| AC8 | 診斷與公開證據遮蔽 PAT，不帶原始錯誤或秘密。 | TC04、TC05 |
| AC9 | 各 runtime 提示符合上述 Human 觀察門檻。 | TC05 |
| AC10 | 本題驗證隔離項目有 ownership、清理及結果紀錄。 | TC05 |

## 採用依據與證據限制

既有 [OAuth 儲存契約](../../docs/architecture/github-oauth-credential-persistence.md)提供 explicit DPK query、禁止同步、group／service／account、有限錯誤、actor 協調及完整替換策略；[雙登入契約](../../docs/architecture/github-dual-login-contract.md)提供 PAT 值語義與遮蔽。E015 的正式 adapter 驗證接線、跨程序、重建、ownership 與安全收據可選擇採用必要機制，不重用其 ready、額度、真人通過或清理授權。

OAuth 舊成功不是 PAT 成功。E007 的 profile 更新後讀回仍沿用原無法判定及 Human 接受限制。舊 profile 到期資訊不代表目前主機狀態；當次有效 profile／簽章環境尚未核對，真 DPK 執行前必須 preflight。

後續登入 runtime、UI 接入、啟動恢復及帳號管理為獨立 follow-up，不在本題補造需求。
