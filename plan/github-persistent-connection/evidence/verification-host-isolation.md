# 新驗證 host：production 與依賴隔離

## R03 Implementer 自驗（2026-10-21）

- `git diff 16606b89 -- Sources Tests Package.swift Package.resolved` 為空：D19舊新增檔不存在，M4修後bytes與base一致，topic前正式能力及原tests未移除。完整from／to／hash見 [manifest](verification-host-manifest.md)。
- 根package graph／products／lockfiles未改；App只連既有 GitHubIntegration、local RivetHTTPClient public products與系統frameworks，不依賴RivetPresentation。只對自身module使用@testable import；沒有production反向依賴、dispositionAPI、visibility擴張或控制key／receipt工具。
- App source imports實際集合：AppKit、CryptoKit、Darwin、Foundation、GitHubIntegration、Network、Observation、RivetHTTPClient、Security、SwiftUI、Synchronization。source24個Swift leaves（15source＋9test）；新App全30個leaves（含README／project／scheme／resources／Xcode生成Package.resolved）。App pins與root pins相同。
- 實際 `xcodebuild -showBuildSettings`：product/module `GitHubConnectionVerification`，bundle `local.rivet.github-connection-verification`，Swift6／macOS15／ONLY_ACTIVE_ARCH=YES／ENABLE_DEBUG_DYLIB=NO／ENABLE_APP_SANDBOX=NO。project與共享scheme、hostedtests核對新target／testmodule／TEST_HOST／key；Info及entitlements為同驗證privategroup。repo不填Team／certificate／profile rawidentity。
- 在本角色新0700私有scratch，逐檔複製當前tracked且仍存在的1128個檔案，**排除整個apps目錄**，因此驗證App完整缺席；未修改production副本或新增stub。對這份實際snapshot執行普通 `swift build --package-path <private-production-snapshot>`：exit0／Build complete。再跑相同 `swift test --package-path <private-production-snapshot> --filter 'GitHubIntegrationTests\|RivetPresentationTests' --skip KeychainTokenStoreTests`：exit0、202tests／22suites pass。沒有用舊basearchive冒充當前副本。
- E00732與舊native圖29共61leaves對ca00bc0逐bytes核對不變；未改舊evidence／原生收據、原安裝App／真DPK或Appleassets。README等錯誤產品宣稱留既定R07修正，不能因source已隔離就認為文件已完成。

此處是自驗；獨立R04仍pending。真signing／DPK／GitHub與提示觀察全部 [live pending](verification-host-live.md)，不能以unsigned fakehosted結果替代。

## R04 獨立隔離重驗

- Sources／Tests／Package.swift／Package.resolved相對16606b89完整zero-diff；D19不存在，M4與base bytes相符。D19逐個舊SHA對ca00bc0、新SHA對App-local bytes核符；30個App leaves及受審時62個status leaves皆在精確manifest內，無新增未授權production契約。
- 43交接hash及E00732＋舊native29全部核對；61immutable項另以git show ca00bc0逐bytes重核。舊evidence／導覽及原安裝App／真DPK／Apple資產本角色未修改。
- 實際source imports僅既有publicproducts與系統frameworks，無production @testable import、無RivetPresentation／production反向依賴，無App-local public／open surfaces。production內無驗證namespace／控制key／receipt工具。
- Tester自有當前source副本，排除**整個apps**後普通swiftbuild exit0；相同productiontests202／22及publicconsumer12／3全pass。未用舊base archive、未修改副本production或補stub；因此整個驗證App移除後production可獨立build/test。
- 新target/module/product/scheme/testhost、畫面常駐驗證字樣、新bundle/group/service/key與root一致pins均核符；privatebuildsettings／原生xcresult與sourcehash鏈見contracts及私有收據。格式／lint／plist／pins／privacy／diffcheck通過。

R04 verdict=approved／requiredFixes=[]，只交R05；R06真人與R07文件圖仍pending，不推論正式產品能力或profile更新成功。

## R08 歸屬及歷史來源獨立回查

R07 106actions對實際status、87finalhashes核符；production Sources／Tests／Package／locks及packages對base16606b89完整zero-diff，D19／M4還原保持，沒有新增productionUI／API／env／receipt或反向依賴。R04 App全缺席普通build／202tests／consumer12等既有實證沿用，不無故重跑。

App30中的README由R07作doc-only現況更新，其餘29source／project／resources／tests bytes仍與R05／R06受測相同；舊README與舊manifest私有快照SHA核符，不修改R03／R05／R06歷史30hash。R06live原8c5c0b8a…05ea1、E00732／舊native29共61immutable仍逐bytes保持，8份歷史文件僅banner prepend、原ca00bc0完整suffix不變。

新版32diagramleaves與App單向依賴、publicports／runtime、Coordinator保存ownership及非產品定位一致；無PR61合流／去重或工具config變更。R08僅追加自己contracts／isolation／review／step，未修受審source／docs／圖或碰任何真App／憑證／Apple資產。verdict=approved／requiredFixes=[]，交R09；尚非發布或最終Humanreview。
