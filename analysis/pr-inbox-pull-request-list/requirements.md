# PR Inbox / PullRequestList：Requirements

## Mission 與依據

- Topic slug：`pr-inbox-pull-request-list`；owner：non-BC `RivetPresentation`。
- Goal：交付可獨立 build、test、Preview 與 Human Review 的原生 macOS SwiftUI `PullRequestList`，重用已採用的 `PullRequestRow`，提供單選、List 焦點、鍵盤選取與安全的 Open PR intent。
- 依據：使用者已核對的對話版正式計畫與 Minor 調整、`docs/presentation/native-interaction-contract.md`、已採用 Row 的 Human amendment。對話版計畫只授權正式文件編寫；只有獨立 Plan-Reviewer 對本四份文件明示 `approved` 才能進實作。
- 工作區：Human/operator 已從乾淨的 `dev` 準備專用 worktree；branch 為 `codex/pr-inbox-pull-request-list`，HEAD/local `dev`/local `origin/dev` 為 `4ba15ae`，branch 唯一 attach。Plan-Creator 不執行 Git。

## Goal／In-Scope

- 原生 `List(selection:)` 呈現有序且 ID 唯一的 `PullRequestRowPresentation` 集合，使用已採用 Row、原生單選外觀與輔助使用語意。
- Presentation parent 持有 selected PR identity，List 管理自身選取與焦點互動；Up／Down 使用原生行為，焦點在 List 時支援無 modifier 的 Home／End／Enter。
- 單擊只選取。Enter 或雙擊只對目前仍存在、已選取且 `canOpen` 已確認安全的 ID 發出一次 `onOpen` intent。
- 提供 debug-only Preview：六筆標準資料、已選列、Open intent ID／次數、窄寬、長清單、焦點返回，以及可操作的 missing／nonselected／unsafe Open guard probes；另有 inactive selection 與 Increase Contrast 檢查入口。加入受限 Swift Testing 與 Human Review 證據。

## Non-Goal／Out-Of-Scope

- 不修改 `PullRequestRow` 或 `PullRequestRowPresentation`；不另建重複 Row DTO、generic UI 架構、production mapper、Domain/Application/Integration 邏輯、網路或持久化。
- 不建立 Inbox workspace、sidebar、header、filter、loading/empty/error/offline、Reader 或 workspace 導覽；List 只發 intent，不建立 Reader state。
- 不加入 PR row context menu；現行 contract 的 context `Open` 為 MAY。不建立 app menu counterpart；完整 Inbox 的該 MUST 由未來 owning composition 履行，本次不宣稱端到端 command 驗收。
- 不自行定義首列選取、stale identity replacement 或 filter policy。完整 Inbox 初次 content、無效選取、Reader 返回列消失的首列 fallback 仍屬未來 parent 的 F-01／content matrix／F-15 責任。
- 不擴張 BC、Package graph 或產品能力；不自動 commit、push、PR、merge、release、tag，亦不開始下一個 Inbox 元件。

## Selection 與 Open 成功條件

- 有效 selected ID 仍在新 collection 時，保持同一 ID；已選 ID 消失時清為 `nil`，不替換成其他 PR；初始 `selection == nil` 時保持 `nil`；空集合無有效選取。資料或選取更新不自行搶焦點。
- 單擊任何列只改單選，無 Open intent。初始未選列雙擊時，原生首擊先選中該列，再對同一 selected ID 恰發一次 intent。
- 啟動時 ID 不存在、不是目前有效 selection 或 `canOpen(id) == false`，Open 必須 no-op 且保持 selection 與 focus。`canOpen` 的 true 由呼叫端保證 Open capability 與 action safety 均 known-safe；未知即 false。
- 原生 Row title 固定單行 tail truncation、次層 identity、逐級 metadata 收斂不變；List 不產生水平捲動，長清單可垂直捲動。

## Acceptance 與 Human Boundary

- `plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.plan.md` 的 PL-01～PL-06 為 TestCase register；每項含 trigger、可觀察結果、證據與 adopted contract trace。
- Debug／release build、focused 與 root tests、static isolation 與 exact path review 均須通過。Swift Testing 證明三種 Open guard 的純判定；Human 用 Preview 驗證單擊／雙擊／Enter 的原生事件，並以 debug-only probes 觀察 missing／nonselected／unsafe 時 intent 次數不增加、selection／focus 不變。Human 另用 inactive／Increase Contrast Preview 變體、鍵盤、VoiceOver、窄寬與長清單檢查 PL-02、PL-03、PL-05；自動測試不能代替互動證據。
- Tester 完成後交獨立 Reviewer；只有 Reviewer 明示 `approved` 才進 Human Review。Human 明示「採用／調整／放棄」後停止，不自動開始下一 Mission。

## Workflow Truth

Current workflow truth 以 `plan/pr-inbox-pull-request-list/pr-inbox-pull-request-list.step.md` 為準；所有 planning／implementation／testing／review findings 與 handoff 歷史均保留於該 ledger，不再把歷史中間狀態描述為 current gate。

HC-01 completed：HR-01～HR-07 pass，Visual／structural pass，Long List internal vertical scrolling pass，VoiceOver pass；固定 x 逐列單擊 finding 已 withdrawn／not reproduced。Human decision 原值為 `採用 PullRequestList`。PC-10 completed；獨立 Plan-Reviewer PR-03 明示 `approved`（Findings：None）。Topic／Mission completed／stopped，Current Step=`None`，Next Action=`Stop`，不得自動開始下一 component。PR #41 已 Ready；這是外部交付狀態，不重開既定 scope／contract、Human acceptance 或新增 capability。
