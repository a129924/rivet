# Tester 獨立驗證

- 日期：2026-10-20；角色：Tester。Topic：`github-oauth-credential-persistence`。
- Verdict：**approved**；required fixes：[]。可交獨立 Reviewer，不代替成果審查、發布或 Human acceptance。
- 本輪只新增本 evidence leaf 與更新 step 的 Tester S05 交接；未修改 source、測試期望、其他 worktree、E007 或任何 live Security 資料。
- Package 為 macOS 15／Swift 6，主要交付 GitHubIntegration library；本輪不啟動 executable。

## 實際命令與結果

| 命令 | 結果 |
| --- | --- |
| `swift test --skip KeychainTokenStoreTests` | exit 0；269 tests／31 suites，含新 adapter 13 tests。明確跳過既有 legacy Keychain live suite，沒有宣稱其本輪通過。 |
| `scripts/check-github-integration-consumer.sh` | exit 0；全新 generated scratch build，13 tests／3 suites；public DPK construction 不存取 Security。腳本完成後清除其 exact scratch，fixture `.build` 保持不存在。 |
| `scripts/check-swift-format.sh` | exit 0，strict read-only lint；格式修正後重驗通過。 |
| `scripts/check-swiftlint.sh` | 修正後 exit 0；122 files，0 violations／0 serious。 |
| `swift test --filter GitHubIntegrationTests.StaticIsolationTests` | 格式修正後 exit 0；29 tests／1 suite，含 exact source/import allowlist。 |

初次 default sandbox 的 SwiftPM 執行受 build database／Clang module cache 寫入限制，consumer manifest 亦受同一 cache 限制；以僅限本驗證的 escalation 重跑成功，未把權限失敗算成產品失敗。SwiftLint 初次另有 cache 寫入限制，取得權限後仍確認 `StaticIsolationTests.swift` opening_brace serious violation。已交還 Implementer；其將相同兩個 Security source paths 的 OR 改為等價 Set.contains，未停用規則。Tester 隨後只重跑 strict format／lint 與該隔離 suite，未無故重跑整套。曾使用不匹配的 filter `GitHubIntegrationStaticIsolationTests` 跑出零 tests，明確不算通過；以上 module-qualified filter 才是有效重驗。

Consumer fresh build 有唯讀基線 `JSONSemanticDecodingError.Kind` 非 Sendable 的 compiler warnings；不在本 topic 修改範圍，build／tests 均成功，不能宣稱 build 零 warning。

## T01–T08 適用證據

- T01／T02：獨立 root run 通過新 fake-only suite；configuration 與六欄 round trip、absent、不同 ID 拒絕、過期日期／空 scope、invalid construction 零 Security calls、diagnostics／reflection redaction。corrupt credential payloads 共 25 cases，access statuses 7 cases；unknown version／missing／null／wrong type／empty token／非 bearer 被區分為 corrupt，並不覆寫。nonfinite Date save 於 Security 前失敗。
- T03：逐項核對來源與通過的 query tests：DPK=true、sync=false、明確 group/service/account、AfterFirstUnlockThisDeviceOnly、無 presence/ACL；update→missing add→duplicate 僅再 update 一次；denied 不 delete/retry。
- T04：完整 A→B、3 個 replacement failures 保留完整已提交 A、configuration-first partial save 不 rollback、20 個同 facade views 的 read/write pairs 未交錯。這是 fake 同程序觀察，不是跨 process coordination 證據。
- T05：正式 adapter 注入 fake Security／受控 clock/fetcher，restore 與 rotation bundle 保存後才交付；accepted rotation save failure 成為 terminal persist，第二次 snapshot 不增加 Security calls，fetcher count 維持 1，磁碟語意僅由 fake item 模擬。
- T06：上述四項 required checks 全通過；provider／clients regression 不改期望，隔離測試的允許清單符合獨立核准 amendment。
- T07：獨立重算 sequence spec 與 HTML 的 SHA-256／bytes，均符合 delivery receipt；visual receipt 綁相同 HTML。showcase 9/9、errors=0、warnings=0，四個 containment viewport 均 ok，四張 light/dark screenshot leaves 存在。沿用 Implementer 已完成的 Agent 看圖紀錄，Tester 本輪沒有重跑 Archify 或冒稱自己／Human 實際看圖。Human acceptance 與工具 auto visualReview 仍 pending。
- T08：README／長期文件及圖均明示 fake-only／live 未驗證；尚無 committed source diff，PR Lens 與 commit/push/Draft PR 留待發佈執行者提供實際 IDs。Graphify 依既有 tool evidence 無圖 source fallback；本輪未 build／refresh／安裝或發布工具產物。獨立成果 review 與 Human review 仍待後續角色。

