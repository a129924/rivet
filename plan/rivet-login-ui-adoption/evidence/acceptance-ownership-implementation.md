# I03：R3 驗收歸屬實作與自驗

- 日期：2026-11-18；owner=Implementer；topic=`rivet-login-ui-adoption`。
- 來源：feature `feat/rivet-login-ui-adoption`，HEAD基線 `44ddbeea6235e9b785b41a9f787c92f52aa85eaf`＋本輪未commit工作區；P03獨立Plan-Reviewer已approved／required fixes無，按caller明示證據記入帳本，不是作者自審。
- 本輪只依R3 allowlist實作，未commit／push／launch任何新app，未更新root設定或依賴版本。

## 1. E011 六項定點 freeze

指定freeze `d2332bfff25510a3f78c1fbc8b0d2d9cf953b223`，E011 tree=`b6a1e6e1196e64999af9591ec32f09211f1936c6`。逐檔恢復如下，沒有整目錄restore：

| 恢復檔 | freeze Git blob | 結果 |
| --- | --- | --- |
| `experiments/E011/Sources/RivetLoginDemo/main.swift` | `06fc0e261d862c4dcb5c463fbcecfc92124a9e45` | bytes吻合 |
| `experiments/E011/Sources/RivetLoginDemoRuntime/LoginDemoHost.swift` | `0519ea65b0c922aa3525472460aa3a3c4040dc64` | bytes吻合 |
| `experiments/E011/Tests/RivetLoginDemoRuntimeTests/LoginDemoModelTests.swift` | `87301e4e536143fca9add64a90b327b6a3d5c1c5` | bytes吻合 |

僅刪除本PR新增三檔：LoginPreviewConfiguration.swift、LoginPreviewHost.swift、LoginPreviewConfigurationTests.swift（原E011各自路徑依plan R3）。其餘E011原內容不碰，尤其model／README。

工作區對freeze的 `git diff --name-only <freeze> -- experiments/E011` 為空，E011未追蹤檔列舉也為空。這證明本輪working content逐路徑等於freeze；未為驗證改index，未commit的HEAD E011 tree仍是起始a1fd3793...，不得冒稱HEAD已換成freeze tree，後續commit再核對。

Frozen host未傳content，可由目前initializer預設.standard編譯；此語法相容不表示HEAD重建與舊Demo文案逐字／語意等效。本輪E011只保留歷史，不再用作正式驗收consumer；不加formal demo mode／footer或bundle特判。歷史重播只由完整freeze revision／舊binary支持。

## 2. Formal／tool／history ownership

正式root source只改 DEBUG 私有 `RivetLoginView+Previews.swift`：@State phase／字級／content／canCreateToken／generation／last-kind/count，有限合法事件回寫。提交associated String不綁定、不讀取、不保存長度／hash／值，不寫log。Phase/font/content/canCreate控制保留同generation；Reset才改generation並清receipt，保留目前呈現設定。無wrapper Task／timer／service或自動完成，控件在正式component外。

既有正式helper／content／兩種initializer consumer tests已足夠，未新增鏡像tests或formal hook；未建立RivetLoginConsumerTests.swift。不import E011／GitHubIntegration，不重建登入VO。以下readonly檔與起始HEAD逐bytes相同：

