# Keychain 本機 OAuth 憑證保存可行性：狀態帳本

- Topic：`github-oauth-keychain-local-feasibility`
- 目前 phase：自簽預檢結果交付
- Current step：S06
- Current step status：in-progress
- 上游正式 verdict：approved（本次限定自簽授權修訂經獨立 Plan-Reviewer 複審；不代表實驗成功）
- [需求](../../analysis/github-oauth-keychain-local-feasibility/requirements.md)／[規格](../../analysis/github-oauth-keychain-local-feasibility/technical-spec.md)／[契約](github-oauth-keychain-local-feasibility.plan.md)

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| S01 | completed | Plan-Creator | 已核准對話計畫映射為同 slug 四份正式 artifacts，保留九欄、T01–T06、工具與時間／清理契約。 | 本 topic requirements、technical-spec、plan、step 四檔已建立；沒有 host／測量結果或正式 approval 聲明。 |
| S02 | completed | Plan-Reviewer | 獨立審查四檔一致性、scope 與執行條件，明示正式 verdict。 | 先前 needs-rework 的整輪 cleanup 歧義已由 Plan-Creator 修正；同一獨立 Plan-Reviewer 複審明示 approved（上游交測訊息）；此為先前版本。使用者後續授權實驗專用自簽憑證補 T03，本次四檔修訂經獨立審查 needs-rework，要求 writer=第一次 build／reader=第二次 build；已回修，獨立 Plan-Reviewer 本次複審正式 approved；僅核准限定計畫，不代表 T03 成功。 |
| S03 | completed | Implementer | 正式 approved 後，preflight、重查實驗編號，建立受限最小 host／八段紀錄及必要素材，固定候選與判準後交測。 | E005 host、runner、build script 與初始八段 README 已建立；Swift 6 build／ad-hoc signature verify 與 Python syntax 檢查通過，未作 Keychain 成功宣稱。 |
| S04 | completed | Tester | 獨立執行 T01–T06、fresh-process、真重建、提示觀察及整輪實驗所有退出 cleanup（子程序正常結束保留 item）；保存四狀態／任務完成判斷與工具交付狀態。 | E005 evidence/normal-run.json、early-stop-run.json、environment.json 與八段 README。T02／T04 六欄成功；T03 真重建 requirement 不同，無 acceptance read；UX unobserved；真 absent／malformed 成功，denial 只 synthetic。正常兩項與提前停止一項清理確認不存在。實驗無法判定，Keychain 驗證任務完成；Reviewer 指出受控停止 cleanup 缺口後，Implementer bounded fix，Tester 新增真 controlled-stop-run 與 synthetic SIGINT／SIGTERM 兩測試（delete 重複同訊號），均成功清理／保存 receipt。舊正常與 early-stop 證據保留；不可捕捉停止限制明列。Tester 複驗 verdict approved（交獨立 Reviewer，非採用核准）。 |
| S05 | completed | Reviewer | 獨立檢視實際證據、分類、限制、cleanup 與工具產物，明示成果 verdict。 | 獨立 Reviewer 明示 approved；核對 SIGINT／SIGTERM 受控 cleanup 回修及 synthetic／真 controlled-stop 證據、receipt 相對路徑、T03／UX 限制、四尺寸與實際圖檢視。非採用核准；以上為原成果。本次兩輪自簽 preflight 與紀錄也經獨立 Reviewer 複審 approved。 |
| S06 | completed | Implementer | 依獨立審查結果，只回寫指定 docs 條件結論；按 topic commit／push／開 Draft PR 供人類 review。 | 已依 staged diff 確認單一 topic 邊界；核心 commit e6438ad 已 push，Draft PR #58（base dev、isDraft true）已查證。所有 pre-commit hooks 通過；PR Lens 真實核心 diff 本機 validate／render 完成。此交付紀錄以同 topic docs commit 保存，最終 head 核對在 repository 外。 |
| S07 | pending | Human | 人類檢視 Draft PR，決定是否接受本輪結果；正式採用另行規劃。 | Draft PR #58 已建立：https://github.com/a129924/rivet/pull/58；等待 Human review，未核准採用／merge／release。 |

Status 記錄不等同 approval。Plan-Creator 不審自己的四檔；Tester／Reviewer 維持獨立。Human 是人類邊界 owner，不是新增 agent role。

## Locked Decisions

