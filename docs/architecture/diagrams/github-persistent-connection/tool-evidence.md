> **歷史圖表索引：此版 production 歸屬已撤回。** 下方原文與原native圖／收據保留 `ca00bc0`，source `7e81b77` 僅供追溯；當時真人build在commit前，依原sourcehash，不能當新驗證App已驗收。請改讀[獨立驗證App v2圖](verification-host-v2/BUILD.md)與[新host真人結果](../../../../plan/github-persistent-connection/evidence/verification-host-live.md)。本頁原產品完成／舊UI或API敘述僅屬歷史，未回改工具receipt。

# 工具證據與有限 fallback

## Archify／architecture-canvas

Archify pin 2.16、runtime package 2.16.0-dev.0；使用本機技能 CLI，沒有 install／upgrade。三圖均以 `--repo-root .` 產生原始 repository-relative delivery／visual receipts，並綁定 spec／artifact SHA。不是手動投影，不修改 trusted HTML 或凍結 receipt。9checks 與四尺寸及 12 張親看截圖見 [BUILD](BUILD.md)、[visual-review](visual-review.md)。Canvas 只作者 `scene.js` 純資料，由技能 validator／build 組裝；5 bands、17 boxes、16 edges、0 errors／0 warnings，最終 viewer 已實際截圖親看。

## PR Lens

本機 pinned CLI `pr-lens --version` 回 `0.11.0`，help 可用；已讀 graph document schema／example，明確要求真實而不同的 base／head commit。repository `.github/pr-lens.yml` 不存在（no-config），本輪不建立 config 或 `.pr-lens` workspace。

S09 當時尚無本 topic source commit，不能拿相同 SHA 偽造 change map。本輪用已鎖 manifest 的 bounded working-tree source 逐檔對照契約與 immutable S08 證據：

| 邊界／變更 | 直接 source 核對 | 保持的鄰接責任 |
| --- | --- | --- |
| OAuth public composition | `Contracts/GitHubOAuthAppConfiguration.swift`、`OAuth/GitHubOAuth.swift`、`OAuth/GitHubOAuthAuthorizationSession.swift` | 既有 OAuthTokenFetcher／bundle／HTTP token fetcher ports 與 concrete 隔離 |
| 完整 DPK pair | `Stores/GitHubOAuthDataProtectionStores.swift` | 原 legacy KeychainTokenStore 與原 OAuthCredentialStore 不遷移、不改 contract |
| 只讀 provider disposition | `Providers/OAuthTokenProvider.swift` | single-flight／停止與 accepted-save-failure policy 保持 |
| host／Presentation／probe | `apps/Rivet/Sources` 四檔、`Sources/Presentation/GitHubConnection` 兩檔 | PR Inbox／Reader 不改；leaf 不 import GitHubIntegration |
| 共用雙 client | `GitHubClientScope.swift`、`REST/GitHubHTTPClient.swift`、`GraphQL/GitHubGraphQLClient.swift` | client 自持工作與一次 401 recovery，generic HTTP auth 未改 |

上表前三列的相對路徑根為 `Sources/BoundedContexts/GitHubIntegration`；Scope 真實位置為 `Composition/GitHubClientScope.swift`。這是 source-verified fallback，不宣稱已產生或 validate/render PR Lens map，也沒有假造 base/head/PR 編號／URL。S12 依核准流程在真 code/topic commit 後，用實際 base／該 head 建立 bounded code-change graph，外部 scratch validate／render、核 output manifest，後續 docs commit 補實際 IDs／manifest SHA／coverage；map 不冒稱涵蓋後續 docs commit。沒有 analyze/provider API、auth、upload、canvas、外連發布或 PR write。

## Graphify

每次 CLI（包括版本）均設 `GRAPHIFY_NO_AUTO_REFRESH=1`；`graphify --version` 實際回 `0.9.73`。限定檢查 `.graphify`、`graphify-out`、`graphify-out/graph.json`，均不存在，因此沒有可查詢且可驗 freshness 的現成 graph；不以 query 失敗冒充 navigation 成功，不新建 graph／cache／stamp／hook／config。

改用指定 source 的 targeted `rg` 與局部讀取，回查實際關係：Coordinator 持有 provider／operationTask 並依 disposition 決定 retry；RivetApp 注入完整 DPK store 與 production fetcher；GitHubClientScope 提供共享雙 client；AccountProbe 明傳 GET/user headers 且僅 200 有效帳號；Presentation leaf 無 BC／integration import。圖中的重要邊皆可回到上述 source，而非依 graph 推論。未呼叫 semantic／provider、extract/build、watcher、MCP、URL clone 或外部服務。

## 狀態