| Readonly來源 | SHA-256 |
| --- | --- |
| `.gitignore` | `be6d6a9d53c51fc1a4b83760745a2f2f6f16d368311c696f00995c107a80a348` |
| `Package.resolved` | `7d3387a0b8f2bb5244bff91b9118e8ba17b3f71861a5a8a31c6693163449d4db` |
| `Package.swift` | `fa4132032dbb0561189857b43c6fc55b29b13dc6b406ee527e2fdbf53ff33ffe` |
| `Sources/Presentation/Login/LoginMethodSelection.swift` | `17829627a157ac2347f3e89da817786458d19100dcc0fc7ee267b90f8e3ee9d3` |
| `Sources/Presentation/Login/LoginOAuthSection.swift` | `1ad81b7b81ad5b601b89814a21d6a10660f797c8be9078a38b6ad904757b2d0c` |
| `Sources/Presentation/Login/LoginPATForm.swift` | `56014bc66bf15f7bef880ea01950de25d98f2c5e5f2403b2263a386aead97b1a` |
| `Sources/Presentation/Login/LoginStatusNotice.swift` | `99c015fb5ba77f26dbbd813d27547e7082098044838e7fe7d20ead3e7d0199dd` |
| `Sources/Presentation/Login/LoginStyles.swift` | `8b3712069cbc98bc3b8a47527690281c0fb457623de362bebcaf847f95359aec` |
| `Sources/Presentation/Login/RivetLoginArtwork.swift` | `fc3ddf512ec076c89e7c97f6c0a11c856ca28f2b326188e1623b184416d9ab03` |
| `Sources/Presentation/Login/RivetLoginContent.swift` | `75692aa1c6edf4c2d3feee5328a93180c11441c72ddd7b3f972a8d9aaf6f60f4` |
| `Sources/Presentation/Login/RivetLoginPresentation.swift` | `aa6d55000cae1960ef75a546137e30d182c891b2f1b2b00af3d0ec076979b493` |
| `Sources/Presentation/Login/RivetLoginView.swift` | `838db5a5c01764156c4178f4b6dccfe78054004d5483f662db40d931c84f574c` |
| `experiments/E011/README.md` | `915f3a5b4e7029e02aea78513868151b26b8eed1941d37c7986d8fbdb346be09` |
| `experiments/E011/Sources/RivetLoginDemoRuntime/LoginDemoModel.swift` | `3b00d2aa9968081fb1efb1290ea505de53bfeeb0959d30f0d6a1bcf8fc27f809` |

root Package Git blob仍為af69162fa848074fe62c9a4fd8d4056e3e3c6102。舊evidence／凍結圖未修改。Login adoption僅追加本輪ownership，從OAuth topic heading起的registry尾段與HEAD bytes完全相同；未改其他topic程度／決策／限制。

## 3. Tests 與 controlled Preview 的實際涵蓋

| 作者執行的檢查 | 實際結果與適用限制 |
| --- | --- |
| Tool red | exit1，最小Support placeholder下新tests因無LoginAcceptanceConfiguration／Parent而編譯失敗，歸因於新能力尚未實作 |
| Tool green | exit0，8tests／2suites；八state、3外觀×4合法字級、10非法args，合法phase事件／stale no-op、kind/count、create可用性、同generation及Reset。只證工具parent/config，非View實際callback |
| Root正式Login filter | exit0，9tests／3suites：RivetLoginPresentationTests／RivetLoginTypographyTests／RivetLoginContentTests；直接正式helper/content／一般consumer initializer，不跑無關root suites |
| Tool product build-app | final run exit0；標準SwiftPM sandbox、固定依賴、rootreadonly guards；未launch |
| Scoped Swift format | 9files exit0；只DEBUG wrapper與tool Swift來源／manifest／tests |
| Scoped strict SwiftLint | 9files exit0、0 violations；Host長if綁定的opening-brace衝突已以短guard修正，不改lint設定 |
| build-app script syntax | `bash -n` exit0 |
| Root／freeze／history | source／lock hash及逐路徑diff核對通過；獨立Tester另核，作者不代填其結果 |

Tool tests的最後compile與sourceguard調整只影響Host私有guard拼法；final product已在新run重新建置並以來源manifest核對。Controlled #Preview已編譯，但本輪沒有啟動Xcode Canvas做rendered操作，因此R3-TC03真正連續點擊／PAT保值／焦點／聲音仍有gap；不能用parser或parent自己收intent來填正式View integration pass。

## 4. 最小 native tool 與 offline build

