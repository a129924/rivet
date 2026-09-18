# Auth 子系統責任重定義：技術規格

## Decision Status

本文件鎖定 architecture decision，而非 Swift implementation specification。
adopted target 是 Model C；現行 source 的 Model A 仍是 legacy runtime，直到 future
concrete-consumer topic 取得獨立 implementation approval 為止。

## Locked Architecture Contract

```text
caller
  │ original HTTPRequest（所有權保留）
  ▼
AuthRequester ──要求新 flow──────► Auth（factory／strategy provider）
  │                                  │
  │◄── per-execution AuthFlow（新建）─┘
  │
  ├── response input ───────────────► AuthFlow（policy/state）
  │◄── semantic decision ────────────┤  response semantics／retry decision
  │                                  │  no request construction／no I/O
  │                                  │
  ├── retained original request ────► Requester（generic HTTP I/O）
  │◄── raw HTTPResponse ─────────────┤
  │
  └── deferred refresh dispatch ────► deferred refresh I/O boundary
                                        （未命名、未鎖定；不由 AuthFlow 直接呼叫）
```

- `Auth` 的 contract 是在每個 `AuthRequester` execution 開始時建立並回傳一個獨立
  `AuthFlow` 的 factory／authentication strategy，不是 credential store、HTTP decorator
  或 I/O component。它不取得 caller original request 的 ownership。
- `AuthFlow` 擁有 per-execution authentication state、response-to-next-decision
  transition、refresh eligibility、retry limit 和 terminal decision。它可以讀取
  `HTTPResponse`，包括 401 semantics；這不是 request construction 或 I/O authority。
- `AuthRequester` 擁有 original request 的 lifetime 和 semantic action
  interpretation。它不得重訂 retry policy，也不得把 caller request ownership
  交給 flow；它只保有 caller original request，**不建構**該 request。selected／decorated
  representation 的 owner／API 維持 deferred；它以 `Requester` 執行該 retained request。
- `Requester` 唯一負責 generic HTTP I/O：接收已選定 `HTTPRequest`，交 transport，
  回傳 raw `HTTPResponse`。它不認識 auth flow、credential refresh 或 retry policy。

## Capability Boundary

Model C 的 type contract 必須最終能表達下列限制：

| Capability | `AuthFlow` target | Owner |
| --- | --- | --- |
| 讀取 401／其他 raw response semantics | 允許 | `AuthFlow` 作為 policy input |
| 決定是否 refresh、retry、finish | 允許 | `AuthFlow`，唯一 policy owner |
| 保有／讀取 original URL、method、query、body | 禁止 | `AuthRequester` 只保有 caller original request |
| 建構或修改 arbitrary `HTTPRequest` | 禁止 | 不授予 `AuthFlow`；exact decoration owner deferred |
| 建構 refresh endpoint request | 禁止 | future refresh I/O component，尚未定義 |
| 執行 transport／`Requester`／`URLSession` I/O | 禁止 | `Requester` 或 future dedicated I/O component |
| 持久化／更新 credential | 禁止 | future credential lifecycle boundary，尚未定義 |

這些 capability 是 future API review 的 acceptance boundary；本 topic 不從中推導
`AuthAction` enum、protocol methods 或 value type。

## Responsibility Matrix

| Role | Owns auth state | Knows HTTPResponse | Knows original request | Builds original request | Builds refresh request | Performs I/O | Controls retry |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `Auth` | 否 | 否 | 否 | 否 | 否 | 否 | 否 |
| `AuthFlow` | 是 | 是 | 否 | 否 | 否 | 否 | 是 |
| `AuthRequester` | 否 | 是，轉交給 flow | 是，唯一 owner | 否；只保有 caller original request，selected／decorated representation deferred | 否 | 否，僅委派 | 否 |
| `Requester` | 否 | 是，raw return | 僅取得待執行 instance | 否 | 否 | 是 | 否 |
| `TokenFetcher` | N/A | N/A | N/A | N/A | N/A | N/A | N/A |
| `TokenProvider` | N/A | N/A | N/A | N/A | N/A | N/A | N/A |

## Legacy and Target Distinction

| Dimension | Legacy Model A | Adopted Model C target |
| --- | --- | --- |
| Flow input | `Auth.makeFlow(for: HTTPRequest)` 授予 original request | exact factory input deferred；flow 不取得 original request capability |
| Flow output | `.send(HTTPRequest)`，可指向任意／多個 request | semantic decision；exact action type deferred |
| `AuthRequester` | generic loop driver | semantic interpreter + sole original request owner |
| Refresh HTTP request | contract 允許 flow 建構 | future dedicated I/O owner，未定義 |
| Retry policy | flow 可透過任意 action 實現，但 type boundary 不限制 work | flow 的明確 state transition responsibility |
| Runtime status | 已實作 | 已採用、尚未實作 |

Model B（restricted HTTP action）未採用，因為它要求現在先選擇 header overlay 與
request-decoration ownership。Model C 保留最小責任決定，延後尚無 concrete consumer
佐證的 representation。

