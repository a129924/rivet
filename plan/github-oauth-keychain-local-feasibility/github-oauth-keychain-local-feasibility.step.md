# Keychain 本機 OAuth 憑證保存可行性：狀態帳本

- Topic：`github-oauth-keychain-local-feasibility`
- 目前 phase：Human review／search-list 待決策
- Current step：S07
- Current step status：pending
- 上游正式 verdict：approved（最新時窗及 metadata 正規化計畫經獨立審查；非 T03 成功）
- [需求](../../analysis/github-oauth-keychain-local-feasibility/requirements.md)／[規格](../../analysis/github-oauth-keychain-local-feasibility/technical-spec.md)／[契約](github-oauth-keychain-local-feasibility.plan.md)

## Steps

| ID | Status | Owner role | 完成條件 | 驗證證據 |
| --- | --- | --- | --- | --- |
| S01 | completed | Plan-Creator | 已核准對話計畫映射為同 slug 四份正式 artifacts，保留九欄、T01–T06、工具與時間／清理契約。 | 本 topic requirements、technical-spec、plan、step 四檔已建立；沒有 host／測量結果或正式 approval 聲明。 |
| S02 | completed | Plan-Reviewer | 獨立審查四檔一致性、scope 與執行條件，明示正式 verdict。 | 原 cleanup、first／second 與 trust ownership 回修均保留歷史；最新 Human-start 時窗與 CodeSigning metadata 正規化修訂已分別經獨立 Plan-Reviewer 正式 approved，不代替實測成功。 |
| S03 | completed | Implementer | 正式 approved 後建立受限 host、trust helper、runner 與必要紀錄，按 scope 交測。 | 原 E005 成果保留；本次限定 trust helper、metadata checker 與同 cert ready gate／SHA1 selector 已實作並經獨立純檢查及 code review。四輪真試驗已停止，未取得可簽署 host，不把準備或測量完成當成 T03 成功。 |
| S04 | completed | Tester | 獨立執行 T01–T06、fresh-process、真重建、提示觀察及整輪實驗所有退出 cleanup（子程序正常結束保留 item）；保存四狀態／任務完成判斷與工具交付狀態。 | E005 evidence/normal-run.json、early-stop-run.json、environment.json 與八段 README。T02／T04 六欄成功；T03 真重建 requirement 不同，無 acceptance read；UX unobserved；真 absent／malformed 成功，denial 只 synthetic。正常兩項與提前停止一項清理確認不存在。實驗無法判定，Keychain 驗證任務完成；Reviewer 指出受控停止 cleanup 缺口後，Implementer bounded fix，Tester 新增真 controlled-stop-run 與 synthetic SIGINT／SIGTERM 兩測試（delete 重複同訊號），均成功清理／保存 receipt。舊正常與 early-stop 證據保留；不可捕捉停止限制明列。Tester 複驗 verdict approved（交獨立 Reviewer，非採用核准）。  本次四輪限定 trust 測量、全部 source snapshots／receipts／cleanup 亦經獨立 Tester closure approved；真 T03 未執行、machine validationTaskComplete=false，記錄工作完成但主假設仍無法判定。 |
| S05 | completed | Reviewer | 獨立檢視實際證據、分類、限制、cleanup 與工具產物，明示成果 verdict。 | 獨立 Reviewer 明示 approved；核對 SIGINT／SIGTERM 受控 cleanup 回修及 synthetic／真 controlled-stop 證據、receipt 相對路徑、T03／UX 限制、四尺寸與實際圖檢視。非採用核准；以上為原成果。本次兩輪自簽 preflight 與紀錄也經獨立 Reviewer 複審 approved。  以上 approvals 為歷史成果；最新四輪結果也經本次獨立 Reviewer closure approved。 |
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
- 需新增帳號／超出限定自簽憑證例外的憑證操作／付費／安全設定、免費來源不明或時間到達：停止依賴操作，清理並交還缺口。除末節本輪新 cert 的 user-domain codeSign trust 唯一例外外，任何 trust／預設 Keychain／全域 search-list 改動即停；禁止 admin／SSL／broad trust。
- Draft PR #58 已建立並驗證為 Draft，供 human review；主假設仍無法判定，未授權 merge／release／正式採用。

