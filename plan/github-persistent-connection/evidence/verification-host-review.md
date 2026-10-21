# 驗證產物歸屬回修：獨立審查帳

本輪R02 planning由獨立Plan-Reviewer approved／requiredFixes=[]，僅放行R03，不沿用舊產品定位approval。2026-10-21 R03 Implementer完成source搬移、自驗與逐檔manifest；不能自審或批准新hostlive。

| 階段 | Owner | 狀態／verdict | 界線 |
|---|---|---|---|
| R04 | 獨立Tester | approved；requiredFixes=[] | TC01–TC07獨立通過；78hosted／202production／12consumer、App缺席普通build；非真人 |
| R05 | 獨立Reviewer | approved；requiredFixes=[] | source／ownership／terminaltracker／tests獨立核對；只放行R06 |
| R06a–f | Tester＋Human | approved；requiredFixes=[] | 本輪六段machine成功；setup/build及五結果段Human全0；非全topicfinal |
| R08 | 獨立Tester | approved；requiredFixes=[] | TC08/TC09、106actions／87hash／61immutable、三圖9/9／四尺寸／Canvas重建與親看 |
| R09 | 獨立Reviewer | approved；requiredFixes=[] | 最終scope／claims／新舊來源與圖一致；只交R10 |
| R10 | Implementer | pending | stagedtopiccommits／hooks／push／更新原DraftPR62 |
| R11 | Human | pending | 最終review，不merge |

舊S01–S12、舊5份evidence及native圖保留為原版本歷史，正式產品交付宣稱撤回；E007unknown與Human接受限制保持。不把舊0次提示、舊approval或本輪mock當新host結果。

## R04 獨立 Tester 收據