工具只有下列11個檔案，三個targets（Support／executable／tests），不改root products/targets：Package.swift、Package.resolved、README.md、scripts/build-app.sh；Sources/RivetLoginAcceptance/main.swift；Support下Configuration／Parent／Host／Fixtures四檔；Tests下ConfigurationTests／ParentTests兩檔。

必要性限於獨立NSWindow、標準Edit responder chain／Return/Escape、焦點、resource bundle與Human聲音差異。App主窗780×500最小content、預設.standard、中性footer／failure；一個原生Acceptance menu提供phase／13-17-21字級／standard-controlled copy／canCreate／Reset／唯讀kind-count，無獨立Controls窗、overlay或新快捷鍵。Menu寫入同一parent/root；Reset才改generation。只公開工具啟動function，不向正式library增加public API。

外部初始test run別名 `$R3_TEST_RUN`=`rivet-login-ui-adoption-r3`；最終build run別名 `$ACCEPTANCE_RUN`=`rivet-login-ui-adoption-r3-final`，均在系統暫存根、checkout外。需要的cache是feature既有 `.build/repositories/apollo-ios-b9a1b528`，已核對bare／固定revision後copy至外部cache。工具local path dependency雖只取Presentation，SwiftPM仍解析root transitive Apollo manifests/cache；不宣稱零cache需求。root與tool pins同為Apollo2.1.2／38c202227d0f09508e573dcf22f54885cfb0c5d4，own lock originHash=`9d5d8720693b04e772ef550491516e461bb02199915316160ed5102d9eaffd02`，root originHash=`8e65da25ec3dc05e19beca8a886041da802fb1aa4d4d2b5ab054156cb7b52dbe`，差異不代表版本更新。

工具tests／build使用README與腳本明列的 `GIT_CONFIG_COUNT=2`／HTTP與HTTPS=never、`--skip-update --disable-automatic-resolution --disable-keychain --disable-netrc`、external scratch/cache/modules／local manifest cache，標準sandbox保持，不改HOME或全域設定。首次缺own lock時的明確resolve只從既有cache取得固定版本，後續build停用自動resolution。root Package.resolved SHA前後皆 `7d3387a0b8f2bb5244bff91b9118e8ba17b3f71861a5a8a31c6693163449d4db`；Package及gitignore亦有前後guard。root正式filter使用feature既有cache，不更新root lock。`--skip-update`只有工具鏈deprecated提示。

腳本不launch／不停止app，不覆寫已存在artifact；新app與過往RivetLoginPreview.app完全分開。SwiftPM description中的其他planned targets不是實編證據；產品compile/link與test plugin編譯分開由獨立Tester核對，不把Apollo plugin編譯當執行安裝。

## 5. Final source／binary／resource／完整 app SHA

新artifact為 `$ACCEPTANCE_RUN/native/RivetLoginAcceptance.app`，bundle ID=`local.rivet.login-ui-acceptance`。它不是舊4d4cf13...binary，舊啟動許可不能套用。Final build receipt位於 `$ACCEPTANCE_RUN/acceptance-build.json`，內含28項source清單、app各檔案／mode／resource等完整資料，均為root或run相對路徑；下列來源已重新核對目前bytes一致。

- Source manifest SHA-256：`00181908494c9cd347a5fb396b637e2aeea69533068bf2914616180be7e4de39`。
- Binary SHA-256：`5015e1621050fca4c5f048dea1ef08f0b1a96c743714dde256a5a44ae391312e`；2554720 bytes。
- 完整 app tree SHA-256：`256256cb7805d79ad23803ba98210083b28641ef2d95c6e07f975d5e05a83e38`。
- Tree hash定義：按relative path排序，對含type／mode、檔案bytes與SHA或symlink target的canonical JSON取SHA-256；不含timestamps；收據在app外，避免自我雜湊。
- 實際resource bundle=`Rivet_RivetPresentation.bundle`；複製來源是本次tool product build輸出，非舊wrapper假定位置。檔案存在與copy bytes核對不等於已實際render圖示，T07另驗。
- `nativeLaunch: not-run`；沒有啟動新app、Canvas或操作／停止其他app。Plist語法檢查OK，不是native接受。

