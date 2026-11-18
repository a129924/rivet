# OAuth／PAT 雙登入契約需求

- Topic：`github-dual-login-contract`
- 狀態：規劃與成果審查已 approved；先前 inventory 暫停及文件回修為歷史。執行／發布／Human review 現行狀態以配對 step 帳本為準。
- 配對：[技術規格](technical-spec.md)、[執行計畫](../../plan/github-dual-login-contract/github-dual-login-contract.plan.md)、[步驟帳本](../../plan/github-dual-login-contract/github-dual-login-contract.step.md)。

## Goal

讓應用組裝端以不可變 Value Object 表達 GitHub.com OAuth 或 PAT 登入請求，透過同一非同步 Protocol 收取一致的成功、有限失敗或取消結果，以受控替身獨立驗證契約相容性。

本次「應用層」是呼叫責任描述，不建立 Application module。GitHubIntegration 是既有 non-BC shared GitHub-specific integration target，適合作為本切片的最小可編譯落點。

## Non-Goal

不交付正式登入服務、真實連線、帳號資訊或 session。帳號、token capability、credential／provider／client 組裝需求留待實際接線確認。

## In-Scope

- OAuth／PAT 請求 VO、PAT 本地有效性、共同 Protocol、有限結果及取消契約。
- PAT 與外層請求的敏感診斷遮蔽、一般 import 使用方式及受控契約測試。
- 必要回歸維護：既有 StaticIsolationTests 的鎖定 source inventory 僅加入本次新增契約檔路徑；不改隔離語義或其餘既有路徑。
- 長期說明、Archify 受控呼叫 sequence、限定 diff 的 local PR Lens change map，以及 Graphify 導覽可用性判斷與 source-search fallback。

## Out-Of-Scope

真瀏覽器、callback、code exchange、PAT 遠端驗證、UI 接線、帳號／session／token／clients 交接、儲存／還原、refresh、401 recovery、多帳號、登出及 PR 導覽。不新增 target、runtime、bridge 或 BC，不修改既有 provider／scope。

## 現況與需求依據

- 現有登入 UI 提供 OAuth 與 PAT intent；connected 狀態不帶帳號或 session payload，目前沒有正式 consumer 證明需要這些資料。
- PAT UI 已採 whitespacesAndNewlines trim，拒絕 trim 後空值，不檢查 prefix；新 VO 沿用此本地規則。
- GitHubClientScope.prepare 只接受具體 OAuthTokenProvider；現有 GitHubAccessTokenProvider 尚無可用 bridge。本輪不以更改 scope 來支撐未確認需求。
- 本需求由使用者草案及後續確認收斂，並非採用 E013／E014 驗證 App 為正式產品 caller。

## Acceptance Criteria

1. OAuth 與 PAT 都能交給同一 LoginAuthenticating 入口；請求只含該方式必要資料。
2. OAuth case 無 payload，OAuth App 配置留服務組裝端；PAT case 只能持有已完成本地驗證的 PAT 值。
3. PAT trim 外圍空白／換行、拒絕空值、保留內部空白、不限制 prefix；不宣稱遠端有效。
4. 非拋錯 LoginOutcome 明確區分 success、failure(LoginFailure.authenticationFailed)、cancelled；取消不映射成普通失敗。
5. **修訂原草案 AC5：兩種方式共同回傳無 payload 的成功標記；帳號與 session 交接延後。**
6. 文件說明既有 OAuth／PAT UI intent 的未來對應，但不新增 UI 接線。
7. 替身與測試明示使用受控結果，不冒稱真實授權、帳號或連線成功。
8. PAT 及外層 request 的 description、debugDescription、customMirror 不洩漏 token 原值、片段、長度或雜湊。
9. 交付圖須通過 Archify showcase／deliver／四尺寸 containment 與實際截圖審視；PR Lens、Graphify 限本機既定工具與明示 fallback。

## 授權與停止點

使用者已明示實作本 topic、直接 topic commit／push／建立以 dev 為目標的 Draft PR，最後交人類 review；不授權 merge、release、工具安裝或發布圖至外部服務。執行仍須依 SDD 獨立規劃審查、測試與成果審查，不以對話計畫接受取代 gates。

2026-11-13 18:20 Asia/Taipei 開始收斂：停止擴張與新探索，優先完成既定驗證、證據、交付與狀態記錄；未完成項如實揭露，不跳過 gate，不將時間到視為通過。
