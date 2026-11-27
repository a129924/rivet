# PR Inbox I2 · 技術規格

## 接線與責任

規劃使用 `experiments/E025` 的獨立驗證 App，重用已採用的 `RivetPresentation.InboxWorkspace`。E024 的原生基線與 E020 歷史證據各自保留。現有 `PullRequestList` 固定組合 `PullRequestRow`，後者寬版會串接必填的作者、時間與分隔點。I2 在驗證 App 使用 SwiftUI `List(selection:)` 和四欄列，維持原生選取。列主文是 title，副文是 `owner/repo #number`。 [E024](../../experiments/E024/evidence/variant-b-native.md) · [共用列實作](../../Sources/Presentation/PRInbox/PullRequestRow.swift)

受控模式注入合成回應的 `GitHubRestClient`，真人模式使用既有 OAuth `GitHubClientScope.rest`。兩者共用 `GitHubSelfReviewSource`、`PRInboxFacade.refresh()`、`InboxItem` 映射與原生畫面。受控分頁提供有效 next Link 和可識別的第一頁 PR，讓第二頁實際回傳失敗。合格 Draft 由輸入 fixture 的 `draft: true`、作者及 open 狀態識別，結果列以完整四欄核對。

## 既有 OAuth 連線

驗證 App 可直接使用同一程序內可取得的既有 scope。若從既有資料還原，以公開 `GitHubOAuthStartupRestorer` 和相符的 DPK 存取條件取得 `.ready(scope)`。還原時確認有效簽章及授權的 access group，並依既有 runtime 維持單一 credential owner。既有 grant 的必要刷新與輪替保存遵循 runtime 契約。入口只使用既有授權，範圍排除互動授權、要求新增 scope、PAT 與憑證匯入。簽章、存取、可用 scope 與真人樣本現況均待此次驗收確認。 [既有還原契約](../../docs/architecture/github-oauth-startup-restore-runtime.md)

真人比對以來源查詢使用的 `/user` 帳號為準。可重用 E020 的觀測方式，從同一次來源請求核對帳號，另由 GitHub PR 詳情獨立核對其作者、open 及四欄。即使使用歷史 #72，也需當場重查。私人樣本的原始畫面留本機，可提交證據使用遮蔽後的畫面及逐欄比對。 [E020](../../experiments/E020/README.md)

## 更新與選取

Presentation Session 持有本工作階段最後一次完整成功的清單與選取。選取鍵為 `(owner, repository, number)`，title 只供顯示。完整成功時一次替換清單，保留仍在其中的選取，否則選第一列。完整成功為空時，清除選取並顯示空清單。每次更新只有一個有效結果可發布。

失敗時，若本工作階段仍有可讀的舊列，保留原清單及有效選取，顯示「清單可能不是最新的」。沒有可讀舊列時，顯示「無法取得 Pull Request」，清單區沒有可操作列。後續頁失敗走同一處理，第一頁的暫時資料留在來源查詢內。啟動時選定受控或真人模式，每次啟動各自建立 Session。