| App內resource | bytes | SHA-256 |
| --- | --- | --- |
| `Contents/Resources/Rivet_RivetPresentation.bundle/GitHubMark.pdf` | 1812 | `37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1` |

| 實際build來源（完整清單） | SHA-256 |
| --- | --- |
| `Package.swift` | `fa4132032dbb0561189857b43c6fc55b29b13dc6b406ee527e2fdbf53ff33ffe` |
| `Package.resolved` | `7d3387a0b8f2bb5244bff91b9118e8ba17b3f71861a5a8a31c6693163449d4db` |
| `tools/acceptance/login-ui/Package.swift` | `2125c1c8ec3fd8da36e1daaef02fdcba845fcd4c4a020e8ae6473d8118b70194` |
| `tools/acceptance/login-ui/Package.resolved` | `1e72f0b04ea62c3e1268ea870f026100dfebea9c1822d7b5b5d95599c23c4c0d` |
| `tools/acceptance/login-ui/scripts/build-app.sh` | `fd2a62c5afe67def7c60818a3d69acba4fe78aa6919f42f15a59e004171a48bb` |
| `Sources/Presentation/Login/LoginMethodSelection.swift` | `17829627a157ac2347f3e89da817786458d19100dcc0fc7ee267b90f8e3ee9d3` |
| `Sources/Presentation/Login/LoginOAuthSection.swift` | `1ad81b7b81ad5b601b89814a21d6a10660f797c8be9078a38b6ad904757b2d0c` |
| `Sources/Presentation/Login/LoginPATForm.swift` | `56014bc66bf15f7bef880ea01950de25d98f2c5e5f2403b2263a386aead97b1a` |
| `Sources/Presentation/Login/LoginStatusNotice.swift` | `99c015fb5ba77f26dbbd813d27547e7082098044838e7fe7d20ead3e7d0199dd` |
| `Sources/Presentation/Login/LoginStyles.swift` | `8b3712069cbc98bc3b8a47527690281c0fb457623de362bebcaf847f95359aec` |
| `Sources/Presentation/Login/RivetLoginArtwork.swift` | `fc3ddf512ec076c89e7c97f6c0a11c856ca28f2b326188e1623b184416d9ab03` |
| `Sources/Presentation/Login/RivetLoginContent.swift` | `75692aa1c6edf4c2d3feee5328a93180c11441c72ddd7b3f972a8d9aaf6f60f4` |
| `Sources/Presentation/Login/RivetLoginPresentation.swift` | `aa6d55000cae1960ef75a546137e30d182c891b2f1b2b00af3d0ec076979b493` |
| `Sources/Presentation/Login/RivetLoginView+Previews.swift` | `e652b868e3c8d287a814e7eda19e42471044c92eb0f0e93caeef03cec9fa2c34` |
| `Sources/Presentation/Login/RivetLoginView.swift` | `838db5a5c01764156c4178f4b6dccfe78054004d5483f662db40d931c84f574c` |
| `Sources/Presentation/PRInbox/InboxHeader+Previews.swift` | `21c958517a33ada2418b427b0b32014264afed44a1c3ae8e3d10116c921aff17` |
| `Sources/Presentation/PRInbox/InboxHeader.swift` | `ce0925188a8a25be51a7345cd92e2762f8b2b400e5fffdfb7b08e49a69cceb28` |
| `Sources/Presentation/PRInbox/PullRequestList+Previews.swift` | `370c31f70e196f620dd9443fb602495d3102a2f969ba558781626b73247f79d6` |
| `Sources/Presentation/PRInbox/PullRequestList.swift` | `f53ed4aa683e2496099aabc73b396f84bc61f3174929ac12d88424ef68be6537` |
| `Sources/Presentation/PRInbox/PullRequestRow+Previews.swift` | `6b31538b53e8f241e04cc264bbc8ea2e14ff0c7034b99b3451548675bf030acc` |
| `Sources/Presentation/PRInbox/PullRequestRow.swift` | `e2a679513041c43aa64e261a5dcabfc083d20397df7ef6e0db1733780aeb2401` |
| `Sources/Presentation/PRInbox/PullRequestRowPresentation.swift` | `23b1eb80e972794563a21c637d9bfde516371f296abf293857552a4cce44b574` |
| `Sources/Presentation/Resources/Login/GitHubMark.pdf` | `37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1` |
| `tools/acceptance/login-ui/Sources/RivetLoginAcceptance/main.swift` | `a2321b42b470faca5611f7eb03e9a1368001aa16badcb4209ac08e7cfe8da1c4` |
| `tools/acceptance/login-ui/Sources/RivetLoginAcceptanceSupport/LoginAcceptanceConfiguration.swift` | `9257334ea4134ccd4be90b6947cab60a2c5dec539ab17c3a678b6b40eac0acbf` |
| `tools/acceptance/login-ui/Sources/RivetLoginAcceptanceSupport/LoginAcceptanceFixtures.swift` | `c34a9077575aa71e22067705cd2272caa8f703378fb360df95e7821515391e3a` |
| `tools/acceptance/login-ui/Sources/RivetLoginAcceptanceSupport/LoginAcceptanceHost.swift` | `91a3342e55c903c392a9faa56c4e39ffbb8baf9e652b3a7a3479d9d5132b1829` |
| `tools/acceptance/login-ui/Sources/RivetLoginAcceptanceSupport/LoginAcceptanceParent.swift` | `7b75ce1dc4e2103e8d8b63490ddf5c747ffef272338ada7a7fde61ad804f7c48` |

