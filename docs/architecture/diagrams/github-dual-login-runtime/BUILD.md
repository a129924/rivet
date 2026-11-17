# OAuth／PAT runtime sequence 圖證據

來源為本 feature 的正式 `GitHubLoginService`／coordinator、`GitHubLoginOAuthFlow` 與 callback relay；沒有依賴 experiments 的執行碼，也不代表 TC08 live 已完成。

- 規格：[runtime.sequence.json](runtime.sequence.json)
- 正式 HTML：[runtime-sequence.html](runtime-sequence.html)
- Showcase：[validation.json](validation.json)，9/9、0 errors、0 warnings。
- 原子交付：[delivery.json](delivery.json)，SHA-256／bytes 綁定凍結規格與 HTML；公開收據僅將 input/output 改記 repository-relative，hash／bytes 不改。
- 四尺寸：[visual-check receipt](runtime-sequence.visual-check.json) 與 [light/dark contact sheet](runtime-sequence.visual-check.html)。自動收據的 visualReview=pending 保留，不冒充 Agent 或 Human 視覺結論。

## 重現

使用已安裝 Archify skill（metadata version 2.16）；`ARCHIFY_HOME` 指向該 skill 目錄，從 repository root 執行：

```sh
node "$ARCHIFY_HOME/bin/archify.mjs" validate sequence docs/architecture/diagrams/github-dual-login-runtime/runtime.sequence.json --quality showcase --json
node "$ARCHIFY_HOME/bin/archify.mjs" deliver sequence docs/architecture/diagrams/github-dual-login-runtime/runtime.sequence.json docs/architecture/diagrams/github-dual-login-runtime/runtime-sequence.html --quality showcase --json
node "$ARCHIFY_HOME/bin/archify.mjs" visual-check docs/architecture/diagrams/github-dual-login-runtime/runtime-sequence.html --repo-root . --json
```

作者內容為繁體中文；meta.locale 省略，固定 Viewer UI 與 HTML lang 使用 English fallback。靜態 classic，無 motion、preview server、發布或 artifact.cafe。

## 驗證與視覺結果

2026-11-17，bounded Implementer `/root/diagram_implementer`：

- 最終 validate 與 deliver 均 exit 0；完整 showcase 9 checks、composition pass、0 errors／0 warnings。
- visual-check exit 0；1440×900、1600×1000、1920×1080、2048×1320 均無水平／垂直 overflow。
- Agent 實際查看最小／最大桌面的 light/dark 四張 PNG，確認主路徑、標籤、結論卡、legend 與 navigation dock 無遮蔽，最大桌面圖與結論卡保持平衡。
- `visual_review: passed` 僅指上述 Agent 檢視；**Human 視覺接受 pending**。
- `correction_rounds: 2`。首版三個較小桌面垂直 overflow；只壓縮作者 Y 間距與 viewBox，不縮字、不隱藏或裁切。第一次修正觸發末列可讀時間軸上界診斷，第二次將末列移入範圍後重新 validate／deliver／visual-check。失敗版不作最終證據。

圖為成功主路徑的時序摘要：已占用立即拒絕而不繼續；PAT 跳過 OAuth 通道。OAuth 返回候選 bundle 前已收尾；共同 worker 執行驗證／保存後 settled，才釋放 coordinator。所有失敗與取消不逐一展開；取消優先、最後同步檢查後無 await、已保存後取消不回滾及另一 store 保留的規則保存在結論卡與正式契約中。

圖的 deterministic checks／Agent 看圖不等於 runtime correctness approval、Human 接受或真 GitHub／DPK live。