## Time Budget：原授權窗歷史（新 trust 補測依末節新窗）

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

- 2026-10-15 03:37:31 UTC：自簽預檢成果 commit `3a0eb8f` 已 push；GitHub 查證 Draft PR #58 head 為該 commit、base dev、isDraft true，hooks 全通過。PR Lens 本機對實際 diff validate／render 通過（8 nodes／8 edges），Graphify 0.9.73 重查無 repository graph，沿限定 source fallback、不建圖／refresh。S06 本次交付 completed、S07 Human review pending；本帳本另以同 topic docs commit 保存，最終 head 與 PR body 核對留 repository 外，不新增測量或採用。

- 2026-10-15 03:44:50 UTC：使用者要求續行下一步；僅同一自簽 PEM 候選失敗診斷，不變判準／安全邊界或原截止。新增已知錯誤片語 allowlist 與本輪專用 Keychain identity 數量，保留上輪 source snapshot；待獨立 Tester／Reviewer，不再用不足分類當作具體根因。

- 2026-10-15 03:46:19 UTC：獨立 Tester 單輪同候選診斷確認 1 matching／0 valid，`CSSMERR_TP_NOT_TRUSTED`，codesign `no identity found`。零 OAuth 寫入／T03 acceptance 未執行，專用 Keychain／秘密清理與全域設定一致已核對；禁止信任調整邊界維持，結果待 Reviewer，若續行信任變更交 Human 決策。

- 2026-10-15 03:47:59 UTC：獨立 Tester／Reviewer 明示 `approved`，唯一 provenance 文字修正已核對。本輪具體診斷僅為隔離 identity 的 codesigning policy 不受信任與 codesign 找不到可用 identity；已回寫指定 docs。依既有授權提交／更新同一 Draft PR，最終 head 以 PR 與 repository 外核對為準。信任設定未獲授權，停於 Human 決策，不新增測量／變體、不外推正式採用；原03:56:28新測量截止仍有效。


## 新授權 trust 窗：目前有效契約

- Human 已明確核准僅本輪新 self-signed cert、user domain、codeSign policy 的 trust，以及額外最多 30 分鐘；原信任禁令僅在此範圍例外。禁止 admin／`-d`、SSL／broad trust、既有 ACL／partition-list、default／全域 search-list 改動；Human 自行操作系統密碼／approval。
- 先證明 exact cert 無 user trust；新增後讀回驗證只有 user／codeSign。trust＋兩 build／DR 預檢零 OAuth write；成功才確認 CUA 並等 Human 明確 ready，同 cert／固定 active path first 寫 second 讀、核對不同 hash。不 ready／連線不通／到停止點即 cleanup。
- finally／受控 signal／trustfailed／timeout／正常或例外皆 cleanup；只有三 domain baseline absence 確認且本輪 add 已嘗試才撤回 exact-cert user trust，核對無 user trust後才刪專用 Keychain／cert／秘密。baseline 已有 trust／查證失敗／未 add 只清自建素材，絕不撤原有 trust。刪 cert 不代表撤 trust；部分新增也需核對。撤回失敗保留非秘密撤回依據、殘留原因，標清理未完成／任務否。
- 新窗起算 2026-10-15 03:54:20 UTC；04:19:20 UTC 停新測量，04:24:20 UTC 總上限，最後五分鐘優先撤 trust／清理紀錄。原 90 分鐘窗及證據保留為歷史，非暗延長，等 ready 不延長。
- 本次 S02 completed：trust cleanup ownership 已回修且獨立 Plan-Reviewer 複審 approved；既有 approvals 不用來代替本次審查。T03／主假設目前仍無法判定；新窗操作未執行，舊 receipts 不覆寫，S07 人類審查未宣稱完成。
- 2026-10-15 03:55:44 UTC：Plan-Creator 僅更新四份 planning artifacts 的新 trust 例外、順序、撤回驗證與明確新時間窗；未新增 trust、未實作／測試／commit。交獨立 Plan-Reviewer。