## 圖的重算值

- `storage-sequence.json`：`c15ec952b7676031c8fafc3d11199a19787e6fb6a555a2928bd76d521f419de1`。
- `storage-sequence.html`：`89fbde70f5bc931e258f1a1640ffb975ca238d97c63cb1c4cec0bc6d207ced95`。

## 驗證來源快照

| 檔案 | SHA-256 |
| --- | --- |
| Sources/BoundedContexts/GitHubIntegration/Contracts/GitHubOAuthAppConfiguration.swift | `570bfc17cc8d3c5d4701b47a74043c1294196c52cec95ff8c9831a9761b60e95` |
| Sources/BoundedContexts/GitHubIntegration/Stores/GitHubOAuthDataProtectionStores.swift | `023b33f6bece762acefa628e8975d7646d7457b50524ea37d050db18f4a13b00` |
| Tests/GitHubIntegrationTests/GitHubOAuthDataProtectionStoresTests.swift | `d18708598c9d67ff314d8f603996028ef0ed2a850bf6a8006ae537627d9834a9` |
| Tests/GitHubIntegrationTests/StaticIsolationTests.swift | `9e9cc19fe95e7afde510cc26b93075082e406f5233e589d1864fa364af517071` |
| Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PublicAPITests.swift | `cc256964d47b4f2b4b74251fbe442b08d363506f31b9d703b9735a0331ce14c7` |

## 限制與交接

未執行真 DPK／跨程序儲存／簽章或 profile／系統提示／真 OAuth；本 topic 不依賴他人的 persistent-connection／E007 gate。Fake 通過不代表上述 live 能力。Human 視覺 pending、PR Lens 真 diff 與發佈證據保持待辦。下一角色為獨立 Reviewer，只審本 topic 精確 manifest、最終來源與本測試證據，不將 Tester approval 當成產品或 Human 接受。


## LG92 Tester：dev 衝突整合的獨立局部驗證（2026-11-10）

Verdict：**approved**；required fixes=[]。上游 LG90 approved、LG91 completed handoff 後，在原 feature 的非提交 merge 工作樹獨立閱讀實際 source／staged delta，親跑下列必要非真人範圍；未沿用作者 exit code 代替執行。HEAD 仍 `fbd4434a`、MERGE_HEAD 精確 `758aca9b`，未 commit／push／更新 PR。

| 親跑範圍 | 命令／結果 |
|---|---|
| DPK fake stores／provider／factories／authorization session／code exchange／static isolation | `swift test --skip-update --filter 'GitHubOAuthDataProtectionStoresTests|GitHubOAuthFactoryTests|GitHubOAuthAuthorizationSessionTests|GitHubOAuthCodeExchangerTests|OAuthTokenProviderTests|GitHubIntegrationTests.StaticIsolationTests'`；74 tests／6 suites，exit 0，命令耗時 4.464 秒 |
| 跨 target public consumer | `swift test --package-path Tests/GitHubIntegrationConsumer --skip-update --filter PublicAPITests`；11 tests／1 suite，exit 0，命令耗時 1.445 秒 |
| 原作者 TDD／strict receipts | 唯讀核原 RED 3 tests／1 suite、8 issues、exit 1，GREEN 同 suite exit 0；format／SwiftLint receipts exit 0。受審四 Swift 葉均與作者 hashes 相同；不為重建 RED 改 source，也未重跑未受影響 suite |