## Flow Topology to Document

### Normal Request

1. caller 將 original request 交給 `AuthRequester`；它是唯一 owner。
2. `AuthRequester` 向 `Auth` factory 要求新 flow；`Auth` 為這個 execution 建立並回傳
   一個 independent `AuthFlow`，之後才開始與 flow 的 semantic send decision exchange；
   factory interface 尚未鎖定。
3. `AuthRequester` 只轉交 retained caller original request 以供執行；它不建構
   original request，selected／decorated representation 尚未鎖定。
4. `Requester` 執行 HTTP I/O，回傳 raw `HTTPResponse`。
5. `AuthRequester` 把 response 交給 `AuthFlow`；flow 作 terminal policy decision。
6. `AuthRequester` 回傳 terminal response；它不自行產生 retry count policy。

### 401 Refresh and Retry

1. initial semantic send 前，`AuthRequester` 向 `Auth` factory 要求 flow，`Auth` 為該
   execution 建立並回傳一個 independent `AuthFlow`；之後的 `AuthRequester ↔ AuthFlow`
   exchange 才開始，且只傳遞 response／semantic decision，不帶 request payload。
2. `Requester` 回傳 401 raw response；`AuthRequester` 將它交給 `AuthFlow`。只有具
   refresh capability 且該 state eligible 的 flow 可在第一次 401 發出 semantic refresh
   decision；不具資格的 flow 可以 terminal，仍由 flow 單一擁有 decision/state。
3. `AuthRequester` 只解讀 semantic refresh decision，交給 **deferred credential-refresh
   I/O boundary**；這份文件不命名 type、不定義 endpoint、payload、credential update
   API 或 refresh-result type。
4. deferred boundary 完成其 I/O 與 credential update responsibility後，將 refresh result
   經 `AuthRequester` 的 deferred result boundary 傳回 flow；沒有 receive→retry shortcut。
5. **只有 refresh-success** result 使 flow 可發出 semantic retry decision；refresh
   failure、ineligible flow 與第二次 401 都 terminal。`AuthRequester` 仍只可重送其
   retained original work，且不自行決定 retry。

401 diagram 不得將上述 topology 畫成 existing runtime，亦不得以圖表建立新的
`TokenFetcher`、`TokenProvider`、`CredentialRefresher` 或 `AuthEvent` public contract。

## Long-Lived Documentation Contract

僅 final replacement Plan Review gate **PR-03** 明示 `approved` 後，獨立 Implementer
可只在以下 paths materialize decision。PR-03 的 `approved` 是此 topic 唯一滿足
「Plan Review approved」條件的 verdict；PR-01 與 PR-02 均為 historical
`needs-rework`，不授權 IM-01。

- 新增 `docs/architecture/rivet-http-client-auth-responsibilities.md`，含 matrix、
  legacy/target distinction、Model A/B/C comparison、recommendation 與 trade-off。
- 更新 `docs/architecture/README.md` 和 `docs/architecture/bounded-contexts/README.md`
  的索引／boundary wording。
- 修訂既有 AuthFlow lifecycle artifact 和 HTTP client package canvas，使其標示 legacy
  runtime 與 adopted target 的差異，而不把 target 說成已交付。
- 在 `docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/` 新增一份
  architecture-canvas component/dependency diagram，以及三份 Archify diagrams：normal
  request sequence、401 refresh/retry sequence、AuthFlow state diagram。

Canvas 只表達 component responsibility/dependency，不表達 runtime sequence。三份
Archify artifacts 只表達 adopted target；所有作者內容為繁體中文。不得發布
artifact.cafe。

## PR #37 Comment-Fix Materialization Contract

此 comment-fix 不改變 Model C。獨立 Implementer 只可在既有 allowlist 內完成下列
修正，並使 source、generated output 與 evidence 一致：

1. canonical responsibility document 的 matrix 改為 `AuthRequester` 不建構 original
   request，只保有 caller original request；selected／decorated representation 仍 deferred，
   不新增 decoration API 或 runtime role。
2. lifecycle、401 sequence、state diagram 由 `Auth` factory 在 initial semantic send 前
   建立 one per-execution flow，並將 `AuthRequester ↔ AuthFlow` 標為無 request-payload 的
   response／semantic exchange；不得畫成 `AuthRequester` 向預先存在的 flow 取得 instance。
3. 401／state 明示 eligible refresh-capable flow 才可在 first 401 request refresh，
   refresh result 經 deferred boundary 回 flow，只有 refresh-success retry；ineligible、
   refresh-failure 及 second-401 terminal。
4. `http-client-package-structure/BUILD.md` 僅可調整固定 build kicker／subtitle 的作者
   arguments，使既有 pipeline 可重現已交付繁中 HTML；enhancement script 和其他 build
   semantics 均為 ReadOnly。
5. lifecycle、401、state 的所有說明性文案必須使用繁體中文：以「request 資料」、「資格」、
   「延後確定」、「更新成功」分別取代 payload、eligibility、deferred、refresh-success
   的解釋；只有 type、protocol、state、檔名等 identifier 可保留英文。

