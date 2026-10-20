# 可跨重啟持續使用的 GitHub 連線：需求

- Topic：`github-persistent-connection`
- 狀態：Human 已接受 profile 更新後讀回尚未驗證的限制，受限採用 DPK 並授權繼續產品；S04e completed，S05 pending，僅此 gate amendment 待獨立回查。
- 更新：2026-10-20，Plan-Creator；依 Human 明示決策修訂唯一 renewal 採用前置，其他契約及證據不變。
- 配對：[技術契約](technical-spec.md)、[執行計畫](../../plan/github-persistent-connection/github-persistent-connection.plan.md)、[帳本](../../plan/github-persistent-connection/github-persistent-connection.step.md)。

## 意圖與成功結果

單一使用者在正式 Rivet 入口完成自有 GitHub.com OAuth App 授權後，安全保存完整 credential；完整結束程序並重啟仍可使用 GitHub API，access token 到期時自動刷新並保存輪替結果，無法繼續時提供可區分的下一步。

端到端結果是「產品入口 → 初次授權 → 保存 → 重啟還原 → 自動刷新 → GET /user 顯示目前帳號」。分段 source、實驗或 mock green 不等於此結果通過。首版以唯讀帳號結果證明連線，不整合 PR 業務。

## 已鎖定決策

1. 單一 Mission；不新增 BC。GitHub-specific authorization／DPK adapters 留在 non-BC GitHubIntegration；Application composition 擁有連線 coordinator、provider／scope；Presentation 只接收 display-ready input／intent。
2. 單帳號 GitHub.com、可到期且可 refresh 的完整六欄 bundle；重用現有 provider／雙 client ownership、single-flight、snapshot version、expiry-first refresh 及 HTTP 401 最多一次原工作重送。
3. Human 選 DPK；系統提示判準維持首次 ≤1、同 binary fresh-process 0、同身分真正重建 0，不因候選失敗而降低。原採用前置要求相同 App ID／private group／certificate 的 profile renewal／reprovision 讀回成功；Human 現明確接受該項尚未驗證的限制，僅此前置解除，其他產品驗收不變。
4. 使用者自有 OAuth App、本機自用；首次由產品輸入 client ID／secret，secret 與 credential 分為兩個 DPK items。不是公開分發的 embedded shared secret，也不導入 broker。
5. 不重開既有 ownership、credential lifecycle 或 generic HTTP auth 決策；正式 interfaces 僅 additive。
6. Branch 為 `feat/github-persistent-connection`，base／PR target 均為 `dev`；沒有既定 owner 慣例，不加 owner。

## In Scope／Out of Scope

納入最小 signed Rivet.app、首次設定／授權、callback 驗證、完整保存與還原、刷新與輪替保存、同 App 修復／必要重新授權、有限連線狀態、GET /user、脫敏診斷、契約／真儲存／正式入口驗證、長期文件與圖。

不包含多帳號、帳號或 App 切換、GitHub Enterprise、PAT、device flow、broker、完整 logout／remote revoke、PR Inbox／Reader adapters、一般 retry／pagination／rate-limit framework、多程序或跨裝置 refresh 協調、實驗／legacy store 遷移、公開發行／完整 notarization，以及 generic HTTP auth 改寫。

## 可觀察行為與驗收

