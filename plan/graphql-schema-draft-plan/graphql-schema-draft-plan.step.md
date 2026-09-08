# PR Reader GitHub GraphQL SDL Schema Snapshot：Step Ledger

## Current Phase

Reviewer — RV-01 pending。IM-01、HG-01、IM-02 與 TE-01 已依交接完成；RV-01 現已允許由獨立 Reviewer 開始。此 ledger 的 status、evidence 與 current phase 只記錄已交接的事實，不構成 approval；HC-02 仍保持 pending，browser visual check 仍是 human-check limitation，非 PASS。

## Ledger

| ID | Owner role | Status | Work | Completion condition | Evidence |
| --- | --- | --- | --- | --- | --- |
| PL-01 | Plan-Creator | completed | 建立同 slug 的 requirements、technical spec、plan 與 step artifacts。 | 四份 artifacts 一致鎖定 schema-only mission、write boundary、human token gate、retirement／architecture writeback、exclusions與驗證。 | 本 topic 四份正式 artifact paths；未建立 schema、改 docs/map/code，未跑 Rover、commit、push 或 PR。 |
| PR-01 | Plan-Reviewer | completed | 獨立審查 planning artifacts 的 scope、path、locked decisions、human gate 與 workflow completeness。 | 給出可路由至 HG-01 與 IM-01 的明示 verdict；此 ledger 不以 status 或 artifact existence 自行產生 verdict。 | Upstream Plan-Reviewer handoff；本 ledger 只記錄其既有 routing，不宣告或推定 approval。 |
| IM-01 | Implementer | completed | 獨立於 HG-01，完成 GitHub Integration retirement 與授權 docs/map architecture writeback。 | 僅修改／刪除 locked docs/map paths；表達 BC-local Infra、future non-BC `GitHubTransport` 與 generic `RivetHTTPClient`，且無 schema、operation、codegen、runtime、REST或 transport drift。 | Implementer／Tester handoff：feature worktree only；allowed docs/retirements/map 更新。architecture-canvas validate 為 `5 bands/20 boxes/15 edges/0 errors/0 warnings`；canonical flags temporary rebuild 與 tracked `index.html` byte-for-byte 一致；`git diff --check` pass；active docs/map 無 central GitHub Integration 或 BC-to-BC dependency，且無 `Schema.graphqls`、PRReader REST directory、Apollo/codegen/operation/runtime drift。Playwright local open→snapshot→screenshot 等待 30s 無 output/screenshot，visual check 為 `human-check` limitation，非 PASS。 |
| HG-01 | Human | completed | 在受控外部環境以 locked Rover `v0.41.0` behavior 取得 non-secret GitHub SDL。 | 固定 endpoint、四個 headers、default SDL stdout、mode `0600` temporary/staging files、trap cleanup與same-parent `mv` 均遵守；token 未落盤、輸出、記錄或寫入 config。完成後才可執行 IM-02。 | Human confirmation：HG-01 已在受控外部環境完成。不得以 agent log、token value、repository identity、headers 或其他秘密作 evidence。 |
| IM-02 | Implementer | completed | 僅在 HG-01 completed 後，於固定 source path materialize 已取得的 non-secret schema。 | 唯一新增 source asset 是 PR Reader GraphQL `Schema.graphqls`；有 exact three-line provenance、未轉換 SDL及無 secret。不得重新執行 Rover或接觸 token。 | Implementer handoff：唯一新增 `Schema.graphqls`；schema 為 non-secret SDL，未新增 REST、operation、Apollo、codegen、runtime、transport 或 temporary artifact。 |
| TE-01 | Tester | completed | 僅在 HG-01 與 IM-02 都 completed 後，獨立執行 schema presence、secret hygiene、map validation/build、temporary visual check 與 path/diff verification。 | 技術規格列出的 static verification contract 通過，且沒有 operation/codegen/runtime/REST/transport drift；browser visual check 維持 human-check limitation，非 PASS。 | Static PASS：`Schema.graphqls` nonempty、1,398,223 bytes；provenance 為 endpoint、RFC3339 `2026-09-07T07:06:47Z`、API version `2022-11-28`；含 review fields；allowlist 無 REST／operation／Apollo／codegen／temporary／token drift；repository-managed schema 的 file mode 未檢查，因 Git 不保留 `0600`；`git diff --check` pass。Map 為 `6 planes/5 bands/20 boxes/15 edges/0 errors/0 warnings`，canonical byte-identical。Relay issue URL 是 upstream SDL，允許存在。 |
| RV-01 | Reviewer | pending | 僅在 TE-01 completed 後，獨立審查 implementation、verification evidence 與 topic scope。 | 明示 verdict 為 `approved`、`needs-rework`、`blocked` 或 `human-check`；不以 tracker status 代替 verdict。 | 現已允許開始；尚無 Reviewer verdict，HG-01、IM-02 與 TE-01 的 completion 不構成 approval。 |
| HC-02 | Human | pending | 僅在 RV-01 明示 `approved` 後進行 final human review。 | Human 明確確認是否接受 delivery；不得由 agent 將 RV-01、step status或 evidence 視為 human acceptance。 | Human decision；尚未開始。 |

## Blockers

- RV-01 是目前 pending 的獨立 review gate。HC-02 保持 pending，僅在 RV-01 明示 verdict 允許時進入；任何 status/evidence 不構成 approval。
- HG-01 已由 human gate 完成；agent 仍不可要求、接收或處理 GitHub token。不得使用 public schema、手寫 SDL、替代 CLI 或 persisted credential。
- Playwright visual capture 在 local open→snapshot→screenshot 等待 30s 無 output/screenshot，是 IM-01 existing evidence 中的 `human-check` limitation；不得列為 visual PASS 或作為 TE-01 的 PASS evidence。

## Human Check

- HG-01 的 schema download、token exposure prevention 與 Rover controlled-terminal safety 已依 human confirmation 完成；HC-02 是仍 pending 的 final delivery human review。
- Reviewer 若判定 `blocked`、`human-check` 或 scope／contract／path drift，停止自動前進並交還 human。
- HC-02 後的 commit、push、draft PR、merge、release 或後續 integration 仍需依其獨立 workflow 與 human boundary 處理；本 ledger 不授權跨越。

## Last Updated

2026-09-07（Plan-Creator 依交接的 human／Implementer／Tester factual evidence 更新 HG-01、IM-02、TE-01，將 phase 路由至 RV-01 pending；未記錄 Reviewer verdict、human acceptance、commit、push 或 PR completion）
