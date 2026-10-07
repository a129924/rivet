# E002：PKCE token exchange 與 credential 相容性驗證

目前成果：獨立 Reviewer 已對 runner＋[v3 sequence](diagrams/pkce-token-exchange-v3.html) 明示 approved；四張 captures 實看可讀平衡、語意正確。A001 approved，追加使用 1／2（原 2／2、累計 3／4），HC-DIAGRAM 解除。真實 OAuth 0／2、四軸未驗證；S06 commit `819184f6ddebe05090608a11da602a67e247b5df` 已完成、六項正常 hooks 全通過；S07 PR Lens approved。本文件為 S08 收尾 commit 前／push 前 snapshot，S09 最終 map coverage 與 S10 push pending，後續以 PR／remote 證據為準。

## 目標、原因與事前判準

沿用 E001 OAuth App／IPv4 loopback，確認加入 S256 後能否取得既有 `GitHubOAuthCredentialBundle` 六欄、完成一次 `GET /user`，再以另一組新 code 與錯誤 verifier 測量拒絕。scope 僅要求 `offline_access`；不以 granted scope 含此字串判定成功。code exchange 仍要求 client_secret。[GitHub 官方授權文件](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)

四軸分開記錄 exchange、schema、API、PKCE。全成功才總體成功；有效 failure 使總體失敗；App 設定／人工授權／網路／timeout 不足則無法判定。反向任何非空 access／refresh token 均失敗；通用 `bad_verification_code` 需正向 baseline、相同 App／secret、每次相符 redirect、有效 state、新 code、立即單次交換排除混淆，未知 error 不視為 PKCE 專屬訊號。[官方錯誤說明](https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/troubleshooting-oauth-app-access-token-request-errors)

## 實作契約

| 欄位 | 內容 |
| --- | --- |
| In-Scope | 獨立 SwiftPM runner、S256／state、token exchange、本地 DTO → public bundle、一次 /user、mock、遮蔽證據與一張 sequence。 |
| Out-Of-Scope | refresh rotation、Keychain、產品 UI／client、secret 部署、Graphify 建圖、發布。 |
| ReadOnly | 根 Package／Sources／Tests、E001、docs／settings；dev 全部檔案唯讀。 |
| Written | E002 package／Sources／Tests／README／diagrams、同 topic 四檔。 |
| Deleted | 無。 |
| Modify | 僅上述 E002 與正式 topic artifacts；未實測不改長期架構文件。 |
| Goal | 四軸有效測量與安全、可重現的遮蔽證據。 |
| Non-Goal | 正式採用、secret 配送、schema 放寬、公開 internal DTO。 |
| TestCase | 正向新 code＋正 verifier；反向另一組新 code＋錯 verifier；T03–T09 局部 mock 與 T10 交付檢查。 |

core 僅取 root public `GitHubIntegration` product；本地 DTO 沿用 String／Int／bearer／scope 空字串型別，以 receivedAt 加秒數映射 Date，再建真正 public bundle。正向取得非空 access token 就執行一次 /user，即使 schema 不相容；200、JSON object、有效整數 id 與非空 login 才 API 成功，只留布林。

授權至 127.0.0.1 動態 port／oauth/callback；callback 必須 state 相符且非重複、非空 code。每次授權獨立隨機 state／32-byte verifier 與 S256 challenge；交換含相同 redirect。最多 2 次新授權，各 callback <=180 秒，每個 HTTP <=30 秒；每 code 一次 POST、無 retry、HTTP redirect 拒絕。正向交換未成功或 network／timeout／取消時停止；schema／API 有效 failure 可以繼續反向。每路徑 listener／session cleanup。

## 重現與環境

從本 topic feature worktree 執行：

```sh
swift build --package-path experiments/E002
swift test --package-path experiments/E002
swift run --package-path experiments/E002 oauth-pkce-probe --client-id <Client-ID>
```

最後一條只由人類安排真實測量時執行。client ID 沿用 E001 App，由人類提供；secret 在本機 TTY 透過 readpassphrase 隱藏輸入，含 signal 復原 terminal echo；不得放 argv／shell／聊天／檔案，不讀既存 secret。可選 `--timeout-seconds <1…180>` 只縮短等待。不具 TTY 或 invalid args 以安全固定文字退出 2，不開瀏覽器。

ephemeral session 關閉 cache／cookie persistence。code／state／verifier／secret／token／userinfo／完整 URL／body／raw error 僅記憶體，不 log／落盤；有限分類輸出。不宣稱記憶體安全抹除，browser／OS 留痕未驗證。