| ID | Given／When | Then |
|---|---|---|
| AC01 | 無資料；完成正式產品設定與真授權 | 設定先保存；完整 credential 保存後才建立 provider／scope；GET /user 成功顯示目前帳號 |
| AC02 | 已保存有效資料；完整退出再開啟 | 不必重新瀏覽器授權即可取得帳號結果 |
| AC03 | access token 到期、refresh 可用；執行操作 | 自動 refresh、先保存完整輪替 bundle 再交付 snapshot；新程序讀回輪替結果 |
| AC04 | REST／GraphQL 使用同一連線 | 共用 provider lifecycle；不建立獨立 credential 狀態，401 最多重送一次 |
| AC05 | 取消、拒絕、無效 callback、技術失敗、失效或 stopped | 結果可區分；無效授權不誤存；停止無效 retry並提供同 App 修復／重新授權 |
| AC06 | 遠端已接受 rotation；本地保存失敗 | 不宣告 ready；原 provider停止，不回復舊 token，保留既有停止契約 |
| AC07 | 工作尚未真正結束；取消 caller／返回畫面／要求重新授權 | 舊工作仍受追蹤，不准寫設定或新 bundle；所有 shared work settled 後才能重新授權 |
| AC08 | 設定缺失／損毀、credential 損毀或 ID 不符 | 依完整有效 payload 的可信 ID 修復；暫時不可存取／denied 僅重試、不覆寫 |
| AC09 | 同 binary fresh-process／同身分真正重建 | 系統提示首次 ≤1、fresh-process 0、rebuild 0；觀察不足保留未驗證 |
| AC10 | 真 GitHub／真儲存／受控失敗的交付 | 分列來源與限制；不得以 build、mock 或分段測量宣稱全產品通過 |
| AC11 | logs、文件、測試或收據 | 不保存原始 secret、token、code、完整 callback query 或原始交換 body |

## 儲存採用與證據界線

[E005](../../experiments/E005/README.md) legacy 最終提示為 0／0／1，未符 rebuild 零提示。[E006](../../experiments/E006/README.md) 2026-10-19 在有效 profile 下三段六欄相符、提示 0／0／0；S07／S08 approved 只接受受限實驗證據，S09 Human review 不等於產品採用。該輪 App／私有 setup 已清理，不能拿來當 renewal 資產。

規劃時 E007 尚未建立；建立前已確認編號未占用。2026-10-20 已完成本輪受限嘗試與安全收尾，因 A／B profile bytes 相同而無法判定，renewal read 未執行；獨立 Tester／Reviewer 只接受證據與收尾，停於 Human Check。詳見 [E007 實際結果](../../experiments/E007/README.md)，不覆寫歷史收據。受限問題只問「同 App ID／private group／certificate，真正不同且有效的 renewal／reprovision profile，能否零提示讀回原完整假 bundle？」

