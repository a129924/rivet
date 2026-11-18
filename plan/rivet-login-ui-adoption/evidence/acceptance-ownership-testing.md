# T06：E011 凍結與驗收歸屬的獨立驗證

> 目前 artifact 以本文末「R06 required fixes 差異複驗」為準；前文保留 RF02 修正前實跑測試與初版 provenance。

- 日期：2026-11-18；owner=獨立 Tester（主 agent，未撰寫 I03 程式）。
- 來源：feature `feat/rivet-login-ui-adoption`，HEAD `44ddbeea6235e9b785b41a9f787c92f52aa85eaf` ＋ I03／R3 未提交差異；不虛構新 commit。實作者明示 source final 後親跑下列檢查，之後只有文件收尾。
- 結果：**T06 自動／source 檢查完成**，交 R06 獨立 Reviewer；不是 code approval、native pass 或新 Human 接受。新 app 未啟動；實際 Canvas 未操作。

## 凍結與來源

E011 使用 `d2332bfff25510a3f78c1fbc8b0d2d9cf953b223`，tree `b6a1e6e1196e64999af9591ec32f09211f1936c6`。三 restore 路徑與三 PR-added 刪除完成後，`git diff d2332bf -- experiments/E011` 為空，且無 E011 untracked；這是 working tree 證據，提交後才可核對新 commit 的 tree ID。沒有整目錄覆蓋。

以原 HEAD bytes 建立外部 baseline，排除六項 E011 與本輪 DEBUG Preview，26 份既有正式核心／root manifest、lock、gitignore／舊 evidence 均 SHA-256 相同，unexpected changes=0。舊 HC01／native／VoiceOver 文件未回填改寫。

獨立核對 build receipt 的 28 份 source bytes、canonical source manifest digest、包裝 app 各檔 bytes／mode／type 及完整 tree digest；全部相符。受測來源 manifest：

`00181908494c9cd347a5fb396b637e2aeea69533068bf2914616180be7e4de39`

## 親跑命令與結果

所有 SwiftPM 命令使用固定 lock、既有 Apollo cache、標準 sandbox；禁止 Git HTTP／HTTPS，帶 `--skip-update --disable-automatic-resolution --disable-keychain --disable-netrc`。工具另用明確外部 scratch／cache／modules 及 `--manifest-cache local`；未更新 root lock、安裝、下載或更改全域設定。`--skip-update` deprecated warning 非失敗。

| 親跑檢查 | 結果與涵蓋 |
| --- | --- |
| root `swift test <flags> --filter RivetLogin` | exit0；16 tests／4 suites；其中正式 helper／typography／content／兩種 initializer 是9 tests／3 suites，凍結 E011 mock flow 為7 tests／1 suite。Filter 同時命中 Demo test module，因此不稱16項都是正式測試 |
| root `swift build <flags> --product RivetLoginDemo` | exit0，0.86s；凍結 consumer 可編譯，未啟動，不代表歷史模擬文案等效 |
| tool `swift test <flags>` | exit0；8 tests／2 suites，0.001s；八啟動 state、3外觀×4字級、10非法參數、合法／過期事件、receipt、form generation／Reset；只證 tool config／parent |
| tool `swift build <flags> --product RivetLoginAcceptance` | exit0，1.12s；實際 built binary SHA 與包裝 app 相同 |
| `swift format lint --strict` | 9個本輪 Swift 檔（含 tool manifest／tests／DEBUG Preview），exit0、無診斷 |
| `swiftlint lint --strict --no-cache` | 上述除 manifest 的8檔，exit0，0 violations／0 serious |
| `bash -n tools/acceptance/login-ui/scripts/build-app.sh` | exit0；另讀取 build script 與實作者 cold-build log，未以 syntax check 冒充執行腳本 |
| `plutil -lint` 新 app Info.plist | exit0；bundle ID／executable／最低 OS 設定相符 |
| `git diff --check` | exit0 |

不重跑無關完整 root suite。原361／32等歷史結果保持其原版本，沒有套到本輪。

## 實際依賴與資源

工具 product 的 `Objects.LinkFileList` 共23 objects，只有 `RivetPresentation.build`、`RivetLoginAcceptanceSupport.build`、`RivetLoginAcceptance.build`，沒有 E011、Demo 或 GitHubIntegration。工具 source 未參照 LoginDemoModel、GitHubIntegration、LoginRequest／LoginOutcome、認證服務或 PAT VO 建構。

SwiftPM description 仍列 root 其他 target 的 planned commands，不能把它們誤稱本 product 皆已編譯。實作者 final cold product log 只編上述三個 modules；獨立 tool tests 另編譯 transitive Apollo 的 Install CLI plugin，但沒有執行安裝。工具仍需 Apollo manifest／固定 cache 解析，不宣稱無 transitive 需求。工具 lock 與 root pins 都是 Apollo 2.1.2／revision `38c202227d0f09508e573dcf22f54885cfb0c5d4`，只有 originHash 不同。

新 artifact `RivetLoginAcceptance.app`，ID `local.rivet.login-ui-acceptance`，未覆寫舊 accepted preview：

