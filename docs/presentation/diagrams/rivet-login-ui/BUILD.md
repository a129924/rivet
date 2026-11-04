# 登入 UI lifecycle：建置與證據

- 日期：2026-10-22；Archify skill metadata version 2.16。
- Diagram type：`lifecycle`；作者內容繁體中文。沒有設定 `meta.locale`，固定 Viewer UI 與 `html lang` fallback English；`Outcomes` 是 renderer 固定字串。
- 靜態、classic、showcase；無外部發布、preview server 或 provider calls。
- 來源：`RivetLoginPhase`、`LoginDemoModel` 與正式 technical-spec。只畫假 UI transition；不代表 OAuth／網路／Keychain。

## 可重現命令

以 `$ARCHIFY` 表示已安裝 skill root，`$TOPIC_SCRATCH` 表示 repository 外本 topic scratch；均不記使用者本機路徑。

```sh
node "$ARCHIFY/bin/archify.mjs" validate lifecycle docs/presentation/diagrams/rivet-login-ui/login-lifecycle.json --quality showcase --json
node "$ARCHIFY/bin/archify.mjs" deliver lifecycle docs/presentation/diagrams/rivet-login-ui/login-lifecycle.json "$TOPIC_SCRATCH/login-lifecycle.html" --quality showcase --json
# 核對 specification receipt，將已交付 HTML 原 bytes copy 到本目錄，核對 hash。
node "$ARCHIFY/bin/archify.mjs" visual-check docs/presentation/diagrams/rivet-login-ui/login-lifecycle.html --repo-root . --json
```

## Frozen receipt

- Validate／deliver：exit 0；9/9 checks、showcase composition pass、0 errors／0 warnings。
- Specification SHA-256：`769f2cbb3b249f9629a00397822a4b0d1dd505d7f26f39d9b5e234b5910c0701`；4146 bytes。
- Artifact SHA-256：`fe912937713f6f42286801317072d8774cae43d69b39e64f9644e021cf64ef4b`；703874 bytes。
- 外置 delivered HTML 與 repository copy SHA 相同；不重 render／不編輯 HTML。Sidecar receipt 綁同 artifact SHA；此receipt為RV-01修正後新版，先前第1輪hash不是新版證據。

## 修正與實看

Deterministic 修正分開處理：初稿缺 reserved main rail、failed 與 PAT lane 相撞、兩條 crossing、兩個 orthogonal endpoint、failure sublabel readability。Objective errors 依序大幅下降至 17→8→8→4→2（check diagnostics）→2→1→0；從未連續兩輪不改善最佳值。未讀 renderer internals。

- 初版實看 `visual_review: failed`：1440／1600／1920 有垂直 overflow，2048 containment pass；這是修正前歷史，不是現版。
- 第1輪歷史（`correction_rounds: 1`）：將 authored viewBox 高度760收斂為660，移除100pt底部冗餘留白，保留字體大小、節點與全部語義。browser recovery corridor 620→550，避開新位置 Legend；過程的兩次 legend-clearance診斷各立即validate，未超過連兩輪無改善停止規則。
- 修改後重新 final validate／deliver／同bytes copy／SHA核對／visual-check，對 exact新版HTML取證。
- `visual_review: passed`：實看新版1440×900／2048×1320 light／dark四圖；無遮擋／clipping／有意義label遺失，最大畫面可讀且沒有空白下帶。
- 自動 receipt 保持 `visualReview: pending`，人工狀態獨立記錄，沒有竄改自動receipt。
- 四尺寸 containment 全pass：1440×900、1600×1000、1920×1080、2048×1320，各scrollWidth／scrollHeight不超過viewport；readerWidth依序1089／1203／1334／1662。readability、captures全pass。

## RV-01 P2 修正：最後第2輪

- `correction_rounds: 2`；本輪沒有source／Swift測試改動，沒有操作CUA。RV-01的原判定為needs-rework，只回修其單一P2圖契約問題；不由Implementer宣告Reviewer approval。
- 原 `token-retry` 畫成 `failed→token`；實際token failure在原failure表單重填，送出直接到verifyingToken。新版改為 `failed→checking`，label `token：重填後送出`，七態與其他edge語義保持。
- 初次最小endpoint修改造成4項automatic port／label診斷；只把重送邊放在verifyingToken下方獨立corridor後降到1項submit micro-segment，再限定submit straight route後0項。每次edit後validate，best errors為4→1→0，未觸發連兩輪不改善停止條件；沒有大重排或改字體。
- 新candidate final validate與外置deliver均exit0：showcase9/9、0errors／0warnings。核對specification hash、同bytes copy與HTML hash後，對repository exact新版HTML執行visual-check exit0。
- 四尺寸container、readability與captures全pass；scrollWidth／scrollHeight依序1440／900、1600／1000、1920／1080、2048／1320，均不超出viewport。
- Implementer重新實看新版1440×900／2048×1320的light／dark四張sidecars：重送方向與label清楚，沒有clipping、opaque-node crossing、label遮擋，最大畫面可讀且無空白下帶。`visual_review: passed`。自動receipt `visualReview: pending`仍原樣保留。
- 此為本輪Implementer自驗；等待獨立Tester核對新hash／圖證據，再由Reviewerclose。第2輪額度已用完，不繼續第三輪perceptual修改；如再有缺口交Dispatcher處理。