### 本窗 TrustProbe 與目前 Human ready 狀態

- helper 限 `Rivet-E005-UUID` cert DER；exact-cert user／admin／system baseline 嚴格 errSecItemNotFound。空 array 是 broad AlwaysTrust，不能當 absent／limited。
- 新增仍只 user codeSigning／trustRoot 的 Policy／Result 兩 keys；讀回恰一 entry、必需 Policy／Result、SecPolicy type／AppleCodeSigning OID／trustRoot，唯一可選 metadata policyName 必須 String 且精確等於 Apple OSS 明定的 String literal `CodeSigning`，admin／system absent；unknown keys／allowedError／SSL／broad／multirow 拒絕。
- trust 互動 ready 尚未收到，只 code preparation；收到 Human 明確 ready 才做需互動 add。兩版簽章／DR 成功後，另確認 CUA／Human T03 ready；密碼／approval 均由 Human。
- trustOwnedAttempt 初始 false，僅三 domain baseline absence 成功後在 add 前設 true；finally 僅 flag=true remove exact-cert user trust＋嚴格 absent 核對後才刪 Keychain／秘密。add failure 仍處理部分新增；flag=false 只清自建素材，不撤原有 trust；失敗保留 cert DER／private Keychain／recovery 資料並明列殘留，不輸出路徑／秘密、不改 partition-list。
- 本次 S02 completed，獨立 Plan-Reviewer 複審 approved；未宣稱 trust、T03 或清理已執行。新窗截止仍04:19:20停測／04:24:20總上限。

- 2026-10-15 03:56:25 UTC：依主工作 session 精確化 TrustProbe 介面與兩個 ready 時點，四檔僅規劃追加；未執行 trust／測量／commit。

目前有效優先規則：本次 Human 新授權的 30 分鐘窗與 exact-cert user-domain codeSign trust 例外，優先於前版一律禁止 trust 及原 90 分鐘截止的敘述；前版限制／收據僅保留為歷史。此優先只開放本次新 cert 的 user/codeSign，不開放 system/admin domain 或其他政策；其餘 scope、安全／UX／cleanup 限制保持有效。

- 2026-10-15 03:58:02 UTC：依獨立 Plan-Reviewer needs-rework 唯一 required fix，四檔限定 trust cleanup ownership：baseline 三 domain absent 且本輪 add 已嘗試才 remove；baseline 失敗／已有 trust／未 add 只清自建素材，絕不撤原有 trust。add failure 仍核對部分新增／absence。S02 needs-rework，已回修待獨立複審；未實作／測量／commit。

- 2026-10-15 03:59:35 UTC：獨立 Plan-Reviewer 複審正式 approved，cleanup ownership required fix 已滿足。Implementer 新增 TrustProbe 與限定 trust runner，Swift6 build／Python syntax 通過；尚未收到 trust authentication Human ready，沒有新增 trust 或 OAuth 寫入。Tester 先驗純 constraint synthetic checks，Reviewer 先檢視 bounded 實作；不以 build green 代替 trust／T03。

- 2026-10-15 04:02:46 UTC：Tester 純檢查 approved，TrustProbe 七項 constraint checks 與 runner 三項 adversarial cleanup tests 通過，缺 gate CLI 在 Security 初始化前拒絕；均 synthetic/noTrustMutation。Reviewer required fixes（helper declined ownership、同程序預檢後 ready gate）已實作並交複核。尚未收到 Human trust-ready，真實 trust／T03 未執行，不以 synthetic 冒充。