### CF01–05 的直接核對

- CF01：`git ls-files -u` 空；八個手動 resolution 葉的工作樹 bytes 與 stage blobs 相同，且與 LG91 handoff hashes 相符。尚未產生 merge commit，不宣稱遠端 PR conflict 已解除。
- CF02：constructor source 與原 feature bytes 完全相同；consumer 真編譯／執行 typed-throws function reference、public fields、兩個空字串 typed error 與全空白／換行的原值保存。兩 factory 的 blank ID／secret 參數化反例及合法路徑通過；直接 source 比對原 dev 的兩個一般 throwing signatures 完全相同。兩入口第一個敘述為共用 validation，位於 fetcher／exchanger／session 建立前；helper 只判 blank、不改寫合法字串，錯誤 enum 的 clientConfiguration 無 payload。配置 diagnostics／reflection 的既有脫敏測試通過。這是 Human 採用的直接 constructor error 差異，不冒稱 dev 直接呼叫端或 App blank-only 起始狀態完全不變。
- CF03：上述 74／11 是親跑的實際合併後整合測試；Security 由原 fake backend 覆蓋，public consumer 的 facade construction 不執行任何 store load／save。未跑真人或完整登入，未以測試成功推論簽章／DPK runtime。
- CF04：獨立 checker 實讀四個衝突 Markdown，102 個相對 links（含 Markdown heading anchors）全部可解析；八個手動葉無 conflict markers、有限秘密／本機絕對路徑 patterns findings。`git diff --check` 與 `git diff --cached --check` 均 exit 0。人工閱讀 merged docs 將首次授權、正式 DPK、受控 provider 與獨立 App 的來源／日期／限制分列；原 unknown／失敗歷史、cleanup／visual／S08 pending 保留。有限 patterns 並非任意秘密的完整辨識保證。
- CF05：以原 auto-index receipt 對照實際 `git ls-files --stage -z`，1,328 個非手動 entries 的 mode／blob／stage 全相同，沒有額外非手動 entry。原兩個個人 metadata bytes 與 merge 前 SHA 相同且完全不在 index。正式 adapter 及 configuration bytes 與原 feature 相同。只追加本 Tester evidence／LG92 row，未 stage／修改被測 source、docs 或其他角色 verdict。

### 證據與停止界線

親跑 stdout／stderr 只留受控私有普通測試 root，兩次命令、elapsed、exit、SHA 與 independent-checks JSON 已工具交接；未在公開文件附私人路徑或 raw diagnostics。原 LG81-Cap-R 的完整 DPK 通過結果保持原來源／假完整 bundle／指定環境限制；本輪新 merged binary 沒有真人驗收，不重做適用成功結果。無 App 建置／簽章／啟動、DPK／OAuth／profile／Apple assets／信任／私鑰權限或清理操作。可交 LG93 獨立 Reviewer；LG94 新 commit message 的 Human 確認仍待，不能沿用前輪 message。


### RF-LG94-LINT Tester 窄核對（2026-11-10）

Completed／approved；required fixes=[]。本 Tester 直接比對真 repo 的工作檔、原 stage／auto-index blob 與已審 candidate：唯一差異是 expectedPaths 前兩個字串之間的換行及縮排，精確單一 span replacement 即得完整新檔，未改字串內 bytes；non-whitespace／token bytes 相同，801→800。原 SHA `14a5aedc7f7553acd534e0a1e3348310fd300fae6408c1af6310a62f852a4508`、新 SHA `1640e25df6e28dc610757e702513875dfbeb3e3f6b6d74e9ce335d95fdc1484d` 與來源／candidate／套用 receipts 逐值核符。