實作局部環境：2026-10-07，arm64 macOS；Swift 6.3.3／Swift tools 與 language mode 6、macOS 15 minimum。App client ID／secret／實際設定／browser 授權皆未查證。

## 結果與局部證據

| 軸 | 真實結果 |
| --- | --- |
| 正向 exchange | 未執行／未驗證 |
| schema 相容性 | 未執行／未驗證 |
| API | 未執行／未驗證 |
| 反向 PKCE | 未執行／未驗證 |
| 總體 | 無法判定；HC-LIVE pending |

真實授權使用量 0／2。mock 不代表 GitHub／App 支援的實證。相容性只表示回應符合既有六欄且可建 public bundle，不宣稱執行 internal decoder。

TDD red：RFC7636 vector 在 placeholder 回傳 verifier 時測試 exit 1；green：實際 SHA-256／base64url 後通過。局部 22 Swift Testing tests（含參數化案例）通過：六欄缺漏／型別／expiry／空 scope、callback 缺漏／重複／錯誤／空 code、form reserved characters、正反兩次獨立授權／每 code 單次交換、HTTP 200 OAuth error、無 baseline／network 停止、反向意外 token、未知錯誤、safeReport sentinel 不外洩、bounded HTTP header、listener timeout／cancel／cleanup。所有 callbacks synthetic，未開實際 browser／外部 HTTP。

`swift build`、`swift format lint --strict --recursive`（僅 E002 Sources／Tests／Package.swift）與既有 config 的 `swiftlint lint --strict` 皆通過，SwiftLint 11 files／0 violations。CLI invalid args 與無 TTY 各 exit 2，只有固定遮蔽文字。Implementer 不自評 approved；獨立 Tester 證據見下方，成果 Reviewer 尚待。

## 歷史圖與導航工具：保留原失敗／缺口

[sequence HTML](diagrams/pkce-token-exchange.html) 是第一輪 trusted delivery：九項 showcase、0 errors／warnings，SHA-256 `0a25648047dd3037763e805c1ad8e473dfa07b43babe354a993c8aa84c6ae1e7`，700520 bytes。四 viewport 的 [visual receipt](diagrams/pkce-token-exchange.visual-check.json) 皆垂直 overflow：1440×900 →1350；1600×1000／1920×1080 →1438；2048×1320 →1464。light／dark captures 已保存；自動 visualReview=pending，非視覺通過。

初稿只有 desktop-readability error；第一輪縮寬 1100→1080 通過。第二輪只壓縮 authored Y／viewBox 高度，[v2 candidate](diagrams/pkce-token-exchange-v2.json) 在末訊息 y490 超出可讀 timeline y477 而 validate／deliver 非零，failed [validation](diagrams/pkce-token-exchange-v2.validation.json)／[delivery](diagrams/pkce-token-exchange-v2.delivery.json) 保存。原 trusted HTML 未被替換；第二輪預算已用盡，停止修復、交獨立 Reviewer 分類。v1 spec／delivery JSON 被第二輪操作覆蓋，缺少該原始 receipt，不能假稱完整 spec/artifact provenance；未偽造歷史。失敗 receipts 僅將本機路徑 metadata 正規化為 repo-relative，錯誤內容未變。不手改 HTML／clip／縮字／reset 預算／preview／發布。

作者文字繁體中文；省略 unsupported meta.locale，固定 Viewer UI／HTML lang fallback English。圖失敗不改寫四個真實 OAuth 軸。

Graphify 無既存可用 graph，僅 targeted source fallback，未建圖／provider／cache／install／改設定。PR Lens 等真實不同 base/head topic commit 才由 Reviewer 在 repo 外做 local validate/render；當時 deferred，先 direct bounded diff；現已在 S07 完成，見下方 coverage。未 upload／發布。

獨立 Tester 已完成分項驗證，成果 Reviewer／human review 尚待；圖子項目前 blocked／needs-rework 待角色分類。後續真實成功仍不代表產品正式採用或 secret 配送方式已決定。

## 獨立 Tester 證據

2026-10-07 — root 以獨立 Tester 角色在 feature worktree 驗證：SwiftPM build exit 0；22 個 Swift Testing tests 於 1.017 秒通過；局部 strict Swift format 與 SwiftLint exit 0（11 files／0 violations）；diff check 與 26 個新檔 allowlist 通過。四個 CLI 邊界案例（缺 args、無 TTY、超過 180 秒、secret argv）均 exit 2，未輸出合成 secret sentinel、未開瀏覽器。