- 2026-10-15 04:04:26 UTC：獨立 Reviewer 正式 approved（僅準備交付），兩項實作 required fixes 與全部純檢查來源 hash 已核對，無剩餘 required fixes。依既有授權提交準備成果並更新 Draft PR；尚待 Human trust-ready，沒有真實 trust／T03 操作或本輪殘留，實驗結果不提前宣稱成功。新窗04:19:20停測／04:24:20總上限維持。


## 最新有效 Human-start 窗與 trust-ready（2026-10-15）

Human 本 turn 明確回覆「可以開始」，trust authentication ready 已收到；此 ready 授權在既定範圍開始本輪，不重問 scope／trust-ready。主工作 session 已向 Human 明說以此次實際 start 另起相同最多 30 分鐘的一輪。

- 本輪起算：2026-10-15 05:42:19 UTC。
- 停止新增測量：2026-10-15 06:07:19 UTC。
- 總上限：2026-10-15 06:12:19 UTC；最後五分鐘優先撤 trust、精確清理與紀錄，不自動延長。
- 本節為最新 active 時間／trust-ready 契約，優先於前述 03:54:20–04:24:20 窗、04:19:20 停測時間及尚未收到 trust-ready 的敘述；那些內容保留為歷史。此為 Human 明確 start 後的新一輪，不暗延長舊窗。主工作 session 交接確認前窗零 trust／OAuth mutation、無殘留；本次修訂不將舊窗寫成已執行。
- 其餘 scope、既有準備 approval、user-only codeSign policy、exact cert、cleanup ownership 及 same-process gate 均保持，不因新時間窗放寬。只有 baseline 三 domain absence 確認且本輪 add 已嘗試才可 remove；既有 trust 不得撤回。密碼／系統 approval 仍由 Human 操作。
- 本次 start 僅滿足 trust-ready。兩版簽章／DR 預檢成功後，T03 仍須確認 CUA 連線並另行取得 Human 的 T03 觀察 ready，不能沿用本次 trust-ready；保持固定 active host path、first writer／second reader、不同 hash 及完整假六欄。
- 本次僅時間與 trust-ready 修訂，交獨立 Plan-Reviewer 快核這兩項；不撤銷既有準備審查，不新增政策／實作決策，不預報 trust 或 T03 成功。

- 2026-10-15 05:43:22 UTC：Plan-Creator 依 Human「可以開始」僅追加最新有效 05:42:19–06:12:19 UTC 窗／06:07:19 停測及 trust-ready 已收到；本次時間／ready 修訂待獨立快核，其他準備 approvals 與鎖定條件保留。未實作、操作 trust／OAuth 或 commit。


## Readback checker false-negative 窄修：OSS CodeSigning policyName metadata

