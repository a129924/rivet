# GitHub 持續連線：獨立驗證 App v2 圖表

本revision描述 `apps/GitHubConnectionVerification` 驗證工具與既有production public契約的責任，**不是正式產品登入能力**。作者內容繁體中文、保留source identifiers；省略meta.locale，固定ViewerUI／HTMLlang依工具採Englishfallback。classic／still，不啟用動畫、不發布artifact.cafe。舊圖位於父目錄，native29檔完全保留，只舊導覽加historybanner。

## 責任與流程

- [責任canvas](responsibility-canvas.html)：5bands／19boxes／17edges；驗證UI、session、DPK、refresh／DTO、coordinator、probe、tracker、clock／receipt皆App-local；正式provider／scope／HTTP原樣。箭頭表達呼叫與注入，provider經既有publicport呼叫adapter，不代表productionimport驗證App。
- [首次授權sequence](authorization-sequence.html)：先保存設定，relayready，state／PKCE、exactcallback、完整exchange，Coordinator完整保存後才建立provider／scope與API；session不直接保存。
- [還原／輪替sequence](restore-refresh-reauth-sequence.html)：真refresh／save包裝結果留本地tracker，保存成功才交snapshot；新observe程序讀回輪替結果。圖描述成功路徑，terminal與reauth見lifecycle。
- [生命週期](connection-lifecycle.html)：temporary同generation明確retry；取消等settlement、reauth先退休；accepted-savefail／輪替未知停舊provider，不復活。退出舊provider的線不表示自動恢復。

## Native 重建與驗證

在repositoryroot，以已安裝技能目錄代入 `<canvas-skill>`／`<archify-skill>`；不安裝、升級或改工具設定：

```sh
node <canvas-skill>/scripts/validate.js docs/architecture/diagrams/github-persistent-connection/verification-host-v2/scene.js
node <canvas-skill>/scripts/build.js --scene docs/architecture/diagrams/github-persistent-connection/verification-host-v2/scene.js --out docs/architecture/diagrams/github-persistent-connection/verification-host-v2/responsibility-canvas.html --title 'GitHub 持續連線獨立驗證工具' --kicker '可行性驗證與限制' --sub '授權 → 保存 → 重啟 → 輪替 → API' --slug github-connection-verification-v2
node <archify-skill>/bin/archify.mjs validate sequence docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.json --repo-root . --quality showcase --json
node <archify-skill>/bin/archify.mjs deliver sequence docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.json docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.html --repo-root . --quality showcase --json > docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.delivery.json
node <archify-skill>/bin/archify.mjs visual-check docs/architecture/diagrams/github-persistent-connection/verification-host-v2/authorization-sequence.html --repo-root . --json
```

第二張替換basename `restore-refresh-reauth-sequence`；第三張type為lifecycle／basename `connection-lifecycle`。每個spec通過後凍結，deliver只由native工具產HTML／receipt，不手改viewer、CSS、JSON收據或PNG。實際runtime未留下額外永久frozenleaf，故無manifest擴張。`--repo-root .`讓工具path保持repositoryrelative。

## R07 作者結果（非獨立批准）

| basename | spec SHA-256 | HTML SHA-256 | native delivery SHA-256 | 結果 |
|---|---|---|---|---|
| `authorization-sequence` | `90ff2756f6c5869166f71fc9a95f847b193b4996e645b9bbd5940555cc5124d9` | `6822566a659e4251115984c843b07bb3ecb9a61e51cf44fcc0cecc0e119a343d` | `346e1cc36c47735167f255b2dc54aa23bb96c58cf26f388cdf6f3cf15179aab9` | 9/9、0錯／0警；4尺寸通過 |
| `restore-refresh-reauth-sequence` | `e93b852eb17c738352cf9cc9bafb1cd77df3d63221e20bb60af67a0a6552600a` | `6acdda69e45e85fcfb6d516651c2ffb9aefdf337742c4fd751fc9febce6e58fc` | `54e4f9d7126bc1aba3c7d8e938d12a530739ff318671028bba152375c024abb3` | 9/9、0錯／0警；4尺寸通過 |
| `connection-lifecycle` | `b0d231066fa456a88d717d85976a07baa53e712be1c917763bdf5aec3faef0e4` | `9363d40a2d3e6618c10160e95b5e81dc844b7c7cd38e126ac0e43f35a1eb7136` | `7fffb03cb40cf493f3764017fcc55ffa25fc53ee0b0aab1bd53b2b47cd41b8f8` | 9/9、0錯／0警；4尺寸通過 |

Canvas scene SHA-256 `5aff38f4cb087c540c861f126cb5fb85811988d7a305f13e140719f3cbf06948`；HTML `881e4605adbb93646ae87647c1e54f48001e3a96f08f7bf8ab25cbe1321f0a55`。validator0errors／0warnings、nativebuildexit0。真Chrome1440×1100、全新私有profile／有界2000ms載入截圖已親看，沒有改viewer。原生圖片只放私有scratch；[視覺記錄](visual-review.md)記真正檢視，不修改nativepending。

三張Archify皆showcase9/9、0compositionerrors／0warnings；visual-check四尺寸1440×900、1600×1000、1920×1080、2048×1320 containment／readability pass，最小／最大light／dark共12張實際PNG親看。沒有裁切、縮字或overflowhidden掩蓋失敗。R08／R09獨立審查與最終Humanreview仍待後續。

## Source 與可行性來源

[R03／R04契約](../../../../../plan/github-persistent-connection/evidence/verification-host-contracts.md)、[production隔離](../../../../../plan/github-persistent-connection/evidence/verification-host-isolation.md)、[R05／本輪審查帳](../../../../../plan/github-persistent-connection/evidence/verification-host-review.md)及[R06新host真人結果](../../../../../plan/github-persistent-connection/evidence/verification-host-live.md)分列fake、受控與真服務。R06a–f新host成功、各段Human0僅依該Tester收據，不重跑真人。App README於R07作doc-only現況更新；R03／R05／R06原30檔hash收據保留，其他29檔仍與實測相同，不宣稱current30全相同。

自然到期／profile更新後讀回／certificate rotation／公開分發未驗證；同Mac／GUIuser／有效profile／相同AppID／privategroup／原certificate與固定位置是前提。profile更新仍未驗證、Human已接受限制，E007unknown不改pass。原Rivet名義host／舊圖不是新版驗收；[長期說明](../../../github-oauth-dual-client.md#獨立驗證-app-與可行性結果)與[歸屬manifest](../../../../../plan/github-persistent-connection/evidence/verification-host-manifest.md)記版本界線。