獨立 visual-check exit 1，trusted HTML SHA-256／700520 bytes 未改變，四尺寸 scrollHeight 依序 1350／1438／1438／1464，均超 viewport；四 light／dark captures 存在。程式局部驗證通過；圖驗收失敗與 v1 spec／receipt 缺口交獨立 Reviewer 分類，不能據此宣稱完整 topic approved。真實 OAuth 仍 0／2、四軸未執行，未修改長期 docs。

## 歷史 S05 獨立審查回修（2026-10-07）

Reviewer 明示 `needs-rework`：P1 正向 credentials／redirect／未確認 OAuth error 應屬前置不足、無法判定；P2 單一 reason 被最終 PKCE 覆寫，未保留 schema／API 原因。圖子項為 `human-check`，不追加修復、不改任何圖檔；S06 commit／push 暫不前進。

bounded code fix：正向 error 以有限分類標記 indeterminate 並停止；有效成功 HTTP／JSON 回應卻未取得 access token 仍為 measured failure。每個軸改存有限 `MeasurementReason` enum，不反射 error code／description／body／userinfo；未執行軸保留原因，PKCE 結果不覆寫 schema／API，API 網路中止另標未執行反向。

新增 red：4 tests／10 issues、exit 1，重現 wrong credentials／redirect／unknown error 舊誤判與三種原因遺失。green 加入前置不足、schema failure＋反向成功、API failure＋反向成功、API network 中止，以及有效無 token failure；局部最終 27 tests（含參數化 cases）1.012 秒通過、exit 0；獨立 Tester／Reviewer 複驗 pending。strict format／SwiftLint 11 files 0 violations，git diff --check 通過。真實授權仍 0／2，四軸未執行。

HC-DIAGRAM：需人類明確選擇 defer 圖驗收，或授權增加修復預算並先修訂正式契約。必需圖 overflow／v2 失敗／v1 spec 與原 receipts 缺口未解；不能自動降 gate 或宣稱 topic approved。PR Lens 缺真實 commit 仍 deferred。

### 歷史回修後獨立 Tester 複驗

2026-10-07 — root Tester 在同 feature worktree 執行完整 E002 tests：27 tests 於 1.013 秒通過，exit 0；局部 strict format／SwiftLint 11 files／0 violations、diff check 通過。新案例覆蓋 credentials／redirect／未知 OAuth error 的 indeterminate 與一次授權停止，以及 schema／API／network／未執行 PKCE 的各軸理由保留。v1 HTML 與 v2 candidate SHA-256 均保持先前值，沒有第三輪圖修復。Code findings 待獨立 Reviewer 複審；HC-DIAGRAM 維持 human-check，未放行 commit／push。

### 獨立 Reviewer 結果

2026-10-07 — P1/P2 均已關閉，code-bounded approved，無新增程式 findings。完整交付仍 human-check：mandatory Archify 四桌面 containment 未通過、v1 spec／receipt 缺口，兩輪修復已用盡。未 commit／push；由人類決定延期圖驗收或追加修復預算，不自行降低 gate。真實 OAuth 仍 0／2、未驗證。

## A001：追加圖修復第 1／2 輪交接（v3）

A001 的獨立 Plan-Reviewer approved／無 required fix 已由 Dispatcher 轉交（2026-10-07），記入 A02；此是追加修復授權，不是圖成果驗收。原兩輪與 v1／v2 現存所有 bytes 保留，前後 SHA-256 全部一致；v1 歷史 spec／原 delivery receipt 缺失仍是缺口，不補造。追加預算使用 1／2，原 2／2，累計 3／4；不需第 2 追加輪即交 Tester／Reviewer。

唯讀限定 renderer 診斷找到原因：v1 viewBox 比例 1080／980 小於 runtime 的 wide ratio 1.55，未啟用 viewport-height-aware 外層閱讀寬度，SVG 按整個 reader 寬度保持比例而超出首屏。v3 只調整 authored spacing 與 viewBox 至 1080×650，保留完整正反流程並補明確反向新 code／state 的 loopback callback；正常 readerLayout 啟用，未改 renderer／HTML、未縮字／裁切／隱藏 overflow／伸展 SVG。

正式最新圖：[v3 sequence](diagrams/pkce-token-exchange-v3.html)，來源 [v3 JSON](diagrams/pkce-token-exchange-v3.json)。validate exit 0：showcase 9／9、0 errors／warnings，來源隨即凍結；deliver exit 0，spec SHA-256 `5409368a7f6634e179828dbedc5470e076908cbfa2460b560211171fd8ef77f3`／3170 bytes；artifact SHA-256 `80a34db39be77b245dc2784ae9b40a89b69402323b75437fd4ce3a8571651214`／701257 bytes。[validation](diagrams/pkce-token-exchange-v3.validation.json)／[delivery](diagrams/pkce-token-exchange-v3.delivery.json) 只將本機 file-path metadata 正規化為 repo-relative，原始 checker 結果／hash／bytes 未改，raw stdout 在執行暫存區保留。

