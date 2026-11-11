# 工具證據

## Archify

Pin 2.16，sequence；delivery receipt 綁 specification／artifact SHA-256 及 bytes。最終 showcase 9/9、0 errors、0 warnings；四尺寸 containment／四張 lightdark 截圖通過。Agent 已實際看圖；Human acceptance pending。詳見 delivery／visual-check receipts 與 visual-review.md。未發布。

## Graphify

`GRAPHIFY_NO_AUTO_REFRESH=1` 下確認版本 0.9.73。本 feature worktree 沒有 graphify-out/graph.json，依 skill 使用 bounded rg 與直接 source reads；已核對 OAuthCredentialStore、bundle、OAuthTokenProvider 及 stores 的呼叫責任。不 build／refresh／install、不更改配置；沒有以缺少的 graph 推論依賴。

## PR Lens

以真 base `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`／source head `e53030883d6de111b52ee64996a7fe01c04109a7` 的 `git diff --find-renames <base>...<head>` 建立外部 scratch 變更圖。CLI 0.11.0 validate／render 均 exit0；實讀 render manifest：1 SVG、4 lanes、7 nodes、7 edges、3 walkthrough steps，保留未變更 provider／port 鄰接與 file refs。初次 generatedAt ISO suffix 格式被拒，修正為 Z 後通過；未忽略 validator failure。圖及 actual.diff 僅留本地，不使用 hosted canvas、不上傳資產、不修改配置。這是變更理解圖，不是 correctness verdict。
