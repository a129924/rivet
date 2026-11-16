# PAT DPK：獨立 Tester 證據

日期：2026-11-16。角色：獨立 Tester `/root/tester`，非本題 Implementer。分支 `feat/github-pat-dpk-storage`，基準 `5713025e3312c0fbc9a7b02a222db0b91d6e1b58`。驗證對象是 feature worktree 尚未 commit 的變更；基準 SHA 不當作新程式版本。所有 repo 寫入僅本證據及工具產生的必要視覺 sidecars；沒有修改來源、dev worktree、stage、commit、push 或 live 資產。

## 實際執行結果

| 驗證 | Tester 親跑結果 |
| --- | --- |
| `swift test` | exit 0，324 tests／40 suites 通過。包含新 PAT、既有 OAuth、靜態隔離及其他 root suites。 |
| `scripts/check-github-integration-consumer.sh` | exit 0，18 tests／4 suites 通過；新增 PAT consumer 不操作真 Security。 |
| `scripts/check-swift-format.sh` | 首次及白名單回修後均 exit 0，strict format 無診斷。 |
| `scripts/check-swiftlint.sh` | 初次 exit 2，發現 StaticIsolationTests 新白名單排版造成 802 行及函式 82 行越界；baseline 副本為零違規，故不是既存 failure。Implementer 回修後 Tester 重跑 exit 0，143 檔、0 violations。 |
| `swift test --filter StaticIsolationTests` | 白名單排版回修後 exit 0，48 tests／3 suites 通過；不因純排版再重跑完整 suite。 |
| E016 Python unittest discover（`python3 -B`，禁寫 bytecode） | 最終 exit 0，17 tests 通過，包含 source／namespace、exclusive receipt、mode／symlink、Human readiness、觀察綁定、門檻、metadata 與 unknown export。 |
| E016 Swift host `swift format lint --strict`／`swiftlint lint --strict --quiet` | 各 exit 0。 |
| E016 unsigned Debug `xcodebuild ... build` | Tester 使用自己的獨立 DerivedData scratch，`CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=`；exit 0、BUILD SUCCEEDED。沒有執行簽章或 live 啟動。 |
| E016 `--self-test` | Tester 自行編譯的 Debug，以及 Implementer 既有 Debug／Rebuilt unsigned binaries，三次皆 exit 0、fake-only 7 checks／passed=true。實際呼共用 Probe.perform，注入 fake store／journal。 |
| `git diff --check` | 最終 exit 0。 |

工具原始 build／test logs 留在本次 repository 外私有 scratch；公開文件不嵌入本機絕對路徑。Tester 的 unsigned Xcode build 有 headermap style 與未依賴 AppIntents.framework 的 metadata extraction skipped 警告，未使建置失敗；不將警告寫成產品功能失敗。

## Variant 與圖的獨立核對

Tester 比較既有 Debug／Rebuilt unsigned binary，SHA-256 分別為 `6e988374f7956a2579c83db57cafa1d2f8fae8e2ebb0db0c000da1172651c767`／`788d6e41b37fe26c65eb76d8f81e3eb4db7a6881b9150dd04b8e69ab2c795cc3`，確實不同。另讀回 Rebuilt clean/build 實際 compiler log 含 `-DPAT_STORAGE_REBUILT`；不是以 hash 不同單獨證明正確重建。這只驗 unsigned variant，不是同簽章身分或真 DPK 還原證據。

Tester 親跑 Archify sequence `validate --quality showcase --json`：exit 0，9/9 checks、composition errors=0／warnings=0；親跑 delivered HTML `visual-check --repo-root`：exit 0，1440×900、1600×1000、1920×1080、2048×1320 containment 全通過。實際檢視最小／最大兩尺寸的 light／dark 四張截圖，文字、訊息、圖例與卡片可讀，未見裁切或路徑遮擋。Agent visual_review：passed；Human 視覺接受仍 pending，不改寫自動收據 `visualReview=pending`。

核對 delivery receipt 與實際 bytes 相符：specification SHA-256 `3278d938d4a3956575f4042165d499cbd2c19c96add87eed48bc6f717ee78335`；HTML SHA-256 `183d7d8fb833337bfc8fdfca74bddb4ae162ba24f203fb304a129989cc958f10`。本次不修改或重新 deliver HTML。

