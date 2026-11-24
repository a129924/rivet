# Cancellation Trace & Contract Review 技術規格

A01 對讀 Swift／Foundation 官方來源與目前程式，標註取消 Task owner、子工作或共享 Task、await 前後檢查、錯誤型別與 wrapping、輸出及實際消費。分開記錄 HTTP、credential、decode failure 與取消。B01 依測試明示斷言標記 Code-confirmed、Test-confirmed 或 Unverified，格式為情境、環境、版本、來源、實際觀察與限制。C01 增加 Experiment-confirmed。

根套件執行以下固定範圍，保留本機已鎖定的依賴。分開執行 HTTPClient 套件測試。

```sh
swift test --skip-update --disable-automatic-resolution --filter 'PRReaderContractTests|PRInboxFacadeTests|GitHubSelfReviewSourceTests|GitHubHTTPClientTests|OAuthTokenProviderTests|GitHubClientScopeTests|GitHubOAuthHTTPTokenFetcherTests|OAuthClassifiedProviderTests|GitHubGraphQLClientTests|BridgeSessionTests'
swift test --package-path packages/RivetHTTPClient --filter URLSessionTransportTests
```

- C01-1 優先使用 E021。ephemeral Foundation URLSession 藉正式 HTTPClient／URLSessionTransport 呼叫 127.0.0.1 的暫用埠。固定 HTTP/1.1 server 收完整請求才告知 harness，扣留回應。對照組收到 200，取消組收到事件才取消。分別觀察 client 的 `HTTPClientError.cancelled`（保留 underlying 類型）及 server 在放行或清理之前的 peer EOF／reset。對照成立且明確的其他 client 結果可否定相應假設。只有 client 訊號時 server 無法判定。
- C01-2 優先使用 E022。經 `GitHubSelfReviewSource(rest:)` 注入 actor 控制的 `GitHubRestClient`，帳號請求成功後卡住最後一筆有效搜尋回應。測試確認等待事件才取消 caller，再交付同一固定回應。對照直接放行。對照成功且取消組為 `.unavailable`、無額外請求時支持預期轉換。成功候選或額外請求可否定相應假設。證據限 Adapter／Facade 與受控 REST。
- 每個候選需要明確的決策連結才執行，最多一組對照和取消配對。設定故障可修正後重跑一次。每案 10 秒 watchdog 僅用於停止與收尾。缺少有效對照、事件順序或必要觀察時為無法判定。實驗狀態與驗證工作是否完成各自記錄。
- 建立前複核目錄、索引及 Git 可達歷史。保留仍可用的候選原指定。占用時按 C01-1、C01-2 的順序挑大於 E022 的最小未使用編號，更新 topic 對應。E020 屬既有唯讀證據。

定論依語意、清楚度、相容性、範圍、可測性、狀態安全與維護性比較 A 保留 nonthrowing Outcome、B throwing cancellation 搭配 Outcome、C BC-local 明確取消結果。既有證據無法解決的決策保留缺口。

## A01 現況追蹤

