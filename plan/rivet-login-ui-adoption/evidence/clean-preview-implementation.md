# I02：乾淨原生預覽入口實作

- 日期：2026-11-17；owner=Implementer；topic=`rivet-login-ui-adoption`。
- 來源：feature worktree `feat/rivet-login-ui-adoption`；HEAD基線 `a7a2fad277ada1dfaeed26d0fad6178c40123f03` ＋本次未commit工作區，不虛構新SHA。
- Human明確要求正式Login外觀的乾淨preview；本次是既有UI範圍的有界入口修正。Technical-spec／plan I02 addendum已先記錄路徑、CLI、責任及差異驗證，未新增topic／架構／approval gate。

## 已完成與責任邊界

- E011新增獨立 `LoginPreviewHost` 與 app-local `LoginPreviewConfiguration`，同一既有executable以 `--preview` 分流；沒有新增target／package。
- Preview只組合正式 `RivetLoginView(content: .standard)`，不建立Controls視窗、overlay、debuglabel、事件計數或測試選單。Native主窗沿用780×500最小content與原生chrome；僅一般Quit／Edit選單。
- `.standard`不含footer或failure message：host明確提供中性footer `Connect your GitHub account to Rivet.`，browser failure為 `Sign-in couldn't be completed. Please try again.`，token failure為 `The token couldn't be verified. Check it and try again.`。不使用 `LoginDemoCopy` 或模擬failureMessage。
- Parent重用既有LoginDemoModel的fake intents處理。沒有timer、自動完成、認證service、VO建構、儲存或session。等待／驗證中不會假裝自行成功；可用啟動參數直接檢視完成畫面。
- 原DemoHost／Controls／model／copy未修改；一般executable無 `--preview` 時仍保留原展示用途。正式 `.standard`／View／components／intents行為bytes不改；現有Xcode `#Preview`只替換footer及failure展示字串。
- T02／T03／H01–H08及R02／R03歷史保留；本次preview不宣稱Human接受，HC01仍pending／no merge。原圖／lifecycle不變。

## CLI 與 wrapper

同一executable接受：

```text
--preview
  [--state welcome|pat|waiting|verifying-account|verifying-token|browser-failure|token-failure|completed]
  [--appearance system|light|dark]
  [--text-size <finite 13...21>]
```

預設welcome／system／13。缺值、未知／重複選項、非有限或超範圍字級在建立NSApplication／視窗前拒絕，主入口回usage與exit2。

已準備且**尚未launch**的獨立原生wrapper：`.build/clean-preview-i02/RivetLoginPreview.app`。此路徑由Git ignore；沒有覆寫舊wrapper或停止／啟動其他app。Bundle ID=`local.rivet.login-ui-preview`，CFBundleExecutable=`RivetLoginDemo`，顯示名稱為Rivet。Main入口依此bundle ID預設加入 `--preview`，因此直接open無args不會誤開Demo／Controls；附加state／appearance／text-size仍走同一parser。

- Binary SHA-256：`4d4cf13f719e8e609101900074e659928c5acf3790ea8ac527b8a06b720a7eea`；2541888 bytes。與正式root build產物逐bytes相同。
- Presentation resource bundle已複製且逐bytes核對：
- `Contents/Resources/Rivet_RivetPresentation.bundle/GitHubMark.pdf`：`37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1`。

後續Tester／Human以獨立bundle／wrapper辨識此預覽；本輪沒有操作任何現有app。參考啟動方式（由後續授權執行者實際launch）：

```sh
open .build/clean-preview-i02/RivetLoginPreview.app
# 檢視其他狀態前，先確認並結束同一preview，再以同一app重新啟動：
open .build/clean-preview-i02/RivetLoginPreview.app --args --state token-failure --appearance dark --text-size 21
```

## 實際自驗

| 檢查 | 結果與限制 |
| --- | --- |
| Red：新增配置／host測試 | exit1，尚無LoginPreviewConfiguration／Host／Error而編譯失敗；可歸因於新入口未實作 |
| `swift test … --filter 'LoginPreviewConfigurationTests\|LoginDemoModelTests\|RivetLoginContentTests'` | 最終exit0，15tests／3suites通過；含八種scene、四種合法字級值、12組不合法args、中性failure與既有fake event routing、Demo／正式copy隔離 |
| 首次green嘗試 | 四個字級斷言因測試以CGFloat比較Optional Double失敗，已修成明確Double值；不是UI或parser defect，最終重跑通過 |
| `swift build … --product RivetLoginDemo` | exit0，使用同一root manifest既有executable；最終binary已與wrapper核對 |
| scoped `swift format lint --strict` | exit0；只限本次5個受影響Swift檔 |
| scoped `swiftlint lint --strict --no-cache` | exit0，5files／0violations；先前兩個formatter換行造成opening_brace finding已用局部命名／短條件修正，未改配置或擴scope |
| 核心／依賴／原Demo bytes | 下表13檔與a7a2fad逐bytes相同；Package及Package.resolved未改，E011 README亦無diff |
| Native呈現／單窗／無展示文字 | 本輪未launch，留T04獨立驗證，不將unit/model tests當作native驗收 |