## 已受測來源摘要

| Repository-relative source | SHA-256 |
| --- | --- |
| `Sources/BoundedContexts/GitHubIntegration/Stores/GitHubPATDataProtectionStore.swift` | `b292562f690bead6a7a73dffaab38c6183d4c92d3b2f1bd0e82139d1a34f8350` |
| `Tests/GitHubIntegrationTests/GitHubPATDataProtectionStoreTests.swift` | `2b06626eb0201ceefae0f2671a08f9c9e1983803f8a3a8471c51b203cfb017d4` |
| `Tests/GitHubIntegrationTests/StaticIsolationTests.swift` | `91acda5d48204db3e21c98c01e06300fdc55d7e93cd2720ed16b35a82c45fc79` |
| `Tests/GitHubIntegrationConsumer/Tests/GitHubIntegrationConsumerTests/PATStorageContractTests.swift` | `9e3b231a4a2ea24a217ac34a22bb26d67bb8ce3753e3363a93c8c1911b6384b3` |
| `experiments/E016/github-pat-dpk-storage/Sources/main.swift` | `79c70131cdafe633a2afa141354e50a8e7e895fa40ba149049a8e3e80e0bd47f` |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `6710bdb32f59f9d9399a23e08b585f866248640aa0d0434f8df8ce669f992412` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `e800de244f4e1ecd32865e5166e82536206066a8b593e9042a556e8c63b69f1d` |

## 限制與交接

本結果僅為離線驗證，不是獨立 Reviewer 的 correctness verdict。Graphify 無既存 graph，依計畫採限定來源搜尋，未建立 graph。PR Lens map 由實際 commit diff 另行製作，本證據未預填 map 成功。

本題真 DPK、有效 profile／簽章環境、跨程序與真正同身分重建還原、Human 提示觀察、真項目 cleanup 與 Human 最終接受均未執行，維持 pending。沒有呼叫本題真 Keychain、建立／輪替 signing assets、或沿用 E015 真人結果。交獨立 Reviewer 檢查 bounded diff 與上述實際證據；不得因此宣稱整個 topic 完成。

## RF-P05-01：獨立 bounded 補驗

2026-11-16，Reviewer 指出 runner post-host guards 失敗後，原始 completed host receipt 不得單獨放行後續觀察／export。Implementer 在 runner 新增獨占、耐久的 accepted proof，綁定 run／phase、attempt／host／build／source proof 的 SHA；只有 open 正常結束且全部 guards 通過才發布。`observed` 必須驗證 accepted proof，`export` 分開記錄 hostOutcome／runnerAccepted，缺 acceptance 時維持 unknown。

Tester 親跑最終 E016 Python unittest discover（`PYTHONDONTWRITEBYTECODE=1 python3 -B`）：exit 0，**20 tests 通過**。其中實際呼叫 launch 的四個負向 subcases 為 binary mismatch、variant mismatch、重複 OS process tuple、open timeout 但 host 已寫 completed；皆不能產 accepted proof、不能讓 observed 前進，export 均為 unknown／runnerAccepted=false。有效 launch 的正向案例可耐久接受並通過觀察；build proof 改變會使既有 acceptance 失效。

抽查實際 launch／accepted／observed／export 接線與上述測試一致；所有 child／signing metadata 使用 mocks，沒有真 Security、簽章或 App launch。Swift／project 未改，故不重跑已通過的 root Swift suites 或 unsigned builds。前文 17 tests 與當時來源 hash 保留為歷史；本節 20 tests 及下列兩檔 hash 為本次 runner 回修的較新驗證，不將兩輪合併成測試總數。

| 回修來源 | SHA-256 |
| --- | --- |
| `experiments/E016/github-pat-dpk-storage/scripts/pat_storage_probe.py` | `7a99371c838c0b3d6e9b01b0d6f549ba48a84e58d6ed7dffca20fce6a934b205` |
| `experiments/E016/github-pat-dpk-storage/Tests/test_probe.py` | `853cd6da878166d5c2de16a998c7c41d5c67f0efa5576771eeea583e739cd150` |

本節只回報補驗結果，RF-P05-01 是否關閉仍由獨立 Reviewer 判定。真 DPK／Human／清理與完整 topic 接受仍 pending。