獨立重算三個原 check 的 stdout／stderr SHA 與 bytes、核真 argv 及 exit：單檔 strict swift-format／SwiftLint 均 exit0；`swift test --skip-update --filter GitHubIntegrationTests.StaticIsolationTests` exit0，stderr 有 fresh `Compiling GitHubIntegrationTests StaticIsolationTests.swift`，stdout 明記 29 tests／1 suite passed（suite36.359秒，wall174.046秒）。不是零命中或僅舊 binary 收據。本輪為等價排版，未再重跑29／74／11或新增測試；只核上述已有真 compile 收據，沒有將 wall 與 suite 耗時混稱。

另以完整 index mode／blob 對照原 Human-approved preflight tree，全部相同，尚未 stage 此修復；其他八個手動 resolution 葉及兩個個人 metadata SHA 保持且 metadata 不在 index。HEAD／MERGE_HEAD pin 未變。第一次正常 hook 的 exit1／未 bypass receipt 及原 logs 仍在私有位置，未改寫成成功。私有獨立核對 JSON／失敗 logs hashes 已工具交接；本 Tester 只追加自身 evidence／row，不改 source、stage、commit 或遠端。交獨立 RF Reviewer；原 LG92／LG93 與 DPK 證據的適用限制保持。


## LG98 Tester：post-merge 文件／Git 準備的有限核驗（2026-11-10）

Completed／approved；required fixes=[]。上游 LG96 approved、LG97 completed 後，獨立實讀兩個 experiments diff 與 merge 固定來源，不重跑 runtime。47 個相對 links 含 heading anchors 皆可解析，5 個 unique `c8c989a2` pinned source paths 在該 Git tree 均存在；whitespace、markers、有限秘密／本機絕對路徑 patterns 無 findings。這是有限文件檢查，不是新單元測試或任意秘密辨識保證。

直接核 pinned LG81-Cap-R 原文：完整假六欄 A→Writer 結束→fresh A→整筆 B→fresh B→真正同身分 clean/build→新程序 B、五 runtime Human 全程0提示及原來源限制均有依據。兩文件將 fake Security／受控 provider、真 DPK 假 bundle 與未驗真遠端 OAuth／refresh／API 分開；不擴首 sign 的 permission-only 觀察、不推論今日 profile 或新 merge binary 已真人驗收。以移除新增 row／section，並精確還原 README 日期及 summary coverage／後續擴展一句的逆變換，兩檔完整原 bytes 皆可還原；E004／E005／E007 舊 rows 逐值不變，0／0／1 UX failure、renewal unknown 與各歷史限制未回填。未預填 branch／worktree 移除、docs commit／dev push、LC06／visual／S08 成功。

獨立核本機 annotated tag object `1473dd0571283919a6b3229d14fa4349cf77020d`，並以真 `git ls-remote` 讀回遠端同 object／peeled `c8c989a2e4be99e73c9cdc17e82cc16ada7a489c`。HEAD 為該 merge，雙親仍含 `89bd01a2`，tree 與 feature 相同；不是後續 docs commit。親讀 Git 私有 archive manifest／兩實檔與 merge 前 metadata checkpoint：archive 0700 且 owned；2 檔的 bytes／SHA／原 mode／owner／group 核符，兩 source leaves 不存在且未進 index。Common Git／archive 與既有 known protected roots 均不在 target worktree；只核既有 ignored 五項分類 receipt，不作新清理盤點，也不代替移除當刻 fresh gate。

實際 index 空、untracked 空；本次八個 dirty 葉精確符合已授兩 docs／四 P／owner evidence，無 production 或 runtime 變更。私有獨立 JSON 與 scope checks 已工具交接，公開不附 archive 來源對照／私人識別資料。兩 docs SHA 分別為 `05437b5bccc76fce052ae8786cd13240357afcc2bd5a8e22549595570cec4345`、`7b41dff479c85587ce6f1dac3f2fc5c3e6bba58f7b46b50b1a167c8e972f1f2c`。本 Tester 只追加自身證據／LG98 row；未 stage、commit、push、刪 branch／worktree 或操作 App／DPK／Apple assets。交 LG99 獨立 Reviewer；LG100 新 docs message 與普通 FF HEAD:dev 的同一次 Human 確認仍待，不以既有 tag／archive 授權取代。