Build／test均在feature worktree用既有固定依賴、標準SwiftPM sandbox；沒有 `--disable-sandbox`、依賴更新或新下載。命令前設定 `GIT_CONFIG_COUNT=2`，將protocol.https.allow／protocol.http.allow設never；SwiftPM共用參數為 `--skip-update --disable-automatic-resolution --disable-keychain --disable-netrc`。`--skip-update`只產生既有deprecated提示，不是建置失敗。沒有改HOME／全域設定，沒有重跑無關完整root suite。

## 可核對來源

| 本次來源／測試 | SHA-256 |
| --- | --- |
| `experiments/E011/Sources/RivetLoginDemoRuntime/LoginPreviewConfiguration.swift` | `4793640724c1e5c95d0c73126020bd8548d133cb908d69116262b74dd6097daa` |
| `experiments/E011/Sources/RivetLoginDemoRuntime/LoginPreviewHost.swift` | `e8a825d5dec97d751bbc4c9766d38b5e8542b9760c4f130b806339bce1de275d` |
| `experiments/E011/Sources/RivetLoginDemo/main.swift` | `d1ec6654389c06b34aba406c9317ce7c2ddabd7b2ab35f763547cf8a15384e5a` |
| `experiments/E011/Tests/RivetLoginDemoRuntimeTests/LoginPreviewConfigurationTests.swift` | `0562886be6a66c77faebefce1029e02c917d847595e5845a7a3ba4bc44050523` |
| `Sources/Presentation/Login/RivetLoginView+Previews.swift` | `3f860c65cda68fb5261c49637a5ece3aee04d9b1cc4dd72ef58f6bec4e23ef34` |

| 與HEAD基線相同的核心／依賴／原展示檔 | SHA-256 |
| --- | --- |
| `Sources/Presentation/Login/LoginMethodSelection.swift` | `17829627a157ac2347f3e89da817786458d19100dcc0fc7ee267b90f8e3ee9d3` |
| `Sources/Presentation/Login/LoginOAuthSection.swift` | `1ad81b7b81ad5b601b89814a21d6a10660f797c8be9078a38b6ad904757b2d0c` |
| `Sources/Presentation/Login/LoginPATForm.swift` | `56014bc66bf15f7bef880ea01950de25d98f2c5e5f2403b2263a386aead97b1a` |
| `Sources/Presentation/Login/LoginStatusNotice.swift` | `99c015fb5ba77f26dbbd813d27547e7082098044838e7fe7d20ead3e7d0199dd` |
| `Sources/Presentation/Login/LoginStyles.swift` | `8b3712069cbc98bc3b8a47527690281c0fb457623de362bebcaf847f95359aec` |
| `Sources/Presentation/Login/RivetLoginArtwork.swift` | `fc3ddf512ec076c89e7c97f6c0a11c856ca28f2b326188e1623b184416d9ab03` |
| `Sources/Presentation/Login/RivetLoginContent.swift` | `75692aa1c6edf4c2d3feee5328a93180c11441c72ddd7b3f972a8d9aaf6f60f4` |
| `Sources/Presentation/Login/RivetLoginPresentation.swift` | `aa6d55000cae1960ef75a546137e30d182c891b2f1b2b00af3d0ec076979b493` |
| `Sources/Presentation/Login/RivetLoginView.swift` | `838db5a5c01764156c4178f4b6dccfe78054004d5483f662db40d931c84f574c` |
| `Package.swift` | `fa4132032dbb0561189857b43c6fc55b29b13dc6b406ee527e2fdbf53ff33ffe` |
| `Package.resolved` | `7d3387a0b8f2bb5244bff91b9118e8ba17b3f71861a5a8a31c6693163449d4db` |
| `experiments/E011/Sources/RivetLoginDemoRuntime/LoginDemoHost.swift` | `59de88fb03df7c7aea4da6521af3fd13313ce5d5d97d1eb177f5ef1b34545408` |
| `experiments/E011/Sources/RivetLoginDemoRuntime/LoginDemoModel.swift` | `3b00d2aa9968081fb1efb1290ea505de53bfeeb0959d30f0d6a1bcf8fc27f809` |

## T04 差異交接

1. 以已準備wrapper實際launch（包括不附args的預設路由），核對單一主窗與Rivet名稱、無Controls／測試選單／overlay。
2. 核對正式`.standard`各狀態、中性footer／兩種failure，畫面及AX不含fake／simulation／example input only／Demo Controls或測試footer。
3. 用CLI覆蓋八種畫面、Light／Dark與13／17／21pt之必要代表；確認基本選擇／取消／Back／提交仍由假parent響應且不會自動完成，原Demo入口仍獨立保留。
4. 正式核心bytes維持，T02／T03／H01–H08沿用其原來源與限制，只補本次入口／copy／launch差異；不重做或外推全部VoiceOver案例。
5. T04後交R04獨立Reviewer，再回HC01。作者沒有自審／commit／push，不宣稱新preview被Human接受。
