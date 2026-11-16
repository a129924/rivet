# OAuth／PAT 雙登入契約執行計畫

- Topic：`github-dual-login-contract`
- 狀態：規劃與成果審查已 approved；先前 inventory 暫停及文件回修為歷史。執行／發布／Human review 現行狀態以配對 step 帳本為準。
- 配對：[需求](../../analysis/github-dual-login-contract/requirements.md)、[技術規格](../../analysis/github-dual-login-contract/technical-spec.md)、[帳本](github-dual-login-contract.step.md)。
- 分支：`feat/github-dual-login-contract`；基底 `dev`，已交接 base SHA `2973150b2789d63c10226b57150073ccc793c509`，未來 Draft PR 目標 `dev`。
- 只在既有 feature worktree 工作，不修改 dev checkout；不得因 sandbox 寫入受限而轉寫 dev。

## Goal

實作技術規格中的完整公開型別與行為，讓同一 caller 以受控結果驗證 OAuth／PAT 的共同契約；新增文件、sequence 及本機 change map 供人類 review。

## Non-Goal

不交付真登入、帳號或 session，不組裝 token provider／clients，不新增 target／runtime／bridge／BC；不安裝、升級工具、不發布或 merge。

## In-Scope

請求 VO、PAT typed local validation、Sendable async nonthrow Protocol、success／failure(LoginFailure.authenticationFailed)／cancelled、診斷遮蔽、受控契約測試、長期文件、Archify sequence、local PR Lens bounded diff map、Graphify 的有限導覽或 source fallback。原 AC5 依使用者確認收斂為無 payload success，帳號與 session 延後。

## Out-Of-Scope

真 OAuth browser／callback／exchange、PAT remote validation、UI wiring、credential persistence／restore／refresh／401、account／session／token capability／clients、多帳號、登出、PR 導覽；既有 provider／scope／HTTP client 不變更。

## Written

實作與文件 allowlist：

| 新增路徑 | 允許內容 |
| --- | --- |
| `Sources/BoundedContexts/GitHubIntegration/Contracts/LoginAuthentication.swift` | 技術規格全部公開型別、VO 驗證與診斷 conformances。 |
| `Tests/GitHubIntegrationTests/LoginAuthenticationContractTests.swift` | 測試 helper／受控替身及契約案例，不增加正式 runtime。 |
| `docs/architecture/github-dual-login-contract.md` | 長期契約、限制、UI intent 對應、圖入口與重建／驗收摘要。 |
| `docs/architecture/diagrams/github-dual-login-contract/` | 僅 login-contract-sequence 的 JSON、HTML、私有 spec snapshot、validation／delivery receipts、visual-check JSON sidecars、light/dark screenshots、contact sheet、雜湊與必要相對路徑重建紀錄；不增加其他圖。 |

PR Lens graph/render/manifest 與 bounded diff snapshot／hash 寫入 repository 外、本 topic 專用目錄；不寫 repository 的 .pr-lens。Build／test cache 只作工具產物，不進版控。

規劃產物單獨授權：Plan-Creator 建立／修改同 slug 的 requirements、technical-spec、plan、step 四檔；不得由 Implementer 任意改寫 locked contract。各角色回報證據，由帳本 owner 記錄 step；scope 變更須先回規劃。除這四檔外，不新增必要 planning artifacts。

## Modify