- binary SHA-256：`5015e1621050fca4c5f048dea1ef08f0b1a96c743714dde256a5a44ae391312e`
- app tree SHA-256：`256256cb7805d79ad23803ba98210083b28641ef2d95c6e07f975d5e05a83e38`
- 實際 bundle `Rivet_RivetPresentation.bundle` 中 GitHubMark.pdf 共1812 bytes，SHA-256 `37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1`；與正式來源及 packaged bytes 一致。

此處只證包裝內容、依賴與來源一致；未親看新窗口的圖示，不能稱 runtime bundle lookup／畫面載入已通過。

## 缺口與接續

| 項目 | 本輪狀態 |
| --- | --- |
| E011 freeze、core／API 保留、直接正式測試、tool tests／build／包裝 | 上述自動與 source 檢查完成，待 R06 分類 |
| controlled #Preview 真 Canvas 連續操作 | 未執行；compiled wrapper／parent unit 不代替 rendered View callback |
| 新 host 單窗／菜單／實際回呼、Return／Escape、焦點、Show-Hide／PAT identity、21pt捲動、Light／Dark與runtime資源 | 未啟動、未驗；R06後提供 exact app／SHA／有限案例，取得操作當下確認才做T07 |
| Human VoiceOver／必要差異 UI 接受 | HC02 pending；保留舊HC01/source3c9baf3／preview42e99fa／binary4d4cf13...原接受與聲音證據 |
| 真認證／request Adapter／憑證儲存／session／登入後導覽／產品 App 組裝 | 本 topic 不接；工具測試或成功 UI 不表示完成產品整合 |

原 I01／I02 曾授權 E011 修改的歷史保留；本輪是依新邊界恢復既定 source。凍結 source 可編譯，但 HEAD 重建使用現行 `.standard`，不能承諾舊 Demo simulation 文案等效；歷史重現需完整 frozen revision 或舊 binary，沒有新增正式 demo mode 或例外偵測。

Raw logs、source baseline 與 build receipt 保留於 repository 外本輪 scratch；文件不輸出本機絕對路徑。沒有新 app PID、AX tree、截圖、聲音或 native pass，也沒有重試舊被拒動作或沿用其舊授權。

`current_step: T06 completed（自動／source）`；`next_step: R06`；`status: COMPLETE`（不含 native／Human）。

## R06 required fixes 差異複驗（2026-11-18）

獨立Reviewer原verdict needs-rework與RF01／RF02保留。Implementer只修現況Reset文案、build-app.sh與作者證據；本節由Tester親跑，不由作者代填。

| 差異檢查 | 實際結果 |
| --- | --- |
| 指定checkout內原不存在的ACCEPTANCE_RUN | exit1，明確拒絕外部路徑限制；directoryCreated=false，指定目錄不存在 |
| 不指定run、TMPDIR指checkout內既有tool目錄 | exit1，同樣拒絕；前後目錄entries相同，newEntries=[]；只改單次process env，不修改系統設定 |
| 親跑修正版build-app.sh，指定新的外部run | exit0；cold product build／包裝／plist成功；沒有launch或覆寫舊app |
| 新28項source bytes與canonical source manifest | 全符合receipt；和RF02前相比，只有build-app.sh改變，所有Swift source完全相同 |
| 新app逐entries bytes／mode／type及canonical tree digest | 全符合新receipt；resource bytes及rootreadonly before／after均和初版相同 |
| bash syntax／git diff-check | 均exit0；未重跑未變Swift的formal／toolunit tests，原結果仍限其確切來源 |

目前新artifact仍為 `RivetLoginAcceptance.app`／`local.rivet.login-ui-acceptance`，來源HEAD44ddbee＋同topic受控工作區；不虛構commit或沿用舊binary確認：

- 目前source manifest SHA-256：`6c1d5266c7f10f2340ed383604fd8a74b3ff7f00a0411c276bd9df86a195921d`。
- 目前binary SHA-256：`9219bd7656c55287ecb6ab1adc6d37f7f9b51e9b9217c15846cb27d8e0460b10`。
- 目前app tree SHA-256：`6be23f92067767340b21cd00644943f7ffe72adbba3872de320ab94762c59eb3`。
- 目前script SHA-256：`7926ef779ade6a423dde2d00a8a39af2c5707cda302d75e2ec7f7adba004ec60`。
- 正式GitHubMark.pdf仍1812bytes／SHA37623a1d...；resource bundle及rootlock未改。

初版source00181908...／binary5015e162...／tree256256cb...保留作RF02前證據，不能用作目前啟動目標。不同外部scratch的debug binary有不同SHA，不以相同Swift就稱同binary；只會針對上列目前exactartifact提出當下確認。

RF01現況文案已明確分開正式form離開／消失清除，以及受控Preview／acceptance parent Reset換generation；原E011／Human歷史未改。新Canvas／native互動／資源實載／Human聲音仍未執行，HC02pending。交R06只復審兩項requiredfix、此差異證據及目前provenance，不自行改判approved。
