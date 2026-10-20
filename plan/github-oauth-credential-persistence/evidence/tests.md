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
