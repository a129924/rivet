# 免費 Personal Team／DPK 可行性需求

> 2026-10-16 原始準備契約；最新執行結果見 [E006 README](../../experiments/E006/README.md)／[step](../../plan/github-oauth-dpk-local-feasibility/github-oauth-dpk-local-feasibility.step.md)。

- Topic：`github-oauth-dpk-local-feasibility`
- 狀態：正式四份 artifacts 已獨立 Plan-Reviewer approved；最小 App 準備完成待獨立 Tester／Reviewer。DPK 真人實驗未執行。
- 實驗：E006；2026-10-16 落地前確認 E001–E005 已占用、E006 未占用；建立實驗時再次確認。
- Branch：`chore/github-oauth-dpk-local-feasibility`；僅 feature worktree。

## 問題與既有證據

在不新增付費 Apple Developer 資格下，能否以真正 macOS App、免費 Personal Team 的 Apple Development 簽章及 development profile，使用 Data Protection Keychain 保存完整假 OAuth bundle，並讓同身分真正重建後零提示讀回？

[E005](../../experiments/E005/README.md) 為歷史 baseline：完整資料跨程序／同身分重建／替換成功；最後分段補測首次 0、fresh-process 0、重建 1 次密碼並選「允許」，故該 legacy 候選 UX 失敗。設定與清理指紋授權另記，清理完成。不可覆寫歷史收據、補造已清理 ACL、重測整套 OAuth／refresh，亦不可據此推論免費 DPK 成敗。

## 九欄契約

| 欄位 | 契約 |
|---|---|
| Goal | 驗證免費 DPK 前提與有效 profile 期間的完整假 bundle、首次／fresh-process／真正重建 UX。 |
| Non-Goal | adapter 正式實作或採用、產品登入、真 OAuth／refresh、分發、續期與長期恢復。 |
| In-Scope | 唯一最小 App／唯一 private group、前提核對、分段 Human-only 觀察、收據、精確清理及本機圖工具。 |
| Out-Of-Scope | legacy fallback、其他 App 身分對照、付費資格、新帳號、ACL／partition／trust／搜尋清單及帳號安全設定變更。 |
| ReadOnly | 既有 topic／E005／原始碼／架構、Apple 官方文件、必要工具設定；目前不盤點帳號／憑證庫。 |
| Written | 新 topic 四份 artifacts；核准後僅 E006 的 App／腳本／測試／八段 README／證據／流程圖。PR Lens 為外部 scratch。 |
| Modify | 新 topic 與 E006；不改 root manifest/config、production、E005、既有 public API 或 docs。長期結論回寫另需明確範圍與審查。 |
| Deleted | 本輪 UUID DPK 項目、實驗 App／私有暫存；不刪證據或 Apple 開發資產。 |
| TestCase | 見 plan T01–T08；mock／圖工具不替代真實 DPK／UX。 |

## 授權層次

Human 已授權建立 feature worktree、落地 planning artifacts，獨立審查通過後準備最小 DPK App、unsigned build 與純 mock tests。這不包含簽章、Xcode 帳號／開發資產盤點、automatic provisioning、實際 App 啟動或任何真 DPK／Security 操作。

取得或重用 Personal Team certificate/profile、登入、註冊 App ID／Mac 前，須具體說明變更、另取 Human 授權，由 Human 操作 Xcode。不呼叫 `-allowProvisioningUpdates`，不自行 revoke／刪除任何 Apple 資產；新舊資產預設保留由 Human 管理，逐項記錄。不把 skill 使用推論為外部授權。真人操作另需完整前提與逐段 Human ready。

## 預固定判準

首次正常保存／存取最多一次提示；相同 binary fresh-process 與同身分真正重建各零提示；三段六欄完整相符。資料與 UX 分開判讀。

- 未執行：目前僅準備，無真 DPK 證據。
- 成功：免費／host／profile 前提成立、資料與提示全部達標、隔離實驗清理完成。
- 失敗：前提成立且觀察完整，可重現資料不符或提示超標。
- 無法判定：資格／profile／host／觀察缺漏或環境受限。清理未完成不得稱任務完整完成。

免費 profile 約七日的續期、重新佈建、certificate 輪替與長期恢復仍為獨立缺口。即使成功，也只支持後續正式規劃，不核准 adapter；GitHubIntegration 邊界與 OAuthTokenProvider lifecycle ownership 不變。

## 依據與限制

文件支持條件路徑，不等於本機已簽發 profile：

- [免費帳號與 Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [macOS capability 支援](https://developer.apple.com/help/account/reference/supported-capabilities-macos)
- [Xcode Personal Team 管理](https://help.apple.com/xcode/mac/current/en.lproj/dev60b6fbbc7.html)
- [certificate 類型](https://developer.apple.com/help/account/certificates/certificates-overview/)
- [TN3137 Mac keychains](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)
- [TN3125 provisioning profiles](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)
- [TN3127 requirement validation](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)

對話草案審查不替代四份正式檔案的獨立 approval。執行與帳本見 [plan](../../plan/github-oauth-dpk-local-feasibility/github-oauth-dpk-local-feasibility.plan.md)／[step](../../plan/github-oauth-dpk-local-feasibility/github-oauth-dpk-local-feasibility.step.md)。