輔助工具 fallback 不代替 correctness review；S09 沒有 Swift 變更，不重跑已綠的 Swift tests。S10a Tester／S10b Reviewer 已 approved、requiredFixes=[]，RF-D01／RF-D02 均獨立解除；S11 Human 已實際接受。既定 S12 發布結果續記於 step，不以輔助工具代 correctness review。


## S12 真 code commit 的 PR Lens bounded map

- Human 於 2026-10-20 09:51:14 UTC 實際接受圖面與成果，沿原授權繼續 topic commit／push／Draft PR。先前 S09 direct-source fallback 為當時真狀態；本段是取得真 code commit 後的實際 local map。
- 真 repository：`a129924/rivet`；base `16606b89b8e3e6b61523c23aa0be9653c1ea7b44`（dev），code head `7e81b7799a20e49f2cb7209706ebe5b3fd9c7f18`。已讀 `git diff --find-renames <base>...<code-head>`，23 個產品 code／test／project leaves、3171 additions／2 deletions；map 不包含其後 E007／plan／docs／圖／發布收據 commits，也不冒稱其 head 為最終 PR head。
- map 以 external 0700 owned scratch 保存，basename `rivet-s12-publication-20261020`；graph schema0.2.0，4 lanes／10 nodes／13 edges／1 flow／4 walkthrough steps，1 hero edge（Coordinator 完整保存）。所有23 changed leaves 皆有真 repository-relative fileRefs／有效行數；另含5個未變 source 鄰居（Scope、REST／GraphQL clients、HTTP token fetcher、generic HTTPClient），逐檔 diff 核實 unchanged。未變 external GitHub／DPK 同樣標 unchanged。
- pinned CLI0.11.0 `validate <scratch>/graph.json` 成功；`render <scratch>/graph.json --theme both --no-config --out <scratch>/rendered` 成功，原生 renderer0.3.1，manifest4 SVG／2 diagrams。沒有 repo .pr-lens、config、install、provider/API、upload 或 publication；GH Draft PR 走 User 另明確授權的 gh，不使用此 skill 發送。
- graph.json SHA-256=`a489e64533fd77d9c7d9ee8760cc01a69376c3f324d463b67f67a55ed637bc32`；native manifest.json SHA-256=`9b2e6d61d8cdcb2f4eaa47b559b0836f4a669c23193dd4a6e18f02b2204c170a`；native graph contentHash=`f19f87cb6f3454f6b57f48dd04bb3b87`。下表 SHA-256 由實際輸出 bytes 計算，不將 native contentHash 混稱 SHA-256。

| 原生 output basename | bytes | SHA-256 |
| --- | --- | --- |
| `connection-light-99dd770da3e1079b058eefb1eb69e4df.svg` | 17918 | `99dd770da3e1079b058eefb1eb69e4df87510a9e2b6a00968d6b04e0e3744d44` |
| `connection-dark-525eb128378a9ec89c05bd8d9ff9f8ce.svg` | 18097 | `525eb128378a9ec89c05bd8d9ff9f8ce71eae15bc92f5044c858f1017b31cb3b` |
| `authorization-flow-light-bb0f4be277a4a9443d951a453aac6caa.svg` | 15809 | `bb0f4be277a4a9443d951a453aac6caa82c5199c833395f7b2345b9a5a1f8286` |
| `authorization-flow-dark-79d6b2f6502df22cceaca248518f081d.svg` | 15953 | `79d6b2f6502df22cceaca248518f081d8fddb39368fcae4ce5454f6a81677be3` |

四個 SVG 均以實際 Chrome 開本地檔案擷取私有 PNG，再逐張 view_image 親看：architecture 在1708×700、flow在1386×517，light／dark完整文字與箭頭可辨識，無截斷；單一完整保存 hero edge 的 from 為產品 Coordinator，session 僅回 bundle。此為 change-map QA，不是產品 correctness review 或替代已通過的 Archify QA。flow 的 animated=true 是 PR Lens renderer 原生輸出，未改寫 trusted SVG。graph／manifest／SVG／四PNG與 find-renames raw diff 保持在私有 scratch，repository 僅存有限 hashes／coverage，無本機絕對路徑。


## S12 Draft PR 交付

真 code map完成後，E007 evidence與正式plan／長期文件／四圖以獨立topic commits保存並正常push；[Draft PR #62](https://github.com/a129924/rivet/pull/62)已建立，實際readback為OPEN、isDraft=true、base=dev、head=feat/github-persistent-connection。初次PRhead為bd00c3e4b266b1703448b91aff220731241a5335，最後doc-only發布收據commit另由Git／PR讀回核實；map head仍固定7e81b7799a20e49f2cb7209706ebe5b3fd9c7f18，沒有冒稱涵蓋後續E007／docs／發布收據。初次statusCheckRollup=[]，不宣稱CI通過。全部既有commit hooks實際通過，沒有跳過；最後停Humanreview，不merge或發布App／圖站。