[visual-check receipt](diagrams/pkce-token-exchange-v3.visual-check.json) exit 0；1440×900、1600×1000、1920×1080、2048×1320 的 scrollWidth／scrollHeight 各等於 viewport，全部無 overflow，readability／Viewer chrome／captures pass。最小與最大 light／dark 四張 screenshots 與 [contact sheet](diagrams/pkce-token-exchange-v3.visual-check.html) 保存。自動 `visualReview=pending`；Implementer 已看最大 dark capture，仍由獨立 Reviewer 實看四張與圖，未自評 gate approved。

A04 Tester 複驗／A05 Reviewer 視覺 gate pending；code-bounded approved／27 tests 證據保持，runner 完全未改或重跑。真實 OAuth 仍 0／2、四軸未執行，commit／push／PR 等成果 gate 放行。

### A04 獨立 Tester 複驗（2026-10-07）

root Tester 重新執行 v3 showcase validate 與 visual-check，均 exit 0；九項檢查通過、零 errors／warnings，四 viewport scrollWidth／scrollHeight 均等於對應 viewport，四張明暗 captures 完整。spec／HTML SHA-256 與 byte count 與 matching delivery receipt 一致。修復前既有 21 個非 README 檔案（11 Swift、10 舊圖證據）hash 全部未變，故保留先前 27 tests／format／lint 證據，未重跑 Swift 或真實 OAuth。自動 visualReview 仍 pending，交獨立 Reviewer 實看與 gate 判定；追加使用 1／2，原 2／2，真實授權 0／2。

## A05 完整成果核准

2026-10-07 — Dispatcher 轉交獨立 Reviewer 明示 `approved`：runner＋v3、四 screenshots 已實看；字標可讀、桌面上下平衡、語意正確，未縮字／裁切／隱藏 overflow／修改 renderer。A001 Plan-Reviewer approved、A04 Tester completed、A05 成果 approved，HC-DIAGRAM 解除。自動 receipts 的 visualReview=pending 保留原值，獨立視覺 approval 記於此與帳本，不竄改工具 receipts。v1／v2 失敗停點與缺口是歷史，不阻新 v3 的完整來源交付。

歷史 S06 準備 snapshot：當時依人類既有授權進行 staged diff 語意檢查，commit／push 尚未發生；後續已完成 S06／S07，見下方現狀。真實 OAuth0／2／HC-LIVE pending 不變。

## S06／S07 已發生證據與 S08 收尾 snapshot

S06 commit：`819184f6ddebe05090608a11da602a67e247b5df`，message `chore(oauth): 新增 E002 PKCE credential 相容性驗證工具`。trailing whitespace、EOF、swift format、GitHubIntegration consumer contract、SwiftLint、renderer check 六項正常 hooks 全 Passed，未 skip；36 個檔案僅 E002＋四 topic artifacts，feature／dev clean、dev HEAD 仍為 base，凍結 20 圖檔 SHA 未變。

S07 獨立 Reviewer approved：pinned PR Lens 0.11.0 local validate／render exit 0，manifest 已讀（3 lanes／8 nodes／8 edges／3 walkthrough steps／1 SVG）。map 真實 coverage：base `a4828938389c7fbfabaffa8c6ca11e0ddbe4b64f` → head `819184f6ddebe05090608a11da602a67e247b5df`；graph SHA-256 `24bf5c1ebc591b17b93b56b69136c54c283a8e506053f09096a33da8e3c83422`。產物僅 repo 外 topic scratch，以下是 scratch-relative 路徑文字，不是 repository 連結：`pr-lens/819184f6/graph.json`、`pr-lens/819184f6/rendered/overview-light-3310335da44d6334c6755d1c8cd2c36b.svg`、同目錄 `manifest.json`。不 upload／發布。

本頁與帳本是 S08 metadata 收尾 commit 前／push 前 snapshot，不能預寫本文件自身 commit SHA；形成新 head 後交 S09 Reviewer 更新 map 或明示 coverage，再按 S10 non-force push／human review 路由。舊「尚未 commit」／「PR Lens deferred」均為歷史，不代表目前狀態。v3／A05 approved、追加1／2（總3／4）不變；真 OAuth0／2、四軸未驗證，HC-LIVE／HC-REVIEW pending。