不同scratch重新建置可能因debug路徑／build UUID得到不同binary SHA；不能用同source就宣稱另一binary已獲當下確認。後續需要針對上述exact app/source/SHA提出有限native案例，R06後取得當下確認，才可啟動。

## 6. 完成程度與獨立交接

I03作者已完成R3六項freeze、controlledPreview及最小工具/source/docs/build/test交接；正式既有能力與Human接受保持，LU-A05只改為凍結歷史consumer，新tool是驗證素材，不是新增產品認證／儲存／session能力。

獨立T06依實際source／cache／app hash核對tests、freeze、readonly、資源與consumer ownership；其結果記自己的acceptance-ownership-testing.md，作者不修改或自審。R06再核對source/diff與差異證據。Canvas實際互動、新NSWindow/Menu／ReturnEscape／same-window callback／focus／大字捲動／resource實載及受影響Human聲音尚未驗；T07/HC02 pending，不套用舊HC01。原I01/I02、T/R/H歷史與HC01/source3c9baf3／preview42e99fa／binary4d4cf13...接受完整保留。

本輪未stage／commit／push／launch／merge。Source/docs可依原授權與獨立review交付，native缺口不能被寫成pass；沒有新增正式服務或設定proposal。


## 7. R06 required fixes 差異附錄（作者修正，待獨立驗證／復審）

R06原needs-rework及RF01／RF02證據保持，不由作者改判。