2026-10-21，verdict=approved，requiredFixes=[]。commands／實際結果／原生logs及私有收據SHA記[contracts](verification-host-contracts.md#r04-獨立-tester2026-10-21)，production還原及App缺席證明記[isolation](verification-host-isolation.md#r04-獨立隔離重驗)。受審source／tests未改，僅追加本角色evidence／step。現交R05獨立Reviewer；R06a–f真人及提示數null、R07/R08/R09/R10/R11均未代填。profile更新後讀回仍未驗證且Human已接受限制；不是新hostlive批准。

## R05 獨立 Reviewer 收據（2026-10-21）

- verdict=**approved**；requiredFixes=`[]`。獨立於R03作者及R04 Tester，讀四正式artifacts、專案與SDD契約，直接逐段審查App-local OAuth／DPK／UI／coordinator／relay／probe／refresh／DTO／tracker／controlledclock／receipt及對應測試；未代修source或重跑已綠測試。
- D19舊production路徑全不存在，M4精確回base16606b89；Sources／Tests／Package／packages整體zero-diff，沒有保留新增productionAPI、共用UI、control或receipt。新App僅單向依賴既有GitHubIntegration／RivetHTTPClient publicproducts及系統frameworks，沒有RivetPresentation或production反向依賴，未合流／去重PR61。
- 每providergeneration獨立Mutex tracker只讀真實fetcher／save結果：credentialRejected、rotationIndeterminate／afterRequestStarted及accepted-savefail對照原provider；nonterminal錯誤與兩次已過期rotationlimit不誤停，成功save清marker。查tracker不額外呼snapshot／prepare／網路／store；Coordinator保留operationhandle至實際settlement，所有reauth／repair先退休，取消／grant／save失敗不復活。latch與終止測試涵蓋相應分支。
- OAuth state／PKCE／exactcallback／有限relay、DPK兩item完整codec／error與identityrepair、無redirect／不重送localrefresh／可信response優先取消等契約保持。testguard早於任何live構造；受控時鐘只限明確新env，真save後才回real，收據0600exclusive／有限hash，名稱／畫面／scheme／product／module／TEST_HOST與namespace明示獨立驗證。
- 直接核34份source/project/test SHA、61份immutable、12份原生log及4份Tester evidence SHA均相符。R04原生78hosted／0failed／0skipped、App全缺席普通productionbuild與202tests／22suites、consumer12／3及24Swiftstrict／plist／pins／deps結果有實證；本角色不把其fake／unsigned結果當live。
- 僅放行既定R06新host逐段真人準備。六段仍pending、promptCount=null；Human「準備完成後可即時配合」只是availability。R07舊宣稱／historybanner及revision圖、後續獨立審查／發布仍待完成；舊host0次不得挪用。E007unknown／profile更新後讀回未驗證、Human接受限制維持，不是最終topicapproval。
- 沒有真App／DPK／Apple／Gitmutation／dev／外部write；僅本review及自身step。私有獨立收據SHA `eb17d6faaaabd86a0bec5be73334013db1202ddd409bd20b4ecc1de7416e84d8`；source／immutable維持鎖定。此刻停止本角色repo寫入。

## R06a–f 新host真人驗證收據

2026-10-21，Tester bounded verdict=approved／requiredFixes=[]；R05受審source及歷史immutable再核未改後，依核准六段逐一取得新host機器結果及Human實際回報。首次真授權保存／API、samebinaryfresh、真正CleanBuildfresh、受控真GitHubrefresh／真DPKsave、輪替後fresh六欄讀回皆成功；各段提示實答0，完整來源與有限hash鏈見[live](verification-host-live.md)。初首exclusive receipt為空設定狀態，未冒稱grant後digest；初bundle在R06c首次直接觀測；controlled非自然到期，profile更新仍unknown／Human接受限制。現交R07 Implementer做既定docs／revision圖，R08/R09成果審查及R10交付仍pending，非正式產品採用／全topic批准。保留全部新舊App／憑證與Apple資產；本角色只追加自身收據／step後停止寫入。

## R08 獨立 Tester 收據（2026-10-21）

verdict=approved，requiredFixes=[]。獨立於R07作者直接核四長期docs／AppREADME／historybanner／v2spec與nativeoutputs、manifest及R06來源；三Archify重新showcase9/9零錯警，privatebytecopy四尺寸visual-check全pass、12canonicalPNG逐張親看。Canvas5/19/17零錯警、native重buildbyte-identical、獨立真Chrome截圖親看，sourceownership／runtime與compiledependency分明。106actions＝status、87hash、143currentlinks／privacy／diffcheck通過；61immutable／R06live未改，README-only新舊來源正確。詳[contracts](verification-host-contracts.md#r08-獨立-testertc08tc09-與來源回查2026-10-21)與[isolation](verification-host-isolation.md#r08-歸屬及歷史來源獨立回查)。私有收據SHA `13cd20f8af19d5fd342613af002d56656bfc10353bc883ce64426707a3e334b3`。

只交R09獨立Reviewer；R10真commit後PRLensmap／push／原DraftPR更新及最終Humanreview未代填。未重跑Swift／真人、未動受審source／docs／圖／App／DPK／Apple資產或Git，僅自己的既定收據／step後停止寫入。profile更新讀回仍未驗證、Human接受限制；不是正式產品能力批准。

## R09 最終獨立 Reviewer 收據（2026-10-21）

- verdict=**approved**；requiredFixes=`[]`。獨立於R07作者及R08 Tester，依四正式artifacts／TC08–TC09審查本輪成果、歸屬、宣稱及來源；R05既有source review保持，未重跑已綠Swift／live／native圖工具，未代修受審source／docs／圖。
- 四長期文件明確撤回正式產品登入交付；App README只作doc-only現況修正，原R03／R05／R06的30hash收據保留，其他29個compiled／resource／project／tests葉檔仍符。D19撤回與M4回base維持，Sources／Tests／Package／packages整體zero-diff，無新增productionAPI、共用UI、控制／收據工具或反向依賴，未合流／去重PR61。
- 本角色直接核87受審hash與R08自身4份收據hash、106actions來源，61immutable及8份historybanner原ca00bc0suffix逐bytes保留；R06live及11份有限machine／Human/UI收據hash相符。新host獨立PID、samebinaryrestore、真Clean／Build不同binary同identity、accepted1／真save1／clock回real、下一observe完整六欄digest相同的鏈一致。setup／build及五結果段Human逐段0只屬新host，沒有挪用舊觀察。
- 初grantprocess的exclusive receipt仍是emptyconfiguration，沒有postgrantdigest；第一次已保存bundle完整digest在R06c。controlled非自然到期、aggregatepairChanged非個別tokenhash、同bytesprofile重建非renewal均明示。profile更新後讀回仍未驗證／Human接受限制，E007unknown及無第三輪保持；不將可行性結果當正式產品採用。
- 新v2精確32leaves反映App-localadapter／DPK／UI／tracker／clock／receipt單向使用既有publiccontracts；runtime經注入port呼叫不誤當productionimport。本角色親看R08真Canvas1440×1100及三張native1440×900PNG（authorization light、restore dark、lifecycle light），箭頭與labels無遮蔽；Coordinator保存／session只returnbundle、samegenerationretry／settlement／retirement與source相符。R08三圖各showcase9/9零錯警／private四尺寸全pass／12PNG親看及Canvas5/19/17零錯警／重建byteidentity的獨立證據有實證，nativevisualReviewpending未改且不等Human接受。
- PRLens在真正修訂sourcecommit前只記working-tree sourcefallback，真map留既定R10；Graphify明示無usablegraph、禁autorefresh與targetedsourcefallback，未造query成功／建索引／改config或公開發布。這些界線符合本輪契約，不引入新gate。
- 只交已授權R10：stageddiff語意／message及mandatoryhooks→topiccommits→真PRLenscoverage→正常push→更新原DraftPR62並readback→R11Humanreview；不重問開始／commit、不新增圖面Human接受前置、不merge。尚未執行的發布不預填，沒有CI不稱綠。
- 只寫本review與自身step；無App／DPK／Apple／dev／Gitmutation／外部writes。私有獨立收據SHA `7f371d4cd30302b502a891d49ca7372b2f28c191da7d9e35c2ddc020dcf89945`。本角色完成即停止repo寫入，保留新舊App／憑證／私有證據供review。
