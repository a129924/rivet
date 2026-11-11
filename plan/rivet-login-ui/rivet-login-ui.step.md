# Rivet 登入 UI：Step Ledger

## Topic 與執行基線

- Slug：`rivet-login-ui`；branch：`feat/rivet-login-ui`；ownership：non-BC `RivetPresentation`。
- 固定基線：`14d0832f042720889993d769b4cbfb720078e6b1`。PC-01 寫入前唯讀確認 feature branch attached、HEAD 相符、工作樹 clean；所有寫入只在已授權 feature worktree，禁止在 dev worktree 修改。
- Branch 命名依本地 `git-branch-naming`：feature 工作＋已知 work item、沒有既定 owner 慣例，因此使用 `feat/rivet-login-ui`，不捏造 owner。
- Human 前輪鎖定 UI／假資料 Demo、slug／branch／ownership 與原 27 個 Written paths；本輪要求納入 Archify、PR Lens、Graphify。新增九個 Archify paths 是本方案為該要求定義的必要交付規劃，不是 Human 曾逐字列出的清單。Human 最新已接受完整本版方案並授權 feature worktree 實作、依 topic 直接 commit、push、開 Draft PR，再進 Human review；不新增重複確認流程。
- 直接 commit 的既有授權不省略 staged diff 語意邊界與 commit message 檢查；由 Implementer 依本地 commit convention 執行。Plan-Creator 不 commit／push／開 PR。
- Planner 的 `approved` 只表示 planning preparation sufficient；獨立對話草稿品質審查已由上游回報 approved，不能替代四文件落盤後的正式 Plan-Reviewer gate。PR-01 既有正式 approved 保留；Dispatcher 已交接 PC-02 delta 的 PR-02 approved，無 required fix。

## Current Phase

- Phase：Human review。IM-10 source已公開交付、PL-04 completed，RV-06 approved／TE-08 completed／partial，Human兩入口及HC-01／HC-03仍pending。
- Current Step：HC-03 pending，最新版Welcome→waiting親聽問題已提出且尚無回覆。待兩入口／雙讀、Human大字／rapid逐項回報，HC-05 observed有聲1／1及全部來源留存。
- Upstream verdict：RV-06正式approved／required fix None由Dispatcher交接，准topic交付。PR-06正式approved／required fix None。Human Welcome→waiting needs-rework留源，待新版補驗。前輪Reviewer結果處置approved／required None准既有HC-03，不代本次通過。RV-05 approved／required None，僅放行正常版HC-05一次；PR-03 approved；TE-05 partial completed；Dispatcher正式交接獨立RV-03 approved／required source fix None，准受限source交付。最新HC-03 PAT兩次未通過，Human needs-rework與HC-01／HC-03 pending仍有效，舊code approval不等於朗讀通過或採用。
- 已發布source head：`dcc48b29686ab324fc19399ef607f462a507cce5`，七檔、完整hooks passed、正常push／ls-remote一致，source／binary凍結值見verification IM-09／TE-08。PL-04限此source，後續metadata另列版本。
- HC-02保留七類Human通過：鍵盤、Welcome VoiceOver、PAT VoiceOver／Show-Hide、帳號／完成／重跑失敗宣告、失敗取消、高對比、Reduce Motion。三缺口為PAT verifying自動宣告、等待兩入口自動宣告、大字測法未確認；spinner旋轉只列觀察。HC-02受測binary SHA與TE-04相同；該Human交接當輪未重跑舊自動檢查。新版IM-05自驗結果見下方及verification，rootstrict仍非零。

## Artifact Register

| Path | Status | Responsibility |
| --- | --- | --- |
| `analysis/rivet-login-ui/requirements.md` | present，PC-03 revised | 意圖、素材、唯一 bounded 能力、驗收與限制。 |
| `analysis/rivet-login-ui/technical-spec.md` | present，PC-03 revised | UI／API／state／native／工具執行設計。 |
| `plan/rivet-login-ui/rivet-login-ui.plan.md` | present，PC-03 revised | 九欄、exact paths、TestCase、執行／review 契約。 |
| `plan/rivet-login-ui/rivet-login-ui.step.md` | present，PC-03 revised | phase、owner、evidence、blocker、verdict、Human boundary。 |

## Ledger

