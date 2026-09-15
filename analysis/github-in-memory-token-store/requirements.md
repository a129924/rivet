# github-in-memory-token-store：需求

## Goal

讓 `GitHubIntegration` 的呼叫端可在單一 process 與單一 store instance 的生命週期內，透過既有 `GitHubTokenStore` contract 保存、讀取、覆寫與刪除一個 GitHub access token，並讓指定長期文件如實同步其已交付的 public、process-local、non-persistent 事實。

## In-Scope

- 一個 process-local、non-persistent 的 in-memory token store。
- 空 store、save/load、overwrite、delete 與空 store delete 的可觀察狀態轉換。
- 外部 consumer 可只依賴 `GitHubIntegration` product 建立並使用該 store。
- 對 `docs/architecture/README.md`、`docs/architecture/bounded-contexts/README.md`、`docs/architecture/bounded-contexts/pr-reader.md` 與 `docs/github-api/README.md` 的受限 factual documentation writeback。

## Non-Goal

- 安全或跨 process credential persistence。
- Token delivery、provider orchestration、GitHub authorization 或請求執行。

## Out-of-Scope

- Keychain、Security framework、檔案、網路、OAuth、refresh、re-auth、401 retry、多帳號、同步與跨裝置行為。
- token validation、正規化、格式化、記錄、加密、帳號選擇或 credential lifecycle 協調。
- `GitHubTokenStore`、credential failure contract、`GitHubTokenProvider` 或 `TokenStoreGitHubTokenProvider` 的變更。
- thread-safety、`Sendable`、actor isolation、async、cancellation 或其他 concurrency guarantee。
- 對上述四份文件以外的 docs、Bounded Context 決策或 deferred capability 的修改。

## Success Criteria

- token 僅存在 store instance 的 process-memory 生命週期；新 instance 與新 process 不取得舊值。
- save 後 load 原樣回傳 token；後一次 save 取代前一次值。
- delete 後及對空 store delete 後，load 均回傳 `nil`。
- 既有 provider 的 `nil → .missingCredential` 與 store-error preservation 行為維持不變。