`limited-trust-shape-run.json` 的交接實證為 user 恰一 entry，keys 為 policy／policyName／result，SecPolicy object、AppleCodeSigning OID 與 trustRoot 均符合；先前 exact-two-keys checker 因回傳 metadata 誤拒。Apple OSS [TrustSettings.cpp](https://github.com/apple-oss-distributions/Security/blob/main/OSX/libsecurity_keychain/lib/TrustSettings.cpp) 的 copyTrustSettings 會附加 policyName。本修正僅正規化 readback metadata，不改 trust policy、主假設或通過標準，不回寫舊 code／receipt。

目前有效 readback 契約：恰一 entry，必需 kSecTrustSettingsPolicy／kSecTrustSettingsResult；Policy 必須 SecPolicy runtime type 且 OID AppleCodeSigning，Result 必須 trustRoot。唯一可選 key 為 kSecTrustSettingsPolicyName；若有，其值必須 String 且精確等於 Apple OSS `SecPolicy.list` 明定的 literal `CodeSigning`。metadata 不符即拒絕；不宣稱公開 `SecPolicyCopyProperties` 的 `kSecPolicyName` 可取得此 friendly label，不呼叫私有 API，不以 label 取代實際 SecPolicy type／OID 的政策資格判斷。admin／system 仍必須 absent。

set 維持僅 Policy／Result 兩 keys、user-only；unknown keys、allowedError、SSL、broad trust／空 array、multi-entry 一律拒絕。只接受本輪 exact cert，baseline absence／cleanup ownership／same-process gate 不變；舊程式與 receipts 保留。此節優先於前文 readback 必須恰兩 keys 的描述，其他限制保持有效。

Human trust-ready／Touch ID 授權已收到；T03 仍須預檢成功後另確認 CUA／Human ready。active 時限不變：06:07:19 UTC 停新測量、06:12:19 UTC 總上限；主六欄／UX／授權 scope 不變。此段為規劃當時狀態：T03 尚未成立，當時僅 planning 窄修、待獨立快核後才實作，未 commit；後續實作與四輪結果見最新紀錄。

- 2026-10-15 05:49:43 UTC：Plan-Creator 依 shape 實證與官方 OSS 收斂，四檔只正規化可選 canonical policyName metadata；set／policy／domain／ownership／scope／時限不改。S02 pending，待獨立快核；未實作／測量／commit。


### policyName 來源更正（不改政策語意）

公開 `SecPolicyCopyProperties` 對標準 codeSign policy 的 `kSecPolicyName` 為 missing；該 key 用於 SSL 等 policy-specific name，不能作為取得 friendly label 的途徑。唯一 optional metadata `kSecTrustSettingsPolicyName` 必須 String 且精確等於 `CodeSigning`，依據為 Apple OSS [SecPolicy.list 第 25 行](https://github.com/apple-oss-distributions/Security/blob/main/OSX/sec/Security/SecPolicy.list#L25) 的 CodeSigning policy 定義。TrustSettings.cpp 以內部名稱附回此 metadata；本實驗不呼叫私有 `SecPolicyGetName`。

仍以實際 SecPolicy runtime type／AppleCodeSigning OID、trustRoot、user-only、exact-one-entry 及 admin／system absent 作政策資格判斷，metadata 只作一致性檢查；unknown keys／allowedError／SSL／broad／multi-entry 仍拒絕。set 仍兩 keys，cleanup ownership／same-process gate／first writer-second reader／UX／scope／06:07:19 停測與06:12:19總上限全不變。此為 checker API 來源更正，不擴 semantic 或改主假設成功標準；舊 code／receipt 保留，本修訂交獨立 Plan-Reviewer。

- 2026-10-15 05:50:57 UTC：Plan-Creator 僅更正四檔 policyName 來源為 Apple OSS literal CodeSigning，移除公開 API 可取 canonical friendly name 的錯誤敘述；不呼叫私有 API，其他嚴格條件與 scope 不變。待獨立 Plan-Reviewer；未實作／測量／commit。

- 2026-10-15 05:57:26 UTC：四輪真實限定 trust 試驗已停止；前兩輪 readback metadata 誤拒，官方來源與 shape 證據後獨立核准 checker 正規化；後兩輪限定 trust／valid identity 成立，但名稱與 exact SHA-1 selector 的 codesign 仍 no identity found。全部零 OAuth 寫入／T03 未執行，trust 撤回與三 domain absence、專用 Keychain／秘密清理、default/search-list 一致均確認。最後 selector 試驗後不再變體；下一個 search-list 前提超出授權未介入。等待 Tester／Reviewer closure，不以局部成功宣稱主假設成立。

- 2026-10-15 06:01:57 UTC：獨立 Tester／Reviewer closure 正式 approved，四輪 receipts／全部來源與metadata回修、zeroOAuth／T03未執行及完整清理核對一致，無 required fixes。已回寫指定 docs；同 topic 提交更新 Draft PR，最終 head 於 repository 外核對。不再本輪測量；search-list 僅待測前提，任何修改須新 Human 授權，未核准採用／merge。
