# OAuth／PAT 雙登入契約步驟帳本

- Topic：`github-dual-login-contract`
- Current phase：S05 獨立成果審查 approved；S06 發布準備進行中。
- Current step：S06 / in-progress。
- Branch：`feat/github-dual-login-contract`；base SHA：`2973150b2789d63c10226b57150073ccc793c509`。
- 配對：[需求](../../analysis/github-dual-login-contract/requirements.md)、[技術規格](../../analysis/github-dual-login-contract/technical-spec.md)、[計畫](github-dual-login-contract.plan.md)。
- Upstream：Planner approved 僅准起草；Human 已接受對話計畫並明示本次受限執行／topic commit／push／Draft PR 授權；原版獨立 Plan-Reviewer 明示 approved、無 required fix；inventory 維護 delta 另經獨立 Plan-Reviewer approved，無 required fix，之後才恢復實作。

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據 | Verdict |
| --- | --- | --- | --- | --- | --- |
| S01 | completed | Plan-Creator | 同 slug 四 artifacts 存在，完整記錄鎖定範圍／介面／九欄位／工具／驗收。 | 本次寫入四檔，寫前均 missing；寫後讀回存在與欄位。這是產出證據，不是品質 approval。 | — |
| S02 | completed | Plan-Reviewer | 獨立再審四檔的 inventory 單條 Modify delta；確認不改隔離語義或公開契約後明示 verdict。 | 歷史：2026-11-13 原版 approved，無 required fix，T04需含已就緒結果的取消優先。delta 已獨立 approved，無 required findings；只允許 inventory 新增一條來源。 | approved |
| S03 | completed | Implementer | 待 S02 delta approved，再新增 inventory 一條路徑並完成原範圍；其餘 source/test format/lint 與 Archify 照原計畫驗證。 | 歷史 red：新公開型別不存在；focused 8 tests green。原 regression 僅 inventory 失敗，獨立 delta approved 後只新增一項；重跑 229 tests／25 suites passed、consumer 15 tests passed，format/root lint/diff check exit0。Archify showcase9/9、deliver0、四尺寸containment及4張截圖自驗passed；PR Lens local validate/render0，工作樹provenance另存。這是交接證據，非獨立成果 approval。 | — |
| S04 | completed | Tester | 接獲 S03 明示交接，獨立執行 T01–T09，記錄命令、exit、來源 SHA/hash 及限制。 | 獨立 focused8、GitHubIntegration229／25 suites、consumer15／3 suites、format、lint140files零違規、diffcheck皆exit0；Archify validate9/9零錯警、11檔hash核對與四張截圖實看；PR Lens validate0。下列 Tester verification 記錄限制與舊狀態文字。此為測試交接，非成果審查 approval。 | — |
| S05 | completed | Reviewer | 依 S04 證據審查 bounded diff／契約／scope／圖與診斷；明示 verdict。 | 歷史：原 Reviewer needs-rework 僅三份 planning 文件開頭狀態 P2，無 required code fix；Plan-Creator 已限定回修，原 Reviewer 最終明示 approved，無剩餘 required fix。 | approved |
| S06 | in-progress | Implementer | 前置 gate satisfied，依明示 topic 授權與 staged semantic/message 檢查，commit／push／建立 dev 目標 Draft PR；不 merge。 | 待實際 commit SHA、push 結果、Draft PR；不得把授權寫成已執行。 | — |
| S07 | pending | Human | 審閱 Draft PR、契約限制、圖視覺及未完成事項。 | 待 Human 明示 review 結果。 | — |

## Blockers

- 既有 source inventory 缺新檔已經 bounded planning delta 獨立 approved 後回修；未改其餘隔離規則。
- S02 原版及 delta approval 歷史保留；S03／S04 completed。S05 曾 needs-rework（文件 P2，無 required code fix），限定回修後原 Reviewer 明示 approved；不把此結果當作 S07 Human review。
- PR Lens CLI 0.11.0 已實際驗證；map 尚綁 working-tree snapshot，S06 commit 後須重綁實際 head 並 validate/render。Graphify 無 graph，未呼 CLI，採 source-search fallback且未建圖。
- 任何 required fix、不可用工具、檔案 allowlist 衝突與 sandbox 阻擋由實際 owner 回報；不得擅改 dev／安裝工具繞過。

## Human Check

