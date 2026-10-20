# GitHub 持續連線：圖表重建

本組圖依正式 source 與已獨立核對的 S08 證據建立；不執行產品、GitHub、Keychain 或 Apple 設定操作。作者內容為繁體中文，識別字保留 source 名稱。Archify 的固定 Viewer UI／HTML lang 採 English fallback（省略 meta.locale）；classic、still，沒有作者動畫。Canvas 也保留技能 viewer 的固定英文控制。

## 圖與責任

- [責任 canvas](responsibility-canvas.html)：使用者／顯示、App composition、non-BC GitHubIntegration、macOS DPK、GitHub.com 五層。17 個元件、16 個有意義的關係；虛線是自有抽象，實線是產品表面或外部設施。composition 持有唯一 provider／scope，初次授權 bundle 由 Coordinator 保存、session 只回傳 bundle；Presentation 不接 integration，雙 client 與 generic HTTP auth 的責任維持。
- [首次授權 sequence](authorization-sequence.html)：先保存設定，relay ready，state／PKCE／瀏覽器與 callback，可信完整 exchange，保存成功後才建立共用連線並 probe。
- [還原／刷新／重授權 sequence](restore-refresh-reauth-sequence.html)：同 provider restore／single-flight refresh、accepted 後先保存；取消仍等 Task settled，重授權先退休且無舊 provider 復活。
- [連線 lifecycle](connection-lifecycle.html)：正常工作、暫時失敗的同 provider 明確重試、退休後新授權、停止的舊 provider。恢復線代表新 bundle 保存後的新 generation，不代表復活舊 provider；停止狀態需由使用者重新授權，圖中沒有自動復原箭頭。

## 重建

從 repository root 執行。`<archify-skill>` 與 `<canvas-skill>` 表示本機已安裝技能目錄，不能原樣當作 shell path；不要 install／upgrade 或更改工具配置。Archify pin 為 2.16（runtime package 2.16.0-dev.0）。必須依 validate → deliver → visual-check 順序，失敗不能當作完成。deliver 會凍結輸入再產 HTML；本 runtime 沒有留下額外永久 frozen snapshot leaf，canonical JSON 的 SHA 由原始 delivery receipt 綁定。

```sh
node <canvas-skill>/scripts/validate.js docs/architecture/diagrams/github-persistent-connection/scene.js
node <canvas-skill>/scripts/build.js --scene docs/architecture/diagrams/github-persistent-connection/scene.js --out docs/architecture/diagrams/github-persistent-connection/responsibility-canvas.html --title 'Rivet GitHub 連線責任' --kicker '持續可用的連線' --sub '產品登入 → 完整保存 → 重啟還原 → 自動刷新 → API' --slug github-persistent-connection

node <archify-skill>/bin/archify.mjs validate sequence docs/architecture/diagrams/github-persistent-connection/authorization-sequence.json --repo-root . --json
node <archify-skill>/bin/archify.mjs deliver sequence docs/architecture/diagrams/github-persistent-connection/authorization-sequence.json docs/architecture/diagrams/github-persistent-connection/authorization-sequence.html --repo-root . --json > docs/architecture/diagrams/github-persistent-connection/authorization-sequence.delivery.json
node <archify-skill>/bin/archify.mjs visual-check docs/architecture/diagrams/github-persistent-connection/authorization-sequence.html --repo-root . --json
```

第二張 sequence 替換 basename 為 `restore-refresh-reauth-sequence`。lifecycle 使用 type `lifecycle`、basename `connection-lifecycle`。`--repo-root .` 讓原生 tool receipts 保持 repository-relative；未手動投影或改寫工具收據。visual-check 自動寫同 basename 的 JSON／HTML 與四張截圖。

## 凍結結果

| 作者 basename | JSON SHA-256 | HTML SHA-256 | showcase 檢查／錯誤警告 | desktop containment |
| --- | --- | --- | --- | --- |
| authorization-sequence | `3992e84bf63911be420a93558157b9611f5826b83bd232552a8034f7440b553c` | `4b091d99201520e4da7e66a96edaea50f4e3337d53cfa082ff026cc6180c1b9b` | 9/9；0/0 | 4/4 |
| restore-refresh-reauth-sequence | `9c65826b91c5d0204422f73770135646f107ba9b7018ca2e0c5dec18a979c542` | `6e4824e66f0b68ecedfec14e39a60da625a75a51eb60cab57c80d5ccbf341c8a` | 9/9；0/0 | 4/4 |
| connection-lifecycle | `730a7d58eb2ee283a2da01560049e2478a6986128e54f80f76c49dd611ecd66e` | `b6d98dab3380ae10c40685045d5b926f035a88c90fbbe66044fc84e1832172ca` | 9/9；0/0 | 4/4 |

Canvas 作者 `scene.js` SHA-256：`187bba542b1e1f2b17e960a74863b39b5e0a2633d4655bfb2d638f27ceff95d3`；HTML SHA-256：`61a8f9b558407ae9d1d04c63b56221325d2d666cd660fa110ef80cd4763e69ae`。技能 validator 回報 5 bands／17 boxes／16 edges、0 errors／0 warnings，build exit 0。HTML 由固定 viewer 建立，沒有手寫 viewer 或 CSS 修補。

三張 Archify 均檢查 1440×900、1600×1000、1920×1080、2048×1320；最小／最大各 light／dark 真截圖共 12 張，作者已逐張開啟檢視，詳見[視覺紀錄](visual-review.md)。工具的 visualReview=pending 保留；Human 已於 2026-10-20 09:51:14 UTC 在主對話明示接受圖面與成果，詳見 visual-review；原始工具 pending 不回填。

## 證據與驗收開關

圖描述目前程式契約，不將所有分支都當作 live 通過。[長期契約](../../github-oauth-dual-client.md#正式產品持續連線)及 [product-e2e](../../../../plan/github-persistent-connection/evidence/product-e2e.md)、[storage-live](../../../../plan/github-persistent-connection/evidence/storage-live.md)區分真實成功、受控到期與 fake 失敗測試。

受控到期僅供明確 opt-in 驗收：`RIVET_GITHUB_VALIDATION_MODE=expire-restored-once` 搭配 `RIVET_GITHUB_VALIDATION_RECEIPT=<私有新檔案位置>`；後續新程序使用 `observe`。receipt 路徑必須在私有本機指定，不能把 raw receipt／Apple ID／credential 寫進 repository。正常未設定模式使用真時鐘；受控模式只影響 provider 的一次還原到期判定，production token receipt 仍用真時鐘；接受新 bundle 後回到真時鐘。此開關不修改系統 clock 或持久 bundle 日期，也不是使用者一般操作流程。

驗收前提仍為同 Mac／GUI 使用者、原 AppID／group／certificate／固定位置及有效 profile。免費 profile 7 日到期、renewal 後讀回 unknown、certificate rotation 與公開分發限制維持；E007 不因本組圖而變成通過。
