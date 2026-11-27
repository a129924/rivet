# E025 · PR Inbox I2 原生驗證

這個 macOS App 使用 Variant B `InboxWorkspace`、正式 `PullRequestList`／`PullRequestRow` 與 `InboxListStatus`。驗證 App 提供四欄資料，持有選取與焦點，並透過正式 `GitHubSelfReviewSource` 和 `PRInboxFacade.refresh()` 取得完整結果。 [採用計畫](../../plan/pr-inbox-native-list-adoption/pr-inbox-native-list-adoption.plan.md)

## 受控驗收

從 repository 根目錄使用既有 Apollo 快取與根套件 pin。若快取在其他位置，將 `APOLLO_CACHE_SOURCE` 指向對應的 bare repository。

```sh
bash experiments/E025/scripts/verify.sh test
bash experiments/E025/scripts/verify.sh regression
app="$(bash experiments/E025/scripts/verify.sh build)"
open "$app"
```

啟動後用底部「受控情境」擬定下一次回應，再按「重新整理」。依執行計畫選取 `sample/ui #42`，重排及改名後核對第三列仍是選取列，移除後核對回到 `sample/core #42`。第二頁案例實際暫停在 REST 第二頁，待畫面顯示「已到第二頁，等待驗證」時先核對畫面，再按「讓第二頁失敗」。

關閉先前的 I2 驗證程序後，可用 `open "$app" --args --fixture=failure`、`--fixture=empty`、`--fixture=page-failure` 分別驗證無舊清單的情境。寬版與 420 pt 窄版各確認標題、repo 與編號，共四個資料欄位。

## 既有 OAuth 真人驗收

使用一個依現有簽章身分、有效 provisioning profile 與授權 access group 簽署的驗證 App。建置時以 `RIVET_I2_BUNDLE_ID` 與 `RIVET_I2_ACCESS_GROUP` 提供相符設定。若原工作階段使用自訂 service，另以 `RIVET_I2_OAUTH_SERVICE` 指定。依照既有 profile 與 entitlements 簽署產物後，用 `open "$app" --args --live` 啟動。此入口檢查 App 自身 entitlement，再用正式 restorer 取得既有 scope。確認同一憑證的其他 writer 已停止。

為暫存 E025 App 簽章前，先將外層的 SwiftPM `.bundle` 移入 `Contents/Resources/`，並保留此次 SwiftPM 建置產物至驗收結束。將有效 profile 放在 `Contents/embedded.provisionprofile`，用原憑證與 entitlements 簽章後執行 `codesign --verify --deep --strict`。

以畫面底部的 OAuth 帳號與 GitHub PR 詳情獨立比對作者與 open 狀態，再核對原生列的 owner、repo、number、title。若使用私人樣本，原始畫面留本機。 [既有 OAuth 還原契約](../../docs/architecture/github-oauth-startup-restore-runtime.md)

## 原 I2 驗收

I2-01～06 受控原生驗收通過。更新 profile 並以同一 OAuth App 完成登入後，I2-07 真人原生上屏亦通過。 [受控驗收](evidence/acceptance.md) · [真人驗收](evidence/i2-07-live.md)

## 正式元件採用驗收

採用後回歸以受控 E025 App 和既有 E024 原生入口執行。另跑 `swift test --filter RivetPresentationTests` 涵蓋正式 Row 與 List。 [採用後驗收](evidence/native-list-adoption.md)
