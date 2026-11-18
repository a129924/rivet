# 正式 hosted integration：N 有限 Live 結果（2026-11-18）

## 結果與目前狀態

本輪以正式 `GitHubIntegrationHostedTests` Swift Testing target／runner 執行 first、fresh 各一次。兩段原生測試皆1案passed、0skip，正式還原ready，交付連線GET /user成功、完整credential readback一致、configuration保持，兩個實際程序均已退出。這是正式測試設施的新N結果，與原E018／L證據分開。

| 段 | 正常執行與機器結果 | Human本輪實答 |
| --- | --- | --- |
| first | 正常CLI建置並freeze本輪產物；原生1案passed、PID99645於16:29:36啟動並退出；既存credential未到期，prepare及final refresh／save皆0 | 「0 次提示 全程觀看」 |
| fresh | 同一context及frozen artifact，無rebuild；原生1案passed、PID2898於16:33:08啟動並退出；同一完整credential、同帳號，prepare及final refresh／save皆0 | 「全程觀看 / 0 次」 |

時間為Asia/Taipei。First／fresh starttime與PID不同；每段正常CLI先exit3等待人工觀察，再以各自正常attest取得exit0。Human由主session重新詢問取得，不是Tester代為觀察，也不沿用E018或first答覆。兩段budget各1/1已用盡，停止任何額外phase、重試、preflight、簽章、DPK／API操作。

兩段均為有效credential還原，`initiallyExpired=false`、`naturalRefreshObserved=false`；沒有真refresh或rotation-save coverage。Prepare／API後final計數分開；均configurationLoads1、credentialLoads1，refreshAttempts／accepted／saveAttempts／saves皆0。Fresh的sameCredential／sameAccount及distinctActualProcesses皆true。N06獨立Reviewer已對本次機器／Human、safe bytes／SHA、provenance、coverage及歷史不變性明示approved、無required finding；核准只涵蓋本次有限結果，不代替Human最終topic接受。

## 來源與受測產物

正式runtime維持原`e31a75a`來源，沒有複製或修改還原邏輯。Runner的nested test bundle與inside-out signing兩個受限修正當時尚未commit，由未提交工作樹的source manifest逐檔凍結後編譯；不能稱`df801f6`已包含這兩個修正。

- Source aggregate：`7cd86cd4ef9603fdd890911c19adcf6b97180e244a616552612e7db399eae131`
- 正式first／fresh共用artifact：`bc78a4ab7c3bf85b7dbf179acef35e21bdff222e9148d6c55b0c4541da1afc9d`
- Embedded profile：`6e5978b96171d38238e9b0525049907ba72f20d85dca4642238e342370da08eb`；有效至2026-11-23T06:19:04Z。
- Context bytes SHA：`c759c7a4af83920588cd6ef0eff79022c63aa8c6e6ba3af322a516f39c5ebf1d`；context本身不公開、不複製到repo。

Actual phase artifact與preflight artifact `0311950c8d7005854c9785e9cbebb9a8ba8a26e2d9c2c893b294075c35a0473d`分開記錄；正式first正常建置，不用preflight產物代替。Source、host／test bundle／依賴／固定xctestrun及其他產物pins在first／fresh間保持。

## 原失敗、修正與準備證據

原N03純build後因錯選外置xctest簽章路徑停止，來源`aeccff…`；NR01修nested路徑後，NR02純preflight又因App內SDK framework複本沿用舊seal但缺sealed files，host deep strict驗證失敗，來源`ac2e…`。兩個失敗roots、proofs、pins及blocked歷史原樣保留，不改成passed。

NR11僅在明示兩個Python檔實作App-bound executable discovery／inside-out signing；27純mock回歸與完整Offline的正向2案、預期原生失敗2案，由獨立Tester驗證通過。NR12唯一新純preflight中，9個App內embedded code、nested test bundle與host共11個targets逐一strict通過，host原deep strict及測試列舉通過；沒有簽SDK、刪seal或降格驗證。NR13獨立Reviewer approved、無required finding，核准範圍為修後來源／pins及準備資格。

純mock／Offline、純preflight、正式first／fresh、Human觀察及N06獨立結果審查分開，不把任一層當成其他層的通過。舊L／M、E018及其他實驗的結果與額度不回填。

## 安全收據與Human綁定

以下4檔為Tester生成explicit allowlist的exact bytes副本；不重新序列化、添加或回填欄位。Safe projections不含token、secret、raw clientID／account、identity、profilePath、控制key或私有路徑。原machine及先前safe資料的pending欄位不改寫，Human另檔保存。

| 檔案 | SHA256 |
| --- | --- |
| [first](hosted-live-first.json) | `3b1f275972596aec1355990a117d28691d011a83fd510cb1fddd07bae2ddc88c` |
| [first Human](hosted-live-first-human.json) | `55204cf81e84209ac17016c6ea45aa68765a5954875a394da53dd0835cdb351f` |
| [fresh](hosted-live-fresh.json) | `c62b2ca56d86023b7f69491cbe24a85739112ea3fb02a86be6abbba20380a2a9` |
| [fresh Human](hosted-live-fresh-human.json) | `47aa84ce5f09ba17f82a1d14e63f736b24d2256a4bcf4648bb0b7df83fc9bdf4` |

First Human綁原machine SHA `58eeaecadb679ff501f01694a98f407ac4e217412bbad77157f958e98f562441`；fresh Human綁`89fc51a9b65d122bac3b27226781ad887edc4f1d456f52b61caf66ff81998bf7`。原machine／process／xcresult／context／key等私有資料不複製到repo。

## Goal / Non-Goal / 邊界

Goal為正式hosted設施的既存有效連線還原、API、完整讀回與新程序continuity。適用當次同機、同GUI user、既有certificate、當時有效profile、exact group及唯一writer。沒有新Apple資產、登入、seed、clear、forced expiry或重用E018。

Non-Goal為產品E2E、普遍遠端repository權限、所有機器／帳號／環境、profile續期、斷電durability及本輪未發生的真refresh／rotation-save。本地ready本身仍不代表遠端權限；本輪GET /user只支持當次帳號查詢。

本次只寫安全證據及必要文件，不改凍結程式、不刪舊證據或補償已接受rotation。H01／M06及topic Human最終接受pending；N06有限結果已approved；N07 commit／push／Draft PR更新仍在交付中，尚未完成。
