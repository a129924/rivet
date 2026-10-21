# v2 工具實證與覆蓋界線

## 圖工具（R07 真執行）

Archify skill pin2.16／runtime2.16.0-dev.0。三spec validate／deliver皆showcase9/9、0errors／0warnings；四尺寸containment各pass、12PNG已逐張親看，nativevisualReviewpending保留。repository-relative原生receipts、不投影／手改生成物，沒有額外frozenleaf。Canvas實際validator5/19/17、0/0，nativebuild及Chrome screenshotexit0，最終截圖作者親看。[BUILD](BUILD.md)列精確命令與SHA，[視覺記錄](visual-review.md)列修正與真人點。

## PR Lens：R10 真 commit 後才建圖

已讀本機pr-lens skill，真CLI `--version` 回0.11.0。repo沒有 `.github/pr-lens.yml`，不新增配置。當前HEAD仍真 `ca00bc074f77fa21a7fac1aaae07dc1059de5b01`，本輪source搬移尚未commit；不能拿舊7e81b77的map當本輪。R07只做bounded working-tree source／manifest fallback：D19撤回、M4還base、App30及App-localrefresh／tracker／UI／project的實際relationships，沒有捏造base/head或map成功。

依既定R10，在受審修訂sourcecommit產生後，以真ca00bc0→該修訂sourcehead的rename-aware diff做localgraph／validate／render／manifest及真截圖，涵蓋精確sourcechanges及unchangedneighbors；若其後docscommit未入map就明列不覆蓋。原PR全差異另相對dev16606b89核productionzero-diff。map只輔助理解，不當correctnessreview；不upload／provider／canvas或用PRLens寫PR。

## Graphify：無可用 graph，定向 source fallback

已讀skill。唯一CLI invocation為 `GRAPHIFY_NO_AUTO_REFRESH=1 graphify --version`，真回0.9.73。既有指定 `graphify-out/graph.json` 不存在，沒有可查revision／nodes；因此不假稱query成功、不自建graph。實際targetedrg核新Appimports與Coordinator.makeProvider、wrapperstore／fetcher、tracker及scopeprepare，對照Appproject兩個既有publicproducts。關鍵關係再讀source確認：tracker只包真refresh／save、不呼額外snapshot；AppUI與DPK不留production；production對basezero-diff。

fallback證據只涵蓋本topic受限source與manifest，不宣稱全repo完整graph、去重或架構偵測。沒有extract／semantic/providercalls／install／hook／watcher／stamp／config／upload；Graphify所有invocation都明確禁autorefresh。私有source-navigationlog與CanvasChromeprofile／圖截圖pointer留本輪owned0700scratch，不入版控本機path或rawAppleidentity。

## 新舊驗證來源

只引用[R06新hostlive](../../../../../plan/github-persistent-connection/evidence/verification-host-live.md)Tester approved／Human各段0；初grantprocess未觀測postgrantdigest，第一次完整oldbundle觀察在R06c；accepted＝persisted＝後續freshrestore新digest不同old。aggregatepairChanged非個別tokenhash，自然到期與profile更新未驗證。舊hostca00bc0／source7e81b77為commit前實測sourcehash歷史，不冒充新App結果。R07不跑Swift／live／Apple操作，只修本輪docs／圖與manifest；獨立R08／R09尚待。

## R10 真 source commit 的 PR Lens map（2026-10-21）

以上R07的pending屬當時紀錄；本節記R10實際產物。source歸屬修正commit `b63af3e51d04487f651ba2fb521fd056f53f1af1` 已存在，正常commit全6個mandatoryhooks Passed，無skip。真base `ca00bc074f77fa21a7fac1aaae07dc1059de5b01` → 真head `b63af3e51d04487f651ba2fb521fd056f53f1af1` 的 `git diff --find-renames --name-status` 有36個rename-aware entries；展開舊／新from/to union為53個精確sourcepaths（D19＋M4＋App30），graph file refs **53/53覆蓋、missing=[]**，另有7個unchanged鄰居檔。對dev16606b89的production Sources／Tests／Package仍zero-diff。

Pinned PRLens0.11.0真validate及 `render --theme both --no-config --out <owned-private>` exit0：4lanes／14nodes／16edges／1flow／3walkthroughsteps，2diagrams／4nativeSVGs。起初generatedAt的+00:00不符CLI，依診斷改Z後通過；首圖卡片省略labels後只縮短4個作者labels再nativevalidate/render，完整summary／53refs不刪。最終4SVG全以全新私有Chromeprofile、按完整SVG尺寸真截圖，light／dark都已view_image親看，未手改generatedSVG。

本map**只覆蓋ca00bc0→上述修訂sourcehead**，不涵後續本輪docs／evidence／v2commit，也不把舊E007或最終PRhead全稱為mapcoverage。graph／coverage／manifest／SVG／Chrome截圖只在外部0700scratch；不寫.pr-lens、config、gitignore，不upload／provider或經PRLens操作PR。R10正常gh更新原DraftPR62另依Human明確授權。

| 私有map產物 | SHA-256 |
|---|---|
| `graph.json` | `386d79008989e6b27afc78e263526a3f61d0ab15a9623c34f1cabb0dd19fd729` |
| `coverage.json` | `460e4f650d9ae29b487eba673ddb2869288f4cba95d57236a0b074d3efc6aa36` |
| `manifest.json` | `b87b7fa2e1ecec196721a6bc1d76a92253b3c50f5e63ed016432e432ef20c41e` |
| `ownership-dark-da6f7391ca9ac2aada902a20fb46da5b.svg` | `da6f7391ca9ac2aada902a20fb46da5b6d1cab2004141463f8909ab476b2c698` |
| `ownership-light-1e91263b5acdfe085ea28d6ac0a5e888.svg` | `1e91263b5acdfe085ea28d6ac0a5e8880b7a90240aafc8dd7884a3b5e8e71515` |
| `runtime-flow-dark-27d6faf7279c3fcf8b49dc83521fe693.svg` | `27d6faf7279c3fcf8b49dc83521fe6930674e7bbdb171c93908ee36646ffd378` |
| `runtime-flow-light-bb5cdb7f5ce4481d0e9450b6fbd88938.svg` | `bb5cdb7f5ce4481d0e9450b6fbd88938f660d8f6fd160461d3c42c36b18eaedf` |

Graphify沿R07已核sourcefallback，沒有可用graph、沒有新build／自動refresh／hooks／upload；所有CLIinvocation帶GRAPHIFY_NO_AUTO_REFRESH=1。本輪source/live/native QA未重跑，只有正常mandatorycommit hooks執行必要checks。