| ID | Status | Owner role | Completion condition | Verification evidence／verdict |
| --- | --- | --- | --- | --- |
| HC-00 | completed | Human | 接受完整本版方案，授權 feature worktree 實作與直接 topic commit／push／Draft PR，最後 Human review。 | 來源：本對話 Human 最新執行指示，由 Dispatcher 明確交接。前輪原 UI／branch／ownership／27 paths、本輪三 skills 及完整方案接受的語意如 Topic 區；不偽稱 Human 曾逐字列九個 Archify 檔。 |
| PC-01 | completed | Plan-Creator | 在已授權 feature worktree 僅建立四份正式 artifact，完整九欄、當時36／10／3／None paths 與 LU-01～11；PC-02 後目前 Modify 為4。 | 本次四文件落盤；寫入前 branch attached、base HEAD 相符、clean。尚未測試或實作。完成狀態不是自審 approval。 |
| PR-01 | completed | Plan-Reviewer | 獨立正式讀四文件，審查 sufficiency／paths／native admission／tools／scope，明示 verdict。 | Dispatcher 交接獨立正式 verdict `approved`、無 required fix；四文件與九欄／exact paths／LU-01～11 reviewed。 |
| IM-01 | completed | Implementer | PR-01 approved 後完成受限 UI／Demo／tests／素材／Archify／docs，提供明示 handoff 與限制。 | 初輪needs-rework歷史保留；後續root284／build／scoped檢查pass、Archify第2輪與4nativePNG完成，RV-01／RV-02 required fixes均closed。完整accessibility與Human採用仍pending，詳verification。 |
| PC-02 | completed | Plan-Creator | 僅修四文件：新增唯一第4 Modify、LU-08 測試／lint 驗收與真實限制，scope／API／工具契約不變。 | 唯讀確認既有 StaticIsolationTests 與 manifest，四文件同步完成；未改測試／產品、未重跑，不自審 approval。 |
| PR-02 | completed | Plan-Reviewer | 獨立正式審查 PC-02 delta，核對最小 expected-set 同步、路徑集合、lint baseline／no-regression 與證據不冒 pass。 | Dispatcher 明示交接 approved、無 required fix；既有 PR-01 不代替本 delta。 |
| TE-01 | completed | Tester | 獨立執行 LU-01～11，分列自動／native／工具結果與缺口。 | partial verification：親跑 focused10／root284、debug/release、format/scopedlint pass；baseline37=現有37、raw素材新增2原樣保留；Archify validate／hash／四圖實看pass。CGWindow真存在但CUA選窗阻塞、capture preflight=false；native四圖／互動／AX pending。見 verification TE-01。 |
| RV-01 | completed | Reviewer | 獨立審查source／tests／證據與單一P2回修，明示verdict。 | Dispatcher交接approved，唯一PAT failure edge P2 closed，無其他required fix；僅供bounded Draft交付，Native／Human採用仍pending。 |
| IM-02 | completed | Implementer | 已授權topic staged review／commit後push feature branch。 | 早期code commit98f0573／兩次拒絕保留歷史；Human公開payload明示後，IM-04 source6fc18b3正常push成功、ls-remote精確SHA一致，未force。 |
| PL-01 | completed | Reviewer | 以真base／code head完成外置本地map與pinned validate／render。 | `14d0832`→`98f0573`，validate／render exit0；1view／4lanes／9nodes／11edges／4steps。只含code commit，未含之後metadata；無raster實看。詳verification目前狀態。 |
| GH-01 | completed | Observer/Dispatcher | push後依授權建立目標dev的Draft PR。 | Dispatcher已建立並attach [Draft PR #66](https://github.com/a129924/rivet/pull/66)，base dev613a505／建立時head6fc18b3，draft=true，未merge。 |
| IM-03 | completed | Implementer | 修正Show／Hide焦點並交自驗與限制。 | 最終source SHA與IM-03／TE-04一致；focused10／root284／debug／release／format／scoped0，自驗attempt1red／attempt2green保留。 |
| TE-04 | completed | Tester | 最終source的bounded native獨立回歸及4真圖。 | Show／Hide4＋rapid4、保值／focus、departure、canonical Return／Escape passed；特殊條件及完整VoiceOver／traversal未冒pass。 |
| RV-02 | completed | Reviewer | 獨立核source／新證據並判required fix。 | Dispatcher正式交接approved、required fix None、TE-03focus defect closed，不代表Human採用。 |
| IM-04 | completed | Implementer | staged單topic檢查、完整hooks commit與正常公開push。 | 6fc18b3c040997155d84ca85abba48abc1a61d6c；7files；hooks全passed；remote SHA一致；dev worktree未改。 |
| PL-02 | completed | Reviewer | 依真PR base／source head建立外置本地change map。 | base613a505→source6fc18b3；merge-base14d0832／40files；CLI0.11.0 validate／render0，1view／4lanes／10nodes／12edges／6steps、23file refs；僅XMLlabels無raster實看。Map不含後續metadata，詳verification。 |
| HC-02 | completed | Human | 交接真Human實測結果，回寫來源、七類通過、三缺口與限制。 | 2026-11-04為交接／回寫日，非各項執行時刻；Human partial／needs-rework，詳verification HC-02。完成只指證據回寫，不代表成果採用。 |
| EX-01 | completed | Explorer | 合併調查PAT verifying／waiting兩入口的焦點與宣告時序，查明macOS字級來源、大字支援目標及可靠測法。 | Explorer明示planning sufficiency approved：同步focus／notification與共用Bool為時序候選，未證唯一root cause；Apple明示macOS Dynamic Type不影響文字大小。建議原LU-05採13／17／21 pt局部真字級，詳technical-spec PC-03；無repo／系統／UI變更。 |
| PC-03 | completed | Plan-Creator | 四文件最小delta鎖定三缺口修法／真字級入口、LU-05／06與新版證據界線；paths不變。 | 本輪四planning文件完成，保留HC-02與原pass；尚未實作／跑測試，不自審approval，交獨立PR-03。 |
| PR-03 | completed | Plan-Reviewer | 獨立審查PC-03的API增量、取消／去重、真字級策略、paths及Human補驗條件。 | Dispatcher正式交接獨立verdict approved、required fix None；僅准受限實作，不代表Human三缺口補驗通過。 |
| IM-05 | completed | Implementer | PR-03 approved後依PC-03完成掛載後phase協調、bodyPointSize增量與局部字級控制、Preview／docs及必要行為測試。 | 受限working diff完成；TDD red→green、focused15／root289／debug／release／format／7檔scoped0自驗，rootstrict39非0；新binary／source SHA見verification IM-05。未啟UI，非朗讀／大字native通過，交TE-05。 |
| TE-05 | completed | Tester | 獨立親跑新版自動檢查、三真入口AX／focus與必要回歸，13／17／21 pt最小視窗實看；交Human聽取／逐項確認。 | partial verification：本Tester親跑focused15／root289／debugrelease／format／scoped136files0／diffcheck0；rootstrict39非0且finding檔bytes未變。主對話Tester CUA真三入口／PAT／三字級五畫面與scroll可達，本Tester獨立實看18 rawJPEG。VOoff，Human聲音／大字與rapid仍pending，三缺口未closed；詳verification TE-05。 |
| RV-03 | completed | Reviewer | 獨立審查PC-03 bounded source、Tester證據／剩餘限制；真commit後本地map另列PL-03。 | Dispatcher正式交接approved、required source fix None；TE-05 partial與Human三缺口／rapid限制保留，code approval不代HC-01採用。 |
| IM-06 | completed | Implementer | RV-03 approved後精確13檔staged語意／message核對、完整hooks commit及正常public push。 | 真source9f8955c40696cee6d77739da6d22d659287cfbc0，全部hooks passed，正常push／ls-remote同SHA；source／binary凍結不變，dev未動。 |
| PL-03 | completed | Reviewer | 以本輪真source commit與實際PR base建立外置本地PR Lens。 | 獨立Reviewer完成base613a505→source9f8955c、merge-base14d0832；pinned0.11.0 validate／render0，12nodes／15edges／6steps／34file refs，XML核對未raster實看。完整hash見verification；不含後續metadata，不取代correctness review。 |
| EX-02 | completed | Explorer | 依HC-03-PAT兩次新版無聲證據，唯讀診斷真正通知發出、AX掛載及VoiceOver scope。 | 明示planning sufficient approved僅足以一次runtime觀測；task／focusPhase初始guard先後為待區辨候選、yield非AX barrier、target合法，不預設修法。 |
| PC-04 | completed | Plan-Creator | 四文件最小delta限定DEBUG有限觀測、外置trace與一次真Human PAT Return case及路由。 | 本delta完成，無source／測試／UI或Git發布；待獨立PR-04，不自審。 |
| PR-04 | completed | Plan-Reviewer | 獨立審instrumentation-only範圍、敏感欄位allowlist、單case預算與不預准後續修法。 | Dispatcher正式交接approved／required None，僅准DEBUG觀測，不預准功能修法或聲音通過。 |
| IM-07 | completed | Implementer | PR-04 approved後僅於既有View加可關閉DEBUG／OSLog觀測，完成適當自動檢查及build。 | 唯一View logging-only；focused15／root289／debugrelease／format／scoped0／diffcheck自驗通過，trace／source與新probe SHA見verification IM-07。未啟UI或驗runtime，交獨立TE-06。 |
| TE-06 | completed | Tester | 核trace可讀、source／binary一致、欄位有限且無敏感資料；preflight後交HC-04一case。 | preflight partial：親跑focused15／root289／debugrelease／format／scoped136files0／diffcheck0，release無probe marker；PID46623 runtime20筆welcome／tokenEntry、finite schema0errors，沒有post／verifyingToken。未消耗Human case、不當聲音通過；詳verification TE-06。 |
| RV-04 | completed | Reviewer | 獨立核logging-only source、preflight runtime／敏感欄位限制與自動證據，再交HC-04。 | Dispatcher正式交接approved／required None，僅准一次前景PAT Return診斷；核PID46623／20筆／15欄0error與source／binary凍結，不推舊原因或預准fix。 |
| HC-04 | completed | Human | instrumented binary真正前景PAT Return最多一次，親聽並結合runtime trace分類。 | 唯一case Human回「讀出驗證中」；PID46623／34筆schema0error，同correlation post前後各一次、無guard.return；1／1已用。只屬觀測版有聲，不代正式修復、HC-03補驗／HC-01採用，詳verification HC-04。 |
| PC-05 | completed | Plan-Creator | 四文件最小delta限定封存探針、單檔hashguard還原與一case正常版對照。 | 獨立PR-05 approved由Dispatcher正式交接；不自審或預填Human成功。 |
| PR-05 | completed | Plan-Reviewer | 獨立審保存／還原邊界、來源與預算、正常對照不等修法／穩定性。 | Dispatcher正式交接approved／required None，僅准PC-05正常版一次對照流程。 |
| IM-08 | completed | Implementer | PR-05 approved後外置封存及hashguard，只還原View至指定原bytes，正常build與適當檢查。 | 雙份外置20件原bytes／manifest核對、七Swift等於HEAD9dd／source9f；focused15／root289／debugrelease／format／scoped136files0／diffcheck passed，新normal SHA見verification IM-08。未UI／換wrapper／Git發布，待TE-07。 |
| TE-07 | completed | Tester | 獨立核source／無probe marker／新normal binary與wrapper一致及Human準備條件。 | partial：七Swift等於HEAD／source9f，正常debugEA297d／releaseFE886c／wrapper marker無且hash相符；雙份archive20件符合manifest，focused15／root289／build／format／scoped1360／diffcheck通過。主CUA只準備PATdummy停entry，HC-05仍0／1；無正常post trace。 |
| RV-05 | completed | Reviewer | 依TE-07證據放行一次bounded正常版對照或回修。 | Dispatcher正式交接approved／required None；獨立核112份Sources／Tests逐bytes、雙archive20件／manifest與TE-07，僅放行HC-05一次，不預准聲音成功／修法／採用。 |
| HC-05 | completed | Human | 正常debug前景真PAT Return最多一次，先不手動進scroll area，收實際聲音／視窗結果。 | 本次明確正常版步驟後Human回「讀出驗證中」，CUA確認verifyingToken；normal EA297d／source89cb未變，1／1已用、observed有聲。先前無送出證據的同句歷史保留，不判穩定修復／全項採用。 |
| EX-03 | completed | Explorer | 依Human同次Cancel可讀而等待狀態缺失，判定最小語義修補充分性。 | 正式planning sufficiency approved／required None；label可帶狀態，當次post unknown，不證唯一原因，不需新probe。 |
| PC-06 | completed | Plan-Creator | 四文件最小delta鎖waiting Cancel焦點label與不另post，保留其他phase。 | 本delta完成，獨立PR-06 approved由Dispatcher正式交接。 |
| PR-06 | completed | Plan-Reviewer | 獨立審label／role／focus／Cancel契約、單一phase通知變更與補驗／交付界線。 | Dispatcher正式交接approved／required fix None，准PC-06 bounded實作。 |
| IM-09 | completed | Implementer | PR-06 approved後僅View的waiting label／post修補、既有長期文件與證據，同LU-08檢查。 | View +1／-1、既有長期說明同步，focused15／root289／debugrelease／format／scoped136files0／diffcheck自驗通過。來源及新binary SHA見verification IM-09，交TE-08。 |
| TE-08 | completed | Tester | 獨立自動檢查及正常新版native role／label／focus／Cancel／Escape來源，準備逐項Human兩入口。 | partial：親跑focused15／root289／debugrelease／format／scoped136files0／diffcheck0；source cf1f／wrapper50a核對。主CUA真Welcome／Retry入口的link／完整label／focus、Cancel／Escape與空PAT／Back通過；AX不代Human聲音／雙讀，大字Human／rapid仍pending，詳verification TE-08。 |
| RV-06 | completed | Reviewer | 獨立審waiting bounded修補與TE-08證據／限制，再依既有授權交付。 | Dispatcher正式交接approved／required fix None。兩行反還原原89cb、其餘六Swift相等，TE-08 checks／native／來源核准，准既有topic交付。 |
| IM-10 | completed | Implementer | RV-06 approved後七檔staged語意／message檢查、完整hooks topic commit及正常public push，核真SHA。 | 真source dcc48b29686ab324fc19399ef607f462a507cce5，六項hooks全Passed，正常public push／ls-remote一致，feature及dev clean，cf1f／50a／25a凍結來源相同。 |
| PL-04 | completed | Reviewer | 以真PR base與source dcc完成外置map、pinned validate／render與來源核對。 | 獨立Reviewer完成base613a505→source dcc48b2、merge-base14d0832，pinned0.11.0 validate／render0，12nodes／15edges／6steps／38refs及全部XML labels核對，raster實看未執行。完整hash見verification，map範圍止於dcc。 |
| HC-03 | pending | Human | 逐項聽新版PAT submit／Welcome→waiting／Retry→waiting，實看13／17／21 pt與必要focus回歸。 | Welcome→waiting只讀Cancel、狀態failed留源。PC-06 Cancel focus label已實作，TE-08 partial完成，待兩入口Human補驗。兩真waiting入口／Human大字／必要focus及rapid未補驗；HC-05正常PAT有聲1／1及舊failed留源，不當穩定修復。 |
| HC-01 | pending | Human | Draft PR 與完整證據交 Human review，決定採用／調整／放棄。 | 最新Human明示七類通過但三缺口未補驗，尚未全面通過；執行／公開授權不等於成果採用。 |
| HC-PUB | completed | Human | 回覆自動approval review要求的具體公開發布確認。 | Human本輪明確同意將`feat/rivet-login-ui`程式／測試／原始素材／文件圖面公開推送至`a129924/rivet`，並以`dev`建立Draft PR；這不是UI成果採用。 |

## Blockers／證據邊界

- 正式 PR-01／PR-02 approved 由 Dispatcher 交接；root target-set expected-set 的兩行最小修復已完成，Tester focused10／root284親跑passed。Root strict lint仍exit2；baseline37逐條等值、raw素材新增2原樣，scoped0，不冒稱rootlint通過。
- HC-02三缺口仍open：PAT verifying自動只讀scroll area；waiting從Welcome只讀展示版不能連接GitHub的說明、從Retry只讀footer；13／15點時Codex變大而Demo未變，大字未驗。七類Human通過保留，三缺口補驗前HC-01不全面通過。舊發布拒絕已由明確公開授權解除，與新原生缺口分開。
- Graphify沒圖的source fallback、PL-02真source map及TE-04舊證據保留來源；HC-02真Human朗讀與工具背景送鍵分開，不將背景無朗讀當缺陷。EX-01只確認可信時序候選及macOS Dynamic Type限制；PC-03採局部13／17／21 pt真字級，不宣稱系統偏好整合；PR-03已approved，IM-05已實作，仍待新版native／Human補驗。
- Archify Showcase diagnostics 與 perceptual correction 的停止規則分開適用，以 technical-spec／plan 原值為準，不把兩者合成一個兩輪上限。
- Exact paths 之外的 repo 輸出或 scope／baseline 衝突回 planning；外置 scratch 不加入 repo／staged diff。

## Human Check

HC-00 是方案接受及直接執行授權。Staged diff 邊界與 message 檢查仍必做，但不為已授權 commit／push／Draft PR 重問。HC-01 是交付後 Human review，不能由 PC-01、draft quality 或正式 agent verdict 代替。無授權合併／release／下一 capability。

## Last Updated

2026-11-11（Asia/Taipei）。IM-10 source dcc48b2完整hooks／正常public push完成，PL-04真source map completed，RV-06 approved／TE-08 partial。最新版Welcome親聽問題已提出、尚無回覆，兩入口／雙讀、Human大字／rapid及HC-01／HC-03 pending，全部舊來源留存。

## PC-02：必要測試契約修正與已知驗證限制

- IM-01 handoff 為 `needs-rework`。Implementer 回報 root `swift test` 非0：284 tests／36 suites，`packageDeclaresTheLockedTargetGraph()` 的 products／targets exact sets 產生兩個 issues；已唯讀確認既有測試與 manifest，原因是本次已授權新增 Demo product／三 targets，非環境問題。
- 唯一新增 Modify 為 `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`；Implementer 僅可在上述 test 的 products expected set 加 `RivetLoginDemo`，targets expected set 加 `RivetLoginDemoRuntime`、`RivetLoginDemo`、`RivetLoginDemoRuntimeTests`。不得改 GitHubIntegration dependency／source／import／credential boundary 等隔離斷言、helpers 或放寬 equality。ReadOnly 10／Written 36／Deleted None 不變，目前 Modify 為4；不新增產品 scope／public API。
- 本輪 Human 既有「接受計畫、無重大問題直接實作」及直接交付授權涵蓋此必要 routine 測試同步，不新增確認流程；PC-02 只修四文件，仍交獨立 Plan-Reviewer PR-02 審查本 delta，未自行宣稱 approved。
- Implementer 自我證據：focused 9 tests、debug／release、format／diff check 成功；新增 production 首輪6項 lint 已修，scoped strict 0 violations／136 files。Root strict lint 尚為38 findings：36屬既有未改 experiments，2屬原樣封存 scaffold；Tester 尚須獨立核對 baseline、素材 SHA 與 no-regression，不能稱 root lint passed，也不為全局0修改原素材／舊 experiments／lint config。
- Root tests 修復與重跑待 Implementer／Tester；Archify deterministic validate／deliver 9/9、0 errors／warnings 僅為 Implementer 回報，visual-check 三尺寸 overflow 交既有 bounded diagram repair，不改工具契約；四份最新 native PNG 仍缺待 Tester 取證。

## 九欄執行契約

### Goal

交付貼近四張參考 PNG 的原生 macOS Rivet 登入 UI，以及能操作七種呈現狀態、明暗外觀與 PAT 表單的假資料展示程式；這是一個 bounded native Presentation capability。

### Non-Goal

不重設計 adopted workflow／native contract，不交付正式登入，不建立新 BC，不順帶實作 Logic／Domain／Application／Integration。工具不擴張 UI scope。

### In-Scope

non-BC `RivetPresentation` 登入元件、獨立原生 Demo、假狀態模型、七份素材保存與 artwork、native 操作／accessibility、必要測試及文件；Graphify bounded navigation、Archify 七態 lifecycle、PR Lens 實際變更圖，作為同一 UI 交付的理解／驗證證據。 PC-03僅追加兩類狀態宣告修補與Demo局部13／17／21 pt真字級驗收；系統文字大小偏好整合仍未交付。

### Out-Of-Scope

真 OAuth／PAT 驗證、browser authorization、GitHub API、Keychain、credential persistence／restore、PR workspace 轉場、其他 BC、既有 Row／List／Header、兩個 OAuth 驗證 App；Graphify 建圖／refresh／integration；PR Lens provider／發布／repo config；artifact.cafe 等發布、合併／release，以及為產圖強迫 commit。已授權的 topic commit／push／Draft PR 僅是本 topic 交付動作，不代表新增產品能力。

### ReadOnly

- `docs/design-principles.md`
- `docs/toolchain.md`
- `docs/development-workflow.md`
- `docs/presentation/native-interaction-contract.md`
- `Sources/RivetPRReaderHarness/main.swift`
- `Sources/Presentation/PRInbox/InboxHeader.swift`
- `Sources/Presentation/PRInbox/InboxHeader+Previews.swift`
- `Tests/RivetPresentationTests/InboxHeaderTests.swift`
- `scripts/check-swift-format.sh`
- `.swiftlint.yml`

### Written

- `analysis/rivet-login-ui/requirements.md`
- `analysis/rivet-login-ui/technical-spec.md`
- `plan/rivet-login-ui/rivet-login-ui.plan.md`
- `plan/rivet-login-ui/rivet-login-ui.step.md`
- `prototypes/rivet-login-ui/Rivet-Login-Dark.png`
- `prototypes/rivet-login-ui/Rivet-Login-Light.png`
- `prototypes/rivet-login-ui/Rivet-Login-OAuth-Dark.png`
- `prototypes/rivet-login-ui/Rivet-Login-PAT-Dark.png`
- `prototypes/rivet-login-ui/Rivet-Login-Prototype.html`
- `prototypes/rivet-login-ui/Rivet-Login-Spec.md`
- `prototypes/rivet-login-ui/RivetLoginView.swift`
- `Sources/Presentation/Login/RivetLoginPresentation.swift`
- `Sources/Presentation/Login/RivetLoginView.swift`
- `Sources/Presentation/Login/RivetLoginArtwork.swift`
- `Sources/Presentation/Login/RivetLoginView+Previews.swift`
- `Sources/Presentation/Resources/Login/GitHubMark.pdf`
- `Sources/RivetLoginDemo/main.swift`
- `Sources/RivetLoginDemoRuntime/LoginDemoHost.swift`
- `Sources/RivetLoginDemoRuntime/LoginDemoModel.swift`
- `Tests/RivetPresentationTests/RivetLoginPresentationTests.swift`
- `Tests/RivetLoginDemoRuntimeTests/LoginDemoModelTests.swift`
- `docs/presentation/login-ui.md`
- `plan/rivet-login-ui/evidence/verification.md`
- `plan/rivet-login-ui/evidence/welcome-light.png`
- `plan/rivet-login-ui/evidence/welcome-dark.png`
- `plan/rivet-login-ui/evidence/waiting-dark.png`
- `plan/rivet-login-ui/evidence/token-dark.png`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.json`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.html`
- `docs/presentation/diagrams/rivet-login-ui/BUILD.md`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.json`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.html`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.1440x900.light.png`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.1440x900.dark.png`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.2048x1320.light.png`
- `docs/presentation/diagrams/rivet-login-ui/login-lifecycle.visual-check.2048x1320.dark.png`

### Modify

- `Package.swift`
- `README.md`
- `docs/architecture/README.md`
- `Tests/GitHubIntegrationTests/StaticIsolationTests.swift`

`Package.swift` 只新增 Demo executable／runtime／其 test target 及 Presentation resource processing，維持 macOS 15、Swift 6 與既有 dependencies。`README.md`／`docs/architecture/README.md` 僅在驗證後補已交付能力、責任與限制。

### Deleted

None。

四組兩兩互斥；ReadOnly／Modify 在固定 baseline 存在，36 Written 在該 baseline 均不存在。Written 的 baseline 分類不因本次建立四文件而改為 Modify。不得使用 glob、directory-only allowlist 或未列 repo 路徑。Repository 外 scratch／工具 caches 不屬交付；禁止將其放進 staged diff。若需額外 repo path，停止並回 planning，不自行擴張。

## TestCase

每項保持 stable ID，證據寫入 `plan/rivet-login-ui/evidence/verification.md`；不能以 build／test 成功取代人工可觀察結果。Native contract 只採用本 capability 對應的共通原生／accessibility rows，不引入 Inbox／Reader 專屬 workflow。

| ID | Context／trigger | Observable expected result | Evidence method | Contract trace |
| --- | --- | --- | --- | --- |
| LU-01 | 780×500 主視窗，依序顯示四 PNG 對應畫面。 | 雙欄、字階、間距、品牌、dots／vignette、靜態 diff 接近來源；差異限已列展示／系統項目。 | 四份列入 Written 的原生截圖與參考 PNG 並列；記錄尺寸及差異。 | Native contract §7／8／13；四 PNG。 |
| LU-02 | 假 GitHub／PAT 成功、失敗、取消、Retry、Reset；另送 stale／重複 intent。 | 七態可達；不重複啟動；取消無 error；connected 停留；沒有外部呼叫。 | `LoginDemoModelTests`＋原生實際操作。 | §2／11／13；AC-NI-030。 |
| LU-03 | PAT 空白、外圍 whitespace、非固定 prefix、Show／Hide、submit、Back、token failure。 | 空白不能送；只 trim 外圍；不驗 prefix；顯示切換保留文字與編輯 focus；送出／離開清除；failure 仍可重填表單。 | `RivetLoginPresentationTests`＋原生操作；證據不保存輸入值。 | §3／10／13；素材 Spec §4 PAT。 |
| LU-04 | System／Light／Dark、主窗 active／inactive、Increase Contrast。 | 外觀依系統或展示設定；品牌兩態深色；focus／disabled／error／success 不只靠顏色。 | 原生檢查，記錄實際系統條件。 | §7／10；AC-NI-026／035／036。 |
| LU-05 | Demo局部13／17／21 pt、780×500 pt最小content與增大視窗；Reduce Motion。 | 右側heading／欄位／按鈕／說明／error／footer真字級依同一比例放大；無遮擋／截斷；footer及核心操作可垂直捲動到達，無水平捲動；非必要動畫不延遲狀態／focus。 | 同一point-size入口的Preview與host原生實看；記錄有效字級／比例、視窗尺寸、binary SHA。不能用Dynamic Type／系統13或15點未生效的操作當大字pass；系統偏好整合未交付。 | §8／10；AC-NI-028；PC-03。 |
| LU-06 | 真PAT submit、Welcome→waiting、browser Retry→waiting；Keyboard／VoiceOver逐態與快速離開回歸。 | 無需手動進scroll area即可理解當前狀態；PC-06 waiting由Cancel焦點label同時提供等待狀態及取消動作，不另post；其他phase通知路徑不變。Cancel／Escape與既有focus落點可用、無明顯雙讀／過期focus；label／heading／disabled與裝飾reading order不回歸。 | Tester核新版link role／label／focus與Cancel／Escape；Human逐項親聽Welcome及Failure Retry兩真waiting入口，不以Controls直切／AX／背景送鍵／build代聲音。PAT舊兩次無聲、probe／HC-05有聲及HC-02通過各留源，大字Human／rapid與未補驗項pending。 | §3／7／10；AC-NI-026／030；PC-03／PC-06。 |
| LU-07 | Source／dependency／copy／path review。 | 無真登入、network、Keychain、persistence 或外部 help 副作用；文案明示模擬；既有 BC／兩驗證 App 不變；所有變更限 exact paths。 | 獨立 Reviewer 核對實際 diff、imports、manifest、provenance。 | §1／2／11／13；AC-NI-030。 |
| LU-08 | bounded 自動驗證、target graph 同步及 native host 啟動。 | focused／root tests、demo debug／release build、format 成功；StaticIsolationTests 僅同步新增 Demo product／三個 targets 的 expected sets，所有 GitHubIntegration 隔離斷言不變。Root strict lint 如實記錄非0，Tester 核對 baseline 舊 findings 無回歸、原素材 SHA 未改及新增 production／tests scoped strict 0；不得為全局0修改 experiments／原素材。GUI 獨立分類，不把啟動成功當原生驗收。 | Tester 獨立跑計畫命令、targeted StaticIsolationTests、baseline／current lint 與 scoped strict 比對、verification matrix；root test 未重跑前不得宣稱修復，root lint 不冒 pass。 | §13；LU-01～07；既有 GitHubIntegration isolation contract。 |
| LU-09 | Graphify availability／revision 檢查。 | 有可用圖時 bounded query 後 source 核實；無圖／過期／失敗則 targeted reads；沒有建圖、refresh、stamp／config／hooks 等額外 repo 輸出。 | 記錄 pinned invocation 或具體 fallback 原因與 source locations。 | Graphify local skill；Human 工具要求；§13。 |
| LU-10 | 七態 lifecycle 的 diagnostics 修正、交付及視覺檢查。 | 與 state model 一致；Showcase 9/9、0 errors／warnings。Objective error count 創最低值時續修，連續兩輪未改善最佳值才停止。Perceptual correction 最多兩輪；修改 candidate 後重跑 validate／deliver／hash 核對／exact HTML 取證及實看。四尺寸 containment、light／dark 實看及未解問題如實記錄。 | 新版 receipts、spec／HTML SHA、九份列入 Written 的圖檔／sidecars、BUILD 中分開的修正紀錄及 `correction_rounds: 0|1|2`；獨立 review。 | Archify delivery contract；Human 工具要求；§13。 |
| LU-11 | 實作後 bounded diff 與真 base／head commits。 | 未有真 head 前直接 review 並將 map 標 pending；真 SHA 到位才產圖。使用 pinned validate／render、適用 overlay，全程外置；不把 map 當 correctness approval。 | Reviewer 核對實際 diff／SHA、外置 graph／manifest；verification 記錄結果及限制。 | PR Lens local skill；Human 工具要求；§13。 |

## PR-02 後 Implementer handoff

Dispatcher正式交接PR-02 approved、無required fix。只對新增第4Modify測試檔增加2行expected-set entries，保留equality／隔離assertions；focused10／root284pass。圖面第1輪9/9／四尺寸／四圖實看自驗pass。Native最後fresh CUA仍cgWindowNotFound，停止重試交Tester；四份nativePNG仍pending，IM-01不宣稱全部completion condition完成。


## TE-01 獨立 Tester handoff

2026-10-22：親跑自動與baseline比較已完成，沒有production／test修改。原生主窗／controls的CGWindowList證實存在且onscreen；CUA選窗長阻塞與screen-capture preflight=false使最新圖及互動不可取證，未索取新權限／改設定、沒有證實sourcebug。Verdict為partial verification，沒有全部passed；LU-01～06 native branches及LU-11仍pending，交Reviewer判斷交付與Human檢查停點。PR Lens留真commit後，不以map替代review。


## RV-01 P2 bounded diagram fix handoff

2026-10-22：Dispatcher明示RV-01 needs-rework，只有PAT failure送出edge一項P2；source／tests沒有required fix。Implementer已回修 `failed→checking` 與 `token：重填後送出`，七態不變；第2輪完整validate／deliver／samebytes核對／四尺寸visual-check與新版四圖實看自驗pass，最新hash見BUILD。未改source、未重跑Swift、未再操作CUA。TE-01 partial verification與Native四圖／操作／AX pending保持。現交Tester核新圖，再交Reviewerclose，不由Implementer宣告gate通過。perceptual兩輪額度已用完。


## TE-02 新版圖證據複核

2026-10-22：TE-02 completed／passed，僅核對 RV-01 P2 回修後 lifecycle。token-retry 已是 failed→checking／「token：重填後送出」，與 model 一致；親validate9/9、0errors／warnings，新spec／HTML SHA與BUILD／receipt一致，四尺寸receipt與四張新版明暗實看pass。無Swift／CUA／deliver／新capture／凍結圖修改；TE-01自動pass及nativepending保留。Reviewer P2 close與整體verdict仍待獨立處理。


## IM-02：topic commit／push 準備

Dispatcher已交接正式RV-01 `approved`，唯一P2圖契約修正closed，沒有其他required fix；此approval供bounded code／evidence的Draft交付，不表示Native完整驗收或Human採用。TE-01自動驗證與第2輪Archify新證據已獨立核對；四份Native PNG、互動與AX仍pending，不建placeholder。

IM-02進行中：核對feature branch與固定base、dev仍dev且clean；實際32個Written＋4個Modify共36檔，無ReadOnly／其他topic變更。依Human已明示的直接topic commit／push授權，stage後仍檢查單一語意與message `feat(presentation): 新增原生登入畫面與假資料展示`；本紀錄尚未宣稱commit／push成功或填SHA。PR Lens及Draft PR留後續正式交付，不merge／release。


## 本地交付收尾／公開發布確認停點

Code commit `98f057324419d33926850d926483080c3f3ca633`已完成36檔與全部hooks，feature clean；dev仍dev且clean。依Human原「commit by topic→push→Draft PR」指令嘗試push兩次，但autoapproval均在命令執行前拒絕。既有origin已核對public `a129924/rivet`、owner同名、ADMIN／push權限，第二次仍要求明確將本topic程式／測試／使用者原始素材／文件與圖面公開至此repo的Human確認。這是工具審核的額外要求，不抹掉原授權；沒有第三retry或換通道，遠端feature branch不存在，noPR。

PL-01獨立Reviewer本地map已完成，真base14d0832→codehead98f0573；pinnedvalidate／render exit0，external symbolic path與contentHash詳verification。Reviewer只核source／manifest／SVG XML labels，未做raster視覺review；map不包含本次兩檔metadata收尾，不假稱final-head provenance。

本次只更新verification／step，按既有topic commit授權建立本地docs metadata commit，不push／remote／PR；不在自身文件預填該commit SHA。Native四PNG／互動／AX及Human最終採用保持pending。


## TE-03 handoff（2026-10-22）

- TE-03 completed-needs-rework：四份已列Written的真PNG均1560×1064px、已實看；主要七態／PAT／明暗／resize與AX結構已驗。前輪capture=false／CUA阻塞保留為歷史，本輪preflight與AX查詢已可用。
- 唯一已確認required fix：Show／Hide切換後valueLength保持、secure旗標正確，但實際focus由AXTextField失去到AXWindow；精確復現與View對應位置見verification TE-03。交獨立Implementer既有View內bounded修正，Tester不得改production。
- Target-PID Return成功、Escape兩次未取消而AXCancel正常，列待調查觀察，不先當已鎖sourcebug。KeyboardUIMode0、app後續失active使Tab完整traversal未定；VoiceOver／大字／IncreaseContrast與ReduceMotion啟用條件pending，未改全域設定。
- Human已明確補公開payload授權，舊auto-review拒絕是歷史；push／Draft暫待focus修正回歸，由Dispatcher續行。既有code／PL-01 map與root284等證據保留，不冒稱本輪重跑或Human採用。
- 本輪只寫4PNG、verification與step，沒有production／tests／commit／push／PR；外置helper／logs不入repo。最後主窗回780×532frame、Reset welcome，程序保留。


## IM-03 handoff（2026-10-22）

TE-03 Show／Hide focus required fix 已在既有 View 內 bounded 回修；不同私有欄位 identity＋可取消 task 在 yield 後轉交焦點。立即 task 的 attempt 1仍 red，最終 attempt 2真 AX 自驗 secure／visible／secure 全 focused、值長保持，完整限制見 verification。Focused10／root284／debug／release／format／唯一 source scoped strict 自驗皆 exit0；沒有修改 Host／Escape mapping、public API、tests 或其他產品行為。最新既有 wrapper PID36729、Welcome；四份原生 PNG 保留 TE-03 歷史，待 Tester 最終 source 回歸與新截圖。此為 Implementer 自驗完成、獨立 Tester／Reviewer pending，不自行清除 required fix 或放行 gate；未 commit／push／PR。


## TE-04 handoff（2026-10-22）

- Tester最終source獨立native回歸passed：Show／Hide四次及rapid4均保值、AXFocused=true／AXTextField；Back／Reset／submit離開後無殘留textfield或task拉回，重進空白hidden且focus=true。Source／binary SHA、精確限制見verification TE-04；required fix close交獨立Reviewer，不代判gate。
- Canonical private CGEventSource、flags0、Unicode13／27與keyCode36／53兩組Return→waiting／Escape→welcome成功；TE-03舊觀察保留，不推導舊產品keyboardbug。沒有改Host或keyboard mapping。
- 新binary正式4PNG均780×532px（1×，780×500content＋32chrome）且實看對照，無resample；TE-03舊hash保留歷史。其餘特殊系統條件／VoiceOver／完整traversal仍pending，未改global setting。
- Human已明確native驗收與公開payload至`a129924/rivet`、Draft base `dev`授權；舊拒絕保留，但不再列缺Human回答。尚未commit／push／PR，下一步獨立Reviewer，再由Dispatcher依授權交付，最後Human成果review。
- 本Tester只改verification／step及4PNG；既有View變更屬IM-03，不由Tester改動。未新增repo路徑、工具安裝、重跑Swift或產圖。


## RV-02／IM-04：正式審查後公開交付準備（2026-10-22）

Dispatcher正式交接RV-02 `approved`、required fix `None`；TE-03 focus defect closed。TE-04最終source／binary／新版四圖與focus／departure／canonical鍵盤bounded驗證通過，其他Human條件仍pending。Human已直接明確同意程式、測試、原始素材與文件圖面公開推送到public `a129924/rivet`，並建立base `dev`的Draft PR；舊拒絕不是目前欠缺Human授權。

Implementer本輪只準備stage既有View、verification／step與4真PNG共7檔，依staged diff核對單topic並採`fix(presentation): 保留 PAT 顯示切換後的輸入焦點`；完整hooks、正常非force只push feature branch。七原始素材／frozen圖／resource未改，dev worktree唯讀核clean且外部HEAD613a505，不rebase／merge／改dev。本紀錄不預填新SHA、push或PR成功；PR由Dispatcher後續建立，Human成果採用仍pending。


## GH-01／PL-02 收尾與Human boundary（2026-10-22）

IM-04 source commit `6fc18b3c040997155d84ca85abba48abc1a61d6c`已正常公開push且ls-remote同SHA；完整hooks passed。Dispatcher已建立並attach [Draft PR #66](https://github.com/a129924/rivet/pull/66)，draft=true、base dev建立時SHA613a505，source head6fc18b3；未merge／release。PL-02已依真PR base與source head完成本地map，三點merge-base14d0832／40files，pinned validate／render0，23file refs exactsource核對；完整hash／外置位置見verification。Map只含source6fc18b3，不冒稱本輪後續metadata head，僅XMLlabels核對未raster實看。

目前Human review／HC-01pending。RV-02 approved／required fix None、focus defect closed與TE-04 bounded pass保持；公開payload授權不等於成果採用。完整traversal／VoiceOver朗讀、大字、IncreaseContrast／ReduceMotion啟用條件仍pending。本輪只更新verification／step，不改code／tests／四PNG／Archify，不重跑GUI或產圖；最終metadata commit不在自身回填SHA。


## HC-02：Human partial／needs-rework 交接（2026-11-04）

以主對話Human完整交接為來源，2026-11-04僅是交接／正式回寫日，不補造每項操作時間。受測binary SHA `1009d4464106663e8ab554082ef7faea9d79adf80474f9a65c7677845731b873`；暫存App包遺失已修復、使用相同執行檔重啟後驗收，交接側無source／Git改動。本輪只回寫verification／step，不改其他三份正式contract、source／tests／素材／PNG／圖面，不commit／push／改PR或操作UI／系統設定。

七類Human通過與適用範圍詳verification HC-02。新needs-rework僅三缺口：PAT verifying自動只讀scroll area；waiting由Welcome只讀展示版無法連接說明、由失敗重試只讀footer；13／15點Codex變大而Demo不變，大字未驗。失敗宣告初次state未確認且工具讀Welcome／後重跑Human正確失敗訊息通過，兩者均保留，不推論偶發bug。CapsLock＋方向鍵／CapsLock＋Shift＋↓為Human操作；背景送鍵沒有朗讀不作產品缺陷證據；原生spinner旋轉只列觀察。

依Human交接已還原文字大小預設，增加對比／減少透明度／Reduce Motion／VoiceOver均關閉；Demo System／Welcome、shouldFail off、failure origin Browser。舊focused10／root284／debug／release／format／scopedlint／hooks只保留原來源，本輪未重跑；rootstrict非零。HC-01維持pending與尚未全面通過；先EX-01調查，再依證據交IM-05／TE-05／RV-03，不預填任何新設計、通過或approval，不重開鎖定決策，無merge／release授權。

## PC-03：EX-01調查後的最小planning delta（2026-11-04）

Explorer已明示planning sufficiency approved；焦點／宣告同步及共用Bool只是source支持的可信候選，尚未native證明唯一root cause。Apple Dynamic Type在macOS不影響文字大小的限制已寫technical-spec；原ScaledMetric與大字Preview不算system integration或大字pass。

本輪只修四正式planning文件，鎖定掛載後phase對應的可取消focus／去重宣告，保持waiting Cancel、verifying／connected status heading等既有落點；並採Demo局部13／17／21 pt真字級。公開init唯一增量bodyPointSize預設13置onIntent前，finite clamp13...21／非finite回13；改字級不清PAT或改form identity，Reset保留字級。右側文字同比放大，左側裝飾固定且AX隱藏，Preview同真入口。這是LU-05可重現測法，macOS系統文字大小偏好整合未交付。

ReadOnly10／Written36／Modify4／Deleted None不變、不新增repo path；實作限plan PC-03所列既有檔案，七原素材／凍結Archify不改，Graphify與本地PR Lens原工具契約保留。先獨立PR-03明示approved，再IM-05→TE-05→獨立RV-03；成果approved後沿既有staged邊界／message、topic commit／正常public push及Draft PR66更新授權，不merge／release。新版三真入口需Human親聽，大字需有效13／17／21 pt實看，HC-03逐項等回報；AX／舊binary pass／Controls直切不能替代。


## IM-05：PR-03後bounded source交接（2026-11-04）

Dispatcher正式交接獨立PR-03 approved／required fix None後，已完成phase-specific、可取消的focus／announcement分序與await後stale檢查；bodyPointSize預設13、finite clamp13...21／非finite13，Demo局部13／17／21真font、改size保留form／Reset保留size、Preview及長期docs同步。未改七態／intent／BC／manifest／原素材／四PNG／凍結圖，未新增repo檔。自驗focused15／root289／debug與release／format／scoped0通過，rootstrict39非0；首red與中途lint修正、精確source／binary SHA與logs見verification IM-05。

本輪不操作UI／VoiceOver／系統設定、未改既有wrapper，仍是原binary。交TE-05核新binary、三真入口AX／focus與13／17／21 pt實看，再RV-03；HC-03必須Human逐項等待回報，AX／unit／build不冒聲音pass。HC-02原七類pass與三缺口原文保留，HC-01／HC-03 pending；未stage／commit／push／改PR或跑hooks。


## TE-05 handoff（2026-11-04）

本Tester親跑focused15／root289／debugrelease／format／scoped136files0／diffcheck0，rootstrict39=舊experiments37＋原樣prototype2，九個finding files與七原素材均與HEADbytes相等。Source／binary SHA凍結核對通過，舊Demo由主對話Tester CUA正常Quit後才換既有wrapper；沒有替代UI技術。

主對話Tester CUA完成真PATsubmit、Welcome→waiting、Retry→waiting與Cancel／單步Escape、Show／Hide持續編輯／清除；13／17／21×五畫面真字級及垂直scroll可達。本Tester獨立實看18外置rawJPEG（原錯`.png`僅rename`.jpg`、bytes不變，1560×1064含CUA白padding），沒有改原四canonical PNG來源。工具批次rapid送鍵結果無法判定，不當pass或產品bug；VOoff不當聲音／targetfocus成功。

TE-05為completed／partial verification，執行項目無新required source fix觀察，交獨立RV-03判source與證據；HC-02七類舊pass留源，三缺口的Human朗讀／新版大字親驗、rapid回歸與HC-01／HC-03 pending。最終System／Welcome13、failure off、Browser origin，Controls關閉可⌘0開；沒有改全域設定。本Tester只寫verification／step，不改source／tests／contract／PNG，不stage／commit／push／改PR。


## RV-03後交付準備（2026-11-04）

Dispatcher正式交接獨立RV-03 approved／required source fix None；TE-05 partial證據與HC-02舊七類pass完整保留，三缺口及HC-01／HC-03不closed。只收尾verification／step目前摘要，不改凍結source、tests、docs或圖像bytes；依Human既有直接topic commit與具體public payload授權，核精確13檔單topic diff與message後保留完整hooks，正常push feature，不動dev、不force／rebase／merge／release。此處未預填新SHA／成功；PL-03仍pending，交真source commit後的獨立Reviewer，PR操作留Dispatcher。


## IM-06／PL-03交付後Human停點（2026-11-04）

Source9f8955c已完整hooks commit／正常公開push、ls-remote同SHA，獨立PL-03已完成並明確bounded此code head；真base／merge-base／hash／外置路徑與實看限制見verification。Draft66 targetdev仍待Human review，三真入口聲音／真正大字Human／rapid未closed；HC-02七類舊pass留源，HC-01／HC-03 pending。此輪僅兩metadata，不改source／圖像，不重跑Swift／native／產圖，不merge／release或回填自身SHA。

## PC-04：一次觀測的planning delta（2026-11-04）

EX-02明示planning sufficient approved僅足夠一次bounded runtime觀測，尚不足選定已證修法。HC-03 PAT兩次無聲、各次CUA verifyingToken、第二次後VoiceOver on與Human補充「有，其他項目會朗讀」一併保留；不回推首次或前兩次原因。
PC-04只鎖定View內可關閉的DEBUG／OSLog有限allowlist觀測、外置trace及PR-04→IM-07→TE-06→HC-04一個真前景PAT Return流程；logger會影響timing，post不證聲音、mainWindow不證own View附窗／AX ready。未到post、post到但條件未知、條件足仍無聲的後續修法／單變數probe均須依新證據另路由，非本delta預准。
四文件以外未寫；原pathsets／公開字級契約／七態／工具契約不動，waiting／大字Human／rapid仍pending，HC-01／HC-03尚未全面通過；本完成不是自審approval。


## IM-07診斷版交接（2026-11-04）

PR-04正式approved後僅既有View加DEBUG有限notice追蹤，保留第一guard／onChange／focus／通知API及priority／yield數；私有helper留同檔同View。自驗focused15／root289／debugrelease／format／scoped0／diffcheck通過，release無獨特probe marker；不是功能修補。精確source／binary SHA、外置logs與trace predicate見verification IM-07，HEAD仍9dd80ea、working diff未commit。

交TE-06核trace可讀與敏感欄位／新來源後，由主對話CUA準備HC-04最多一次Human前景PAT Return；本輪未啟UI／替換runningwrapper／改VoiceOver或全域設定，case未使用。其他項目Human有聲與兩次PAT無聲並存，三缺口與HC-01／HC-03仍pending；post／window條件不當朗讀或AX-ready證據，未知保持unknown，再依runtime證據路由，不預准下一修法。


## TE-06 preflight handoff（2026-11-04）

TE-06 completed／partial verification：logging-only／敏感欄位source核對、focused15／root289／debugrelease／format／scoped136files0／diffcheck0，release marker缺席皆完成。舊wrapper由主對話CUA正常Quit，本Tester確認process結束後換probe／resources核SHA；主對話再以CUA準備Welcome→PAT entry假輸入，沒有Return。

精確Unified Log predicate最近5m可讀，PID46623共20筆welcome／tokenEntry，payload allowlist及有限值schema0errors；無guard-return／post／verifyingToken。沒有post符合兩phase不宣告的source，不能據此推submit返回原因。最末main／key／active／VoiceOver布林true不證own View附窗／AX-ready／聲音；原JSON及hash只外置，詳verification。

交獨立RV-04核code／probe後才HC-04一次Human前景Return；本輪HC-04 0／1、三缺口及HC-01／HC-03未closed，不預准下一功能修法。本Tester只寫verification／step，未改source或執行stage／commit／push／PR。


## HC-04結果交接（2026-11-04）

Human唯一前景Return回「讀出驗證中」，預算1／1已用；Tester獨立核34筆／PID46623／finite schema0error，同correlation90309595…於15:55:03完成post前後、無early return。後續AX binding分時記錄，不當聲音機制／own AX-ready證明；working source98bb／probe18c／HEAD9dd未變。舊兩次9a failed無trace仍cause unknown、1009d七類pass保留；logging可能改timing，不當功能修法。三缺口、waiting兩入口／大字Human／rapid及HC-01／HC-03未closed，交獨立Reviewer分類，不新case或Git發布。

## PC-05：移除自身探針後的單次正常對照（2026-11-04）

Reviewer正式結果處置approved／required source fix None，本次不支持功能修法；HC-04 34筆同PID／唯一post前後各一、Human有聲及24h採集偏差均保留來源，不證AX-ready／聲音機制。先封存探針與trace hashes、hashguard後只還原View原bytes，再獨立核正常版source／marker／新實測binary，依PC-05流程取得Reviewer放行後才交HC-05一次真前景Return。
HC-04 completed-observed／1of1 used不重用；HC-05 pending／0of1為新正常版對照，非修法驗收預准。前兩次正常版failed與原因未知保留，單次有聲不證穩定修復；waiting二入口／大字Human／rapid仍pending、HC-01／HC-03未全面通過。僅四文件planning delta，不寫source／verification／UI、不跑build或Git發布。


## TE-07交接（2026-11-04）

正常版preflight partial完成：七Swift等於HEAD9dd／source9f；probe雙份20件與manifest193805…完整核對；新normal EA297d／FE886c及wrapper無marker、resources相同。獨立focused15／root289／debugrelease／format／scoped1360／diffcheck通過，舊rootlint39非pass。主CUA正常換版後僅停PATdummy14字元／entry，HC-05 0／1；待RV-05後才唯一Human前景Return。HC-04預算已用、舊failed／有聲與採集偏差不改，不判logging因果／穩定修復，三缺口及HC-01／HC-03仍pending。本Tester只寫verification／step，不改source／tests／圖或Git發布。


## HC-05正常版結果交接（2026-11-11）

Human在明確正常版Return步驟後回「讀出驗證中」，CUA僅核既有app已verifyingToken；HC-05 completed-observed有聲、1／1已用，聲音非AX推定。親核normal EA297d／View89cb／published9f bytes及HEAD9dd未變，無probe marker／正常post trace。舊failed／同句無新送出證據歷史、HC-04及七類pass留源，一次有聲不證穩定修復／logging因果；待獨立Reviewer處置，HC-01／HC-03與其他缺口pending。主對話後續只Reset至System／Welcome13、Browser／failure0、primary focus，尚未觸發新waiting case。本Tester只寫兩metadata，無UI／build／test／source或Git mutation。

## PC-06：waiting焦點label最小delta（2026-11-11）

Explorer明示planning sufficiency approved／required None，只支持既有Cancel焦點的狀態語義修補，不證歷史root cause；本delta只改四planning、未實作或自審。PC-03／LU-06已明確waiting改採 `Waiting for simulated authorization. Cancel sign in.` focus label且不另post，其他phase不變；兩真入口仍需Human逐項補驗。
PC-06→PR-06→IM-09→TE-08→RV-06；唯一source View與既有長期說明／證據，其他paths／API／字級／七態／工具不擴。準備正常新版wrapper才交Human，不在Implementer階段動running app；沿既有code review後topic Git／Draft交付授權，PC-05對照不發布限制不擴套，無merge／release。HC-05正常PAT observed有聲1／1與舊failed／probe留源，HC-01／HC-03、大字Human／rapid仍未全面通過。