- 完全免費；不依賴既有付費簽章／profile。首次正常流程最多一次提示，正常後續與同身分真重建零提示。
- DPK 優先；免費前提不能證實時只可首次寫入前固定 legacy，不在失敗後 fallback。所選前提不足不稱假設失敗或必須付費。
- UUID generic-password 單 Data，六欄完整私有 DTO、Date expiry；production API／provider ownership／既定架構不改。
- 正常 T02–T04 完成後獨立負向；真 denial 缺口可保留，synthetic 明標；正常全部提示計入 UX。
- 任一寫入嘗試後，整輪 experiment 正常完成／失敗／停止／例外退出才精確清理主要及負向項目；writer／reader 正常結束保留 item 供 T02–T04；殘留記 UUID／原因，任務完成否。
- 90 分鐘總額、75 分鐘停止測量／圖作業、最後十五分鐘優先清理紀錄；工具不延長預算。
- Branch `chore/github-oauth-keychain-local-feasibility`；只在已建 feature worktree 寫入，不改 dev。
- 同 topic commit／push／Draft PR 已授權；不新增等待 commit 批准，不授權 merge／release／發布或正式採用。

## Blockers

- 前版本正式 Plan-Reviewer 已複審 approved，planning cleanup blocker 已解除；本次自簽憑證限定例外四檔修訂也經獨立 Plan-Reviewer approved，不沿用前版本 approval。
- DPK 免費 host／profile 仍未確認。legacy ad-hoc 真重建 designated requirement 改變；後續 Human 已觀察原 binary 單輪 0 提示，但無 T03 acceptance read 或重建後 UX 證據。主要採用決策仍受阻，不是已判定機制失敗。
- 若無自然真 denial，保留未驗證缺口；不自行製造安全設定改動。
- 正常 run 的主要／負向項目、獨立 early-stop 與 controlled-stop 項目均已精確清理並確認不存在；無已知殘留。

## Human Check

- 已收到使用者本 topic 實現、直接 commit、push、Draft PR 供人類 review 的授權，無需再次等待 commit 批准。
- 需新增帳號／超出限定自簽憑證例外的憑證操作／付費／安全設定、免費來源不明或時間到達：停止依賴操作，清理並交還缺口。若需要改 trust／預設 Keychain／全域 search-list 即停。
- Draft PR #58 已建立並驗證為 Draft，供 human review；主假設仍無法判定，未授權 merge／release／正式採用。

## Time Budget

- 起算：2026-10-15 02:41:28 UTC。
- 停止新增測量／圖作業：2026-10-15 03:56:28 UTC。
- 清理／紀錄優先區間：03:56:28–04:11:28 UTC。
- 總上限：2026-10-15 04:11:28 UTC；不自動延長。
- 實驗四狀態：無法判定；本輪 Keychain 驗證任務完成，原因／缺口／決策限制與清理已完整記錄。受限成果已經獨立 Reviewer approved；核心 commit／push／Draft PR 已完成，Human review pending。

## 最後更新

- 2026-10-15 02:42 UTC：Plan-Creator 依已核准對話計畫建立四檔；S01 completed、S02 pending，正式 verdict null。未寫 host、未測試／操作 Keychain／產圖、未 commit。

- 2026-10-15 02:46:12 UTC：收到獨立 Plan-Reviewer needs-rework，僅回修整輪 cleanup 歧義：writer／reader 正常結束保留 item，整輪退出才清理；S02 needs-rework，待獨立複審。未新增 scope、未寫 host 或執行測量。

- 2026-10-15：獨立 Plan-Reviewer 複審明示正式 `approved`，整輪退出清理歧義已修正；Implementer 開始 E005 host，尚無 Keychain 測量結果。

- 2026-10-15 02:53 UTC：Implementer 完成 E005 host，明示交獨立 Tester 執行正常與提前停止 cleanup；本輪選 legacy，DPK 免費 profile 未證。Archify showcase 9/9、0 errors／warnings，已 deliver，visual-check 進行中。

- 2026-10-15 02:55 UTC：獨立 Tester 執行 normal（02:53:53–02:54:00）及 UUID 隔離 early-stop（02:54:07–02:54:10）run；兩者 cleanup 完整。T02／T04／真 absent／malformed 成功；T03 requirement 不同、UX 無觀察，整體無法判定；synthetic 不當真 denial。S04 completed，Tester verdict approved，S05 pending；不核准採用。

- 2026-10-15 02:58 UTC：依獨立 Reviewer cleanup 缺口，Implementer 修復 SIGINT／SIGTERM 受控停止與 finally 重複訊號保護；Tester synthetic 控制流程兩測試通過，新 UUID 真 controlled-stop-run（02:57:52–02:57:55）清理／absence confirmed 成功。normal／early-stop 舊 receipts 未覆寫；SIGKILL／crash／host failure 不保證 cleanup，限制已明列。S04 複驗 approved，S05 等待獨立 Reviewer 複審。

- 2026-10-15T02:59:52+00:00：獨立 Reviewer 明示成果 approved，兩項 required fixes 已核對。Implementer 僅回寫指定 docs 與本 topic 實證限制；S05 completed、S06 in-progress，尚未 commit／push／開 Draft PR。