- `README.md`、`docs/architecture/README.md`：只補本契約能力、限制與長期文件入口。不改寫既有 topic 歷史或宣稱正式登入交付。
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`：僅在 `targetContainsOnlyTheLockedSourceFilesAndNoForbiddenImports` 的 `expectedPaths` Set 加入 `"Contracts/LoginAuthentication.swift"` 一條；不改任何其他 expected path、assertion、source enumeration、forbidden import／隔離語義或其他測試。須本次 delta 獨立 approved 後才執行。

## Deleted

空集合。

## ReadOnly

上述 allowlist 以外所有 tracked files 均只讀，包括 Package.swift、除上述 inventory 單條例外以外的既有 Swift／tests、Presentation、OAuth／provider／scope、其他 topic／docs、AGENTS、skill、hooks、tool configuration、.gitignore。若執行時與 allowlist 衝突，停止並交回規劃，不自行擴大。

## TestCase

| ID | 案例／完成條件 |
| --- | --- |
| T01 | PAT 空字串、空白／換行回 typed empty；trim 外圍、保存內部空白、不限制 prefix；非法值不能建立 pat request。 |
| T02 | 一般 import GitHubIntegration（不靠 @testable）能建構公開 VO、以 Sendable fake conform；同一 existential caller 接收 oauth／pat。 |
| T03 | 每種 request 分別取得受控 success、failure(authenticationFailed)、cancelled，結果完全符合公開型別。 |
| T04 | 預先取消不啟動工作、等待期間取消傳遞且等 settled、回傳後取消不改已得結果；以 continuation／barrier 同步，不用 sleep 推測競態。 |
| T05 | PAT 與 request 的 String／debug／dump／Mirror 不出現 sentinel、片段、長度或雜湊，仍可辨識登入方式。 |
| T06 | focused contract tests、既有 GitHubIntegration tests 與 repository 規定相關 format／lint／diff checks 通過；inventory 只新增本契約路徑，其他隔離 checks 不變。重跑原失敗 source inventory case 與 GitHubIntegration regression，記錄命令、來源版本與 exit 結果，不憑空推算通過數。 |
| T07 | 文件、sequence 與 code 一致；完整標示受控結果、success 無payload、無真登入／session／client 能力。 |
| T08 | Archify showcase 9 checks／0 errors／0 warnings、deliver exit0 與 spec／HTML hashes，四尺寸 containment 並實際審視截圖。 |
| T09 | PR Lens bounded actual diff map 正確或記錄直接 diff review fallback；Graphify 不建 graph，source 關係均回查。 |

## 工具與圖交付

### Archify

使用 sequence schema/common/example；依 skill artifact-first，不先讀 renderer internals。作者內容繁中，省略 meta.locale 並揭露固定 Viewer UI 與 html lang fallback English；static、showcase，不新增 architecture boundary 圖。描繪本地 PAT 拒絕、共同受控入口與取消，不暗示真 OAuth。

每次 candidate edit 後 validate；最終須 9 artifact checks、0 composition errors、0 warnings。deliver 為最終驗收，freeze bytes，記錄 spec／artifact SHA-256 與 byte counts。之後 visual-check 使用 repo-root，相對路徑 receipts；1440×900、1600×1000、1920×1080、2048×1320 均滿足 scrollWidth<=innerWidth、scrollHeight<=innerHeight。實際審視最小／最大 light/dark screenshots 及 contact sheet，另記視覺結論；自動 visualReview=pending 不等於已審視。不得以 hidden overflow／clip／縮字假造通過。工具失敗、skip 或未實際審視時列文件交付待補，不放行該交付；依 skill bounded repair 停止規則回報。不發布 artifact.cafe／外部服務。

### PR Lens

使用已配置 pinned CLI 0.11.0 的 local validate/render，不 install／npx／analyze／auth／API／upload／publish／server。依真實 bounded diff（含 --find-renames 的實際 base...head）及 base/head SHA 組 map；working tree 若未提交，另保存 bounded staged/unstaged diff、untracked 新檔快照、manifest／hash，不用相同 commit IDs 假裝變更不存在。包含必要 unchanged neighbors 與 file refs，不將 map 當 correctness review。

graph、render、manifest 與 diff provenance 放 repository 外的 per-topic 目錄。當前交接為無 .github/pr-lens.yml，使用 --no-config；若執行時已存在則唯讀採用，不建立或修改配置。工具不可用、validation/render 失敗或 map 增加誤導時，記錄實際錯誤並改直接 diff review，不自動安裝或宣稱 map 完成。

### Graphify

當前無可用 graph，採 targeted rg／source reads，不 extract／build graph。若後續發現既存 graph，核對來源版本後才做 bounded query/path/explain，重要關係回查原碼。每次 CLI invocation（含 help/version）均設 GRAPHIFY_NO_AUTO_REFRESH=1。使用 pinned graphifyy 0.9.73；工具缺失／不相容就記錄 error 與 fallback，不安裝／升級、不改 skills／hooks／config／stamp，不 semantic extraction／provider／fetch／upload。

三工具只查到既定配置／檔案存在不等於 runtime／版本通過；執行證據須實際取得。無新 runtime／測試證據時不得先宣稱通過。

## 執行順序、授權與收斂

1. Plan-Creator 建立四 artifacts，交獨立 Plan-Reviewer；只有明示 approved 才進實作。
2. Implementer 依契約完成 Swift／tests／docs／sequence 與 bounded 工具產物，自驗後交 Tester。
3. Tester 獨立執行交付範圍驗證，Reviewer 獨立審查實際 diff、證據與 scope；required fix 交對應產出角色。
4. 使用者本輪已明示直接 topic commit／push／Draft PR 授權；交付角色仍先依 git-commit-convention 檢查 staged semantic boundary 與 message，再依本次明確授權操作。此文件不等同命令已執行或人類已完成最終 review。Draft PR 目標 dev，不 merge／release。
5. 最終交 Human review，保留工具 fallback／未完成項與來源 SHA；不以 checkbox、帳本狀態或時間到取代審查 verdict。

2026-11-13 18:20 Asia/Taipei 開始收斂，不新增探索或擴大 scope。既定驗證、證據與安全交付可繼續；如尚有 gate 未通過則如實保留 pending／blocked，不為趕時限放行。sandbox 若不准 feature worktree 寫入，走 escalation，不改 dev 作替代。