Human 在第一輪收尾後明確授權再補一次方法明確的 E007 驗證，保留本 topic 主軸；只額外一輪，以新 UUID／新 t0／新 45 分鐘窗口獨立執行，不重啟或改寫第一輪。方法限定備份後暫移本輪唯一 profile 的本機快取，再由 Xcode 單次 Build 重新取得；官方方法只觸發重新請求，不保證 bytes 不同。第二輪先首存，再移快取；原 certificate／App ID／group／DR 與提示判準維持。只進行一次移出／refetch／B 建置嘗試；無法安全定位、仍同 bytes 或需新 certificate／付費／安全設定即停止，不再追查其他方法。詳見 [E007 第二輪程序](../../experiments/E007/README.md#9-第二輪受限補驗證方法已獨立計畫審查)。

以下為兩輪執行當時的判準與路由（新 Human 接受決策另列於後）：每輪 45 分鐘，35 分鐘停止新增測量，10 分鐘精確清理（第二輪包含快取恢復）。完整讀回且 renewal 零提示為成功；前提成立但拒絕或提示超標為失敗；沒有不同 profile、前提或觀察不足為無法判定。需新 certificate、安全設定或付費資格即停止。當時 gate 為失敗或無法判定停止正式 DPK 採用並回 Human（後續 Human 已接受唯一例外，見下）；成功仍需獨立判讀與符合 Human 採用決策；第二輪符合本次條件授權時無須重問。不能由一次更新推論已過期恢復、certificate rotation 或所有未來週期。Human「通過就回產品實作」是本輪條件式前進授權：唯一補驗證在真正不同有效 profile、同身分、六欄／UX、精確恢復與清理均符合原判準，且獨立 Tester／Reviewer 明示真成功、無重大問題時，S04e 依該實際 Human 決策記錄條件成立並前進 S05，不再重問相同採用許可；目前尚未成立，不預填成功或觀察。第二輪仍無新 profile 時停止追查；是否接受「profile 更新後尚未驗證」並修訂 gate，或改儲存方案，只能由 Human 決定，不預先降低判準。

第二輪實際結果：唯一額外輪已於 2026-10-20 執行並完成有限證據／安全收尾。A GUI 建置與六欄保存讀回成功，首段全程 0 提示；四個精確候選查得一份匹配。私有 raw backup 一份 bytes/hash 相符，但 backup／restore-check 副本新增一個系統 provenance xattr，原檔為零，完整恢復預檢未通過，故在任何移出前停止。removed=0、refetch=0、B 建置=0、renewal read 未執行；這不是已 refetch 仍同 profile，也不證明普遍不可恢復。原 cache 完整未變，不需恢復；UUID 假資料與私有 root 已於原窗口內清理。備份非測量段只有未見視窗的有限回報，全段提示數未確證、保留 null。Tester／Reviewer 的 approved 僅接受證據與安全收尾，主假設仍無法判定。詳見 [第二輪結果](../../experiments/E007/README.md#10-第二輪唯一補驗證實際結果)。

唯一額外輪已用完，不再等待開始訊號、不自動第三輪。原「通過就回產品」的真成功條件未成立；其後 Human 明確回答：「接受 profile 更新後尚未驗證的限制，修訂 gate 並繼續產品實作」。本次只解除「renewal 必須先驗證成功」的採用前置；其他驗收維持，仍保留連線失效處理與重新授權路徑。S04e 因這項實際 Human 決策完成，不把 E007 unknown 變 pass；S05 可依修訂契約繼續，待獨立 Plan-Reviewer 回查此 gate delta 後交 Implementer，不再重問採用。

## 授權、限制與人類邊界

使用者本輪已明確授權：先建立 feature worktree、在其中依核准計畫實作；沒有重大問題時完成 topic commit → push → Draft PR → Human review。這項明確授權涵蓋完成後的 topic commit／push／Draft PR，不重複套用較早的預設逐次確認；仍須依 staged diff 檢查語意邊界與 message，且不能越過未解 blocker、Reviewer verdict 或 Human boundary。

本輪執行授權不表示 E007 profile 更新已成功，也不代替各段 Human 真提示觀察；第二輪原成功條件未成立，後續受限採用依 Human 明示接受未知的新決策，不重問同一許可。免費 Personal Team profile 七日到期並需 reprovision／rebuild；有效 profile 是可用前提，過期期間不可用。真系統操作、renewal 觀察與產品入口驗收必須留實際證據，不能預填。

官方依據：GitHub [OAuth authorization／offline_access／S256／loopback／refresh](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)、Apple [Personal Team 限制](https://developer.apple.com/help/account/basics/about-your-developer-account)、[TN3137](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains)、[TN3125](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)。文件與 source 足以鎖定 authorization 設計，不重做既有 E001–E003；只有 renewal 的實際行為需要新實驗。

第二輪方法依據：Apple [Edit, download, or delete provisioning profiles](https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles/) 的 Xcode cache 更新說明，以及 [Xcode 16 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes) 的新舊 profile cache 位置說明。這些是方法依據，並非 DPK 更新讀回成功的證據。

### Human 受限採用的精確界線

未知只限「同身分 profile 更新後讀回尚未驗證」。首版仍限本機自用、有效 embedded development profile、同 Mac／GUI user／App ID／private group／原 certificate 與固定安裝位置；Personal Team 七日到期、過期期間不可用、已過期恢復／certificate rotation／公開發行未驗證的限制不擴大。E007 兩輪均無法判定且 phase 2 未執行的證據保持。產品 V06 首次≤1／fresh 0／rebuild 0／輪替後 fresh-process，V07 真正式授權／重啟／GET /user／真遠端 refresh 與受控時鐘分列，V08 regressions、V09 工具圖與 Human 產品 UX 全保留。denied 不覆寫、accepted rotation 保存失敗停 provider、雙 client 共用 lifecycle、明確失效及必要重新授權與原 scope 均不變。