## Validation and Gate Contract

1. Plan-Creator 完成四份 artifacts 後，必須交由獨立 Plan-Reviewer；Plan-Creator
   不得自判 `approved`。
2. PR-03 是 PR-01／PR-02 rework 後的 final replacement approval gate。只有 PR-03
   明示 `approved` 才滿足本 topic 的「Plan Review approved」條件，並授權 IM-01
   寫入 long-lived allowlist。
3. architecture-canvas artifact 必須依 skill 執行 validate、build，並人工檢閱 exact
   light/dark output。
4. 每份 Archify artifact 必須先以 showcase quality validate（完整 9/9 checks、0
   errors、0 warnings），再 deliver；delivery 會 freeze exact source/output。之後須
   以 repository-root visual-check 取得 evidence，並人工檢閱 exact delivered
   light/dark output。
5. TE-01 是 historical `needs-rework`，不是 delivery entry condition。其唯一
   independent replacement verification gate 為 TE-02：獨立 Tester 必須驗證
   changed-path allowlist、`git diff --check`、legacy/target wording、OAuth isolation、
   diagram receipts 與 exact delivered visual evidence，並明示 TE-02 = `approved`。
   此 `approved` 等價於本 topic 的 verification pass。
6. TE-03 是 IM-02 diagram-localization correction 的 independent re-test，必須明示
   TE-03 = `approved`；它不取代 TE-02 作為 TE-01 的唯一 replacement verification
   gate。
7. TE-02／TE-03 `approved` 不改變 AuthFlow state diagram human accepted desktop containment
   limitation 的 non-pass truth；它不得被描述為 visual-check pass。RV-01 的
   `needs-rework` 只回交 verification/delivery wording；Plan-Creator correction 後，
   PR-04 independent Plan-Reviewer re-review 必須 `approved`，才可進入 RV-02。
8. RV-02 的獨立 Reviewer 必須判定 scope／contract／workflow drift，並明示
   RV-02 = `approved`。本 topic 的「無重大問題」只定義為 TE-02 = `approved`、
   TE-03 = `approved` **且** RV-02 = `approved`；不得以單一 check 或未解決 finding
   取代此 gate。
9. 只有上述「無重大問題」條件成立，DL-01 才可依 user-authorized topic workflow 與
   `git-commit-convention` 完成 topic commit、push 至 PR #37；該 PR 現為 OPEN、ready for
   review，這是已完成的 historical delivery gate。
10. PR #37 是 **OPEN、ready for review** 的既有 PR，planning contract 不得改變其 status。
    RV-03 `needs-rework` 的 replacement workflow 是 PC-07 Plan-Creator amendment → PR-07
    independent Plan Review → IM-04 Implementer → TE-05 independent Tester → RV-04
    independent Reviewer → DL-03 topic commit/push to the existing ready-for-review PR →
    CH-02 reply/resolve → HC-02 human review。CH-02 僅可在 TE-05/RV-04 approved 與
    DL-03 completed 後執行：T06 依 supplied evidence
    reply+resolve；T01/T02/T03/T05/T07/T08/T09 要等 corrected delivery visible；T04 要等
    reproducibility fix visible。不得現在 resolve，且不得 merge、release 或開始 Swift
    implementation。

## TestCase

- **TC-01**：future implementation 的 flow unit test 證明 normal response terminal、
  eligible refresh-capable flow 的 first 401 requests refresh、refresh success permits
  original retry、second 401 stops、ineligible flow／refresh failure terminal；本 topic 不新增
  此 Swift test。
- **TC-02**：future compile/API test 證明 `AuthFlow` 無 arbitrary endpoint/request
  construction authority；若未來不採納此限制，必須另開 topic 明確重啟 architecture
  decision。
- **TC-03**：documentation test 檢查 matrix、sequence 和 state diagram 對 decision、
  I/O、state、original request ownership 一致。
- **TC-04**：changed-path／ReadOnly test 檢查無 Swift、package、OAuth dual-client
  lifecycle 或 historical topic 變更。
- **TC-05**：diagram validation/visual evidence 滿足本文件的 skill gate，且 no
  artifact.cafe publication。
- **TC-06**：canonical matrix、lifecycle、401 與 state 的 source/generated evidence
  一致表達 `Auth` factory 先建立 per-execution flow、沒有 request-payload flow exchange
  或 receive→retry shortcut。
- **TC-07**：`BUILD.md` 固定作者參數可重現 package canvas 的已交付繁中 HTML；enhancement
  script 與其他 build semantics 不變。
- **TC-08**：lifecycle、401、state 說明性文案為繁體中文，以「request 資料」、「資格」、
  「延後確定」、「更新成功」取代 payload、eligibility、deferred、refresh-success 的解釋；
  英文限於 identifier。
- **TC-09**：PR #37 維持 OPEN、ready for review；PR-07 至 CH-02 不改 PR status，DL-03
  commit/push 後才可進入 thread resolve，最後交 HC-02。
