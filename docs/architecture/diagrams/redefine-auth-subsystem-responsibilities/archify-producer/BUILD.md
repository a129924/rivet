# Archify document language producer overlay

本 producer 是本 topic 的 repository-local overlay，並非 upstream 已支援的功能。Upstream package 為
2.16.0-dev.0，skill 為 2.16；PC-33 Planner 已核查九個 baseline pins。外部 Archify 安裝僅供唯讀來源，
可透過 ARCHIFY_UPSTREAM_ROOT 指定；預設採使用者 Codex skills 安裝目錄。所有版本與依賴以
upstream-pin.json 的 upstream-relative SHA-256 為準，manifest 不記錄安裝位置。

## 重建與測試

從 feature repository root 執行，input/output 一律使用 repository-relative path：

~~~sh
PRODUCER=docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/run.mjs
node --test docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/archify-producer/producer.test.mjs
node "$PRODUCER" validate sequence docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/normal-request.json --quality showcase --repo-root . --json
node "$PRODUCER" deliver sequence docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/normal-request.json docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/normal-request.html --quality showcase --repo-root . --json
node "$PRODUCER" visual-check docs/architecture/diagrams/redefine-auth-subsystem-responsibilities/normal-request.html --repo-root . --json
~~~

401-refresh-retry 使用 sequence；auth-flow-state 與 http-client-auth-flow-contract/auth-flow-lifecycle 使用 lifecycle。
四份 final source 都需個別 validate 後 freeze，再 deliver 及 visual-check。不得使用本 wrapper 修改其餘
diagram。visual-check 僅讀取 trusted HTML，不 rerender；四 viewport 與最小／最大 light/dark screenshots
由標準 CLI 取得，visualReview 仍為 pending。人工 inspection 的結果記在 topic IM evidence，
不改寫自動 receipt。

## Pins、private runtime 與 patch

Manifest 完整列出 743 個私有 runtime files 的 relative path/hash：bin、renderers、schemas、assets、
scripts、package.json，以及 generator 使用的 AJV 與其依賴／其他 runtime parser dependencies。
所有 copy bytes 都由 manifest 授權並核對，不把整套工具 vendor 進 repository。新增工具相依檔案
必須先更新並獨立審查 manifest；僅五個 touched hashes 不構成完整重現性。

run.mjs 在任何 copy／patch／artifact／receipt writing 前核對全部 pins，複製到獨立暫存 runtime，
再次核對每個 copy，並套用 document-language.patch。Patch 精確涵蓋五檔：

- schemas/sequence.schema.json
- schemas/lifecycle.schema.json
- renderers/shared/generated-validators.mjs
- renderers/shared/cli.mjs
- renderers/shared/utils.mjs

兩份 typed schema 僅新增 optional meta.document_language const zh-Hant。Generated validator 是
由 pinned scripts/generate-validators.mjs 對已核准 schema 機械產生；不得手改 validator。
完整五-target patch 由 baseline 與 private generated tree 的 diff 機械產生。每次 private runtime
套 patch 後均執行 generator --check；測試亦比較兩次 fresh runtime 的全部 743 files hashes。
Common schema、i18n、template、generator、CLI entry、package 均保持 upstream bytes。

writeDiagram 傳遞 documentLanguage；svgRootAttrs 決定 root SVG lang；applyTemplate 僅替換 HTML root lang。
無 document_language 時仍依 resolved Viewer locale（absent/default en、explicit en 或 zh-CN）。
Viewer catalog、default labels、title suffix 與 locale enum 均不變，不新增 zh-Hant Viewer locale。

## Failure 與 receipt

先 canonicalize repository root，再 canonicalize input/output；reject absolute input/output、
parent traversal、repo 外路徑與指向 repo 外的 symlink。從 root alias 執行時依 canonical root 判定，
不是以文字前綴認定 containment。標準 upstream output safety guards 仍保留。

Invalid document_language 或任何 pin mismatch 必須在 artifact／receipt 寫入前失敗。
Delivery 委派標準 deliver，將 stdout 原始 bytes 直接寫進 receipt 同目錄的唯一暫存檔；
成功 exit 後檢查 JSON identity、showcase 9/9、zero errors/warnings、實際 source/HTML bytes 與 SHA-256、
repository-relative path metadata 及無本機位置，再同目錄 atomic rename 成 .delivery.json。
stdout/HTML/receipt 不做字串後處理；stdout receipt 原始 bytes 與 sidecar 完全一致。
Metadata 驗證走訪任意深度的 objects／arrays 與所有 string（含非 path key、array strings、
provenance cwd／root／temp 及 command 引數）；拒絕 POSIX absolute、Windows drive／UNC／rooted
及 slash／backslash parent traversal，不依欄位名稱或特定機器前綴黑名單。檢查不改寫原始 bytes。
HTML commit 與 receipt commit 是兩次獨立 atomic rename，非雙檔 transaction。Receipt 驗證失敗時
wrapper exit nonzero、保留前一 receipt，trusted HTML 可能已由 upstream 完成 commit，須停止交付並重新核查；
不將不完整 evidence 宣稱通過。暫存 cleanup 僅限本次自己建立的 runtime/capture，
不清除 repo ignored／untracked files。

Visual evidence 以標準工具量測；state 既有 containment exception 必須如實保留：
1440×900 scrollHeight 1035；1600×1000／1920×1080 scrollHeight 1109；2048×1320 containment pass。
不以 clipping、internal scrolling 或縮字假造 pass。無 image reader 時人工檢視保持未完成。

## 大型 generated diff 的機械回復

本次 generated-validator diff 曾遭 shell tool output 截斷。獨立 Reviewer 分類允許停止原 pending
寫入、核對前後相同 hash，再從已核准 pinned private tree 機械重建完整五-target patch。
這是 generated diff 的 bulk mechanical rewrite；沒有改成四-target patch 包裝、手寫 validator、
修改全域安裝或繞過 pin/patch failure。Fresh runtime patch 與 generator check 通過後才可交付。
