# GitHub 首次登入與當次 API 使用

本機 `apps/Rivet/Rivet.xcodeproj` 的 Rivet scheme 提供正式 SwiftUI 入口。使用者輸入自有 GitHub.com OAuth App 的 Client ID 與 Client Secret，再主動開啟預設瀏覽器；配置及完整 OAuth bundle 僅留當次程序，不恢復、不落盤。

## 責任與契約

GitHubIntegration 仍為 non-BC。新增 `GitHubOAuthAppConfiguration`、`GitHubOAuth.makeTokenFetcher(configuration:)` 及 `makeAuthorizationSession(configuration:redirectURI:)`；現有 refresh concrete 保持 internal。Session actor 封裝 state、verifier 與一次 callback claim，檢查 loopback URI、state、單值 code/error，採 S256、offline_access。無效 callback 不消耗有效等待；取消、到期或重複結果不發布連線。初次交換無自動重送，完整六欄依同一 receivedAt 轉換成既有 bundle。

App 擁有 loopback relay、coordinator、完整記憶體 store、provider／scope 與 `/user` probe；Presentation 只接收 display-ready 狀態及 intents。Relay 只綁 127.0.0.1 動態 port，限制 headers／connections／讀取時間。Coordinator 追蹤單一 operation，取消後等待實際工作 settled；prepare 重試保留原 provider，重複 API 使用原 scope。既有 refresh／rotation／single-flight／401 recovery 與 BC 邊界不變。

成功指 HTTP 200 且 `/user` 的 login／id 有效；不是 callback 或 prepare 成功。Secret 與 token 不寫 diagnostics、檔案或測試證據。產品可顯示自己的身分，但驗收證據只記欄位有效與前後一致。

## 本機啟動

在 Xcode 開啟 `apps/Rivet/Rivet.xcodeproj`，選 Rivet scheme、My Mac，再執行。採 ad hoc 簽章、macOS 15+；不需 Development Team、provisioning profile 或 Keychain entitlement。

也可從 repository 根目錄：

```sh
xcodebuild -project apps/Rivet/Rivet.xcodeproj -scheme Rivet -destination 'platform=macOS' -derivedDataPath .build/github-first-sign-in/DerivedData CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- build
open .build/github-first-sign-in/DerivedData/Build/Products/Debug/Rivet.app
```

OAuth App callback 設為 `http://127.0.0.1/oauth/callback`；runtime 帶動態 port。若需更動外部 App 配置，由擁有者確認。本 topic 不保存配置、不讀 gh credential，也不自行變更 GitHub App。

## 驗證與限制

受控測試涵蓋 callback、單次交換、取消與真 settlement、完整 store、prepare 重試及 API 結果。2026-10-20 Human 在正式 app 完成授權；agent 觀察實際 API 成功，並操作再次查詢後仍顯示成功及一致身分。這只證明本次正向流程，不證明反向 PKCE enforcement、所有遠端 refresh／401 路徑或重啟恢復。

[責任與依賴 canvas](diagrams/github-first-sign-in/index.html) 與 [授權 sequence](diagrams/github-first-sign-in/authorization-sequence.html) 的作者文字為繁體中文；固定 Viewer UI／HTML lang 使用 English fallback。[工具與視覺限制](diagrams/github-first-sign-in/visual-review.md) 如實分列。

持久化／DPK／跨重啟及合流由 `github-persistent-connection` 後續消費本 topic 的授權入口，不另建立競爭 host。正式規劃與 ownership amendment 見 `analysis/github-first-sign-in/`、`plan/github-first-sign-in/`。E001–E003 仍是受限可行性依據，未定結論不升格為實證。
