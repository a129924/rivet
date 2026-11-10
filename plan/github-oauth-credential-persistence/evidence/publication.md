# 發佈交接

- 執行者：Implementer；日期：2026-10-20。User 已明確授權 topic commit → push → Draft PR → Human review；沒有 merge 授權。
- Branch：`feat/github-oauth-credential-persistence`；base／PR target：`dev`，base `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`。
- Source commit：`e53030883d6de111b52ee64996a7fe01c04109a7`，`feat(github-integration): 新增 DPK OAuth 憑證儲存`。
- Staged 語意檢查只包含本 topic 程式／測試／規劃／文件圖，diff --check 通過；沒有 dev 或他人工作線的實作變更。
- Commit hooks 最初 renderer-check 因新 worktree 缺 biome 而 exit127；依既有 lockfile 執行 bun install --frozen-lockfile，只建立 generated dependencies，沒有修改 lockfile／renderer source。重試後 whitespace、EOF、Swift format、consumer、SwiftLint、renderer check 全部 Passed，未略過 hooks。
- 已 `git push -u origin feat/github-oauth-credential-persistence` 成功。
- 已用 `gh pr create --base dev --head feat/github-oauth-credential-persistence --draft` 建立 [Draft PR #60](https://github.com/a129924/rivet/pull/60)。PR 清楚列出 fake-only 驗證、未驗 live 項目與 Human pending；沒有 merge。
- PR Lens 0.11.0 對上述真 base/source head validate/render exit0；實讀外部 manifest，1 SVG、4 lanes／7 nodes／7 edges、3步walkthrough，保留unchanged neighbours與file refs。只在本地，不上傳圖資。Graphify0.9.73無既存graph採bounded source fallback，不build／refresh／改設定。
- 此後僅補此發佈收據、step與tool-evidence；程式與測試保持獨立Tester／Reviewer核對的SHA。補記為同topic docs commit後push，不改公開契約或重新宣稱測試。
- Human review／視覺接受：pending；真DPK、跨程序、signing／profile／prompts、OAuth／整套登入仍未驗證。獨立Tester／Reviewer approved只適用本topic的受控證據。


## LG84 收尾交付與 PR 更新草案（2026-11-05；未發布）

本段只為本地草案，未stage／commit／push或寫PR。Planner本輪audit所見PR #60仍OPEN Draft、published HEAD為`ec193a26`；`dev`／本地`origin/dev`為`758aca9b`。這些是audit時點資訊，後續Git操作前需再唯讀核對。LG81-Cap-R completed／approved只代表本窗口假完整bundle／指定環境DPK驗收通過，不代S08 Human接受或整個topic完成。

### 擬議 PR title/body

Title：`feat(github-integration): 保存完整 OAuth 憑證並驗證跨程序還原`

Body 草案：

```markdown
GitHub OAuth 完整憑證現在可透過 caller-owned `GitHubOAuthDataProtectionStores` 保存與還原。Adapter 提供 configuration／credential 兩個 items、clientID-bound store、strict 六欄 codec、完整替換及有限錯誤，沿用 provider 的 restore／refresh／persist-stop 契約。

- 原S05/S06已獨立核對fake Security／受控provider與public consumer；不是今日重測。
- 指定簽章環境已用正式adapter與完整假bundle完成保存A、writer退出後freshA、整筆B、freshB、真正同身分重建後freshB；LG81-Cap-R獨立approved。五runtime Human均全程觀察、0提示；其他建置／簽章提示依各段原文，不擴張首sign的permission-only觀察。
- Validation工具有purpose/identity/source/boot/deadline/once與request→report→ACK→operation→final歸屬鏈；NoApp／unsigned準備不當作signed-host證據，舊unknown歷史保留。

驗證限制：本輪live只credential item與指定環境，不是真OAuth、遠端refresh／API／產品登入、configuration item live、系統拒絕、crash／斷電durability或所有環境保證。LC06 cleanup未做；原資產／ownership proof保留。原sequence圖為初始adapter snapshot，技術QA沿用、Human視覺及S08接受pending。

PR仍Draft，與目前dev有五個未整合conflict，包含configuration公開契約差異；本次沒有merge/rebase或機械選邊，不能視為可合併。長期契約見 docs/architecture/github-oauth-credential-persistence.md，受限驗收與獨立結果見 plan/github-oauth-credential-persistence/evidence/live-validation.md 及 live-preparation-review.md。
```

### 待整合的明確範圍（本輪不實作）

Planner audit列出：README.md、Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift、docs/architecture/README.md、docs/architecture/github-oauth-dual-client.md、docs/design-principles.md。本topic configuration為public／typed finite error／空字串拒絕；dev為internal／AuthError／trim後拒絕，尚未決定相容合流。日後另授整合時須保原鎖定契約，核公開surface／consumer及行為差異再審；未證相容即停，不在文件收尾加相容層。不因conflict否定本輪DPK結果，也不把merge禁令當文件收尾blocker。

### Exact-stage 與 message 提案（尚未執行）

LG86成果Reviewer approved後才由LG87按plan LG82 D/P/E/V exact leaf聯集stage實際topic變更；排除兩個個人.swiftpm metadata、任何xcuserdata／private assets／build／憑證。先讀index，不reset未知內容；stage後核path set及diff --cached --check，再依git-commit-convention檢真正staged diff的語意邊界與message，交Human確認。

暫擬一個同topic提交：`test(github-integration): 補齊 DPK 跨程序驗收工具與證據`。這尚非staged審查或Human核准的message；實際內容須包含必要docs／歷史證據與既有validation工具，若邊界不符由LG87重新提出。現在不commit/push/merge/rebase、更新PR、清理任何資料或改圖bytes；Human visual／S08／cleanup／PR整合保持尚缺。