- RF01：`docs/presentation/login-ui.md`現況狀態段分開記錄正式form離開／消失清除，以及現行controlled Preview／acceptance parent明確Reset更換form generation；新consumer的rendered／native Reset仍待驗。沒有改寫歷史E011觀察或Human接受。
- RF02：`tools/acceptance/login-ui/scripts/build-app.sh`先canonical解析並檢查指定run位於checkout外、既有app輸出不衝突，通過才mkdir／寫receipt。沒有指定run時，先canonical檢查TMPDIR parent存在且在checkout外，才於該parent建立新temporary run；拒絕路徑不先建立run。所有Swift、root manifest／lock／設定未改。
- 作者只執行`bash -n`與`git diff --check`，均exit0；未重跑整套tests／build，未launch／commit／push。非法run無目錄副作用與外部正向build由獨立Tester補驗，不以作者source判讀代替。
- 修正後script SHA-256：`7926ef779ade6a423dde2d00a8a39af2c5707cda302d75e2ec7f7adba004ec60`。上節source manifest `00181908…`及其28項清單只代表RF02修正前初版build，不能再宣稱符合目前script bytes；初版binary `5015e162…`與app tree `256256cb…`證據保留原適用版本。新版receipt／完整source與app SHA將在獨立Tester完成後續記，本附錄完成前不提出啟動確認。

修正已交獨立Tester與R06差異復審；作者沒有給R06 approved verdict，native／Canvas／HC02仍pending。


### RF02 修後目前 final provenance（依獨立 Tester 複驗）

獨立Tester親跑：checkout內原不存在的指定run被拒絕，exit1且`directoryCreated=false`；default TMPDIR指checkout內亦exit1且`newEntries=[]`。修後腳本的外部正向build exit0、plist OK；逐bytes／mode／type及canonical digest核對28項source與app一致。與初版source清單相比僅build script不同，所有Swift未變；rootReadonly與resource bytes相同，沒有重跑未變formal／tool unit。作者不修改獨立T06檔，差異結果由Tester記錄。

目前run別名 `$R3_REVIEWED_RUN`=`rivet-login-ui-adoption-r3-reviewed`，在系統暫存根、checkout外；receipt為`$R3_REVIEWED_RUN/acceptance-build.json`，app為`$R3_REVIEWED_RUN/native/RivetLoginAcceptance.app`，ID仍是`local.rivet.login-ui-acceptance`。

- 目前 source manifest SHA-256：`6c1d5266c7f10f2340ed383604fd8a74b3ff7f00a0411c276bd9df86a195921d`，28項source；與上節初版清單只有build script更新為`7926ef779ade6a423dde2d00a8a39af2c5707cda302d75e2ec7f7adba004ec60`。
- 目前 binary SHA-256：`9219bd7656c55287ecb6ab1adc6d37f7f9b51e9b9217c15846cb27d8e0460b10`；2554800 bytes。
- 目前完整 app tree SHA-256：`6be23f92067767340b21cd00644943f7ffe72adbba3872de320ab94762c59eb3`；canonical定義與初版相同。
- 正式GitHubMark.pdf仍1812 bytes／SHA`37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1`；root manifest／lock／gitignore SHA保持。
- `nativeLaunch: not-run`。初版5015e162…及其receipt保留歷史；本段才是目前修後provenance，不能以相同Swift套用任何舊binary接受。

R06原verdict維持needs-rework，RF01／RF02修後差異已交獨立復審，尚無復審approved；新native／Canvas／HC02 pending，未commit／push／launch。


## 8. R07 RF03 資源包裝差異（作者修正，待 source-only 復審）

獨立 R07 明示 needs-rework，只有 RF03（P2）：初版9219bd76… artifact將bundle放在Contents/Resources，實際generated accessor卻先找app根目錄，再找絕對buildPath。T07圖示可見不能排除fallback；原T07結果INCOMPLETE與原R06approved均依各自來源保留，不改歷史證據。

本輪只修tool script：將實際build輸出的同一正式bundle複製至app根目錄`Rivet_RivetPresentation.bundle`，符合accessor首選路徑；`resources`清單與`appEntries`從新位置產生，GitHubMark.pdf的預期相對位置為`Rivet_RivetPresentation.bundle/GitHubMark.pdf`。不copy至Contents/Resources，不改正式resource bytes、Swift／API／root manifest或E011；未增加Host控制或產品設定。Tool README同步說明主路徑與runtime限制。

