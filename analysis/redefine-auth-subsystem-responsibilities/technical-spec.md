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
AuthRequester ──取得 independent flow──► Auth（strategy／flow provider）
  │
  ├── response input ───────────────► AuthFlow（policy/state）
  │◄── semantic decision ────────────┤  response semantics／retry decision
  │                                  │  no request construction／no I/O
  │                                  │
  ├── preserved original request ───► Requester（generic HTTP I/O）
  │◄── raw HTTPResponse ─────────────┤
  │
  └── deferred refresh dispatch ────► deferred refresh I/O boundary
                                        （未命名、未鎖定；不由 AuthFlow 直接呼叫）
```

- `Auth` 的 contract 是提供 authentication strategy 與獨立 flow instance，不是
  credential store、HTTP decorator 或 I/O component。它不取得 caller original
  request 的 ownership。
- `AuthFlow` 擁有 per-execution authentication state、response-to-next-decision
  transition、refresh eligibility、retry limit 和 terminal decision。它可以讀取
  `HTTPResponse`，包括 401 semantics；這不是 request construction 或 I/O authority。
- `AuthRequester` 擁有 original request 的 lifetime 和 semantic action
  interpretation。它不得重訂 retry policy，也不得把 caller request ownership
  交給 flow。它以 `Requester` 執行已保留 caller intent 的 request。
- `Requester` 唯一負責 generic HTTP I/O：接收已選定 `HTTPRequest`，交 transport，
  回傳 raw `HTTPResponse`。它不認識 auth flow、credential refresh 或 retry policy。

## Capability Boundary

Model C 的 type contract 必須最終能表達下列限制：

| Capability | `AuthFlow` target | Owner |
| --- | --- | --- |
| 讀取 401／其他 raw response semantics | 允許 | `AuthFlow` 作為 policy input |
| 決定是否 refresh、retry、finish | 允許 | `AuthFlow`，唯一 policy owner |
| 保有／讀取 original URL、method、query、body | 禁止 | `AuthRequester` |
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
| `AuthRequester` | 否 | 是，轉交給 flow | 是，唯一 owner | 是，僅保留 caller intent；representation deferred | 否 | 否，僅委派 | 否 |
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
2. `AuthRequester` 取得 independent `AuthFlow`，並取得 flow 的 semantic send
   decision；factory interface 尚未鎖定。
3. `AuthRequester` 以 preserved caller intent 準備待執行 request；decoration
   representation 尚未鎖定。
4. `Requester` 執行 HTTP I/O，回傳 raw `HTTPResponse`。
5. `AuthRequester` 把 response 交給 `AuthFlow`；flow 作 terminal policy decision。
6. `AuthRequester` 回傳 terminal response；它不自行產生 retry count policy。

### 401 Refresh and Retry

1. `Requester` 回傳 401 raw response；`AuthRequester` 將它交給 `AuthFlow`。
2. `AuthFlow` 依自己的 state 判斷是否進入 refresh；它是唯一 decision/state owner。
3. `AuthRequester` 只解讀 semantic refresh decision，交給 **deferred credential-refresh
   I/O boundary**；這份文件不命名 type、不定義 endpoint、payload、credential update
   API 或 refresh-result type。
4. deferred boundary 完成其 I/O 與 credential update responsibility 後，將足夠的結果
   交回 flow 的結果傳遞邊界；該 delivery contract deferred。
5. flow 決定是否允許 original request retry；`AuthRequester` 仍只可重送其保有的
   original work。第二次 401 的 terminal/retry decision 仍只屬 flow。

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
   `git-commit-convention` 完成 topic commit、push、open **draft PR**。
10. DL-01 完成後進入 HC-01 human review；停止自動前進。不得 merge、release 或處理
   review comment，也不得開始 future Swift implementation。

## TestCase

- **TC-01**：future implementation 的 flow unit test 證明 normal response terminal、
  first 401 requests refresh、refresh success permits original retry、second 401 stops、
  refresh failure is terminal；本 topic 不新增此 Swift test。
- **TC-02**：future compile/API test 證明 `AuthFlow` 無 arbitrary endpoint/request
  construction authority；若未來不採納此限制，必須另開 topic 明確重啟 architecture
  decision。
- **TC-03**：documentation test 檢查 matrix、sequence 和 state diagram 對 decision、
  I/O、state、original request ownership 一致。
- **TC-04**：changed-path／ReadOnly test 檢查無 Swift、package、OAuth dual-client
  lifecycle 或 historical topic 變更。
- **TC-05**：diagram validation/visual evidence 滿足本文件的 skill gate，且 no
  artifact.cafe publication。