受審 production 來源為 `386af9e`。Swift 取消是合作式的，task group 會等待 child 收尾，非結構化 Task 由持有 handle 的元件管理。Foundation async URLSession 連動 Swift Task cancellation，底層取消回報可用 URL error，peer 的具體時序由 E021 查證。[Swift SE-0304](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0304-structured-concurrency.md#cancellation) · [Apple WWDC21](https://developer.apple.com/videos/play/wwdc2021/10095/?time=473) · [URLSessionTask.cancel](https://developer.apple.com/documentation/foundation/urlsessiontask/cancel%28%29)

| 邊界 | 目前程式的行為 |
| --- | --- |
| E020 CLI | `withTaskGroup` 啟動查詢及期限兩個子工作，先以 `next()` 選報告，再 `cancelAll()`。離開群組後只印已選的報告。準備的 `try?` 將取消與其他失敗都折為 `.preparationUnavailable`，Facade 返回後按期限、帳號比對、Outcome 消費。逾時報告已選定後，慢 child 可延後退出但無法覆蓋該報告。E020 使用 `RefreshDisabled`。 [Probe.swift](../../experiments/E020/Sources/SelfReviewProbe/Probe.swift#L18-L59) |
| Inbox Port／Facade | `PRInboxFacade.refresh()` 經 `RefreshInboxUseCase` 呼叫 `SelfReviewSource`，以 nonthrowing Outcome 回傳，成功才做同步候選過濾，失敗直接傳遞。未持有 refresh Task handle 或產品狀態。 [RefreshInboxUseCase.swift](../../Sources/BoundedContexts/PRInbox/RefreshInboxUseCase.swift#L16-L23) |
| Inbox Adapter／ProbeREST | Adapter 在 REST await 前及成功返回後檢查取消。catch 將取消、HTTP／credential／decode／分頁等錯誤折為 `.unavailable`。E020 wrapper 還有自己的 send 前取消、期限與用途 guard。最後一次取消檢查後，終頁同步 decode、DTO mapping、Link 檢查與成功回傳間沒有額外檢查。 [GitHubSelfReviewSource.swift](../../Sources/PRInboxGitHub/GitHubSelfReviewSource.swift#L21-L72) · [Probe.swift](../../experiments/E020/Sources/SelfReviewProbe/Probe.swift#L97-L112) |
| GitHub REST | 方法與目的地驗證先於取消檢查。snapshot、replacement、send 的 await 前後觀察 Task flag，辨認 `CancellationError`、`URLError.cancelled`、typed refresh 與支援的 wrapped cancellation，統一擲出 `CancellationError`。其他 credential／執行失敗各有技術分類。只在首個 401 進入一次 recovery，再次 401 表達 authentication failure。 [GitHubHTTPClient.swift](../../Sources/BoundedContexts/GitHubIntegration/REST/GitHubHTTPClient.swift#L50-L132) |
| OAuth Scope／Provider | Scope 在 await 邊界觀察取消。Provider 以自有的共享 restore／refresh Task 及另建的 save Task 控制生命週期。取消一個 caller 不停止共享工作，等待 `.value` 可持續到工作收尾。有效 rotation 仍先保存。共享 refresh 本身已發送且取消、沒有可信回應時，當次為 cancellation，後續是技術上的 `.rotationIndeterminate`。 [OAuthTokenProvider.swift](../../Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift#L136-L159) · [旋轉保存與失敗分類](../../Sources/BoundedContexts/GitHubIntegration/Providers/OAuthTokenProvider.swift#L192-L255) |
| HTTPClient／Transport | Requester 轉交 `URLSessionTransport.execute` 的 `URLSession.data(for:)`。Transport 以 `.cancelled(underlying:)` 保留可辨識的取消。非取消 URL error、非 HTTP response 及無法判讀的 error 各有技術結果。 [URLSessionTransport.swift](../../packages/RivetHTTPClient/Sources/RivetHTTPClient/Execution/URLSessionTransport.swift#L10-L47) |
| Reader Port／E012 | `fetchContent(for:)` 回傳 Reader-local nonthrowing Outcome，現有 failure 無取消 case。找到的 conformer 為既有測試替身。E012 host 自行追蹤頁面世代及逾時，bridge 檢查 PR／snapshot／file identity。現行 fixture 不走 Reader Port。 [PRContentSource.swift](../../Sources/BoundedContexts/PRReader/Core/PRContentSource.swift) · [ReaderHarness.swift](../../experiments/E012/Sources/RivetPRReaderHarnessRuntime/ReaderHarness.swift#L170-L241) |

## B01 八種情境的證據

2026-11-24 於 arm64 macOS 26.5.2／Swift 6.3.3 執行本文件兩條指令。根套件 10 suites／110 項、HTTP Transport 1 suite／6 項，兩條命令均 exit 0。下列受控證據各自限於所述邊界。

| 情境 | 等級與限制 |
| --- | --- |
| 請求前取消 | **Test-confirmed**。REST pre-cancel 是 0 load／0 send。Refresh preflight 是 0 fetch transport。 [REST](../../Tests/GitHubIntegrationTests/REST/GitHubHTTPClientTests.swift#L228-L246) · [Refresh](../../Tests/GitHubIntegrationTests/GitHubOAuthHTTPTokenFetcherTests.swift#L139-L150) |
| HTTP I/O 中取消 | **Test-confirmed**。Foundation URLProtocol 注入的兩種取消形態均保留 underlying error。stub 未觀察實際的 peer close，故 C01-1 使用本地真 Foundation I/O 補證。 [Transport](../../packages/RivetHTTPClient/Tests/RivetHTTPClientTests/Execution/URLSessionTransportTests.swift#L88-L120) |
| Token snapshot 中取消 | **Test-confirmed**。GraphQL restore gate 放行後不送出，Scope 最後檢查不交付。REST 使用同 provider，專屬 in-flight restore 情境未驗證。 [GraphQL](../../Tests/GitHubIntegrationTests/GraphQL/GitHubGraphQLClientTests.swift#L176-L193) · [Scope](../../Tests/GitHubIntegrationTests/GitHubClientScopeTests.swift#L144-L168) |
| Token refresh 中取消 | **Test-confirmed**。REST 是 1 send／1 refresh，取消 caller 不 replay，fetcher 未被取消且仍可取得 replacement。Scope 驗證已接受輪替仍保存。送出後取消到後續 technical terminal 由另一 fetcher 測試支持。 [REST](../../Tests/GitHubIntegrationTests/REST/GitHubHTTPClientTests.swift#L209-L225) · [Scope](../../Tests/GitHubIntegrationTests/GitHubClientScopeTests.swift#L106-L122) · [Refresh](../../Tests/GitHubIntegrationTests/GitHubOAuthHTTPTokenFetcherTests.swift#L250-L259) |
| 回應返回前取消 | **Test-confirmed**。受控 REST 在首個 401 回來時取消，之後 refresh 為 0。正常成功回應跨 Adapter await 晚到由 C01-2 補證。 [REST](../../Tests/GitHubIntegrationTests/REST/GitHubHTTPClientTests.swift#L193-L207) |
| DTO decode 前取消 | **Code-confirmed**。Adapter 在成功 await 後檢查，再同步 decode。**Test-confirmed** 的取消錯誤注入案例得到 `.unavailable` 且恰好兩次請求。最後檢查後可產生成功的空窗屬靜態推論。 [Adapter](../../Sources/PRInboxGitHub/GitHubSelfReviewSource.swift#L60-L72) · [測試](../../Tests/RivetPRInboxGitHubTests/GitHubSelfReviewSourceTests.swift#L168-L176) |
| Task 完成後取消 | **Code-confirmed**。E020 只印已選定的報告。**Unverified**。產品 caller 及狀態 owner 尚未接線，無可觀察的舊結果更新。 [E020](../../experiments/E020/Sources/SelfReviewProbe/Probe.swift#L18-L30) |
| 多個 Task 並行 | **Test-confirmed**。GraphQL shared provider 同時有正常與取消 waiter，覆蓋成功與分類失敗。REST 另確認取消 caller 後可取 shared replacement。兩個 REST caller 的產品狀態消費未驗證。 [GraphQL](../../Tests/GitHubIntegrationTests/GraphQL/GitHubGraphQLClientTests.swift#L279-L330) · [REST](../../Tests/GitHubIntegrationTests/REST/GitHubHTTPClientTests.swift#L209-L225) |

## C01 隔離實測

- **Experiment-confirmed · E021。** 對照是 HTTP 200 與固定 body。取消組在收到完整請求後取消，client 回 `.cancelled`，underlying 為 `NSURLErrorDomain/-999`，loopback peer 在送出回應或開始清理前觀察到 EOF。使用真 Foundation、本機合成 HTTP/1.1 server。 [E021 結果](../../experiments/E021/README.md#結果與證據)
- **Experiment-confirmed · E022。** 在最後成功回應的 stub gate 真正取消 caller，兩個取消旗標皆 true，Facade 回 `.unavailable`。對照取得固定候選，兩組各只有 `/user` 與 `/search/issues`。證據限正式 Adapter／UseCase／Facade 與受控 REST await，最後檢查後的同步窗口仍僅為靜態推論。 [E022 結果](../../experiments/E022/README.md#結果與證據)

兩個案例各一組配對、未重跑。獨立 Tester 確認 production、既有測試及 E020 與基線無差異。

## D01 契約比較與建議

| 元件 | 現況與契約依據 | 分類、影響及變更界線 |
| --- | --- | --- |
| Transport | 以 `.cancelled(underlying:)` 保留取消區別。既有 URLProtocol 測試只支持 mapping。 | **設計改善**。E021 補真本地 I/O 證據。技術契約已能表達取消。既有 caller 無需改動即可個別使用此結果。 |
| REST／OAuth | REST 正規化取消。Provider 管共享工作、版本及已接受輪替保存。受控測試支持取消 caller 不 replay。 | **契約澄清**。caller 可等待共享工作收尾。若改成取消即提前返回，影響 REST／Scope／GraphQL 等 waiter 的等待契約，可獨立於 BC Port 設計處理。 |
| Inbox Adapter／Port | BC 文件規定 HTTP／認證／DTO／分頁失敗映射。Adapter 把取消也折為 `.unavailable`，目前 public Outcome 無取消欄位。 [Inbox 契約](../../docs/architecture/bounded-contexts/pr-inbox.md) | **契約不明**。Facade caller 單看 Outcome 無法識別原因。E020 的期限與報告選定已限制 CLI 的結果消費。若需增加表達，應在產品 caller 上找到具體需求。改簽名或公開 enum 會影響 conformer、caller 或 exhaustive switch。 |
| Reader Port | 執行契約為 nonthrowing Outcome 與 Reader-local failure。GitHub 實際 Adapter 尚未接線。 [Reader 契約](../../docs/architecture/bounded-contexts/pr-reader.md) | **契約不明**。現有測試 conformer 及未來 caller 受介面更動影響。可以在 Reader 自身接線 topic 獨立決定。 |
| 結果提交 | E020 保留首份報告。E012 guard 限本地 fixture。終頁最後一次檢查後存在同步工作窗口。 | **潛在競態**。缺產品 state owner 或提交路徑，未確認產品行為錯誤。結果提交 guard 屬 caller 的獨立責任，可在產品接線時驗證。 |

| 方案 | 語意、相容性與維護 |
| --- | --- |
| A · 保留 nonthrowing Outcome | 維持公開契約與 BC-local failure。Task owner 可觀察自身取消旗標，並獨立驗證 stale-result guard。當下層回報取消但 caller flag 未取消，單看 Outcome 仍無法辨認。 |
| B · `async throws -> Outcome` | 有獨立取消通道，可清楚測試正規化。需遷移 Port conformer、Facade、caller 及測試並定義可擲出的範圍。Outcome 與 catch 雙通道提高維護成本。 |
| C · BC-local 明確取消結果 | 可明確區分成功、failure 與取消。新增 public enum case 或改回傳型別會影響 exhaustive switch 或介面相容性。caller 需多一個狀態分支與相應測試。避免共用 Outcome 擴散不同 BC 的 failure 契約。 |

建議保留 A，後續產品接線先確認 Task owner。讓狀態 owner 在同一隔離點確認請求身分與取消狀態後提交，並以事件控制測試舊結果晚到。出現 caller 需辨識下層取消、且自身旗標不足的產品案例時，再由獨立 BC topic 比較 B／C。未接線的產品 state、同步 decode 中途取消與跨環境 transport 行為保持未驗證。新契約待 Human 決定。