- 修後script SHA-256：`9a88a9b2d2b0a90a0e19c3bd3059d5cc28a538d644f0c3c337c9683cda1059c1`；舊source6c1d5266…／binary9219bd76…／app6be23f92…仍僅屬RF03前artifact，本節不把它們當成修後來源。新app、source／binary／resource與canonical app receipt交獨立Tester於全新外部run建置核對，尚未取得新版hash。
- 作者只做`bash -n`與`git diff --check`，不重建／不重跑未變Swift的9formal、7frozen及8tool unit；不launch、不移動cache、不操作現有PID，不commit／push。
- R07只交source-only差異復審，不由作者給approved。T07保持INCOMPLETE；Light、獨立資源fresh-process runtime、新host Human聲音與Canvas仍pending。下一個exact app／binary需新的操作當下確認；Light若使用既有CLI，需一併明示shell `open` 帶args方式，不繞過工具拒絕或提前執行。

本輪source已穩定，交獨立Tester建置與R07復審；原HC01與所有歷史接受不回撤、不套用至新artifact。


### RF03 修後目前 provenance（獨立 Tester 建置，source-only 復審 pending）

獨立Tester於新外部run `$R3_RESOURCE_FIX_RUN`=`rivet-login-ui-adoption-r3-resource-fix` 親跑script，exit0；receipt=`$R3_RESOURCE_FIX_RUN/acceptance-build.json`，app=`$R3_RESOURCE_FIX_RUN/native/RivetLoginAcceptance.app`，ID=`local.rivet.login-ui-acceptance`。28項source及app每entry的bytes／mode／type／canonicaldigest皆吻合；與RF03前6c1d5266…的28source相比只有script不同，所有Swift不變，rootreadonly及resource SHA相同。

- 目前source manifest SHA-256：`3e748de3a3b19225e1a03160d90318037a0be8430b13b911ec2e958b34bdd988`。
- 目前binary SHA-256：`6a7867b568843e6146132c0d96b233f4f93c2f25a1d59e3b726313a4e642c0c1`；2554896 bytes。
- 目前完整app tree SHA-256：`ccfbbd965a9a8b40e4b3df22562f7542d02b2dc28a93f9a3b4a6df2988877cae`。
- `Rivet_RivetPresentation.bundle/GitHubMark.pdf`：1812 bytes，SHA-256=`37623a1d6bed743407256099357e4a5a93c278903932ae55307d1602fb87a3f1`。
- appRoot bundle=true、舊Contents/Resources位置=false，generated accessor首選與新位置一致。純Foundation `Bundle(path:)` probe能取得該PDF；此證據是包裝／Foundation資源解析，並非GUI或app runtime已排除fallback。
- 獨立Tester另記`bash -n`／diff-check0；raw proof別名為`rf03-build.log`、`rf03-artifact-check.json`、`rf03-foundation-probe.log`，由Tester保留外部provenance run，作者不改其證據。

新app已build但`nativeLaunch: not-run`，未動fallback。原9219bd76…的啟動確認不套用新6a7867b5…；source-only復審待獨立R07，作者沒有改判approved。Fresh process受控排除該次buildPath fallback、Light的既有CLI shell open帶args方式及Human聲音，仍須新exact app／source／binary的操作當下確認後才補驗。T07 INCOMPLETE、HC02／Canvas pending，無launch／stage／commit／push。


### RF03 受限交付路由

獨立R07 source-only復審已明示approved、無新增source requiredfix，僅限artifact準備交付及提出exact新app當下確認；原needs-rework歷史與fresh-process排fallback的runtime條件保持。依Human原topic直接commit／push授權提交本輪七檔修正與證據，使用正常hooks，不launch／merge。Current T07 human-check等新6a7867b5…binary及Light shell open帶既有CLI args方式的明示確認；整體T07仍INCOMPLETE、HC02／Canvas pending。不以本段代填未完成的push或native結果，實際commit／push交回主agent核對。
