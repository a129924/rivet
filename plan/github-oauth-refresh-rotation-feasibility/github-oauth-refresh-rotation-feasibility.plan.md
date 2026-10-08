# E003 — 受限執行計畫

- Topic：`github-oauth-refresh-rotation-feasibility`；branch：`chore/github-oauth-refresh-rotation-feasibility`。
- 作業位置：由 dev 基線建立的 E003 feature worktree；dev worktree 完全唯讀。實際 base/head SHA 由後續 Git 角色查證，不預寫。
- 配對文件：[requirements](../../analysis/github-oauth-refresh-rotation-feasibility/requirements.md)、[technical-spec](../../analysis/github-oauth-refresh-rotation-feasibility/technical-spec.md)、[step](github-oauth-refresh-rotation-feasibility.step.md)。
- Formal planning verdict：2026-10-08 獨立 Plan-Reviewer 明示 `approved`，required fixes 無；獨立成果 Reviewer 亦已明示 `approved`，無 required fix。Draft PR human review 仍 pending。

## swift-implementation Contract

| 欄位 | 契約 |
| --- | --- |
| Goal | 交付 E003 可重現的 refresh／rotation 實驗 runner，於真實授權可用時取得四項分離且遮蔽的量測。 |
| Non-Goal | 不證明產品自動刷新、正式 credential lifecycle、遠端撤銷、E002 PKCE 成功或正式採用。 |
| In-Scope | 一次新授權、初始與新 access token 各一次 `/user`、一次正向 refresh、一次舊 refresh token 重用、六欄／bundle 相容、局部測試、README、一張 Archify sequence、受限 Graphify／PR Lens。 |
| Out-Of-Scope | Keychain／持久化、`OAuthTokenProvider`、並行／single-flight、REST／GraphQL client、401 recovery／retry、舊 access token、真實到期、logout／revoke、多帳號、E002 PKCE 補測、Graphify 建圖、工具發布、merge／release。 |
| ReadOnly | root Package.swift／Sources／Tests、E001／E002、既有 docs／architecture／skills／設定；dev worktree 所有檔案。既有 graph、PR 設定只讀。 |
| Written | 四份同 slug artifacts；`experiments/E003` 的 Package.swift、Sources／Tests、README、diagrams JSON／HTML／receipts／captures；PR Lens 僅 repo 外暫存。 |
| Deleted | 無。 |
| Modify | 僅本 topic 四份 artifacts 與新 E003 檔案；其他既有檔案如需變更，先回 planning 判定 scope。 |
| TestCase | T01 初始 `/user`、T02 正向 refresh／bundle、T03 新 `/user` 同身分、T04 舊 refresh token 明確拒絕；另有局部模擬、敏感值、圖與 diff allowlist 驗證。 |

## 執行與交接

1. Plan-Creator 在 feature worktree 建四份 artifacts；獨立 Plan-Reviewer 審查 locked decisions、scope、驗收與 workflow，只有明示 `approved` 才進實作。
2. Implementer 只在 feature worktree 建獨立 E003 SwiftPM package、局部測試、README 與一張 Archify sequence；E002 與產品維持唯讀。README 的真實結果初始標「未執行／無法判定」。圖需九項 showcase、零 errors／warnings、deliver receipt、四尺寸 containment、captures 與獨立視覺審查。不發布 artifact.cafe。
3. Tester 獨立執行 `swift build --package-path experiments/E003`、`swift test --package-path experiments/E003`、E003 局部 format／lint、CLI 安全與 diff allowlist；核對圖 receipts／hash／四尺寸。真實 OAuth 只在人工前置與互動安排成立時執行，不由 mock／build 代替。
4. Reviewer 獨立審查 source、資料邊界、分項分類、工具證據與圖的實際畫面，明示 verdict。needs-rework 回對應產出角色；blocked／human-check 停止。
5. Reviewer `approved` 且無重大問題後，Implementer 依 staged diff 用 `$git-commit-convention` 檢查語意邊界並提出 message。使用者本輪已明示 commit by topic → non-force push → 開指向 dev 的 Draft PR → human review，不需重問例行授權；不 merge。
6. 真實 base/head commit 形成後，Reviewer 才建立 repo 外 PR Lens local map 並 validate／render；若有收尾 commit，刷新 final-head coverage 或明示缺口。PR Lens 不代替 code review，也不透過其工具 push／開 PR。Draft PR 交人類審查。

## 驗收與停止

T01：初始 `/user` HTTP 200、有有效 user ID。T02：新 token pair 均非空且各自更換，六欄可解析、期限正、bearer、scope 集合與初始相同，能建立 public bundle。T03：新 `/user` HTTP 200 且 user ID 相同。T04：舊 refresh token 回 `bad_refresh_token`、無新 token；泛用 HTTP／網路錯誤不算。四項皆符合才是 E003 真實成功；有效可判讀違反為失敗；前置或回應不足為無法判定。

最多一次新授權、callback 180 秒、正向 refresh 一次、舊 token 重用一次，無自動重試。正向 refresh request 已送出而 response 遺失時 rotation 未知並停止；舊 token 意外取得新 token 時記失敗且停止使用。secret／token／user ID／原始回應不落盤；僅記遮蔽有限證據。真實授權與遠端 rotation 不可本機回滾，結束時只釋放記憶體，不宣稱 revoke。

HC-LIVE：2026-10-08 已在 feature worktree 完成一次本機隱藏 secret 輸入與人工 browser 授權；runner exit 0、T01–T04 與 overall 均成功，遮蔽證據及限制見 [E003 README](../../experiments/E003/README.md)。這只支持本次 refresh／rotation 測量，不擴張為產品自動刷新或遠端撤銷。HC-REVIEW：Draft PR #48 已建立，仍待人類實際審查。若實測與獨立審查後需回寫持久結論，另行處理 `docs/` 受限變更，不預先修改架構真相。