- 已確認：GitHubIntegration 落點、不新增 target、oauth 無payload、success 無payload、非拋錯 Outcome、帳號／session 延後；其餘明列計畫亦已由使用者接受。
- 已授權：本 topic 實作及直接 topic commit／push／Draft PR，最後交人類 review。未授權 merge、release、發布圖／工具安裝。
- 待確認：S07 最終 Human review；不把先前計畫接受當作成果 review。
- 2026-11-13 18:20 Asia/Taipei 開始收斂，時間條件不豁免 gates；未完成狀態如實交付。

## Implementer verification

- Red：`swift test --filter LoginAuthenticationContractTests` exit1，診斷新型別不存在（非依賴失敗）。Green 同命令 exit0，8 tests。
- Regression：`swift test --filter GitHubIntegrationTests` exit0，229 tests／25 suites。
- Public consumer：`scripts/check-github-integration-consumer.sh` exit0，15 tests／3 suites。
- `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`（140 files，0 violations）、`git diff --check` 均 exit0。
- 本機 raw logs 位於 topic 專用暫存區與 login red/green/regression/consumer/format/lint logs；不入版控，也不以原始 log 暴露本機絕對路徑。
- Archify receipts／hashes／視覺自驗與 contact sheet 位於圖目錄，作者內容繁中，固定 Viewer UI／HTML lang English fallback。初版閱讀寬修正及第二輪垂直containment修正後完成；trusted HTML 未被手工修改。
- PR Lens 的 graph／manifest／SVG／working-tree.diff／untracked snapshots／hash provenance 均為 repository 外本 topic 本機產物；不 upload，不開 server；發布階段仍須綁定最終 commit。
- Graphify：無既有 graph，使用 targeted source reads；未 extract/build、安裝或改配置。

## Tester verification

- 來源 HEAD：`2973150b2789d63c10226b57150073ccc793c509` 加本 topic 未提交工作樹；新 source SHA-256 `524e1dbfe4f33c16fd4dfc79d4b07ced2ddfc37032fd017423bc6ba1428b4341`、新 tests `0ddc70c763010393cfffa2c6f47ca6c9a3419d771bb31f9acd2ead5eb5c7c9ab`，與 PR Lens 工作樹來源快照一致。
- 親跑 `swift test --filter LoginAuthenticationContractTests` exit0：8 tests／1 suite（含4筆空值參數、兩種request各結果、三類診斷及預先／等待／ready success-failure／return後取消）。
- 親跑 `swift test --filter GitHubIntegrationTests` exit0：229 tests／25 suites；source inventory diff 僅加入新契約路徑，不改其他隔離計算／assertion。
- 親跑 `scripts/check-github-integration-consumer.sh` exit0：15 tests／3 suites；一般 import 的新 public 契約另由上述新測試檔編譯驗證，不將既有 consumer15 冒稱含新契約。
- 親跑 `scripts/check-swift-format.sh`、`scripts/check-swiftlint.sh`（140 files、0 violations）、`git diff --check` 均 exit0。
- 獨立 Archify showcase validate exit0：9/9、0 errors、0 warnings；核對 delivery spec／HTML hashes、四尺寸 containment receipt，以及 hashes.json 的11檔bytes／SHA，全部相符。未重deliver、未改 trusted spec／HTML／receipts；實際審視最小及最大尺寸四張 light/dark 截圖，標籤、箭線與結論卡無遮擋，完整可讀。自動 visualReview=pending 保留，不冒稱 Human 視覺接受。
- PR Lens 獨立 validate exit0；7筆 source refs 存在、source/test 快照hash相符，manifest 為1張SVG。當前map是未提交工作樹，不是已提交PR；S06仍須重綁最終head並validate/render。
- Graphify：repo檔名搜尋無既存 graph，依計畫 source-search fallback；未執行CLI或build。
- 交 Reviewer 注意：requirements／technical-spec／plan 開頭仍保留 inventory delta「待再審／實作暫停」舊狀態，與已正確更新的本帳本不一致；Tester未修改該三檔。功能契約內容、長期說明與圖一致。
- 本機獨立驗證 raw logs 置於 topic 專用暫存檔，不入版控；無真OAuth／PAT、session或網路登入驗證。

## Reviewer verification

- 原 Reviewer 已確認三份 planning 文件的限定狀態回修，最終 verdict approved、無剩餘 required fix；首次 needs-rework 與回修歷史保留。
- 依此明示 verdict 進入 S06，只準備 stage／semantic boundary／message 與遠端狀態檢查；commit、push 與 Draft PR 結果待實際執行記錄。

## Last updated

- 2026-11-13 17:59:43  Asia/Taipei
- Updated by：Implementer（S06 發布準備）。
- 更新內容：記錄原 Reviewer 最終 approved、保留 needs-rework 歷史，S06 標為 in-progress；未預填 commit／push／PR 成功。