- 2026-10-15T03:05:29+00:00：S06 completed，核心 commit e6438ad、push 與 Draft PR #58 已實際查證；所有 hooks 通過，Graphify fallback、Archify 完成交付、PR Lens 核心 diff 本機 validate／render。S07 pending，停於 Human review；交付帳本另以同 topic docs commit 保存，最終 head／remote 一致性核對不新增實驗或採用。

- 2026-10-15T03:18:20+00:00：使用者要求並確認沿原範圍親自觀察 Keychain；獨立 Tester 新 UUID 單輪 03:16:56–03:17:01 UTC，13 操作 exit0、兩項清理確認不存在。Human 明確全程觀察 0 提示，另存 human-observation.json 綁定新 machine receipt，舊收據與 machine null 保留。此補測仍無 T03 acceptance read，主假設無法判定；等待獨立 Reviewer 核對新觀察範圍，S07 人類 review 未宣稱完成。

- 2026-10-15T03:19:39+00:00：獨立 Reviewer 核對後續 machine／Human 觀察與 receipt SHA-256、13 操作及兩項清理，明示 approved，核可指定 docs／analysis 僅原 binary 實際操作 0 提示的條件化回寫。整體仍無法判定；S07 人類 review pending，不核准採用／merge。


## T03 自簽身分補測授權與待辦

- 使用者明確授權唯一限定例外：新增一張實驗專用自簽 Code Signing cert／private key，建立／匯入 repository 外獨立實驗 Keychain，補 E005 同一 legacy／假六欄的 T03；不得改既有 ACL、系統信任、預設 Keychain、全域 search-list、付費或新增帳號。
- 先完成兩次真正重建與 DR 預檢，保留 first／second 並保存核對不同 hash、designated requirement 相等。再於固定 host 路徑還原 first 作 writer 寫新 UUID OAuth item，換 second 作 fresh reader；保存核對實際兩端 hash，禁止兩端都用 second。前提不足即停，不能稱 T03 已完成；秘密不進 repository／log／證據。
- 整輪退出精確清理本次 OAuth item、專用憑證 Keychain 及秘密／匯入素材，分別確認不存在；殘留記非秘密 UUID／原因、任務完成否。
- 本次 S02 completed：writer=first／reader=second 修訂經獨立 Plan-Reviewer 複審 approved。兩輪 preflight 已執行且清理完整，T03 acceptance 未執行；本次成果 S05 獨立複審 approved，先前 S03–S06 完成證據仍保留，S07 人類 review pending。
- 本次兩輪自簽 preflight 已執行，未滿足穩定簽章前提，因此 T03 acceptance 未執行；主要假設仍無法判定。歷史資料及原審查結論不覆寫，維持既有 Implementer／Tester／Reviewer 職責，不新增 gate。
- 原 03:56:28 UTC 停新測量／04:11:28 UTC 總上限不變，不自動延長。
- 2026-10-15 03:29:41 UTC：Plan-Creator 僅落盤此窄範圍授權與 cleanup／DR 前提；未建立憑證／Keychain、未實作／測試、未 commit。交獨立 Plan-Reviewer。

- 2026-10-15 03:30:48 UTC：依獨立 Plan-Reviewer needs-rework 唯一 required fix，四檔明訂兩次 build／DR 預檢後保留 first／second，固定路徑 first 寫／second 讀，保存核對不同 hash。S02 needs-rework，已回修待獨立複審；未實作／測試／commit。

- 2026-10-15 03:32 UTC：獨立 Plan-Reviewer 複審正式 `approved`，first writer／second reader required fix 已滿足。Implementer 建立獨立 self-signed runner；Tester 先執行無 OAuth 寫入的兩版簽章 preflight，Reviewer 檢視 bounded 實作；尚不宣稱 T03 或主假設成功。

- 2026-10-15 03:33 UTC：Tester PKCS12 transport preflight 停於匯入 exit1，無 OAuth 寫入，專用 Keychain／秘密精確清理及全域設定一致已核對。此不證明信任錯誤；保留舊 receipt，僅增加一次 PEM transport 相容性檢查，不變 backend／政策／判準。

- 2026-10-15 03:35 UTC：獨立 Tester 兩輪無 OAuth 寫入的自簽 preflight 已結束：PKCS12 import exit1；PEM import cert/private key exit0 後 signFirst exit1，沒有 DR 比較或 T03 acceptance。兩輪 create/delete0，專用 Keychain／秘密 scratch 已刪，default/search-list 全相等。未調整安全政策、未增加其他變體。README／analysis 如實補錄 unknown、機器前提任務未達與紀錄完成語意；等待獨立 Reviewer，未核准採用。

- 2026-10-15 03:36:29 UTC：獨立 Tester／Reviewer 正式 `approved`，source snapshot、兩份 receipt、零 OAuth 寫入、cleanup 與 unknown 分類核對通過，無 required fix。僅回寫指定 docs 條件結論；S06 本次交付 in-progress，原成果與 Human 0 提示紀錄保留。未核准採用／merge。
