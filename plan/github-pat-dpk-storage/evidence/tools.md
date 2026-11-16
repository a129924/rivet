# 本機圖形與導覽工具證據

2026-11-16；所有操作為本機，沒有圖形上傳、發布、server、provider 或自動安裝。

## PR Lens

- 使用固定 CLI 0.11.0。真實 base：`5713025e3312c0fbc9a7b02a222db0b91d6e1b58`；實作 head：`cdddaf6e92b4c834aeca227ba635dbc634c9eb38`。讀取 `git diff --find-renames` 與必要 source context。
- 外部私有 scratch 葉名：`github-pat-dpk-storage-pr-lens-knw7uyb7`；graph／SVG／manifest 均留 repository 外，不提交或上傳。
- 初次 generatedAt 使用帶 offset 格式遭 strict ISO validator 拒絕，改成 UTC Z 格式後 validate exit 0：4 lanes、7 nodes、6 edges、0 flows、3 walkthrough steps。
- render `--theme light --no-config` exit 0；repository 沒有既有 config，未建立設定或 `.pr-lens`。Manifest：1 SVG／1 diagram，head SHA 與實作 commit 相同。
- graph SHA-256：`c307626817da4d52c0e7f1d6d680c59e3425cfcaa72de9bc0439b04b675b3c19`。Renderer `@coldtea/pr-lens-renderer@0.3.1`；SVG bytes：12070，manifest contentHash：`06a4d79bca7436e32f6b25c03dec2b27`。
- 獨立 Reviewer `/root/planner` change-map verdict：approved，required fixes 0。確認新增 store／host／tests／consumer、unchanged PAT VO／OAuth／DPK 與關係忠於實作 diff，沒有新增 OAuth 依賴。
- 圖鎖定上述實作 commit；後續只新增交付文件，不宣稱此圖包含收尾 metadata diff。圖不是 correctness 或 live review。

## Graphify

當前沒有可用 persistent graph。依明示 skill 使用限定來源搜尋並核對真實原始碼；沒有 query 可執行，沒有 extract／build、provider、URL fetch、install、refresh、stamp 或 config／hook 修改。沒有宣稱 graph 完整性或節省成本。未來如有可用 graph，每次 CLI 都必須設定 `GRAPHIFY_NO_AUTO_REFRESH=1`。

## Archify

[Diagram BUILD](../../../docs/architecture/diagrams/github-pat-dpk-storage/BUILD.md) 與同目錄 receipts 保留最終 JSON／HTML hashes、9/9 showcase、0 errors／warnings、四尺寸 containment。獨立 Tester 已親跑並檢視四張最小／最大 light／dark。自動 receipt 的 visualReview=pending 保持；Human 接受仍 pending。
